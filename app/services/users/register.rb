module Users
  class Register
    class TemplateSetupFailed < StandardError; end

    # No User callbacks: existing users and unrelated model creation stay untouched.
    # Account and all starter versions commit together on the same connection.
    def self.call(user:)
      raise ArgumentError, "new_user_required" unless user.new_record?

      User.transaction do
        user.save!
        Templates::DemoSeeder.call(user: user)
      end
      user
    rescue ActiveRecord::RecordInvalid => error
      raise if error.record.equal?(user)

      raise TemplateSetupFailed
    rescue ActiveModel::ValidationError, Templates::Renderer::InvalidInput, Templates::DemoSeeder::IncompleteTemplate
      raise TemplateSetupFailed
    end
  end
end
