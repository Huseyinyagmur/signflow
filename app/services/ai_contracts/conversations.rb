module AiContracts
  class Conversations
    State = Struct.new(:lock, :expires_at, :runner, :tools, :messages, :result, :receipts, :step, :failed, keyword_init: true)
    STATES, LOCK = {}, Mutex.new
    MAX_STATES = 64

    class Binding
      attr_reader :data
      def initialize(version)
        @data = { "binding" => { "template_id" => version.template_id, "version_id" => version.id } }
      end
    end

    class MeteredProvider
      def initialize(provider, user_id) = (@provider, @user_id = provider, user_id)
      def reply(**options)
        Quota.consume!(@user_id, :model)
        @provider.reply(**options)
      end
    end

    def self.reset!
      LOCK.synchronize { STATES.clear }
      Quota::STORE.clear
    end

    def initialize(user:) = @user = user

    def start(version_id:, synthetic:)
      raise SignflowAgent::Error, "synthetic_data_required" unless synthetic == "1"
      raise SignflowAgent::Error, "invalid_id" unless version_id.is_a?(Integer) || version_id.is_a?(String)
      raise SignflowAgent::Error, "invalid_id" unless version_id.to_s.match?(/\A[1-9]\d{0,17}\z/)

      version = @user.templates.joins(:versions).where(template_versions: { id: version_id }).first!
      version = Templates::Manage.new(user: @user).version(version.id, version_id)
      Quota.consume!(@user.id, :starts)
      LOCK.synchronize do
        STATES.delete_if { |_, value| value.expires_at <= Time.current }
        raise SignflowAgent::Error, "conversation_capacity" if STATES.size >= MAX_STATES

        conversation = @user.ai_contract_conversations.create!(template_version: version,
          public_id: SecureRandom.uuid, expires_at: 1.hour.from_now)
        STATES[conversation.public_id] = State.new(lock: Mutex.new, expires_at: conversation.expires_at,
          messages: [], receipts: {}, step: 0, failed: false)
        conversation
      end
    end

    def find(id) = @user.ai_contract_conversations.find_by!(public_id: id)

    def snapshot(conversation)
      state = state_for(conversation)
      state.lock.synchronize { view(state) }
    end

    def message(conversation, prompt:, step:)
      raise SignflowAgent::Error, "invalid_user_input" unless prompt.is_a?(String) && prompt.strip.size.between?(1, 8000)

      SignflowAgent.reject_secrets!(prompt, [])
      state = state_for(conversation)
      state.lock.synchronize do
        digest = Digest::SHA256.hexdigest(prompt.to_s)
        if state.receipts.key?(step)
          raise SignflowAgent::Error, "message_conflict" unless state.receipts[step] == digest

          raise SignflowAgent::Error, "conversation_failed_start_new" if state.failed
          return
        end
        raise SignflowAgent::Error, "message_conflict" unless step == state.step.to_s && !state.result&.dig(:payload) && !conversation.document_id
        raise SignflowAgent::Error, "conversation_failed_start_new" if state.failed

        state.receipts[step] = digest
        begin
          initialize_runner(state, conversation, prompt) unless state.runner
          state.result = state.runner.advance(input: prompt)
          state.messages << { role: :user, text: prompt }
          if state.result[:kind] == :question
            labels = state.result[:fields].map { |field| SignflowAgent::Tools::FIELD_LABELS.fetch(field) }
            state.messages << { role: :assistant, text: "Lütfen tamamlayın: #{labels.join(', ')}" }
          else
            state.messages << { role: :assistant, text: "Bilgiler doğrulandı. Önizlemeyi kontrol edip Taslağı Oluştur düğmesine basabilirsiniz." }
          end
          state.step += 1
        rescue SignflowAgent::Error
          state.failed = true
          state.result = nil
          raise
        end
      end
    end

    def approve(conversation)
      # Recovery even after process restart/TTL, without another model invocation.
      return Documents::Manage.new(user: @user).find(conversation.document_id) if conversation.document_id

      state = state_for(conversation)
      state.lock.synchronize do
        raise SignflowAgent::Error, "proposal_required" unless state.result&.dig(:kind) == :proposal && !state.failed

        proposed = state.result.fetch(:payload)
        # Recheck grounding/deadline at the actual human confirmation time.
        payload = state.tools.prepare(proposed.slice("values").merge("document" => proposed.fetch("document").except("title")))
        CreateDraft.call(user: @user, conversation_id: conversation.public_id, payload: payload)
      end
    end

    def preview(conversation, snapshot)
      payload = snapshot.dig(:result, :payload)
      return unless payload

      Documents::Manage.new(user: @user).build_from_template(version: conversation.template_version,
        attributes: payload.fetch("document"), values: payload.fetch("values"))
    end

    private

    def state_for(conversation)
      raise ActiveRecord::RecordNotFound unless conversation.user_id == @user.id
      raise SignflowAgent::Error, "conversation_expired" if conversation.expires_at <= Time.current

      LOCK.synchronize do
        STATES.delete_if { |_, value| value.expires_at <= Time.current }
        STATES[conversation.public_id]
      end || raise(SignflowAgent::Error, "conversation_lost_start_new")
    end

    def initialize_runner(state, conversation, prompt)
      provider, secrets = ProviderFactory.build
      # Key rejection occurs before preflight/network or transcript acceptance.
      SignflowAgent.reject_secrets!(prompt, secrets)
      Quota.consume!(@user.id, :model)
      provider.verify_model!
      state.tools = SignflowAgent::Tools.new(api: TemplateAccess.new(user: @user, conversation: conversation),
        job: Binding.new(conversation.template_version), secrets: secrets, clock: -> { Time.current })
      state.runner = SignflowAgent::Runner.new(provider: MeteredProvider.new(provider, @user.id), tools: state.tools)
    end

    def view(state)
      { messages: state.messages.deep_dup, result: state.result.deep_dup, step: state.step, failed: state.failed }
    end
  end
end
