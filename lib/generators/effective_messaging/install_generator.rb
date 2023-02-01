module EffectiveMessaging
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      desc 'Creates an EffectiveMessaging initializer in your application.'

      source_root File.expand_path('../../templates', __FILE__)

      def self.next_migration_number(dirname)
        if not ActiveRecord::Base.timestamped_migrations
          Time.new.utc.strftime("%Y%m%d%H%M%S")
        else
          '%.3d' % (current_migration_number(dirname) + 1)
        end
      end

      def copy_initializer
        template ('../' * 3) + 'config/effective_messaging.rb', 'config/initializers/effective_messaging.rb'
      end

      def create_migration_file
        @chats_table_name  = ':' + EffectiveMessaging.chats_table_name.to_s
        @chat_users_table_name  = ':' + EffectiveMessaging.chat_users_table_name.to_s
        @chat_messages_table_name  = ':' + EffectiveMessaging.chat_messages_table_name.to_s
        @notifications_table_name  = ':' + EffectiveMessaging.notifications_table_name.to_s

        migration_template ('../' * 3) + 'db/migrate/01_create_effective_messaging.rb.erb', 'db/migrate/create_effective_messaging.rb'
      end

    end
  end
end
