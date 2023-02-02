# Effective Messaging

Centralize all communications between one or more users.

Works with effective_reports to schedule notifications to report results containing emails.

## Getting Started

This requires Rails 6+ and Twitter Bootstrap 4 and just works with Devise.

Please first install the [effective_datatables](https://github.com/code-and-effect/effective_datatables) gem.

Please download and install the [Twitter Bootstrap4](http://getbootstrap.com)

Add to your Gemfile:

```ruby
gem 'effective_messaging'
```

Run the bundle command to install it:

```console
bundle install
```

Then run the generator:

```ruby
rails generate effective_messaging:install
```

The generator will install an initializer which describes all configuration options and creates a database migration.

If you want to tweak the table names, manually adjust both the configuration file and the migration now.

Then migrate the database:

```ruby
rake db:migrate
```

Please add the following to your User model:

```ruby
effective_messaging_user                 # effective_messaging_user

# Effective messaging
def effective_messaging_display_name
  to_s
end

# An anonymous token for your users
def effective_messaging_anonymous_name
  'Anonymous' + Base64::encode64("#{id}-#{created_at.strftime('%F')}").chomp.first(8)
end
```

Add dashboard:

```haml
.card.card-dashboard.mb-4
  .card-body= render 'effective/messaging/dashboard'
```

Add a link to the admin menu:

```haml
- if can?(:admin, :effective_messaging) && can?(:index, Effective::Chat)
  = nav_link_to 'Chats', effective_messaging.admin_chats_path

- if can?(:admin, :effective_messaging) && can?(:index, Effective::ChatMessage)
  = nav_link_to 'Chat Messages', effective_messaging.admin_chat_messages_path

- if can?(:admin, :effective_messaging) && can?(:index, Effective::Notification)
  = nav_link_to 'Chat Messages', effective_messaging.admin_notifications_path
```

## Authorization

All authorization checks are handled via the effective_resources gem found in the `config/initializers/effective_resources.rb` file.

## Permissions

The permissions you actually want to define are as follows (using CanCan):

```ruby
can(:index, Effective::Chat)
can([:show, :update], Effective::Chat) { |chat| user.chat_user(chat: chat).present? }

if user.admin?
  can :admin, :effective_messaging

  can(crud, Effective::Chat)
  can(crud, Effective::ChatUser)
  can(crud - [:new, :create], Effective::ChatMessage)

  can(crud + [:create_notification_job], Effective::Notification)
end
```

## Creating a chat

```ruby
users = User.where(id: [1,2,3])

chat = Effective::Chat.new(title: 'A cool chat', anonymous: true, users: users)
chat.save!
```

and you can just render it *outside of a form*:

```haml
- chat = Effective::Chat.first
= render(chat)
= render('effective/chats/chat', chat: chat)
```

## Creating a notification

First create an effective report with an email column in the results.

Then visit /admin/notifications to schedule a notification with a From, Subject and Body

## License

MIT License.  Copyright [Code and Effect Inc.](http://www.codeandeffect.com/)

## Testing

Run tests by:

```ruby
rails test
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Bonus points for test coverage
6. Create new Pull Request
