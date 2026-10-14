module TemplateText
  extend ActiveSupport::Concern

  included do
    validates :title, presence: true, length: { maximum: 160 }
    validates :description, length: { maximum: 2000 }
    validates :content, presence: true, length: { maximum: 50_000 }
    validate :validate_template_syntax
  end

  private

  def validate_template_syntax
    Templates::Renderer.fields(content.to_s)
  rescue Templates::Renderer::InvalidInput => error
    errors.add(:content, error.message)
  end
end
