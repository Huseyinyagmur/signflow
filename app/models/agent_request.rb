class AgentRequest < ApplicationRecord
  belongs_to :user
  belongs_to :agent_credential
  belongs_to :document
  validates :operation, inclusion: { in: [ "create_draft" ] }
  validates :idempotency_key_digest, :payload_digest, format: { with: /\A[0-9a-f]{64}\z/ }
  validate :same_owner

  def readonly?
    persisted?
  end

  private

  def same_owner
    if document&.user_id != user_id || agent_credential&.user_id != user_id
      errors.add(:base, "Agent request resources must have the same owner")
    end
  end
end
