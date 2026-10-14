require "test_helper"

class DocumentsTest < ActiveSupport::TestCase
  setup do
    @document = create_document
    @manager = Documents::Manage.new(user: @document.user)
  end

  test "owner can find edit and send their document" do
    assert_equal @document, @manager.find(@document.id)
    @manager.update!(@document.id, title: "Updated")
    assert_equal "Updated", @document.reload.title
    assert Documents::Signing.find(token: @manager.send_for_signature!(@document.id))
  end

  test "other users cannot find update or send a document" do
    manager = Documents::Manage.new(user: create_user(email: "other@example.com"))
    assert_raises(ActiveRecord::RecordNotFound) { manager.find(@document.id) }
    assert_raises(ActiveRecord::RecordNotFound) { manager.update!(@document.id, title: "Stolen") }
    assert_raises(ActiveRecord::RecordNotFound) { manager.send_for_signature!(@document.id) }
    assert @document.reload.draft?
  end

  test "ignores mass assigned owner state and signing metadata" do
    document = @manager.create!(title: "New", content: "Terms", user_id: -1,
      status: "signed", signed_at: Time.current, signing_token_digest: "fake")
    assert_equal @document.user, document.user
    assert document.draft?
    assert_nil document.signed_at
    assert_nil document.signing_token_digest
  end

  test "token grants access only to its own pending document" do
    other = create_document(user: @document.user)
    first_token = @document.send_for_signature!
    second_token = other.send_for_signature!
    assert_not_equal first_token, second_token
    assert_equal @document, Documents::Signing.find(token: first_token)
    Documents::Signing.sign!(token: first_token, signer_name: "Recipient", accepted: "1")
    assert @document.reload.signed?
    assert other.reload.pending?
    assert_raises(ActiveRecord::RecordNotFound) { Documents::Signing.sign!(token: first_token) }
  end

  test "rejects missing malformed unknown and stored digest credentials" do
    @document.send_for_signature!
    [ nil, "", 123, "invalid", "a" * 43, @document.signing_token_digest ].each do |token|
      assert_raises(ActiveRecord::RecordNotFound) { Documents::Signing.find(token: token) }
    end
  end

  test "expired deadline denies access even before explicit expiration" do
    token = @document.send_for_signature!
    travel_to @document.expires_at, with_usec: true do
      assert_raises(ActiveRecord::RecordNotFound) { Documents::Signing.find(token: token) }
      assert_raises(ActiveRecord::RecordNotFound) { Documents::Signing.sign!(token: token) }
      assert @document.reload.expired?
      assert_raises(ActiveRecord::RecordNotFound) { Documents::Signing.find(token: token) }
    end
  end
end
