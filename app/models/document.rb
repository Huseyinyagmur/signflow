require "digest"
require "securerandom"

class Document < ApplicationRecord
  class InvalidTransition < StandardError; end

  STATUSES = %w[draft pending signed expired].freeze
  LIFECYCLE_FIELDS = %w[status signed_at signing_token_digest signer_name].freeze
  SEALED_FIELDS = %w[title content recipient_name recipient_email expires_at user_id].freeze

  belongs_to :user
  enum :status, STATUSES.index_with(&:itself), default: :draft, validate: true
  normalizes :recipient_email, with: ->(email) { email.strip.downcase }

  validates :title, :content, presence: true
  validates :recipient_name, :recipient_email, :expires_at, presence: true, unless: :draft?
  validates :recipient_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :signing_token_digest, presence: true, if: :pending?
  validates :signed_at, presence: true, if: :signed?
  validates :signer_name, presence: true, length: { maximum: 120 }, if: :signed?
  validate :protect_lifecycle
  validate :protect_sent_document

  def send_for_signature!
    token = SecureRandom.urlsafe_base64(32)
    with_lock do
      raise InvalidTransition, "Only drafts can be sent" unless draft?
      raise InvalidTransition, "Deadline must be in the future" unless expires_at && expires_at > Time.current

      transition!(status: "pending", signing_token_digest: self.class.token_digest(token))
    end
    token # Returned once; never persisted or logged in plaintext.
  end

  def sign!(signer_name: recipient_name)
    with_lock do
      raise InvalidTransition, "Document is not awaiting signature" unless pending?
      now = Time.current
      raise InvalidTransition, "Signing deadline has passed" if expires_at <= now

      transition!(status: "signed", signed_at: now, signing_token_digest: nil,
        signer_name: signer_name.to_s.strip)
    end
    self
  end

  def expire!
    with_lock do
      raise InvalidTransition, "Only pending documents can expire" unless pending?
      raise InvalidTransition, "Signing deadline has not passed" if expires_at > Time.current

      transition!(status: "expired", signing_token_digest: nil)
    end
    self
  end

  def self.token_digest(token)
    Digest::SHA256.hexdigest(token)
  end

  private

  def transition!(attributes)
    @transitioning = true
    update!(attributes)
  ensure
    @transitioning = false
  end

  def protect_lifecycle
    return if @transitioning

    invalid = if new_record?
      !draft? || signed_at.present? || signing_token_digest.present? || signer_name.present?
    else
      LIFECYCLE_FIELDS.any? { |field| will_save_change_to_attribute?(field) }
    end
    errors.add(:base, "Use document transition methods") if invalid
  end

  def protect_sent_document
    return if new_record?

    if status_in_database != "draft" && SEALED_FIELDS.any? { |field| will_save_change_to_attribute?(field) }
      errors.add(:base, "Sent documents cannot be edited")
    end
    errors.add(:user, "cannot be reassigned") if will_save_change_to_user_id?
  end
end
