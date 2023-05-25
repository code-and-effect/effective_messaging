# frozen_string_literal: true

module Effective
  class Notification < ActiveRecord::Base
    self.table_name = EffectiveMessaging.notifications_table_name.to_s

    attr_accessor :current_user
    attr_accessor :current_resource

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

    serialize :audience_emails, Array
    serialize :scheduled_dates, Array

    scope :sorted, -> { order(:id) }
    scope :deep, -> { includes(report: :report_columns) }

    scope :enabled, -> { where(enabled: true) }
    scope :disabled, -> { where(enabled: false) }

    before_validation do
      self.from ||= EffectiveMessaging.froms.first
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
      errors.add(:report, 'must include an email or user column') unless report.email_report_column || report.user_report_column
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
      Array(report&.report_columns).map(&:name)
    end

    def rows_count
      @rows_count ||= report.collection().count if report
    end

    # Button on the Admin interface. Enqueues the job to send right away.
    def send_now!
      raise('expected to be persisted') unless persisted?
      NotificationJob.perform_later(id)
      true
    end

    # The main function
    def notify!
      scheduled_email? ? notify_by_schedule! : notify_by_resources!
    end

    # Operates on every resource in the data source. Sends one email for each row
    def notify_by_resources!
      notified = 0

      report.collection().find_each do |resource|
        next unless notifiable?(resource)
        print('.')

        # For logging
        assign_attributes(current_resource: resource)

        # Send the resource email
        build_notification_log(resource: resource).save!
        Effective::NotificationsMailer.notify_resource(self, resource).deliver_now

        notified += 1

        GC.start if (notified % 250) == 0
      end

      notified > 0 ? update!(last_notified_at: Time.zone.now, last_notified_count: notified) : touch
    end

    def notify_by_schedule!
      notified = 0

      if notifiable_scheduled?
        build_notification_log(resource: nil).save!
        Effective::NotificationsMailer.notify(self).deliver_now
        notified += 1
      end

      notified > 0 ? update!(last_notified_at: Time.zone.now, last_notified_count: notified) : touch
    end

    def notifiable?(resource)
      raise('expected an acts_as_reportable resource') unless resource.class.try(:acts_as_reportable?)

      if schedule_type == 'immediate'
        notifiable_immediate?(resource: resource)
      elsif schedule_type == 'scheduled'
        notifiable_scheduled?(date: nil)
      else
        raise("unsupported schedule_type")
      end
    end

    # Consider the notification logs which track how many and how long ago this notification was sent
    # It's notifiable? when first time or if it's been immediate_days since last notification
    def notifiable_immediate?(resource:)
      raise('expected an immexiate? notification') unless immediate?

      email = resource_email(resource) || resource_user(resource).try(:email)
      raise("expected an email for #{report} #{report&.id} and #{resource} #{resource&.id}") unless email.present?

      logs = notification_logs.select { |log| log.email == email }

      if logs.count == 0
        true # This is the first time. We should send.
      elsif logs.count < immediate_times
        # We still have to send it but consider dates.
        last_sent_days_ago = logs.map(&:days_ago).min || 0
        last_sent_days_ago >= immediate_days
      else
        false # We've already sent enough times
      end
    end

    def notifiable_scheduled?(date: nil)
      raise('expected a scheduled? notification') unless scheduled?

      date ||= Time.zone.now.beginning_of_day

      case scheduled_method
      when 'days'
        scheduled_dates.find { |day| day == date.strftime('%F') }.present?
      else
        raise('unsupported scheduled_method')
      end
    end

    def render_email(resource = nil)
      raise('expected an acts_as_reportable resource') if resource.present? && !resource.class.try(:acts_as_reportable?)

      to = if audience == 'emails'
        audience_emails.presence
      elsif audience == 'report'
        resource_email(resource) || resource_user(resource).try(:email)
      end

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

    def assigns_for(resource)
      return {} unless resource.present?

      Array(report&.report_columns).inject({}) do |h, column|
        value = resource.send(column.name)
        h[column.name] = column.format(value); h
      end
    end

    def build_notification_log(resource: nil)
      user = resource_user(resource)

      email = resource_email(resource) || user.try(:email)
      email ||= audience_emails_to_s if scheduled_email?

      notification_logs.build(email: email, report: report, resource: resource, user: user)
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
      audience_emails.presence&.join(',')
    end

    def resource_user(resource)
      return unless resource.present?

      column = report&.user_report_column
      return unless column.present?

      resource.public_send(column.name) || (resource if resource.respond_to?(:email))
    end

    def resource_email(resource)
      return unless resource.present?

      column = report&.email_report_column
      return unless column.present?

      resource.public_send(column.name)
    end

  end
end
