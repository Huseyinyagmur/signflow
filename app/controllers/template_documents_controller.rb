class TemplateDocumentsController < ApplicationController
  before_action :set_version

  def new
    @values = {}
    @document = current_user.documents.build(title: @version.title)
  end

  def preview
    build_document
    if @document.valid?
      @preview_ready = true
      render :new
    else
      render :new, status: :unprocessable_entity
    end
  rescue Templates::Renderer::InvalidInput => error
    invalid_values(error)
  end

  def create
    build_document
    @document.save!
    redirect_to @document, status: :see_other, notice: "Şablondan bağımsız bir sözleşme taslağı oluşturuldu."
  rescue Templates::Renderer::InvalidInput => error
    invalid_values(error)
  rescue ActiveRecord::RecordInvalid => error
    @document = error.record
    render :new, status: :unprocessable_entity
  end

  private

  def set_version
    manager = Templates::Manage.new(user: current_user)
    @template = manager.find(params[:template_id])
    version_id = action_name == "new" ? params[:version_id].presence || @template.current_version_id : params.require(:version_id)
    @version = manager.version(@template.id, version_id)
  end

  def build_document
    @values = variable_values
    @document = Documents::Manage.new(user: current_user).build_from_template(
      version: @version, attributes: document_params, values: @values)
  end

  def variable_values
    values = params.fetch(:values, ActionController::Parameters.new)
    raise Templates::Renderer::InvalidInput, "Değişkenler alan-değer listesi olmalıdır." unless values.is_a?(ActionController::Parameters)

    # Only consumed by the strict renderer, never mass-assigned to a model.
    # Preserve unknown keys so the renderer rejects them rather than silently dropping them.
    values.to_unsafe_h
  end

  def document_params
    params.require(:document).permit(:title, :recipient_name, :recipient_email, :expires_at)
  end

  def invalid_values(error)
    @values = {} unless @values.is_a?(Hash)
    @document = current_user.documents.build(document_params)
    @render_error = error.message
    render :new, status: :unprocessable_entity
  end
end
