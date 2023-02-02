class CreateEffectiveReports < ActiveRecord::Migration[6.0]
  def change
    create_table :reports do |t|
      t.integer :created_by_id
      t.string :created_by_type

      t.string :title
      t.text :description

      t.string :reportable_class_name

      t.timestamps
    end

    create_table :report_columns do |t|
      t.integer :report_id

      t.string :name
      t.integer :position

      t.string :as

      t.boolean :filter
      t.string :operation

      t.text :value_associated
      t.boolean :value_boolean
      t.date :value_date
      t.decimal :value_decimal
      t.integer :value_integer
      t.integer :value_price
      t.string :value_string

      t.timestamps
    end

    create_table :report_scopes do |t|
      t.integer :report_id

      t.string :name
      t.boolean :advanced

      t.boolean :value_boolean
      t.date :value_date
      t.decimal :value_decimal
      t.integer :value_integer
      t.integer :value_price
      t.string :value_string

      t.timestamps
    end

  end
end
