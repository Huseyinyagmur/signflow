module Api
  module V1
    # Separate bearer-only transport. Web ApplicationController/CSRF/session are unchanged.
    class BaseController < ActionController::API
      wrap_parameters false
      before_action :protect_response
      before_action :require_agent_access
      rescue_from StandardError, with: :unexpected_failure
      rescue_from ActiveRecord::RecordNotFound, with: -> { api_error("not_found", :not_found) }
      rescue_from Agents::CreateDraft::Unauthorized, with: -> { api_error("unauthorized", :unauthorized) }
      rescue_from Agents::CreateDraft::InvalidKey, with: -> { api_error("invalid_idempotency_key", :bad_request) }
      rescue_from Agents::CreateDraft::Conflict, with: -> { api_error("idempotency_conflict", :conflict) }
      rescue_from Agents::CreateDraft::InvalidInput, Templates::Renderer::InvalidInput,
        ActiveRecord::RecordInvalid, with: -> { api_error("invalid_input", :unprocessable_entity) }
      rescue_from JSON::ParserError, ActionDispatch::Http::Parameters::ParseError,
        with: -> { api_error("invalid_json", :bad_request) }
      rescue_from ActiveRecord::RecordNotUnique, ActiveRecord::Deadlocked, ActiveRecord::LockWaitTimeout,
        ActiveRecord::StatementTimeout, with: -> { api_error("retry_same_request", :service_unavailable) }

      private

      def unexpected_failure
        Rails.logger.error("Agent API failed; request_id=#{request.request_id}")
        api_error("internal_error", :internal_server_error)
      end

      def protect_response
        response.headers["Cache-Control"] = "no-store"
      end

      def require_agent_access
        return api_error("not_found", :not_found) unless ENV["AGENT_API_ENABLED"] == "true"

        match = /\ABearer (sf_agent_[A-Za-z0-9_-]{43})\z/.match(request.get_header("HTTP_AUTHORIZATION").to_s)
        @credential = AgentCredential.authenticate(match && match[1])
        api_error("unauthorized", :unauthorized) unless @credential
      end

      def api_error(code, status)
        render json: { error: code }, status: status
      end

      def draft_response(document, replayed: nil)
        result = { id: document.id, title: document.title, content: document.content,
          status: document.status, template_version_id: document.template_version_id,
          review_path: document_path(document) }
        result[:replayed] = replayed unless replayed.nil?
        result
      end
    end
  end
end
