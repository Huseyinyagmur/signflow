class SigningController < ApplicationController
  skip_before_action :require_authentication
  before_action :protect_response
  rescue_from ActiveRecord::RecordNotFound, Document::InvalidTransition, with: :unavailable

  def show
    @acceptance = SignatureAcceptance.new
    @signing_token = session[:signing_token]
    @document = Documents::Signing.find(token: @signing_token) if @signing_token
  end

  def access
    Documents::Signing.find(token: params[:token])
    session[:signing_token] = params[:token]
    redirect_to signing_path, status: :see_other
  end

  def create
    @signing_token = params[:token]
    input = params.require(:signature_acceptance).permit(:signer_name, :accepted)
    Documents::Signing.sign!(token: @signing_token, **input.to_h.symbolize_keys)
    session.delete(:signing_token)
    redirect_to signing_complete_path, status: :see_other
  rescue ActiveModel::ValidationError => error
    @acceptance = error.model
    @document = Documents::Signing.find(token: @signing_token)
    render :show, status: :unprocessable_entity
  end

  def complete
  end

  private

  def protect_response
    response.headers["Cache-Control"] = "no-store"
    response.headers["X-Robots-Tag"] = "noindex, nofollow"
  end

  def unavailable
    session.delete(:signing_token)
    render :unavailable, status: :not_found
  end
end
