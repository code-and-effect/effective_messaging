require 'effective_resources'
require 'effective_datatables'
require 'effective_messaging/engine'
require 'effective_messaging/version'

module EffectiveMessaging

  def self.config_keys
    [
      :layout,
      :mailer, :parent_mailer, :deliver_method, :mailer_layout, :mailer_sender, :mailer_admin, :mailer_subject, :use_effective_email_templates
    ]
  end

  include EffectiveGem

end
