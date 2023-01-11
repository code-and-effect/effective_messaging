# frozen_string_literal: true

module Effective
  class ChatUser < ActiveRecord::Base
    self.table_name = EffectiveMessaging.chat_users_table_name.to_s

    log_changes(to: :chat) if respond_to?(:log_changes)

    belongs_to :chat
    belongs_to :user, polymorphic: true

    scope :with_name, -> (name) {
      anonymous = where(chat_id: Chat.where(anonymous: true)).where('anonymous_name ILIKE ?', "%#{name}%")
      displayed = where(chat_id: Chat.where(anonymous: false)).where('display_name ILIKE ?', "%#{name}%")

      anonymous.or(displayed)
    }

    effective_resource do
      display_name      :string
      anonymous_name    :string

      last_notified_at  :datetime

      timestamps
    end

    scope :sorted, -> { order(:id) }
    scope :deep, -> { includes(:chat) }

    before_validation do
      self.display_name ||= user.effective_messaging_display_name
      self.anonymous_name ||= user.effective_messaging_anonymous_name
    end

    validates :display_name, presence: true, length: { maximum: 255 }
    validates :anonymous_name, presence: true, length: { maximum: 255 }

    def to_s
      name.presence || 'New Chat User'
    end

    def name
      chat&.anonymous? ? anonymous_name : display_name
    end

  end
end
