require "net/http"
require "json"
require "uri"

# Deterministic API transport; this is NOT an LLM agent.
module SignflowAgentHttp
  class Error < StandardError; end

  class Client
    attr_reader :last_status

    def initialize(base_url:, token:, allow_loopback_http: false)
      @base = URI.parse(base_url)
      loopback = allow_loopback_http && %w[localhost 127.0.0.1].include?(@base.host) && @base.scheme == "http"
      unless (@base.scheme == "https" || loopback) && @base.host && @base.userinfo.nil? &&
          [ "", "/" ].include?(@base.path) && @base.query.nil? && @base.fragment.nil?
        raise Error, "unsafe_base_url"
      end
      raise Error, "credential_required" if token.to_s.empty?

      @token = token
    rescue URI::InvalidURIError
      raise Error, "unsafe_base_url"
    end

    def request(method, path, expected:, payload: nil, key: nil)
      raise Error, "invalid_api_path" unless path.match?(/\A\/api\/v1\/[a-z0-9_\/-]+\z/)

      klass = { get: Net::HTTP::Get, post: Net::HTTP::Post }.fetch(method)
      request = klass.new(path)
      request["Authorization"] = "Bearer #{@token}"
      request["Accept"] = "application/json"
      request["Idempotency-Key"] = key if key
      if payload
        request["Content-Type"] = "application/json"
        request.body = JSON.generate(payload)
      end
      # Do not inherit HTTP_PROXY or follow redirects carrying credentials.
      http = Net::HTTP.new(@base.host, @base.port, nil)
      http.use_ssl = @base.scheme == "https"
      http.open_timeout = 5
      http.read_timeout = 20
      http.write_timeout = 10
      http.max_retries = 0
      response = http.request(request)
      @last_status = response.code.to_i
      raise Error, "unexpected_http_#{@last_status}" unless Array(expected).include?(@last_status)
      raise Error, "invalid_response" unless response["content-type"].to_s.start_with?("application/json") && response.body.bytesize <= 200_000

      JSON.parse(response.body)
    rescue JSON::ParserError
      raise Error, "invalid_response"
    rescue IOError, SystemCallError, Timeout::Error, OpenSSL::SSL::SSLError
      raise Error, "network_error_retry_with_same_key"
    end
  end
end
