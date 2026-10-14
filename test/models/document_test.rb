require "test_helper"

class DocumentTest < ActiveSupport::TestCase
  setup do
    @document = create_document
  end

  test "starts as a draft and requires an owner title and content" do
    assert @document.draft?
    document = Document.new
    assert_not document.valid?
    %i[user title content].each { |field| assert document.errors[field].any? }
  end

  test "validates status and recipient email" do
    @document.status = "unknown"
    @document.recipient_email = "invalid"
    assert_not @document.valid?
    assert @document.errors[:status].any?
    assert @document.errors[:recipient_email].any?
  end

  test "allows incomplete drafts but requires recipient and deadline when sending" do
    @document.update!(recipient_name: nil, recipient_email: nil, expires_at: nil)
    assert_raises(Document::InvalidTransition) { @document.send_for_signature! }
    @document.update!(expires_at: 1.day.from_now)
    assert_raises(ActiveRecord::RecordInvalid) { @document.send_for_signature! }
    assert @document.reload.draft?
    assert_nil @document.signing_token_digest
  end

  test "sends a draft and only stores a token digest" do
    token = @document.send_for_signature!
    assert_match(/\A[A-Za-z0-9_-]{43}\z/, token)
    assert @document.reload.pending?
    assert_equal Digest::SHA256.hexdigest(token), @document.signing_token_digest
    assert_not_includes @document.attributes.values, token
  end

  test "signs before deadline and invalidates token" do
    @document.send_for_signature!
    travel_to @document.expires_at - 1.second, with_usec: true do
      @document.sign!
      assert @document.reload.signed?
      assert_equal Time.current, @document.signed_at
      assert_nil @document.signing_token_digest
    end
  end

  test "rejects signing exactly at and after deadline" do
    @document.send_for_signature!
    [ @document.expires_at, @document.expires_at + 1.second ].each do |time|
      travel_to time, with_usec: true do
        assert_raises(Document::InvalidTransition) { @document.sign! }
        assert @document.reload.pending?
        assert_nil @document.signed_at
      end
    end
  end

  test "expires at deadline and invalidates token" do
    @document.send_for_signature!
    assert_raises(Document::InvalidTransition) { @document.expire! }
    travel_to @document.expires_at, with_usec: true do
      @document.expire!
      assert @document.reload.expired?
      assert_nil @document.signing_token_digest
      assert_nil @document.signed_at
    end
  end

  test "cannot send with a deadline at or before now" do
    travel_to Time.current.change(usec: 0) do
      [ Time.current, 1.second.ago ].each do |deadline|
        @document.update!(expires_at: deadline)
        assert_raises(Document::InvalidTransition) { @document.send_for_signature! }
      end
    end
  end

  test "rejects invalid transitions from draft pending signed and expired" do
    assert_raises(Document::InvalidTransition) { @document.sign! }
    assert_raises(Document::InvalidTransition) { @document.expire! }
    @document.send_for_signature!
    assert_raises(Document::InvalidTransition) { @document.send_for_signature! }
    @document.sign!
    %i[send_for_signature! sign! expire!].each do |method|
      assert_raises(Document::InvalidTransition) { @document.public_send(method) }
    end
    expired = create_document(user: @document.user)
    expired.send_for_signature!
    travel_to expired.expires_at, with_usec: true do
      expired.expire!
      %i[send_for_signature! sign! expire!].each do |method|
        assert_raises(Document::InvalidTransition) { expired.public_send(method) }
      end
    end
  end

  test "rejects direct lifecycle writes and non-draft creation" do
    { status: "pending", signed_at: Time.current, signing_token_digest: "forged" }.each do |field, value|
      assert_not @document.update(field => value)
      @document.reload
    end
    document = @document.dup
    document.status = "signed"
    assert_not document.save
  end

  test "freezes document terms recipient and deadline after sending" do
    @document.send_for_signature!
    { title: "Changed", content: "Changed", recipient_name: "Other",
      recipient_email: "other@example.com", expires_at: 2.days.from_now }.each do |field, value|
      assert_not @document.update(field => value)
      @document.reload
    end
  end

  test "never allows ownership reassignment" do
    assert_not @document.update(user: create_user(email: "other@example.com"))
  end

  test "stale instances cannot sign an already signed document" do
    @document.send_for_signature!
    stale = Document.find(@document.id)
    @document.sign!
    assert_raises(Document::InvalidTransition) { stale.sign! }
  end
end
