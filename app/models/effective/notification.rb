# frozen_string_literal: true

module Effective
  class Notification < ActiveRecord::Base
    self.table_name = EffectiveMessaging.notifications_table_name.to_s

    attr_accessor :current_user

    log_changes if respond_to?(:log_changes)

    effective_resource do
      subject           :string
      from              :string
      cc                :string
      bcc               :string
      body              :text

      last_notified_at  :datetime

      timestamps

    end

    scope :sorted, -> { order(:id) }
    scope :deep, -> { includes(:chat) }

    validates :from, presence: true, email: true
    validates :body, presence: true, liquid: true
    validates :subject, presence: true, liquid: true

    def to_s
      body.presence || 'New Notification'
    end

    def template_body
      Liquid::Template.parse(body)
    end

    def template_subject
      Liquid::Template.parse(subject)
    end

  end
end
