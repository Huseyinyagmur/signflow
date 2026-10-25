class AiContractConversation < ApplicationRecord
  belongs_to :user
  belongs_to :template_version
  belongs_to :document, optional: true
  attr_readonly :user_id, :template_version_id, :public_id, :expires_at
  validates :public_id, presence: true, uniqueness: true
  validates :expires_at, presence: true
  validate :same_owner

  def to_param = public_id

  private

  def same_owner
    errors.add(:template_version, :invalid) unless template_version&.template&.user_id == user_id
    errors.add(:document, :invalid) if document && (document.user_id != user_id || document.template_version_id != template_version_id)
    errors.add(:document, :invalid) if document_id_in_database && will_save_change_to_document_id?
  end
end
