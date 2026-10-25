require "digest"
require "json"

module Agents
  class CreateDraft
    class InvalidInput < StandardError; end
    class InvalidKey < StandardError; end
    class Conflict < StandardError; end
    class Unauthorized < StandardError; end
    REQUEST_MODEL = AgentRequest
    DOCUMENT_FIELDS = %w[title recipient_name recipient_email expires_at].freeze

    def self.call(credential:, key:, payload:)
      new(credential: credential, key: key, payload: payload).call
    end

    def initialize(credential:, key:, payload:)
      raise InvalidKey unless key.is_a?(String) && key.match?(/\A[A-Za-z0-9_-]{16,128}\z/)

      @credential, @payload = credential, payload
      @key_digest = Digest::SHA256.hexdigest(key)
      validate_payload!
      @payload_digest = Digest::SHA256.hexdigest(JSON.generate(canonical(@payload)))
    end

    def call
      user = @credential.user
      user.with_lock do
        raise Unauthorized unless @credential.reload.active? && @credential.user_id == user.id

        existing = user.agent_requests.find_by(operation: "create_draft", idempotency_key_digest: @key_digest)
        return replay(existing, user) if existing

        version = Templates::Manage.new(user: user).version(@payload.fetch("template_id"), @payload.fetch("template_version_id"))
        document = Documents::Manage.new(user: user).build_from_template(version: version,
          attributes: @payload.fetch("document"), values: @payload.fetch("values"))
        document.save!
        REQUEST_MODEL.create!(user: user, agent_credential: @credential, document: document,
          operation: "create_draft", idempotency_key_digest: @key_digest, payload_digest: @payload_digest)
        [ document, false ]
      end
    end

    private

    def replay(existing, user)
      raise Conflict unless existing.payload_digest == @payload_digest

      [ Documents::Manage.new(user: user).find(existing.document_id), true ]
    end

    def validate_payload!
      raise InvalidInput unless @payload.is_a?(Hash) && @payload.keys.sort == %w[document template_id template_version_id values]
      %w[template_id template_version_id].each do |name|
        raise InvalidInput unless @payload[name].is_a?(Integer) && @payload[name].positive?
      end
      document, values = @payload.values_at("document", "values")
      raise InvalidInput unless document.is_a?(Hash) && (document.keys - DOCUMENT_FIELDS).empty?
      raise InvalidInput unless document.values.all? { |value| value.is_a?(String) && value.length <= 5000 }
      raise InvalidInput unless values.is_a?(Hash) && values.size <= Templates::Renderer::FIELDS.size
      raise InvalidInput unless values.all? { |key, value| key.is_a?(String) && value.is_a?(String) && value.length <= 5000 }
      if document["expires_at"].present?
        expiry = Time.iso8601(document["expires_at"]) rescue nil
        raise InvalidInput unless expiry && document["expires_at"].match?(/(?:Z|[+-]\d{2}:\d{2})\z/)
      end
    end

    def canonical(value)
      value.is_a?(Hash) ? value.keys.sort.to_h { |key| [ key, canonical(value.fetch(key)) ] } : value
    end
  end
end
