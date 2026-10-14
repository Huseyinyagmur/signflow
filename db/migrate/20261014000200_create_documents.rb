class CreateDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :documents do |t|
      t.string :title, null: false
      t.text :content, null: false
      t.string :status, null: false, default: "draft"
      t.datetime :expires_at
      t.datetime :signed_at
      t.references :user, null: false, foreign_key: true
      t.string :recipient_name
      t.string :recipient_email
      t.string :signing_token_digest
      t.timestamps
    end
    add_index :documents, :signing_token_digest, unique: true
    add_index :documents, [ :status, :expires_at ]
    add_check_constraint :documents, "status IN ('draft', 'pending', 'signed', 'expired')", name: "documents_valid_status"
  end
end
