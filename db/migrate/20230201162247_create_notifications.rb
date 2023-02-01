class CreateNotifications < ActiveRecord::Migration[6.1]
  def change
    create_table :notifications do |t|
      t.string :subject
      t.string :from
      t.string :cc
      t.string :bcc
      t.text :body
      t.datetime :last_notified_at

      t.timestamps
    end
  end
end
