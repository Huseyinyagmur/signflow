module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :current_user
  end

  private

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = if session[:expires_at].to_i > Time.current.to_i
      User.find_by(id: session[:user_id])
    end
  end

  def require_authentication
    return if current_user

    reset_session
    respond_to do |format|
      format.html { redirect_to new_session_path, alert: "Devam etmek için giriş yapın." }
      format.json { head :unauthorized }
    end
  end
end
