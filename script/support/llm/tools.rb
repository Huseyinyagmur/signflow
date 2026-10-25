require "uri"

module SignflowAgent
  class Tools
    FIELDS = %w[alici_adi hizmet ucret baslangic_tarihi bitis_tarihi].freeze
    DOCUMENT_FIELDS = %w[recipient_name recipient_email expires_at].freeze
    MONEY = /(?<![\p{L}\d])\d+(?:[.,]\d+)*(?:[ \t]*(?:bin|milyon))?[ \t]*(?:TL|TRY|₺)(?![\p{L}\d])/i
    FIELD_LABELS = {
      "alici_adi" => "Alıcı adı", "recipient_name" => "Alıcı adı", "recipient_email" => "Alıcı e-postası",
      "hizmet" => "Hizmet açıklaması", "ucret" => "Ücret", "baslangic_tarihi" => "Hizmet başlangıç tarihi (YYYY-MM-DD)",
      "bitis_tarihi" => "Hizmet bitiş tarihi (YYYY-MM-DD)", "expires_at" => "Son imza tarihi (offset içeren ISO8601)"
    }.freeze
    attr_reader :events, :manifest, :verified

    def initialize(api:, job:, secrets:, clock: -> { Time.now }, sleeper: ->(seconds) { sleep(seconds) }, observer: ->(_) { })
      @api, @job, @secrets, @clock, @sleeper = api, job, secrets, clock, sleeper
      @observer = observer
      @events, @user_texts = [], []
    end

    def definitions
      empty = { type: "object", properties: {}, additionalProperties: false }
      strings = ->(keys) { keys.to_h { |name| [ name, { type: "string", minLength: 1, maxLength: 5000 } ] } }
      [ { name: "get_template_version", description: "Read the fixed authorized template version and required variable names. Must be called first.", input_schema: empty },
        { name: "create_draft", description: "Create a draft after all required fields are explicitly supplied. Values must be verbatim substrings of user messages; never guess. Local human field confirmation is required.",
          input_schema: { type: "object", additionalProperties: false, required: %w[values document], properties: {
            values: { type: "object", additionalProperties: false, properties: strings.call(FIELDS) },
            document: { type: "object", additionalProperties: false, required: DOCUMENT_FIELDS, properties: strings.call(DOCUMENT_FIELDS) }
          } } },
        { name: "get_draft", description: "Verify the draft created by this job. Call after create_draft; no arbitrary document IDs allowed.", input_schema: empty } ]
    end

    def add_user_text(text)
      raise Error, "invalid_user_input" unless text.is_a?(String) && text.strip.size.between?(1, 8000) && @user_texts.join.size + text.size <= 20_000

      SignflowAgent.reject_secrets!(text, @secrets)
      @user_texts << text
    end

    def check_content!(content)
      SignflowAgent.reject_secrets!(content, @secrets)
    end

    def call(name, input)
      raise Error, "unknown_tool" unless %w[get_template_version get_draft].include?(name)

      SignflowAgent.object!(input, keys: [])
      name == "get_template_version" ? read_manifest : read_draft
    end

    def prepare(input)
      raise Error, "manifest_required" unless @manifest

      check_content!(input)
      SignflowAgent.object!(input, keys: %w[values document])
      values, document = input.values_at("values", "document")
      SignflowAgent.object!(values, keys: @manifest.fetch("variables"))
      SignflowAgent.object!(document, keys: DOCUMENT_FIELDS)
      (values.values + document.values).each do |value|
        raise Error, "missing_or_ungrounded_fields" unless value.is_a?(String) && value.strip.size.between?(1, 5000) && @user_texts.any? { |text| text.include?(value) }
      end
      raise Error, "invalid_email" unless document["recipient_email"].match?(URI::MailTo::EMAIL_REGEXP)
      if values["ucret"] && !@user_texts.flat_map { |text| text.scan(MONEY) }.include?(values["ucret"])
        raise Error, "fee_must_match_explicit_try_amount"
      end

      expiry = Time.iso8601(document["expires_at"]) rescue nil
      raise Error, "invalid_deadline" unless expiry && expiry > @clock.call && document["expires_at"].match?(/(?:Z|[+-]\d{2}:\d{2})\z/)

      %w[baslangic_tarihi bitis_tarihi].each do |name|
        next unless values[name]

        raise Error, "invalid_service_date" unless values[name].match?(/\A\d{4}-\d{2}-\d{2}\z/) && (Date.iso8601(values[name]) rescue nil)
      end
      { "template_id" => @job.data.fetch("binding").fetch("template_id"),
        "template_version_id" => @job.data.fetch("binding").fetch("version_id"),
        "values" => values, "document" => document.merge("title" => "Agent sözleşme taslağı") }
    end

    def create(payload)
      check_content!(payload)
      SignflowAgent.object!(payload, keys: %w[template_id template_version_id values document])
      binding = @job.data.fetch("binding")
      raise Error, "job_binding_mismatch" unless payload["template_id"] == binding["template_id"] && payload["template_version_id"] == binding["version_id"]

      @job.pin_payload(payload)
      result = api_call("create_draft", :post, "/api/v1/drafts", expected: [ 200, 201 ], payload: payload, key: @job.data.fetch("key"))
      validate_draft!(result, create: true)
      raise Error, "initial_document_not_draft" if !result.fetch("replayed") && result.fetch("status") != "draft"

      @job.record_document(result.fetch("id"))
      safe_draft(result)
    end

    def resume
      raise Error, "nothing_to_resume" unless @job.data["payload"]

      create(@job.data.fetch("payload"))
      read_draft
    end

    def question_fields!(fields)
      raise Error, "manifest_required" unless @manifest
      allowed = @manifest.fetch("variables") + DOCUMENT_FIELDS
      raise Error, "invalid_question" unless fields.is_a?(Array) && fields.size.between?(1, 8) && fields.uniq == fields && (fields - allowed).empty?

      fields
    end

    private

    def read_manifest
      binding = @job.data.fetch("binding")
      result = api_call("get_template_version", :get, "/api/v1/templates/#{binding.fetch('template_id')}/versions/#{binding.fetch('version_id')}", expected: 200)
      SignflowAgent.object!(result, keys: %w[id template_id number title variables])
      raise Error, "invalid_manifest" unless result["id"] == binding["version_id"] && result["template_id"] == binding["template_id"] &&
        result["number"].is_a?(Integer) && result["number"].positive? && result["title"].is_a?(String) && result["title"].size <= 500 &&
        result["variables"].is_a?(Array) && result["variables"].uniq == result["variables"] && (result["variables"] - FIELDS).empty?

      # Titles and full contract text are untrusted data and are unnecessary in model context.
      @manifest = result.reject { |key, _| key == "title" }
    end

    def read_draft
      id = @job.data["document_id"]
      SignflowAgent.positive_id!(id)
      result = api_call("get_draft", :get, "/api/v1/drafts/#{id}", expected: 200)
      validate_draft!(result)
      raise Error, "document_id_mismatch" unless result["id"] == id

      @verified = safe_draft(result)
    end

    def validate_draft!(result, create: false)
      keys = %w[id title content status template_version_id review_path]
      keys += [ "replayed" ] if create
      SignflowAgent.object!(result, keys: keys)
      SignflowAgent.positive_id!(result["id"])
      raise Error, "invalid_draft_response" unless result["title"].is_a?(String) && result["title"].size.between?(1, 5000) &&
        result["content"].is_a?(String) && result["content"].bytesize <= 180_000 && %w[draft pending signed expired].include?(result["status"]) &&
        result["template_version_id"] == @job.data.fetch("binding").fetch("version_id") && result["review_path"] == "/documents/#{result['id']}"
      raise Error, "invalid_replay_response" if create && ![ true, false ].include?(result["replayed"])
    end

    def safe_draft(result)
      result.reject { |key, _| key == "content" }
    end

    def api_call(tool, method, path, **options)
      attempts = 0
      begin
        attempts += 1
        result = @api.request(method, path, **options)
        check_content!(result)
        record_event(tool, @api.respond_to?(:last_status) ? @api.last_status : nil, attempts)
        result
      rescue SignflowAgentHttp::Error => error
        record_event(tool, error.status, attempts)
        transient = [ 429, 500, 502, 503, 504 ].include?(error.status) || error.message == "network_error_retry_with_same_key"
        if transient && attempts < 2
          @sleeper.call(0.5)
          retry
        end
        code = error.status ? "api_http_#{error.status}" : "api_transport_error_resume_same_job"
        raise Error, code
      end
    end

    def record_event(tool, status, attempt)
      event = { "tool" => tool, "http_status" => status, "attempt" => attempt }
      @events << event
      @observer.call(event)
    end
  end
end
