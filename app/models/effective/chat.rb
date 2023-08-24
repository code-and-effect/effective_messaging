# frozen_string_literal: true

module Effective
  class Chat < ActiveRecord::Base
    self.table_name = (EffectiveMessaging.chats_table_name || :chats).to_s

    NOTIFY_AFTER = 2.minutes

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

    scope :for_user, -> (user) { where(id: ChatUser.where(user: user).select(:chat_id)) }
    scope :search_by_chat_user_name, -> (name) { where(id: ChatUser.with_name(name).select(:chat_id)) }

    validates :title, presence: true, length: { maximum: 255 }

    def to_s
      title.presence || 'New Chat'
    end

    # This is an API for sending a message.
    def send_message!(user:, body:)
      raise('expected an effective_messaging_user') unless user.class.respond_to?(:effective_messaging_user?)

      chat_user = chat_user(user: user)
      raise('expected user to be a chat_user in this chat') unless chat_user.present?

      # Build and send message
      chat_message = chat_messages.build(body: body, user: user, chat_user: chat_user, name: chat_user.name)

      # Creates message, which also calls notify! below
      save!

      chat_message
    end

    # Called by an after_commit on chat message
    def notify!(except: nil, force: false)
      raise('expected a ChatUser') if except.present? && !except.kind_of?(ChatUser)

      # Notify everyone in the chat except the user that created this message
      notified = (chat_users - [except]).map do |chat_user|

        # Only notify once every 5 minutes unless force
        if chat_user.last_notified_at.present? && !force
          next if (Time.zone.now - chat_user.last_notified_at) < NOTIFY_AFTER
        end

        EffectiveMessaging.send_email(:chat_new_message, self, chat_user)
        chat_user
      end

      ChatUser.where(id: notified).update_all(last_notified_at: Time.zone.now) if notified.present?

      # updated_at is when last message was sent
      touch
    end

    def chat_user(user:)
      raise('expected an effective_messaging_user') unless user.class.respond_to?(:effective_messaging_user?)
      chat_users.find { |cu| cu.user_id == user.id && cu.user_type == user.class.name }
    end

    def build_chat_user(user:, anonymous_name: nil)
      cu = chat_user(user: user) || chat_users.build(user: user)
      cu.assign_attributes(anonymous_name: anonymous_name) if anonymous_name.present?
      cu
    end

    # Always build
    def build_chat_message(user:, body: nil)
      raise('expected an effective_messaging_user') unless user.class.respond_to?(:effective_messaging_user?)
      chat_messages.build(user: user, body: body)
    end

    # Builders for polymorphic users form
    def users
      chat_users.map(&:user)
    end

    def user_ids
      chat_users.map(&:user_id)
    end

    def user_ids=(user_ids)
      raise('expected a user_type') unless user_type.present?

      # The users in this chat
      self.users = user_type.constantize.where(id: user_ids)

      # Return user_ids
      user_ids
    end

    def users=(users)
      users = Array(users)
      raise('expected a effective_messaging_user') unless users.all? { |user| user.class.respond_to?(:effective_messaging_user?) }

      # Mark for destruction
      chat_users.each { |cu| cu.mark_for_destruction unless users.include?(cu.user) }

      # Find or build chat_users
      users.each { |user| build_chat_user(user: user) }

      # Return users
      users
    end

  end
end
