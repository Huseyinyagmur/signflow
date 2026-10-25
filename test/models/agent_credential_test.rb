require "test_helper"

class AgentCredentialTest < ActiveSupport::TestCase
  test "issues random credentials and stores only a digest" do
    owner = create_user
    first, token = AgentCredential.issue!(user: owner, label: "Local demo", expires_at: 1.day.from_now)
    second, other = AgentCredential.issue!(user: owner, label: "Other", expires_at: 1.day.from_now)
    assert_match(/\Asf_agent_[A-Za-z0-9_-]{43}\z/, token)
    assert_not_equal token, other
    assert_not_equal first.token_digest, second.token_digest
    assert_equal Digest::SHA256.hexdigest(token), first.reload.token_digest
    assert_not_includes first.attributes.values, token
    assert_equal first, AgentCredential.authenticate(token)
    [ nil, "", 123, "bad", first.token_digest ].each { |bad| assert_nil AgentCredential.authenticate(bad) }
  end

  test "expiration is strict and revocation is permanent" do
    credential, token = AgentCredential.issue!(user: create_user, label: "Demo", expires_at: 1.day.from_now)
    travel_to credential.expires_at - 1.second do
      assert AgentCredential.authenticate(token)
    end
    travel_to credential.expires_at, with_usec: true do
      assert_nil AgentCredential.authenticate(token)
    end
    travel_to credential.expires_at + 1.second do
      assert_nil AgentCredential.authenticate(token)
    end
    credential.revoke!
    assert_nil AgentCredential.authenticate(token)
    assert_not credential.update(revoked_at: nil)
    assert_not credential.reload.update(user: create_user(email: "other@example.com"))
    assert_not credential.reload.update(token_digest: "a" * 64)
  end

  test "requires a future bounded expiry and owner" do
    owner = create_user
    [ Time.current, 1.second.ago, 31.days.from_now ].each do |expiry|
      assert_raises(ActiveRecord::RecordInvalid) do
        AgentCredential.issue!(user: owner, label: "Demo", expires_at: expiry)
      end
    end
    assert_not AgentCredential.new(label: "Demo", expires_at: 1.day.from_now).valid?
  end
end
