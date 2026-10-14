class Template < ApplicationRecord
  belongs_to :user
  belongs_to :current_version, class_name: "TemplateVersion", optional: true
  has_many :versions, class_name: "TemplateVersion", dependent: :restrict_with_error

  attr_readonly :user_id, :seed_key
  delegate :title, :description, :content, to: :current_version, allow_nil: true
  validate :current_version_belongs_to_template

  private

  def current_version_belongs_to_template
    if current_version && current_version.template_id != id
      errors.add(:current_version, "bu şablona ait olmalıdır")
    end
  end
end
