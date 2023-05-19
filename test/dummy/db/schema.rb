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

ActiveRecord::Schema.define(version: 6) do

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.integer "record_id", null: false
    t.integer "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.integer "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "chat_messages", force: :cascade do |t|
    t.integer "chat_id"
    t.integer "chat_user_id"
    t.integer "user_id"
    t.string "user_type"
    t.string "name"
    t.text "body"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "chat_users", force: :cascade do |t|
    t.integer "chat_id"
    t.integer "user_id"
    t.string "user_type"
    t.string "display_name"
    t.string "anonymous_name"
    t.datetime "last_notified_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "chats", force: :cascade do |t|
    t.integer "parent_id"
    t.string "parent_type"
    t.string "title"
    t.boolean "anonymous", default: false
    t.integer "chat_messages_count", default: 0
    t.string "token"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "email_templates", force: :cascade do |t|
    t.string "template_name"
    t.string "subject"
    t.string "from"
    t.string "bcc"
    t.string "cc"
    t.string "content_type"
    t.text "body"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "notification_logs", force: :cascade do |t|
    t.integer "notification_id"
    t.integer "report_id"
    t.integer "user_id"
    t.string "user_type"
    t.integer "resource_id"
    t.string "resource_type"
    t.string "email"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "notifications", force: :cascade do |t|
    t.integer "parent_id"
    t.string "parent_type"
    t.integer "user_id"
    t.string "user_type"
    t.integer "report_id"
    t.string "audience"
    t.text "audience_emails"
    t.boolean "attach_report", default: false
    t.string "schedule_type"
    t.integer "immediate_days"
    t.integer "immediate_times"
    t.string "subject"
    t.text "body"
    t.string "from"
    t.string "cc"
    t.string "bcc"
    t.datetime "last_notified_at"
    t.integer "last_notified_count"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "report_columns", force: :cascade do |t|
    t.integer "report_id"
    t.string "name"
    t.integer "position"
    t.string "as"
    t.boolean "filter"
    t.string "operation"
    t.text "value_associated"
    t.boolean "value_boolean"
    t.date "value_date"
    t.decimal "value_decimal"
    t.integer "value_integer"
    t.integer "value_price"
    t.string "value_string"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "report_scopes", force: :cascade do |t|
    t.integer "report_id"
    t.string "name"
    t.boolean "advanced"
    t.boolean "value_boolean"
    t.date "value_date"
    t.decimal "value_decimal"
    t.integer "value_integer"
    t.integer "value_price"
    t.string "value_string"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "reports", force: :cascade do |t|
    t.integer "created_by_id"
    t.string "created_by_type"
    t.string "title"
    t.text "description"
    t.string "reportable_class_name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.string "email", default: "", null: false
    t.string "first_name"
    t.string "last_name"
    t.integer "roles_mask"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
end
