require 'test_helper'

class MessagingTest < ActiveSupport::TestCase
  test 'user factory' do
    user = build_user()
    assert user.valid?
  end

  test 'chat factory' do
    chat = build_effective_chat()
    assert chat.valid?

    assert_equal 0, chat.chat_messages.length
    assert_equal 3, chat.chat_users.length
    assert_equal 3, chat.users.length

    assert chat.save!
  end

end
