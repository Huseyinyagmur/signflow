require "test_helper"

class ExpirationTest < ActiveSupport::TestCase
  test "owner refresh only expires their own documents then sweep expires all due documents" do
    first = create_document
    other = create_document(user: create_user(email: "other@example.com"))
    first.send_for_signature!
    other.send_for_signature!
    travel_to [ first.expires_at, other.expires_at ].max, with_usec: true do
      Documents::Manage.new(user: first.user).all
      assert first.reload.expired?
      assert other.reload.pending?
      Documents::Expiration.call
      assert other.reload.expired?
      Documents::Expiration.call
      assert_nil other.reload.signing_token_digest
    end
  end

  test "sweep leaves drafts signed and future pending documents intact" do
    draft = create_document
    signed = create_document(user: draft.user)
    signed.send_for_signature!
    signed.sign!(signer_name: "Recipient")
    pending = create_document(user: draft.user)
    pending.send_for_signature!
    Documents::Expiration.call
    assert draft.reload.draft?
    assert signed.reload.signed?
    assert pending.reload.pending?
  end

  test "signing service validates acceptance and persists signer metadata" do
    document = create_document
    token = document.send_for_signature!
    assert_raises(ActiveModel::ValidationError) { Documents::Signing.sign!(token: token) }
    assert document.reload.pending?
    Documents::Signing.sign!(token: token, signer_name: "  Deniz  ", accepted: "1")
    assert_equal "Deniz", document.reload.signer_name
    assert_not document.update(signer_name: "Forged")
  end
end
