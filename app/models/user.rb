class User < ApplicationRecord
  has_secure_password
  has_many :documents, dependent: :restrict_with_error
  has_many :templates, dependent: :restrict_with_error
  has_many :agent_credentials, dependent: :restrict_with_error
  has_many :agent_requests, dependent: :restrict_with_error
  has_many :ai_contract_conversations, dependent: :restrict_with_error

  normalizes :email, with: ->(email) { email.strip.downcase }
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :password, length: { minimum: 12 }, if: -> { new_record? || password.present? }
end
