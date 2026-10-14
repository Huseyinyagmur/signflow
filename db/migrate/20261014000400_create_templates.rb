class CreateTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :templates do |t|
      t.references :user, null: false, foreign_key: true
      t.string :seed_key
      t.timestamps
    end
    add_index :templates, [ :user_id, :seed_key ], unique: true

    create_table :template_versions do |t|
      t.references :template, null: false, foreign_key: true
      t.integer :number, null: false
      t.string :title, null: false
      t.text :description
      t.text :content, null: false
      t.timestamps
    end
    add_index :template_versions, [ :template_id, :number ], unique: true
    add_check_constraint :template_versions, "number > 0", name: "template_versions_positive_number"
    add_reference :templates, :current_version, foreign_key: { to_table: :template_versions }
    add_reference :documents, :template_version, foreign_key: true
  end
end
