EffectiveMessaging.setup do |config|
  config.chats_table_name = :chats
  config.chat_users_table_name = :chat_users
  config.chat_messages_table_name = :chat_messages
  config.notifications_table_name = :notifications

  # Layout Settings
  # Configure the Layout per controller, or all at once
  # config.layout = { application: 'application', admin: 'admin' }

  # From Settings
  # For the Admin new notification form. Set to an array to use a select, or nil to use a freeform text entry
  config.froms = ['noreply@example.com']

  # Mailer Settings
  # Please see config/initializers/effective_messaging.rb for default effective_* gem mailer settings
  #
  # Configure the class responsible to send e-mails.
  # config.mailer = 'Effective::MessagingMailer'
  #
  # Override effective_resource mailer defaults
  #
  # config.parent_mailer = nil      # The parent class responsible for sending emails
  # config.deliver_method = nil     # The deliver method, deliver_later or deliver_now
  # config.mailer_layout = nil      # Default mailer layout
  # config.mailer_sender = nil      # Default From value
  # config.mailer_admin = nil       # Default To value for Admin correspondence
  # config.mailer_subject = nil     # Proc.new method used to customize Subject

end
