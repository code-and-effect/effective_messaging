# EffectiveMessagingUser
#
# Mark your user model with effective_messaging_user to get all the includes

module EffectiveMessagingUser
  extend ActiveSupport::Concern

  module Base
    def effective_messaging_user
      include ::EffectiveMessagingUser
    end
  end

  module ClassMethods
    def effective_messaging_user?; true; end
  end

  included do
    has_many :chat_users, -> { Effective::ChatUser.sorted },
      class_name: 'Effective::ChatUser', inverse_of: :user, dependent: :nullify

    accepts_nested_attributes_for :chat_users, allow_destroy: true

    has_many :chats, -> { Effective::Chat.sorted }, through: :chat_users, class_name: 'Effective::Chat'
    accepts_nested_attributes_for :chats, allow_destroy: true
  end

  # Instance Methods
  def chat_user(chat:)
    chat_users.find { |cu| cu.chat_id == chat.id }
  end

  # Find or build
  # def build_chat_user(chat:)
  #   chat_user(chat: chat) || chat_users.build(chat: chat)
  # end

end
