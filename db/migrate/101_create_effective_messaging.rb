class CreateEffectiveMessaging < ActiveRecord::Migration[6.0]
  def change
    create_table :chats do |t|
      t.integer :parent_id
      t.string :parent_type

      t.string :title
      t.boolean :anonymous, default: false

      t.integer :chat_messages_count, default: 0
      t.string :token

      t.timestamps
    end

    create_table :chat_users do |t|
      t.integer :chat_id

      t.integer :user_id
      t.string :user_type

      t.string :display_name
      t.string :anonymous_name

      t.datetime :last_notified_at

      t.timestamps
    end

    create_table :chat_messages do |t|
      t.integer :chat_id
      t.integer :chat_user_id

      t.integer :user_id
      t.string :user_type

      t.string :name
      t.text :body

      t.timestamps
    end

    create_table :notifications do |t|
      t.integer :parent_id
      t.string :parent_type

      t.integer :user_id
      t.string :user_type

      t.integer :report_id

      t.string :audience
      t.text :audience_emails

      t.boolean :enabled, default: false
      t.boolean :attach_report, default: false

      t.string :schedule_type

      t.integer :immediate_days
      t.integer :immediate_times

      t.string :scheduled_method
      t.text :scheduled_dates

      t.string :subject
      t.text :body

      t.string :from
      t.string :cc
      t.string :bcc

      t.datetime :last_notified_at
      t.integer :last_notified_count

      t.timestamps
    end

    create_table :notification_logs  do |t|
      t.integer :notification_id
      t.integer :report_id

      t.integer :user_id
      t.string :user_type

      t.integer :resource_id
      t.string :resource_type

      t.string :email

      t.timestamps
    end

  end
end
