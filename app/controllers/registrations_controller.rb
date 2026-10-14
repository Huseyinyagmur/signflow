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
    if @user.save
      redirect_to new_session_path, notice: "Hesabınız oluşturuldu. Şimdi giriş yapabilirsiniz.", status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end
end
