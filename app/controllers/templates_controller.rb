class TemplatesController < ApplicationController
  before_action :set_manager
  before_action :set_template, only: %i[show edit update history]

  def index
    @templates = @manager.all(query: params[:q])
  end

  def new
    @revision = TemplateRevision.new
  end

  def create
    @template = @manager.create!(revision_params)
    redirect_to @template, status: :see_other, notice: "Şablonunuz hazır. Alanları doldurarak sözleşme oluşturabilirsiniz."
  rescue ActiveModel::ValidationError => error
    @revision = error.model
    render :new, status: :unprocessable_entity
  end

  def show
    @version = params[:version_id].present? ? @manager.version(@template.id, params[:version_id]) : @template.current_version
  end

  def edit
    @revision = TemplateRevision.new(@template.current_version.attributes.slice("title", "description", "content"))
  end

  def update
    @manager.update!(@template.id, revision_params)
    redirect_to @template, status: :see_other, notice: "Yeni sürüm kaydedildi. Önceki sürümler ve sözleşmeler korundu."
  rescue ActiveModel::ValidationError => error
    @revision = error.model
    render :edit, status: :unprocessable_entity
  end

  def history
    @versions = @template.versions.order(number: :desc)
  end

  def add_examples
    Templates::DemoSeeder.call(user: current_user)
    redirect_to templates_path, status: :see_other, notice: "Eksik demo şablonları eklendi. Mevcut şablonlarınız korunuyor."
  end

  private

  def set_manager
    @manager = Templates::Manage.new(user: current_user)
  end

  def set_template
    @template = @manager.find(params[:id])
  end

  def revision_params
    params.require(:template_revision).permit(:title, :description, :content)
  end
end
