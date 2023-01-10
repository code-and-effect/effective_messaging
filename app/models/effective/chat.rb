# frozen_string_literal: true

module Effective
  class Chat < ActiveRecord::Base
    self.table_name = EffectiveMessaging.chats_table_name.to_s

    acts_as_tokened
    log_changes if respond_to?(:log_changes)

    # If we want to use chats in a has_many way
    belongs_to :parent, polymorphic: true, optional: true

    has_many :chat_users, -> { ChatUser.sorted }, inverse_of: :chat, dependent: :destroy
    accepts_nested_attributes_for :chat_users, allow_destroy: true

    has_many :chat_messages, -> { ChatMessage.sorted }, inverse_of: :chat, dependent: :destroy
    accepts_nested_attributes_for :chat_messages, allow_destroy: true

    effective_resource do
      title                  :string
      anonymous              :boolean

      chat_messages_count    :integer
      token                  :string

      timestamps
    end

    scope :sorted, -> { order(id: :desc) }
    scope :deep, -> { includes(:chat_users, :chat_messages) }

    validates :title, presence: true, length: { maximum: 255 }

    def to_s
      title.presence || 'New Chat'
    end

  end
end
