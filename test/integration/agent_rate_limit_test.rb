require "test_helper"

class AgentRateLimitTest < ActionDispatch::IntegrationTest
  setup do
    @flag = ENV["AGENT_API_ENABLED"]
    ENV["AGENT_API_ENABLED"] = "true"
    @owner = create_user
    @template = create_template(user: @owner, content: "{{hizmet}}")
    _, @token = AgentCredential.issue!(user: @owner, label: "Quota", expires_at: 1.day.from_now)
    @headers = { "Authorization" => "Bearer #{@token}", "Idempotency-Key" => "quota-request-0001" }
    @payload = { template_id: @template.id, template_version_id: @template.current_version_id, values: { hizmet: "Demo" }, document: { title: "Quota draft" } }
  end

  teardown do
    ENV["AGENT_API_ENABLED"] = @flag
  end

  test "read quota returns 429 retry after and recovers at the boundary" do
    start = Time.current.change(usec: 0)
    travel_to start
    60.times do
      get manifest, headers: @headers
      assert_response :success
    end
    get manifest, headers: @headers
    assert_response :too_many_requests
    assert_equal "60", response.headers["Retry-After"]
    assert_equal "rate_limit_exceeded", response.parsed_body["error"]
    assert_equal "no-store", response.headers["Cache-Control"]
    head manifest, headers: @headers
    assert_response :too_many_requests
    travel_to start + 60.seconds
    get manifest, headers: @headers
    assert_response :success
  end

  test "revocation is checked before quota and remains effective when exhausted" do
    60.times { get manifest, headers: @headers }
    AgentCredential.authenticate(@token).revoke!
    get manifest, headers: @headers
    assert_response :unauthorized
  end

  test "write quota counts replay without duplicating and is isolated per credential" do
    10.times { post "/api/v1/drafts", params: @payload, headers: @headers, as: :json }
    assert_equal 1, @owner.documents.count
    assert_no_difference([ "Document.count", "AgentRequest.count" ]) do
      post "/api/v1/drafts", params: @payload, headers: @headers, as: :json
      assert_response :too_many_requests
    end
    _, second = AgentCredential.issue!(user: @owner, label: "Second", expires_at: 1.day.from_now)
    @headers["Authorization"] = "Bearer #{second}"
    assert_no_difference("Document.count") do
      post "/api/v1/drafts", params: @payload, headers: @headers, as: :json
      assert_response :success
    end
    assert_equal true, response.parsed_body["replayed"]
    get manifest, headers: @headers
    assert_response :success
  end

  private

  def manifest
    "/api/v1/templates/#{@template.id}/versions/#{@template.current_version_id}"
  end
end
