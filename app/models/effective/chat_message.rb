# frozen_string_literal: true

module Effective
  class ChatMessage < ActiveRecord::Base
    self.table_name = EffectiveMessaging.chat_messages_table_name.to_s

    log_changes(to: :chat) if respond_to?(:log_changes)

    has_many_attached :files

    belongs_to :chat, counter_cache: true
    belongs_to :user, polymorphic: true # Who sent this message

    effective_resource do
      body          :text

      timestamps
    end

    scope :sorted, -> { order(:id) }
    scope :deep, -> { with_attached_files.includes(:chat) }

    validates :body, presence: true

    def to_s
      body.presence || 'New Chat Message'
    end

  end
end
