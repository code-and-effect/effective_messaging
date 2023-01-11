# frozen_string_literal: true

module Effective
  class Chat < ActiveRecord::Base
    self.table_name = EffectiveMessaging.chats_table_name.to_s

    attr_accessor :current_user
    attr_accessor :user_type # Must be set when creating a chat by admin/new form, and passing user_ids

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

    def chat_user(user:)
      raise('expected an effective_messaging_user') unless user.class.respond_to?(:effective_messaging_user?)
      chat_users.find { |cu| cu.user_id == user.id && cu.user_type == user.class.name }
    end

    def build_chat_user(user:)
      chat_user(user: user) || chat_users.build(user: user)
    end

    def chat_messages_for(user:)
      raise('expected an effective_messaging_user') unless user.class.respond_to?(:effective_messaging_user?)
      chat_messages.select { |cm| cm.user_id == user.id && cm.user_type == user.class.name }
    end

    # Find or build
    def build_chat_message(user:, body: nil)
      raise('expected an effective_messaging_user') unless user.class.respond_to?(:effective_messaging_user?)
      chat_messages.build(user: user, body: body)
    end

    # Builders for polymorphic users
    def users
      chat_users.map(&:users)
    end

    def user_ids
      chat_users.map(&:user_id)
    end

    def user_ids=(user_ids)
      raise('expected a user_type') unless user_type.present?

      # The users in this chat
      users = user_type.constantize.where(id: user_ids)

      # Mark for destruction
      chat_users.each { |cu| cu.mark_for_destruction unless users.include?(cu.user) }

      # Build
      users.each { |user| build_chat_user(user: user) }

      # Return all chat users. Some might be marked for destruction.
      chat_users
    end

  end
end
