require "test_helper"

class SignatureAcceptanceTest < ActiveSupport::TestCase
  test "requires a trimmed name and explicit acceptance" do
    acceptance = SignatureAcceptance.new(signer_name: "  Recipient  ", accepted: "1")
    assert acceptance.valid?
    assert_equal "Recipient", acceptance.signer_name
    [ nil, "0", "true", true ].each do |value|
      acceptance.accepted = value
      assert_not acceptance.valid?
    end
  end
end
