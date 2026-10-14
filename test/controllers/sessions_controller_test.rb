require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create_user
  end

  test "requires authentication" do
    get session_path, as: :json
    assert_response :unauthorized
  end

  test "logs in with normalized email and logs out" do
    post session_path, params: { email: " OWNER@EXAMPLE.COM ", password: "secure-password-123" }, as: :json
    assert_response :no_content
    assert_match(/httponly/i, response.headers["Set-Cookie"].to_s)
    assert_match(/samesite=lax/i, response.headers["Set-Cookie"].to_s)
    get session_path, as: :json
    assert_response :success
    assert_equal({ "id" => @user.id, "name" => @user.name }, response.parsed_body)
    delete session_path, as: :json
    assert_response :no_content
    get session_path, as: :json
    assert_response :unauthorized
  end

  test "wrong password and unknown email return the same response" do
    post session_path, params: { email: @user.email, password: "wrong" }, as: :json
    assert_response :unauthorized
    post session_path, params: { email: "unknown@example.com", password: "wrong" }, as: :json
    assert_response :unauthorized
  end

  test "failed login clears existing authentication" do
    post session_path, params: { email: @user.email, password: "secure-password-123" }, as: :json
    post session_path, params: { email: @user.email, password: "wrong" }, as: :json
    get session_path, as: :json
    assert_response :unauthorized
  end

  test "session expires after twelve hours" do
    travel_to Time.current.change(usec: 0) do
      post session_path, params: { email: @user.email, password: "secure-password-123" }, as: :json
    end
    travel 12.hours do
      get session_path, as: :json
      assert_response :unauthorized
    end
  end

  test "rejects login without a CSRF token when forgery protection is enabled" do
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    post session_path, params: { email: @user.email, password: "secure-password-123" }, as: :json
    assert_response :unprocessable_entity
  ensure
    ActionController::Base.allow_forgery_protection = original
  end
end
