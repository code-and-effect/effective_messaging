# frozen_string_literal: true

module Effective
  class Notification < ActiveRecord::Base
    self.table_name = (EffectiveMessaging.notifications_table_name || :notifications).to_s

    attr_accessor :current_user
    attr_accessor :current_resource
    attr_accessor :view_context

    log_changes if respond_to?(:log_changes)

    # Unused. If we want to use notifications in a has_many way
    belongs_to :parent, polymorphic: true, optional: true

    # Unused. When the notification belongs to one user
    belongs_to :user, polymorphic: true, optional: true

    # Effective namespace
    belongs_to :report, class_name: 'Effective::Report', optional: true

    # Tracks the send outs
    has_many :notification_logs, dependent: :delete_all
    accepts_nested_attributes_for :notification_logs

    AUDIENCES = [
      ['Send to user or email from the report', 'report'],
      ['Send to specific addresses', 'emails']
    ]

    SCHEDULE_TYPES = [
      ['On the first day they appear in the report and every x days thereafter', 'immediate'],
      ['When present in the report on the following dates', 'scheduled']
    ]

    # TODO: ['Send once', 'Send daily', 'Send weekly', 'Send monthly', 'Send quarterly', 'Send yearly', 'Send now']
    SCHEDULED_METHODS = [
      ['The following dates...', 'dates'],
    ]

    CONTENT_TYPES = ['text/plain', 'text/html']

    effective_resource do
      audience           :string
      audience_emails    :text

      enabled            :boolean
      attach_report      :boolean

      schedule_type      :string

      # When the schedule is immediate. We send the email when they first appear in the data source
      # And then every immediate_days after for immediate_times
      immediate_days     :integer
      immediate_times    :integer

      # When the schedule id scheduled. We send the email to everyone in the audience on the given dates
      scheduled_method    :string
      scheduled_dates     :text

      # Email
      subject           :string
      body              :text

      from              :string
      cc                :string
      bcc               :string

      # Background tracking
      last_notified_at      :datetime
      last_notified_count   :integer

      timestamps
    end

    if EffectiveResources.serialize_with_coder?
      serialize :audience_emails, type: Array, coder: YAML
      serialize :scheduled_dates, type: Array, coder: YAML
    else
      serialize :audience_emails, Array
      serialize :scheduled_dates, Array
    end

    scope :sorted, -> { order(:id) }
    scope :deep, -> { includes(report: :report_columns) }

    scope :enabled, -> { where(enabled: true) }
    scope :disabled, -> { where(enabled: false) }

    before_validation do
      self.from ||= EffectiveMessaging.mailer_froms.first
    end

    # Emails or Report
    validates :audience, presence: true, inclusion: { in: AUDIENCES.map(&:last) }
    validates :audience_emails, presence: true, if: -> { audience_emails? }

    # Scheduled or Immediate
    validates :schedule_type, presence: true, inclusion: { in: SCHEDULE_TYPES.map(&:last) }

    # Attach Report - Only for scheduled emails
    validates :attach_report, absence: true, unless: -> { scheduled_email? }

    # Immediate
    with_options(if: -> { immediate? }) do
      validates :immediate_days, presence: true, numericality: { greater_than_or_equal_to: 0 }
      validates :immediate_times, presence: true, numericality: { greater_than_or_equal_to: 1 }
    end

    validate(if: -> { immediate? && immediate_days.present? && immediate_times.present? }) do
      self.errors.add(:immediate_times, "must be 1 when when using every 0 days") if immediate_days == 0 && immediate_times != 1
    end

    # Scheduled
    validates :scheduled_method, presence: true, inclusion: { in: SCHEDULED_METHODS.map(&:last) }, if: -> { scheduled? }

    with_options(if: -> { scheduled_method.to_s == 'dates' }) do
      validates :scheduled_dates, presence: true
    end

    validate(if: -> { scheduled_dates.present? }) do
      scheduled_dates.each do |str|
        errors.add(:scheduled_dates, "expected a string") unless str.kind_of?(String)
        errors.add(:scheduled_dates, "#{str} is an invalid date") unless (Time.zone.parse(str) rescue false)
      end
    end

    # Email
    validates :from, presence: true, email: true
    validates :subject, presence: true, liquid: true
    validates :body, presence: true, liquid: true

    # Report
    validates :report, presence: true

    validate(if: -> { report.present? }) do
      errors.add(:report, 'must include an email, user, organization or owner column') unless report.email_report_column || report.emailable_report_column
    end

    validate(if: -> { report.present? && subject.present? }) do
      if(invalid = template_variables(body: false) - report_variables).present?
        errors.add(:subject, "Invalid variable: #{invalid.to_sentence}")
      end
    end

    validate(if: -> { report.present? && body.present? }) do
      if(invalid = template_variables(subject: false) - report_variables).present?
        errors.add(:body, "Invalid variable: #{invalid.to_sentence}")
      end
    end

    def to_s
      subject.presence || model_name.human
    end

    def schedule
      if immediate?
        "Send immediately then every #{immediate_days} days for #{immediate_times} times total"
      elsif scheduled? && scheduled_method == 'dates'
        "Send on #{scheduled_dates.length} scheduled days: #{scheduled_dates.sort.to_sentence}"
      else
        'todo'
      end
    end

    # This operates on each row of the resource.
    # We track the number of notifications total to see if we should notify again or not
    def immediate?
      schedule_type == 'immediate'
    end

    def scheduled?
      schedule_type == 'scheduled'
    end

    def audience_emails?
      audience == 'emails'
    end

    def audience_report?
      audience == 'report'
    end

    # Only scheduled emails can have attached reports.
    # Only scheduled emails can do Send Now
    def scheduled_email?
      scheduled? && audience_emails?
    end

    def audience_emails
      Array(self[:audience_emails]) - [nil, '']
    end

    def scheduled_dates
      Array(self[:scheduled_dates]) - [nil, '']
    end

    def template_subject
      Liquid::Template.parse(subject)
    end

    def template_body
      Liquid::Template.parse(body)
    end

    def report_variables
      assigns_for().keys
    end

    def assign_renderer(view_context)
      raise('expected renderer to respond to') unless view_context.respond_to?(:root_url)
      assign_attributes(view_context: view_context)
      self
    end

    def renderer
      view_context || nil # This isn't ideal
    end

    def rows_count
      @rows_count ||= report.collection().count if report
    end

    def notifiable_rows_count
      report.collection().select { |resource| notifiable?(resource) }.count if report
    end

    def notifiable_tomorrow_rows_count
      report.collection().select { |resource| notifiable_tomorrow?(resource) }.count if report
    end

    def enable!
      update!(enabled: true)
    end

    def disable!
      update!(enabled: false)
    end

    # Enqueues this notification to send right away.
    # Only applies to scheduled_email? notifications
    def send_now!
      raise('expected to be persisted') unless persisted?
      NotificationJob.perform_later(id, force: true)
      true
    end

    # Only applies to immedate? notifications
    # Skips over one notification on the immediate notifications
    def skip_once!
      notified = 0

      report.collection().find_each do |resource|
        print('.')

        # For logging
        assign_attributes(current_resource: resource)

        # Send the resource email
        build_notification_log(resource: resource, skipped: true).save!

        notified += 1

        GC.start if (notified % 250) == 0
      end

      touch
    end

    # The main function to send this thing
    def notify!(force: false)
      scheduled_email? ? notify_by_schedule!(force: force) : notify_by_resources!(force: force)
    end

    # Operates on every resource in the data source. Sends one email for each row
    def notify_by_resources!(force: false)
      notified = 0

      report.collection().find_each do |resource|
        next unless notifiable?(resource) || force

        # Send Now functionality. Don't duplicate if it's same day.
        next if force && already_notified_today?(resource)

        print('.')

        begin
          # For logging
          assign_attributes(current_resource: resource)

          # Send the resource email
          Effective::NotificationsMailer.notify_resource(self, resource).deliver_now

          # Log that it was sent
          build_notification_log(resource: resource).save!

          # Count how many we actually sent
          notified += 1
        rescue => e
          EffectiveLogger.error(e.message, associated: self) if defined?(EffectiveLogger)
          ExceptionNotifier.notify_exception(e, data: { notification_id: id, resource_id: resource.id, resource_type: resource.class.name }) if defined?(ExceptionNotifier)
        end

        GC.start if (notified % 250) == 0
      end

      notified > 0 ? update!(last_notified_at: Time.zone.now, last_notified_count: notified) : touch
    end

    def notify_by_schedule!(force: false)
      notified = 0

      if notifiable_scheduled? || force
        begin
          Effective::NotificationsMailer.notify(self).deliver_now

          # Log that it was sent
          build_notification_log(resource: nil).save!

          # Count how many we actually sent
          notified += 1
        rescue => e
          EffectiveLogger.error(e.message, associated: self) if defined?(EffectiveLogger)
          ExceptionNotifier.notify_exception(e, data: { notification_id: id }) if defined?(ExceptionNotifier)
        end

      end

      notified > 0 ? update!(last_notified_at: Time.zone.now, last_notified_count: notified) : touch
    end

    def notifiable?(resource, date: nil)
      raise('expected an acts_as_reportable resource') unless resource.class.try(:acts_as_reportable?)

      if schedule_type == 'immediate'
        notifiable_immediate?(resource: resource, date: date)
      elsif schedule_type == 'scheduled'
        notifiable_scheduled?(date: date)
      else
        raise("unsupported schedule_type")
      end
    end

    def notifiable_tomorrow?(resource)
      date = Time.zone.now.beginning_of_day.advance(days: 1)
      notifiable?(resource, date: date)
    end

    def already_notified_today?(resource)
      email = resource_emails_to_s(resource)
      raise("expected an email for #{report} #{report&.id} and #{resource} #{resource&.id}") unless email.present?

      logs = notification_logs.select { |log| log.email == email }
      return false if logs.count == 0

      # If we already notified today
      logs.any? { |log| log.created_at&.beginning_of_day == Time.zone.now.beginning_of_day }
    end

    # Consider the notification logs which track how many and how long ago this notification was sent
    # It's notifiable? when first time or if it's been immediate_days since last notification
    def notifiable_immediate?(resource:, date: nil)
      raise('expected an immediate? notification') unless immediate?

      email = resource_emails_to_s(resource)
      raise("expected an email for #{report} #{report&.id} and #{resource} #{resource&.id}") unless email.present?

      logs = notification_logs.select { |log| log.email == email }

      if logs.count == 0
        true # This is the first time. We should send.
      elsif logs.count < immediate_times
        # We still have to send it but consider dates.
        last_sent_days_ago = logs.map { |log| log.days_ago(date: date) }.min || 0
        (last_sent_days_ago >= immediate_days)
      else
        false # We've already sent enough times
      end
    end

    def notifiable_scheduled?(date: nil)
      raise('expected a scheduled? notification') unless scheduled?

      date ||= Time.zone.now.beginning_of_day

      case scheduled_method
      when 'dates'
        scheduled_dates.find { |day| day == date.strftime('%F') }.present?
      else
        raise('unsupported scheduled_method')
      end
    end

    def render_email(resource = nil)
      raise('expected an acts_as_reportable resource') if resource.present? && !resource.class.try(:acts_as_reportable?)

      to = (audience == 'emails' ? audience_emails.presence : resource_emails_to_s(resource))
      raise('expected a to email address') unless to.present?

      assigns = assigns_for(resource)

      {
        to: to,
        from: from,
        cc: cc.presence,
        bcc: bcc.presence,
        content_type: CONTENT_TYPES.first,
        subject: template_subject.render(assigns),
        body: template_body.render(assigns)
      }.compact
    end

    # We pull the Assigns from 3 places:
    # 1. The report.report_columns
    # 2. The class's def reportable_view_assigns(view) method
    def assigns_for(resource = nil)
      return {} unless report.present? 

      resource ||= report.reportable.new
      raise('expected an acts_as_reportable resource') unless resource.class.try(:acts_as_reportable?)
      
      report_assigns = Array(report.report_columns).inject({}) do |h, column|
        value = resource.send(column.name)
        h[column.name] = column.format(value); h
      end

      reportable_view_assigns = resource.reportable_view_assigns(renderer).deep_stringify_keys
      raise('expected notification assigns to return a Hash') unless reportable_view_assigns.kind_of?(Hash)

      # Merge all 3
      report_assigns.merge(reportable_view_assigns)
    end

    def build_notification_log(resource: nil, skipped: false)
      emailable = resource_emailable(resource)

      email = resource_emails_to_s(resource)
      email ||= audience_emails_to_s if scheduled_email?

      notification_logs.build(email: email, report: report, resource: resource, user: emailable, skipped: skipped)
    end

    private

    def template_variables(body: true, subject: true)
      [(template_body.presence if body), (template_subject.presence if subject)].compact.map do |template|
        Liquid::ParseTreeVisitor.for(template.root).add_callback_for(Liquid::VariableLookup) do |node|
          [node.name, *node.lookups].join('.')
        end.visit
      end.flatten.uniq.compact
    end

    def audience_emails_to_s
      audience_emails.presence&.join(', ')
    end

    # All emails for this emailable resource
    def resource_emails_to_s(resource)
      emails = Array(resource_email(resource)).map(&:presence).compact

      if emails.blank? && (emailable = resource_emailable(resource)).present?
        emails = Array(emailable.try(:reportable_emails) || emailable.try(:email)).map(&:presence).compact
      end

      emails.presence&.join(', ')
    end

    # A user, owner, or organization column
    def resource_emailable(resource)
      return unless resource.present?

      column = report&.emailable_report_column
      return unless column.present?

      resource.public_send(column.name) || (resource if resource.respond_to?(:email))
    end

    # An email column
    def resource_email(resource)
      return unless resource.present?

      column = report&.email_report_column
      return unless column.present?

      resource.public_send(column.name)
    end

  end
end
