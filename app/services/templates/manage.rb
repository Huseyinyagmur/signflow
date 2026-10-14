module Templates
  class Manage
    def initialize(user:)
      @user = user
    end

    def all(query: nil)
      scope = @user.templates.joins(:current_version).includes(:current_version).order(updated_at: :desc)
      if query.present?
        pattern = "%#{Template.sanitize_sql_like(query.to_s.strip)}%"
        scope = scope.where("template_versions.title LIKE :q OR template_versions.description LIKE :q", q: pattern)
      end
      scope
    end

    def find(id)
      @user.templates.find(id)
    end

    def version(template_id, version_id)
      find(template_id).versions.find(version_id)
    end

    def create!(attributes, seed_key: nil)
      revision = validated_revision(attributes)
      Template.transaction do
        template = @user.templates.create!(seed_key: seed_key)
        version = template.versions.create!(**revision.attributes, number: 1)
        template.update!(current_version: version)
        template
      end
    end

    def update!(id, attributes)
      template = find(id)
      revision = validated_revision(attributes)
      template.with_lock do
        number = template.versions.maximum(:number).to_i + 1
        version = template.versions.create!(**revision.attributes, number: number)
        template.update!(current_version: version)
      end
      template
    end

    private

    def validated_revision(attributes)
      revision = TemplateRevision.new(attributes.to_h.symbolize_keys.slice(:title, :description, :content))
      raise ActiveModel::ValidationError, revision unless revision.valid?

      revision
    end
  end
end
