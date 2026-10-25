module Api
  module V1
    class DraftsController < BaseController
      def create
        return api_error("json_required", :unsupported_media_type) unless request.media_type == "application/json"

        body = request.body.read(65_537)
        return api_error("payload_too_large", :content_too_large) if body.bytesize > 65_536

        payload = JSON.parse(body)
        return api_error("json_object_required", :bad_request) unless payload.is_a?(Hash)

        document, replayed = Agents::CreateDraft.call(credential: @credential,
          key: request.get_header("HTTP_IDEMPOTENCY_KEY"), payload: payload)
        render json: draft_response(document, replayed: replayed), status: replayed ? :ok : :created
      end

      def show
        user = @credential.user
        receipt = user.agent_requests.find_by!(document_id: params[:id])
        document = Documents::Manage.new(user: user).find(receipt.document_id)
        render json: draft_response(document)
      end
    end
  end
end
