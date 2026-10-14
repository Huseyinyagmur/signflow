class TemplateRevision
  include ActiveModel::Model
  include TemplateText

  attr_accessor :title, :description, :content

  def attributes
    { title: title, description: description, content: content }
  end
end
