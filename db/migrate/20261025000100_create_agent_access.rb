class CreateAgentAccess < ActiveRecord::Migration[8.1]
  def change
    create_table :agent_credentials do |t|
      t.references :user, null: false, foreign_key: true
      t.string :label, null: false
      t.string :token_digest, null: false
      t.datetime :expires_at, null: false
      t.datetime :revoked_at
      t.timestamps
    end
    add_index :agent_credentials, :token_digest, unique: true

    create_table :agent_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.references :agent_credential, null: false, foreign_key: true
      t.references :document, null: false, foreign_key: true, index: { unique: true }
      t.string :operation, null: false, default: "create_draft"
      t.string :idempotency_key_digest, null: false
      t.string :payload_digest, null: false
      t.timestamps
    end
    add_index :agent_requests, [ :user_id, :operation, :idempotency_key_digest ],
      unique: true, name: "index_agent_requests_on_owner_operation_key"
    add_check_constraint :agent_requests, "operation = 'create_draft'", name: "agent_requests_valid_operation"
  end
end
