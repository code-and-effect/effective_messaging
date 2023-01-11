module EffectiveMessagingTestBuilder

  def create_effective_chat!
    build_effective_chat.tap { |chat| chat.save! }
  end

  def build_effective_chat
    user1 = create_user!
    user2 = create_user!
    user3 = create_user!

    Effective::Chat.new(title: 'Effective Chat', users: [user1, user2, user3])
  end

  def create_user!
    build_user.tap { |user| user.save! }
  end

  def build_user
    @user_index ||= 0
    @user_index += 1

    User.new(
      email: "user#{@user_index}@example.com",
      password: 'rubicon2020',
      password_confirmation: 'rubicon2020',
      first_name: 'Test',
      last_name: 'User'
    )
  end

  def build_user_with_address
    user = build_user()

    user.addresses.build(
      addressable: user,
      category: 'billing',
      full_name: 'Test User',
      address1: '1234 Fake Street',
      city: 'Victoria',
      state_code: 'BC',
      country_code: 'CA',
      postal_code: 'H0H0H0'
    )

    user.save!
    user
  end


end
