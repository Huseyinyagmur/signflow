require "json"
require "securerandom"
require "time"
require "date"
require "fileutils"
require_relative "agent_http_client"

module SignflowAgent
  class Error < StandardError; end

  def self.object!(value, keys:, required: keys)
    raise Error, "invalid_structure" unless value.is_a?(Hash) && (value.keys - keys).empty? && (required - value.keys).empty?
  end

  def self.positive_id!(value)
    raise Error, "invalid_id" unless value.is_a?(Integer) && value.positive?
  end

  def self.reject_secrets!(value, secrets)
    text = value.is_a?(String) ? value : JSON.generate(value)
    if secrets.any? { |secret| !secret.to_s.empty? && text.include?(secret) } || text.match?(/sf_agent_[A-Za-z0-9_-]{43}|sk-ant-[A-Za-z0-9_-]+/)
      raise Error, "sensitive_input_rejected"
    end
  end
end

require_relative "llm/job"
require_relative "llm/tools"
require_relative "llm/runner"
require_relative "llm/anthropic_provider"
require_relative "llm/secrets"
