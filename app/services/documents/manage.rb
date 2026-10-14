module Documents
  # Every owner operation starts from this user's association, never Document.find.
  class Manage
    EDITABLE_FIELDS = %i[title content recipient_name recipient_email expires_at].freeze

    def initialize(user:)
      @user = user
    end

    def find(id)
      Expiration.call(scope: @user.documents.where(id: id))
      @user.documents.find(id)
    end

    def all
      Expiration.call(scope: @user.documents)
      @user.documents.order(created_at: :desc)
    end

    def create!(attributes)
      @user.documents.create!(editable(attributes))
    end

    def build_from_template(version:, attributes:, values:)
      raise ActiveRecord::RecordNotFound unless version.template.user_id == @user.id

      content = Templates::Renderer.render(version.content, values: values)
      fields = editable(attributes)
      fields[:title] = version.title if fields[:title].blank?
      fields[:recipient_name] = values.stringify_keys["alici_adi"] if fields[:recipient_name].blank?
      @user.documents.build(**fields, content: content, template_version: version)
    end

    def update!(id, attributes)
      find(id).tap { |document| document.update!(editable(attributes)) }
    end

    def send_for_signature!(id)
      find(id).send_for_signature!
    end

    private

    def editable(attributes)
      attributes.to_h.symbolize_keys.slice(*EDITABLE_FIELDS)
    end
  end
end
