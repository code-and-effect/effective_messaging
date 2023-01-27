# Mostly for the callbacks

module EffectiveMessagingParent
  extend ActiveSupport::Concern

  module Base
    def effective_messaging_parent
      include ::EffectiveMessagingParent
    end
  end

  module ClassMethods
    def effective_messaging_parent?; true; end
  end

  included do
    has_many :chats, -> { Effective::Chat.sorted }, as: :parent, class_name: 'Effective::Chat', dependent: :nullify
    accepts_nested_attributes_for :chats
  end

  def chat
    chats.first
  end

  def build_chat
    raise('to be implemented by parent')

    # chat = chats.first || chats.build()
    # chat_user = chat.build_chat_user(user: user)
    # reviewers.each { |reviewer| chat.build_chat_user(user: reviewer.user) }
    # chat
  end

  def create_chat
    build_chat.tap { |chat| chat.save! }
  end

  # Hook so the parent can specify the correct url for this user to visit to see the new chat message
  def chat_url(chat:, user:, root_url:)
    nil
  end

end
