class CreateAiContractConversations < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_contract_conversations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :template_version, null: false, foreign_key: true
      t.references :document, foreign_key: true, index: { unique: true }
      t.string :public_id, null: false
      t.datetime :expires_at, null: false
      t.timestamps
    end
    add_index :ai_contract_conversations, :public_id, unique: true
  end
end
