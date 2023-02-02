# frozen_string_literal: true

module Effective
  class Notification < ActiveRecord::Base
    self.table_name = EffectiveMessaging.notifications_table_name.to_s

    attr_accessor :current_user
    attr_accessor :current_resource
    log_changes if respond_to?(:log_changes)

    # Unused. If we want to use notifications in a has_many way
    belongs_to :parent, polymorphic: true, optional: true

    # When the notification belongs to one user
    belongs_to :user, polymorphic: true, optional: true

    # Effective namespace
    belongs_to :report, class_name: 'Effective::Report'

    CONTENT_TYPES = ['text/plain', 'text/html']

    effective_resource do
      send_at           :datetime

      subject           :string
      body              :text

      from              :string
      cc                :string
      bcc               :string

      # Tracking background jobs email send out
      started_at         :datetime
      completed_at       :datetime
      notifications_sent :integer

      timestamps
    end

    scope :sorted, -> { order(:id) }
    scope :deep, -> { includes(report: :report_columns) }

    scope :upcoming, -> { where('send_at > ?', Time.zone.now) }
    scope :started, -> { where.not(started_at: nil) }
    scope :completed, -> { where.not(completed_at: nil) }

    # Called by the notifier rake task
    scope :notifiable, -> { where(started_at: nil) }

    before_validation(if: -> { send_at_changed? }) do
      assign_attributes(started_at: nil, completed_at: nil, notifications_sent: nil)
    end

    validates :send_at, presence: true
    validates :from, presence: true, email: true
    validates :subject, presence: true, liquid: true
    validates :body, presence: true, liquid: true

    validate(if: -> { report.present? }) do
      self.errors.add(:report, 'must include an email column') unless report.email_report_column.present?
    end

    validate(if: -> { report.present? && subject.present? }) do
      if(invalid = template_variables(body: false) - report_variables).present?
        self.errors.add(:subject, "Invalid variable: #{invalid.to_sentence}")
      end
    end

    validate(if: -> { report.present? && body.present? }) do
      if(invalid = template_variables(subject: false) - report_variables).present?
        self.errors.add(:body, "Invalid variable: #{invalid.to_sentence}")
      end
    end

    def to_s
      subject.presence || 'notification'
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

    def notifiable?
      started_at.blank? && completed_at.blank?
    end

    def notify_now?
      notifiable? && Time.zone.now >= send_at
    end

    def notify!(force: true, limit: 5)
      return false unless (notify_now? || force)

      update!(started_at: Time.zone.now)

      index = 0

      report.collection().find_each do |resource|
        print('.')

        assign_attributes(current_resource: resource)
        EffectiveMessaging.mailer_class.send(:notification, self, resource).deliver_now

        index += 1
        break if limit && index >= limit

        GC.start if (index % 250) == 0
      end

      update!(current_resource: nil, completed_at: Time.zone.now, notifications_sent: index)
    end

    def render_email(resource)
      raise('expected a resource') unless resource.present?

      assigns = assigns_for(resource)
      email = assigns.fetch(report.email_report_column.name) || raise('expected an email assigns')

      {
        to: email,
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

  end
end
