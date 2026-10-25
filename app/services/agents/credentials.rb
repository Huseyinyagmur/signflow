module Agents
  class Credentials
    class InvalidLifetime < StandardError; end
    LIFETIMES = %w[1 7 30].freeze

    def initialize(user:)
      @user = user
    end

    def all
      @user.agent_credentials.order(created_at: :desc)
    end

    def issue!(label:, lifetime_days:)
      raise InvalidLifetime unless LIFETIMES.include?(lifetime_days.to_s)

      @user.with_lock do
        AgentCredential.issue!(user: @user, label: label, expires_at: lifetime_days.to_i.days.from_now)
      end
    end

    def revoke!(id)
      @user.agent_credentials.find(id).revoke!
    end
  end
end
