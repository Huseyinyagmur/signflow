require "test_helper"
require_relative "../../script/support/agent_http_client"
require "socket"

class AgentHttpClientTest < ActiveSupport::TestCase
  test "rejects unsafe base URLs before any request" do
    [ "http://example.com", "https://user:pass@example.com", "https://example.com/path", "https://example.com?token=secret" ].each do |url|
      assert_raises(SignflowAgentHttp::Error) { SignflowAgentHttp::Client.new(base_url: url, token: "secret", allow_loopback_http: true) }
    end
  end

  test "redirects are never followed and errors do not expose response secrets" do
    server = TCPServer.new("127.0.0.1", 0)
    thread = Thread.new do
      connection = server.accept
      while (line = connection.gets) && line != "\r\n"
        # Read only the incoming HTTP headers.
      end
      connection.write("HTTP/1.1 302 Found\r\nLocation: https://example.com/stolen\r\nContent-Length: 6\r\nConnection: close\r\n\r\nsecret")
      connection.close
    end
    client = SignflowAgentHttp::Client.new(base_url: "http://127.0.0.1:#{server.addr[1]}", token: "secret", allow_loopback_http: true)
    error = assert_raises(SignflowAgentHttp::Error) { client.request(:get, "/api/v1/drafts/1", expected: 200) }
    assert_equal "unexpected_http_302", error.message
    assert thread.join(5)
  ensure
    thread&.kill if thread&.alive?
    server&.close
  end
end
