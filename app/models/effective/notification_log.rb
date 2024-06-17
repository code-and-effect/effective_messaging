# frozen_string_literal: true

module Effective
  class NotificationLog < ActiveRecord::Base
    self.table_name = (EffectiveMessaging.notification_logs_table_name || :notification_logs).to_s

    belongs_to :notification

    belongs_to :report, class_name: 'Effective::Report', optional: true
    belongs_to :resource, polymorphic: true, optional: true
    belongs_to :user, polymorphic: true, optional: true

    effective_resource do
      email        :string
      skipped      :boolean

      timestamps
    end

    scope :sorted, -> { order(:id) }
    scope :deep, -> { includes(:notification, :report, :resource, :user) }

    validates :email, presence: true

    def to_s
      model_name.human
    end

    def days_ago(date: nil)
      now = (date || Time.zone.now).to_date
      (now - (created_at&.to_date || now)).to_i
    end

  end
end
