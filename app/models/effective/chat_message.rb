# frozen_string_literal: true

module Effective
  class ChatMessage < ActiveRecord::Base
    self.table_name = EffectiveMessaging.chat_messages_table_name.to_s

    log_changes(to: :chat) if respond_to?(:log_changes)

    belongs_to :chat, counter_cache: true

    # Who sent this message
    belongs_to :chat_user
    belongs_to :user, polymorphic: true

    effective_resource do
      name          :string       # The name, anonymous or display, when sent
      body          :text

      timestamps
    end

    scope :sorted, -> { order(:id) }
    scope :deep, -> { includes(:chat) }

    # Use the controller's current_user to initialize the chat_user, user and name
    before_validation(if: -> { new_record? && chat.present? }) do
      self.user ||= chat.current_user
      self.chat_user ||= chat.chat_user(user: self.user)
      self.name ||= self.chat_user&.name
    end

    after_commit(on: :create) { chat.notify!(except: chat_user) }

    validates :name, presence: true
    validates :body, presence: true

    def to_s
      body.presence || 'New Chat Message'
    end

  end
end
