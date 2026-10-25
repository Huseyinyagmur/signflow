module AiContracts
  # Adapter for shared CLI Tools, backed directly by owner-scoped services.
  # No bearer credential, loopback HTTP, arbitrary path or write capability.
  class TemplateAccess
    def initialize(user:, conversation:)
      @user, @conversation = user, conversation
    end

    def request(method, path, **)
      version = @conversation.template_version
      expected = "/api/v1/templates/#{version.template_id}/versions/#{version.id}"
      raise SignflowAgent::Error, "web_tool_not_authorized" unless method == :get && path == expected

      version = Templates::Manage.new(user: @user).version(version.template_id, version.id)
      { "id" => version.id, "template_id" => version.template_id, "number" => version.number,
        "title" => version.title, "variables" => version.variables }
    end
  end
end
