class TemplateVersion < ApplicationRecord
  include TemplateText

  belongs_to :template
  has_many :documents, dependent: :restrict_with_error
  validates :number, numericality: { only_integer: true, greater_than: 0 }, uniqueness: { scope: :template_id }

  def readonly?
    persisted?
  end

  def variables
    Templates::Renderer.fields(content)
  end
end
