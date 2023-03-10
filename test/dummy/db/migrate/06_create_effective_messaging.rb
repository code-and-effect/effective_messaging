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

      t.datetime :send_at

      t.string :subject
      t.text :body

      t.string :from
      t.string :cc
      t.string :bcc

      t.datetime :started_at
      t.datetime :completed_at
      t.integer :notifications_sent

      t.timestamps
    end

  end
end
