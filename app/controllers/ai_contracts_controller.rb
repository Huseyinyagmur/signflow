class AiContractsController < ApplicationController
  before_action :feature_enabled
  before_action :private_response
  before_action :load_conversation, only: %i[show message draft]
  rescue_from SignflowAgent::Error, with: :safe_error
  rescue_from ActiveRecord::RecordInvalid, Templates::Renderer::InvalidInput, with: :validation_error

  def new
    @templates = Templates::Manage.new(user: current_user).all
  end

  def create
    conversation = manager.start(version_id: params[:template_version_id], synthetic: params[:synthetic])
    redirect_to ai_contract_path(conversation), status: :see_other
  end

  def show
    load_view
  end

  def message
    manager.message(@conversation, prompt: params[:prompt], step: params[:step].to_s)
    redirect_to ai_contract_path(@conversation), status: :see_other
  end

  def draft
    document = manager.approve(@conversation)
    redirect_to document_path(document), status: :see_other
  end

  private

  def manager = @manager ||= AiContracts::Conversations.new(user: current_user)

  def feature_enabled
    head :not_found unless ENV["AI_CONTRACTS_ENABLED"] == "true"
  end

  def private_response
    response.headers["Cache-Control"] = "no-store"
    response.headers["X-Robots-Tag"] = "noindex, nofollow"
  end

  def load_conversation
    @conversation = manager.find(params[:id])
  end

  def load_view
    @version = @conversation.template_version
    @snapshot = manager.snapshot(@conversation)
    @preview = manager.preview(@conversation, @snapshot)
  end

  def safe_error(error)
    # Only application-defined codes, never a provider body, key or exception trace.
    code = error.message.match?(/\A[a-z0-9_]{1,80}\z/) ? error.message : "ai_request_failed"
    @error = "İşlem tamamlanamadı (#{code}). Taslak oluşturulmadıysa yeni konuşma başlatabilirsiniz."
    status = case code
    when "web_quota_exceeded" then :too_many_requests
    when "message_conflict" then :conflict
    else :unprocessable_entity
    end
    response.headers["Retry-After"] = "600" if status == :too_many_requests
    if @conversation
      @version = @conversation.template_version
      @snapshot = { messages: [], result: nil, step: 0, failed: true }
      render :show, status: status
    else
      @templates = Templates::Manage.new(user: current_user).all
      render :new, status: status
    end
  end

  def validation_error
    safe_error(SignflowAgent::Error.new("invalid_draft_fields"))
  end
end
