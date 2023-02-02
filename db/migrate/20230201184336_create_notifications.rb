class CreateNotifications < ActiveRecord::Migration[6.1]
  def change
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

      t.datetime :last_notified_at

      t.timestamps
    end
  end
end
