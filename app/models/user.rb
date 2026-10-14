class User < ApplicationRecord
  has_secure_password
  has_many :documents, dependent: :restrict_with_error

  normalizes :email, with: ->(email) { email.strip.downcase }
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :password, length: { minimum: 12 }, if: -> { new_record? || password.present? }
end
