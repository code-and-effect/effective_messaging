# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 101) do
  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.integer "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.string "name", null: false
    t.integer "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.string "content_type"
    t.datetime "created_at", precision: nil, null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.integer "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "chat_messages", force: :cascade do |t|
    t.text "body"
    t.integer "chat_id"
    t.integer "chat_user_id"
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.string "user_type"
  end

  create_table "chat_users", force: :cascade do |t|
    t.string "anonymous_name"
    t.integer "chat_id"
    t.datetime "created_at", null: false
    t.string "display_name"
    t.datetime "last_notified_at", precision: nil
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.string "user_type"
  end

  create_table "chats", force: :cascade do |t|
    t.boolean "anonymous", default: false
    t.integer "chat_messages_count", default: 0
    t.datetime "created_at", null: false
    t.integer "parent_id"
    t.string "parent_type"
    t.string "title"
    t.string "token"
    t.datetime "updated_at", null: false
  end

  create_table "email_templates", force: :cascade do |t|
    t.string "bcc"
    t.text "body"
    t.string "cc"
    t.string "content_type"
    t.datetime "created_at", precision: nil
    t.string "from"
    t.string "subject"
    t.string "template_name"
    t.datetime "updated_at", precision: nil
  end

  create_table "notification_logs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.integer "notification_id"
    t.integer "report_id"
    t.integer "resource_id"
    t.string "resource_type"
    t.boolean "skipped", default: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.string "user_type"
  end

  create_table "notifications", force: :cascade do |t|
    t.boolean "attach_report", default: false
    t.string "audience"
    t.text "audience_emails"
    t.string "bcc"
    t.text "body"
    t.string "cc"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.boolean "enabled", default: false
    t.string "from"
    t.integer "immediate_days"
    t.integer "immediate_times"
    t.datetime "last_notified_at", precision: nil
    t.integer "last_notified_count"
    t.integer "parent_id"
    t.string "parent_type"
    t.integer "report_id"
    t.string "schedule_type"
    t.text "scheduled_dates"
    t.string "scheduled_method"
    t.string "subject"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.string "user_type"
  end

  create_table "report_columns", force: :cascade do |t|
    t.string "as"
    t.datetime "created_at", null: false
    t.boolean "filter"
    t.string "name"
    t.string "operation"
    t.integer "position"
    t.integer "report_id"
    t.datetime "updated_at", null: false
    t.text "value_associated"
    t.boolean "value_boolean"
    t.date "value_date"
    t.decimal "value_decimal"
    t.integer "value_integer"
    t.integer "value_price"
    t.string "value_string"
  end

  create_table "report_scopes", force: :cascade do |t|
    t.boolean "advanced"
    t.datetime "created_at", null: false
    t.string "name"
    t.integer "report_id"
    t.datetime "updated_at", null: false
    t.boolean "value_boolean"
    t.date "value_date"
    t.decimal "value_decimal"
    t.integer "value_integer"
    t.integer "value_price"
    t.string "value_string"
  end

  create_table "reports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "created_by_id"
    t.string "created_by_type"
    t.text "description"
    t.string "reportable_class_name"
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.datetime "confirmation_sent_at", precision: nil
    t.datetime "confirmed_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at", precision: nil
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "first_name"
    t.string "last_name"
    t.datetime "last_sign_in_at", precision: nil
    t.string "last_sign_in_ip"
    t.datetime "remember_created_at", precision: nil
    t.datetime "reset_password_sent_at", precision: nil
    t.string "reset_password_token"
    t.integer "roles_mask"
    t.integer "sign_in_count", default: 0, null: false
    t.string "unconfirmed_email"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
end
