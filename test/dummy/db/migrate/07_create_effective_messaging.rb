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

      t.timestamps
    end

    create_table :chat_messages do |t|
      t.integer :chat_id

      t.integer :user_id
      t.string :user_type

      t.text :body

      t.timestamps
    end

  end
end
