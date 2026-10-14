class AddSignerNameToDocuments < ActiveRecord::Migration[8.1]
  def change
    add_column :documents, :signer_name, :string
  end
end
