module SignflowAgent
  class Job
    attr_reader :path, :data

    def initialize(directory:, id:, binding:)
      raise Error, "invalid_job_id" unless id.to_s.match?(/\A[a-zA-Z0-9_-]{1,64}\z/)

      @directory = File.expand_path(directory)
      FileUtils.mkdir_p(@directory, mode: 0o700)
      @path = File.join(@directory, "#{id}.json")
      raise Error, "unsafe_job_file" if File.symlink?(@path) || File.symlink?("#{@path}.lock")

      @lock = File.open("#{@path}.lock", File::RDWR | File::CREAT, 0o600)
      raise Error, "job_already_running" unless @lock.flock(File::LOCK_EX | File::LOCK_NB)

      if File.exist?(@path)
        raise Error, "invalid_job_file" if File.size(@path) > 100_000

        @data = JSON.parse(File.read(@path))
        SignflowAgent.object!(@data, keys: %w[version binding key payload document_id], required: %w[version binding key])
        raise Error, "job_binding_mismatch" unless @data["version"] == 1 && @data["binding"] == binding
        raise Error, "invalid_job_key" unless @data["key"].is_a?(String) && @data["key"].match?(/\A[A-Za-z0-9_-]{16,128}\z/)
      else
        @data = { "version" => 1, "binding" => binding, "key" => SecureRandom.uuid }
        save
      end
    rescue JSON::ParserError, SystemCallError
      close
      raise Error, "job_storage_error"
    rescue Error
      close
      raise
    end

    def pin_payload(payload)
      if @data.key?("payload") && @data["payload"] != payload
        raise Error, "job_payload_conflict"
      end
      @data["payload"] = JSON.parse(JSON.generate(payload))
      save # Before POST: process crash / lost response must retain the same key and payload.
    end

    def record_document(id)
      SignflowAgent.positive_id!(id)
      raise Error, "document_id_mismatch" if @data["document_id"] && @data["document_id"] != id

      @data["document_id"] = id
      save
    end

    def close
      @lock&.close unless @lock&.closed?
    end

    private

    def save
      temporary = "#{@path}.#{SecureRandom.hex(8)}.tmp"
      File.open(temporary, File::WRONLY | File::CREAT | File::EXCL, 0o600) do |file|
        file.write(JSON.generate(@data))
        file.flush
        file.fsync
      end
      File.rename(temporary, @path)
    rescue SystemCallError
      raise Error, "job_storage_error"
    end
  end
end
