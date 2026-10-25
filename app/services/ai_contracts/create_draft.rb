module AiContracts
  class CreateDraft
    def self.call(user:, conversation_id:, payload:)
      conversation = user.ai_contract_conversations.find_by!(public_id: conversation_id)
      # The receipt row serializes approvals across PostgreSQL connections.
      conversation.with_lock do
        return Documents::Manage.new(user: user).find(conversation.document_id) if conversation.document_id
        raise SignflowAgent::Error, "conversation_expired" if conversation.expires_at <= Time.current

        version = Templates::Manage.new(user: user).version(conversation.template_version.template_id, conversation.template_version_id)
        raise SignflowAgent::Error, "job_binding_mismatch" unless payload["template_id"] == version.template_id && payload["template_version_id"] == version.id

        document = Documents::Manage.new(user: user).build_from_template(version: version,
          attributes: payload.fetch("document"), values: payload.fetch("values"))
        document.save!
        conversation.update!(document: document)
        document
      end
    end
  end
end
