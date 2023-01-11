# frozen_string_literal: true

module Effective
  class ChatMessage < ActiveRecord::Base
    self.table_name = EffectiveMessaging.chat_messages_table_name.to_s

    log_changes(to: :chat) if respond_to?(:log_changes)

    has_many_attached :files

    belongs_to :chat, counter_cache: true
    belongs_to :user, polymorphic: true # Who sent this message

    effective_resource do
      name          :string       # The name, anonymous or display, when sent
      body          :text

      timestamps
    end

    scope :sorted, -> { order(:id) }
    scope :deep, -> { with_attached_files.includes(:chat) }

    # These two validations only trust the body sent.
    # And use the controller's current_user to initialize the user
    before_validation(if: -> { new_record? && user.blank? && chat.present? }) do
      self.user ||= chat.current_user
    end

    # And to find the chat user and set the anonymous or display name
    before_validation(if: -> { new_record? && user.present? && chat.present? }) do
      self.name ||= chat.chat_user(user: user)&.name
    end

    validates :name, presence: true
    validates :body, presence: true

    def to_s
      body.presence || 'New Chat Message'
    end

  end
end
