require 'effective_resources'
require 'effective_datatables'
require 'effective_messaging/engine'
require 'effective_messaging/version'

module EffectiveMessaging

  def self.config_keys
    [
      :chats_table_name, :chat_users_table_name, :chat_messages_table_name, :notifications_table_name,
      :layout,
      :froms,
      :mailer, :parent_mailer, :deliver_method, :mailer_layout, :mailer_sender, :mailer_admin, :mailer_subject
    ]
  end

  include EffectiveGem

  def self.mailer_class
    mailer&.constantize || Effective::MessagingMailer
  end

  def self.Notification
    Effective::Notification
  end

end
