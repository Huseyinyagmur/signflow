class DocumentsController < ApplicationController
  before_action :set_manager
  before_action :set_document, only: %i[show edit update send_for_signature]

  def index
    @documents = @manager.all
    @documents = @documents.where(status: params[:status]) if Document::STATUSES.include?(params[:status])
  end

  def new
    @document = current_user.documents.build
  end

  def create
    @document = @manager.create!(document_params)
    redirect_to @document, status: :see_other, notice: "Sözleşmeniz taslak olarak kaydedildi."
  rescue ActiveRecord::RecordInvalid => error
    @document = error.record
    render :new, status: :unprocessable_entity
  end

  def show
  end

  def edit
    redirect_to @document, alert: "Gönderilmiş sözleşmeler düzenlenemez." unless @document.draft?
  end

  def update
    @manager.update!(@document.id, document_params)
    redirect_to @document, status: :see_other, notice: "Taslak güncellendi."
  rescue ActiveRecord::RecordInvalid => error
    @document = error.record
    render :edit, status: :unprocessable_entity
  end

  def send_for_signature
    token = @manager.send_for_signature!(@document.id)
    @document.reload
    @signing_link = "#{signing_url}#token=#{token}"
    response.headers["Cache-Control"] = "no-store"
    render :show
  rescue Document::InvalidTransition, ActiveRecord::RecordInvalid
    @document.reload
    flash.now[:alert] = "Gönderilemedi. Alıcı bilgilerini ve gelecekte bir son imza tarihi seçtiğinizi kontrol edin."
    render :show, status: :unprocessable_entity
  end

  private

  def set_manager
    @manager = Documents::Manage.new(user: current_user)
  end

  def set_document
    @document = @manager.find(params[:id])
  end

  def document_params
    params.require(:document).permit(*Documents::Manage::EDITABLE_FIELDS)
  end
end
