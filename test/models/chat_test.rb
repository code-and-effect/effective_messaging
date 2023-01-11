require 'test_helper'

class ChatTest < ActiveSupport::TestCase
  test 'sending a message notified users' do
    chat = create_effective_chat!
    user = chat.users.first

    assert_email(count: 2) do
      chat.send_message!(user: user, body: 'Cool message')
    end

    assert_equal 1, chat.chat_messages.length

  end


end
