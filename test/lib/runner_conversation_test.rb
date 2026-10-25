require "test_helper"
require_relative "../../script/support/signflow_agent"

class RunnerConversationTest < ActiveSupport::TestCase
  class Tools
    attr_reader :verified
    def add_user_text(*) = nil
    def check_content!(*) = nil
    def definitions = []
    def call(*) = {}
    def question_fields!(fields) = fields
    def prepare(input) = input
    def create(*) = raise("must not write before browser approval")
  end

  class Provider
    attr_reader :messages
    def initialize(*texts) = @texts = texts
    def reply(messages:, **)
      @messages = messages.deep_dup
      { "content" => [ { "type" => "text", "text" => @texts.shift } ], "stop_reason" => "end_turn" }
    end
  end

  test "fenced question JSON is accepted without exposing model prose" do
    runner = SignflowAgent::Runner.new(provider: Provider.new("```json\n{\"type\":\"question\",\"fields\":[\"recipient_email\"]}\n```"), tools: Tools.new)
    assert_equal({ kind: :question, fields: [ "recipient_email" ] }, runner.advance(input: "Synthetic request"))
  end

  test "plain text question gets one bounded structured repair" do
    provider = Provider.new("What is the email?", '{"type":"question","fields":["recipient_email"]}')
    runner = SignflowAgent::Runner.new(provider: provider, tools: Tools.new)
    assert_equal :question, runner.advance(input: "Synthetic request")[:kind]
    assert_equal 2, runner.model_calls
    assert_match(/JSON/, provider.messages.last.fetch("content"))
  end

  test "invalid repair fails closed with a safe specific category" do
    runner = SignflowAgent::Runner.new(provider: Provider.new("question", "still prose"), tools: Tools.new)
    error = assert_raises(SignflowAgent::Error) { runner.advance(input: "Synthetic") }
    assert_equal "invalid_model_question_json", error.message
  end

  test "CLI manifest then fenced question reaches ask instead of invalid model response" do
    replies = [ { "content" => [ { "type" => "tool_use", "id" => "manifest", "name" => "get_template_version", "input" => {} } ], "stop_reason" => "tool_use" },
      { "content" => [ { "type" => "text", "text" => "```json\n{\"type\":\"question\",\"fields\":[\"recipient_email\"]}\n```" } ], "stop_reason" => "end_turn" } ]
    provider = Object.new
    provider.define_singleton_method(:reply) { |**| replies.shift }
    fields = catch(:asked) do
      SignflowAgent::Runner.new(provider: provider, tools: Tools.new).run(input: "Synthetic", ask: ->(question) { throw :asked, question }, confirm: ->(_) { flunk })
    end
    assert_equal [ "recipient_email" ], fields
  end
end
