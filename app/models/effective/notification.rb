# frozen_string_literal: true

module Effective
  class Notification < ActiveRecord::Base
    self.table_name = EffectiveMessaging.notifications_table_name.to_s

    attr_accessor :source # Does Nothing
    attr_accessor :current_user

    log_changes if respond_to?(:log_changes)

    # Unused. If we want to use notifications in a has_many way
    belongs_to :parent, polymorphic: true, optional: true

    # When the notification belongs to one user
    belongs_to :user, polymorphic: true, optional: true

    # Effective namespace
    belongs_to :report, class_name: 'Effective::Report'

    effective_resource do
      send_at           :datetime

      subject           :string
      body              :text

      from              :string
      cc                :string
      bcc               :string

      last_notified_at  :datetime

      timestamps
    end

    scope :sorted, -> { order(:id) }
    scope :deep, -> { all }

    scope :upcoming, -> { where('send_at > ?', Time.zone.now) }
    scope :notified, -> { where.not(last_notified_at: nil) }

    validates :send_at, presence: true
    validates :from, presence: true, email: true
    validates :subject, presence: true, liquid: true
    validates :body, presence: true, liquid: true

    validate(if: -> { report.present? }) do
      self.errors.add(:report, 'must include an email column') unless report_email_column.present?
    end

    def to_s
      body.presence || 'New Notification'
    end

    def report_email_column
      return unless report.present?
      report.report_columns.find { |column| column.name.include?('email') }
    end

    def report_email_variables
      Array(report&.report_columns).map(&:name)
    end

    def template_body
      Liquid::Template.parse(body)
    end

    def template_subject
      Liquid::Template.parse(subject)
    end

  end
end
