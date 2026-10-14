module Documents
  class Signing
    # The token is a bearer credential; never accept a caller-supplied document ID.
    def self.find(token:)
      raise ActiveRecord::RecordNotFound unless token.is_a?(String) && token.match?(/\A[A-Za-z0-9_-]{43}\z/)

      document = Document.where(status: "pending")
        .find_by!(signing_token_digest: Document.token_digest(token))
      Expiration.call(scope: Document.where(id: document.id))
      document.reload
      raise ActiveRecord::RecordNotFound unless document.pending? && document.expires_at > Time.current

      document
    end

    def self.sign!(token:, signer_name: nil, accepted: nil)
      document = find(token: token)
      acceptance = SignatureAcceptance.new(signer_name: signer_name, accepted: accepted)
      raise ActiveModel::ValidationError, acceptance unless acceptance.valid?

      document.sign!(signer_name: acceptance.signer_name)
    end
  end
end
