class DashboardController < ApplicationController
  def show
    documents = Documents::Manage.new(user: current_user).all
    @counts = documents.reorder(nil).group(:status).count
    @documents = documents.limit(5)
  end
end
