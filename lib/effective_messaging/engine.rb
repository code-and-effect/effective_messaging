module EffectiveMessaging
  class Engine < ::Rails::Engine
    engine_name 'effective_messaging'

    # Set up our default configuration options.
    initializer 'effective_messaging.defaults', before: :load_config_initializers do |app|
      eval File.read("#{config.root}/config/effective_messaging.rb")
    end

    # Include acts_as_messaging concern and allow any ActiveRecord object to call it
    initializer 'effective_messaging.active_record' do |app|
      app.config.to_prepare do
        ActiveRecord::Base.extend(EffectiveMessagingParent::Base)
        ActiveRecord::Base.extend(EffectiveMessagingUser::Base)
      end
    end

  end
end
