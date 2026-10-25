class RegistrationsController < ApplicationController
  RATE_LIMIT_STORE = ActiveSupport::Cache::MemoryStore.new
  skip_before_action :require_authentication
  rate_limit to: 10, within: 3.minutes, only: :create,
    store: RATE_LIMIT_STORE,
    with: -> { head :too_many_requests }

  def new
    @user = User.new
  end

  def create
    @user = User.new(params.require(:user).permit(:name, :email, :password, :password_confirmation))
    Users::Register.call(user: @user)
    redirect_to new_session_path, notice: "Hesabınız oluşturuldu. Üç başlangıç şablonunuz hazır. Şimdi giriş yapabilirsiniz.", status: :see_other
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  rescue Users::Register::TemplateSetupFailed
    @user.errors.add(:base, "Başlangıç şablonları hazırlanamadığı için hesabınız oluşturulmadı. Lütfen tekrar deneyin.")
    render :new, status: :unprocessable_entity
  end
end
