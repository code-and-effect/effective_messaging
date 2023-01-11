# frozen_string_literal: true

module Effective
  class ChatUser < ActiveRecord::Base
    self.table_name = EffectiveMessaging.chat_users_table_name.to_s

    NAMES = [
      'Lion', 'Tiger', 'Boar', 'Horse', 'Dog', 'Cat', 'Panther', 'Leopard', 'Cheetah', 'Walrus', 'Otter',
      'Giraffe', 'Rabbit', 'Monkey', 'Crocodile', 'Alligator', 'Tortoise', 'Turtle', 'Lizard', 'Chameleon',
      'Gecko', 'Flamingo', 'Eagle', 'Pigeon', 'Ostrich', 'Bear', 'Elephant', 'Tortoise', 'Porcupine',
      'Dolphin', 'Fox', 'Armadillo', 'Wolf', 'Gorilla', 'Beaver', 'Badger', 'Hamster', 'Hawk', 'Hippo',
      'Jaguar', 'Koala', 'Kangaroo', 'Rhino', 'Hedgehog', 'Zebra', 'Bison', 'Buffalo', 'Mouse', 'Owl',
    ]

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
      self.display_name ||= user.chat_user_display_name
      self.anonymous_name ||= generate_anonymous_name()
    end

    validates :display_name, presence: true, length: { maximum: 255 }
    validates :anonymous_name, presence: true, length: { maximum: 255 }

    def to_s
      name.presence || 'New Chat User'
    end

    def name
      chat&.anonymous? ? anonymous_name : display_name
    end

    private

    def generate_anonymous_name
      existing = Array(chat&.chat_users).map { |chat_user| chat_user.anonymous_name.to_s.sub('Anonymous', '') }
      'Anonymous' + (NAMES - existing).sample
    end

  end
end
