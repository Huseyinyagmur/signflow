class SessionsController < ApplicationController
  RATE_LIMIT_STORE = ActiveSupport::Cache::MemoryStore.new
  skip_before_action :require_authentication, only: %i[new create]
  rate_limit to: 10, within: 3.minutes, only: :create,
    store: RATE_LIMIT_STORE,
    with: -> { head :too_many_requests }

  def create
    user = User.authenticate_by(email: params[:email].to_s.strip.downcase, password: params[:password].to_s)
    reset_session
    if user
      session[:user_id] = user.id
      session[:expires_at] = 12.hours.from_now.to_i
      respond_to do |format|
        format.html { redirect_to dashboard_path, status: :see_other, notice: "SignFlow'a hoş geldiniz." }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html do
          flash.now[:alert] = "E-posta veya parola hatalı."
          render :new, status: :unprocessable_entity
        end
        format.json { head :unauthorized }
      end
    end
  end

  def new
  end

  def show
    render json: { id: current_user.id, name: current_user.name }
  end

  def destroy
    reset_session
    respond_to do |format|
      format.html { redirect_to root_path, status: :see_other, notice: "Oturumunuz kapatıldı." }
      format.json { head :no_content }
    end
  end
end
