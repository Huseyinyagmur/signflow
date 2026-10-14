ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    # SQLite writes and travel_to checks run deterministically on Windows.
    parallelize(workers: 1)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    def create_user(email: "owner@example.com")
      User.create!(email: email, name: "Demo User", password: "secure-password-123")
    end

    def create_document(user: create_user)
      user.documents.create!(title: "Demo contract", content: "Agreement content",
        recipient_name: "Recipient", recipient_email: "recipient@example.com",
        expires_at: 1.day.from_now)
    end

    # Add more helper methods to be used by all tests here...
  end
end

class ActionDispatch::IntegrationTest
  setup do
    SessionsController::RATE_LIMIT_STORE.clear
    RegistrationsController::RATE_LIMIT_STORE.clear
  end
end
