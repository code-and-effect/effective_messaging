require 'test_helper'

class ChatTest < ActiveSupport::TestCase

  test 'chat user name in public chat' do
    chat = build_effective_chat(anonymous: false)
    chat.save!

    chat_user = chat.chat_users.first

    assert_equal chat_user.name, chat_user.user.to_s
  end

  test 'chat user name in anonymous chat' do
    chat = build_effective_chat(anonymous: true)
    chat.save!

    chat_user = chat.chat_users.first

    assert chat_user.name.include?('Anonymous')
  end

  test 'sending a message notifies users' do
    chat = build_effective_chat()

    user = chat.users.first
    user2 = chat.users.last

    assert_email(count: 2) do
      chat.send_message!(user: user, body: 'Cool message')
    end

    chat.reload
    assert_equal 1, chat.chat_messages.length
    assert chat.chat_users.find { |cu| cu.user == user }.last_notified_at.blank?
    assert chat.chat_users.reject { |cu| cu.user == user}.all? { |cu| cu.last_notified_at.present? }

    # No emails sent because it's before timeout
    assert_email(count: 0) do
      chat.send_message!(user: user, body: 'Cool message 2')
    end

    assert_equal 2, chat.chat_messages.length

    # 1 email should be sent to the user
    assert_email(count: 1) do
      chat.send_message!(user: user2, body: 'Cool message 3')
    end

    chat.reload
    assert_equal 3, chat.chat_messages.length
    assert chat.chat_users.find { |cu| cu.user == user }.last_notified_at.present?
  end

end
