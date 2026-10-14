require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "normalizes email and authenticates a hashed password" do
    user = create_user(email: " Owner@Example.COM ")
    assert_equal "owner@example.com", user.email
    assert user.authenticate("secure-password-123")
    assert_not user.authenticate("incorrect")
    assert_not_equal "secure-password-123", user.password_digest
  end

  test "requires name email and a password" do
    user = User.new
    assert_not user.valid?
    %i[name email password].each { |field| assert user.errors[field].any? }
  end

  test "rejects malformed and duplicate emails" do
    create_user
    user = User.new(name: "Other", email: "OWNER@example.com", password: "secure-password-123")
    assert_not user.valid?
    assert user.errors[:email].any?
    user.email = "invalid"
    assert_not user.valid?
  end

  test "requires at least twelve characters and rejects bcrypt overflow" do
    user = User.new(name: "Owner", email: "owner@example.com", password: "short")
    assert_not user.valid?
    user.password = "a" * 73
    assert_not user.valid?
  end

  test "can update profile without changing password" do
    assert create_user.update(name: "New name")
  end

  test "does not delete an owner with documents" do
    document = create_document
    assert_not document.user.destroy
    assert Document.exists?(document.id)
  end
end
