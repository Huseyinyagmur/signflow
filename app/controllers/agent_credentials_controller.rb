class AgentCredentialsController < ApplicationController
  before_action :private_response
  before_action :set_manager

  def index
    @credentials = @manager.all
    @credential = AgentCredential.new
    @lifetime_days = "7"
  end

  def create
    return head :not_found unless ENV["AGENT_API_ENABLED"] == "true"

    fields = params.require(:agent_credential).permit(:label, :lifetime_days)
    @lifetime_days = fields[:lifetime_days]
    @credential, @token = @manager.issue!(label: fields[:label], lifetime_days: @lifetime_days)
    # Only this POST response contains the raw token. Never put it in flash/session/URL.
    render :created
  rescue ActiveRecord::RecordInvalid => error
    @credential = error.record
    @credentials = @manager.all
    render :index, status: :unprocessable_entity
  rescue Agents::Credentials::InvalidLifetime
    @credential = AgentCredential.new(label: fields[:label])
    @credential.errors.add(:base, "Geçerlilik süresi 1, 7 veya 30 gün olmalıdır.")
    @credentials = @manager.all
    render :index, status: :unprocessable_entity
  end

  def revoke
    @manager.revoke!(params[:id])
    redirect_to agent_credentials_path, status: :see_other, notice: "Agent erişimi iptal edildi."
  end

  private

  def set_manager
    @manager = Agents::Credentials.new(user: current_user)
  end

  def private_response
    response.headers["Cache-Control"] = "no-store"
    response.headers["X-Robots-Tag"] = "noindex, nofollow"
    head :not_acceptable unless request.format.html?
  end
end
