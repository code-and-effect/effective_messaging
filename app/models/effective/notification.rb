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

    AUDIENCES = [
      ['Send to each email or user from the data source', 'report'],
      ['Send to the following addresses', 'emails']
    ]

    SCHEDULE_TYPES = [
      ['On the first day they appear in the data source and every x days thereafter', 'immediate'],
      ['When present in the data source on the following dates', 'scheduled']
    ]

    # SCHEDULE_PERIODS = ['Send once', 'Send daily', 'Send weekly', 'Send monthly', 'Send quarterly', 'Send yearly', 'Send now']

    # SCHEDULE_METHODS = [
    #   ['beginning_of_month', 'First day of the month'],
    #   ['end_of_month', 'Last day of the month'],
    #   ['beginning_of_quarter', 'First day of the quarter'],
    #   ['end_of_quarter', 'Last day of the quarter'],
    #   ['beginning_of_year', 'First day of the year'],
    #   ['end_of_year', 'Last day of the year'],
    # ]

    CONTENT_TYPES = ['text/plain', 'text/html']

    effective_resource do
      audience           :string
      audience_emails    :text
      attach_report     :boolean

      schedule_type      :string

      # When the schedule is immediate. We send the email when they first appear in the data source
      # And then every immediate_days after for immediate_times
      immediate_days     :integer
      immediate_times    :integer

      # schedule_period    :string
      # schedule_method    :string  # Send monthly or Send yearly
      # schedule_times     :integer

      # schedule_dates     :text    # Send once. Serialized array of dates.
      # schedule_wday      :integer # Send weekly
      # schedule_day       :integer # Send monthly or Send yearly
      # schedule_month     :integer # Send yearly

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
    #serialize :schedule_dates, Array

    scope :sorted, -> { order(:id) }
    scope :deep, -> { includes(report: :report_columns) }

    # before_validation(if: -> { audience_emails.blank? }) do
    #   self.audience ||= 'report'
    #   self.schedule_type ||= 'immediate'
    #   self.immediate_days ||= 7
    #   self.immediate_times ||= 3
    # end

    validates :audience, presence: true, inclusion: { in: AUDIENCES.map(&:last) }
    validates :schedule_type, presence: true, inclusion: { in: SCHEDULE_TYPES.map(&:last) }

    validates :audience_emails, presence: true, if: -> { audience == 'emails' }
    validates :attach_report, absence: true, if: -> { audience == 'report' }

    with_options(if: -> { immediate? }) do
      validates :immediate_days, presence: true, numericality: { greater_than: 0 }
      validates :immediate_times, presence: true, numericality: { greater_than: 0 }
    end

    with_options(if: -> { scheduled? }) do
    end

    validates :from, presence: true, email: true
    validates :subject, presence: true, liquid: true
    validates :body, presence: true, liquid: true

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

    def immediate?
      schedule_type == 'immediate'
    end

    def scheduled?
      schedule_type == 'scheduled'
    end

    def audience_emails
      Array(self[:audience_emails]) - [nil, '']
    end

    def schedule_dates
      Array(self[:schedule_dates]) - [nil, '']
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

    def notify!(limit: nil)
      notified = 0

      report.collection().find_each do |resource|
        next unless notifiable?(resource)

        print('.')

        notify_resource!(resource)
        notified += 1

        break if limit && notified >= limit
        GC.start if (notified % 250) == 0
      end

      update!(last_notified_at: Time.zone.now, last_notified_count: notified)
    end

    def notifiable?(resource, date: nil)
      date = (date || Time.zone.now).beginning_of_day

      # Look up the user and email
      user = resource_user(resource)
      email = resource_email(resource) || user.try(:email)
      raise("expected an email for #{report} #{report&.id} and #{resource} #{resource.id}") unless email.present?

      email.present?
    end

    # Consider if we have to send or not
    def notify_resource!(resource, force: false)
      assign_attributes(current_resource: resource) # for logging

      # Send it
      Effective::NotificationsMailer.notification(self, resource).deliver_now
      true
    end

    # Enqueues a job that calls notify!
    def create_notification_job!
      save!
      NotificationJob.perform_later(id)
      true
    end

    def render_email(resource)
      raise('expected a resource') unless resource.present?

      to = resource_email(resource) || resource_user(resource).try(:email)
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
      Array(report&.report_columns).inject({}) do |h, column|
        value = resource.send(column.name)
        h[column.name] = column.format(value); h
      end
    end

    private

    def template_variables(body: true, subject: true)
      [(template_body.presence if body), (template_subject.presence if subject)].compact.map do |template|
        Liquid::ParseTreeVisitor.for(template.root).add_callback_for(Liquid::VariableLookup) do |node|
          [node.name, *node.lookups].join('.')
        end.visit
      end.flatten.uniq.compact
    end

    def resource_user(resource)
      column = report&.user_report_column

      user = resource.public_send(column.name) if column.present?
      user ||= resource if resource.respond_to?(:email)
      user
    end

    def resource_email(resource)
      column = report&.email_report_column
      resource.public_send(column.name) if column.present?
    end

  end
end
