require "digest"
require "securerandom"

class AgentCredential < ApplicationRecord
  TOKEN_PATTERN = /\Asf_agent_[A-Za-z0-9_-]{43}\z/

  belongs_to :user
  has_many :agent_requests, dependent: :restrict_with_error
  validates :label, presence: true, length: { maximum: 80 }
  validates :token_digest, format: { with: /\A[0-9a-f]{64}\z/ }, uniqueness: true
  validates :expires_at, presence: true
  validate :expiry_and_identity

  def self.issue!(user:, label:, expires_at: 7.days.from_now)
    token = "sf_agent_#{SecureRandom.urlsafe_base64(32)}"
    credential = create!(user: user, label: label, expires_at: expires_at,
      token_digest: Digest::SHA256.hexdigest(token))
    [ credential, token ] # Deliver once via a secure channel; never log/inspect this pair.
  end

  def self.authenticate(token)
    return unless token.is_a?(String) && TOKEN_PATTERN.match?(token)

    find_by(token_digest: Digest::SHA256.hexdigest(token))&.then { |credential| credential if credential.active? }
  end

  def active?
    revoked_at.nil? && expires_at > Time.current
  end

  def revoke!
    user.with_lock do
      reload
      update!(revoked_at: Time.current) unless revoked_at
    end
  end

  private

  def expiry_and_identity
    if new_record? && expires_at && (expires_at <= Time.current || expires_at > 30.days.from_now)
      errors.add(:expires_at, "must be in the next 30 days")
    end
    if persisted? && %w[user_id token_digest expires_at].any? { |field| will_save_change_to_attribute?(field) }
      errors.add(:base, "Credential identity and expiry are immutable; issue a new credential")
    end
    errors.add(:revoked_at, "cannot be changed after revocation") if persisted? && revoked_at_in_database && will_save_change_to_revoked_at?
  end
end
