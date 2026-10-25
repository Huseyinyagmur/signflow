require "io/console"

module SignflowAgent
  module Secrets
    def self.read(name, env: ENV, console: IO.console)
      value = env[name]
      value = console&.getpass("#{name} (gizli giriş, paylaşmayın): ") if value.to_s.empty?
      raise Error, "missing_secret_configuration" unless value.is_a?(String) && value.size.between?(1, 1024) && !value.match?(/[\x00-\x20\x7f]/)

      value
    end
  end
end
