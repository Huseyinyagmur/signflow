require "test_helper"
require "open3"
require "tmpdir"

class DotenvConfigurationTest < ActiveSupport::TestCase
  test "development automatically loads dotenv while preserving process environment and hiding values" do
    result, output = probe("development")
    assert result.fetch("dotenv_loaded")
    assert result.fetch("file_loaded")
    assert result.fetch("process_preserved")
    assert_match(/Loaded .*\.env/, output)
    assert_not_includes output, "synthetic-dotenv-secret"
  end

  test "test and production do not load dotenv railtie or local secrets" do
    %w[test production].each do |environment|
      result, output = probe(environment)
      assert_not result.fetch("dotenv_loaded")
      assert_not result.fetch("file_loaded")
      assert result.fetch("process_preserved")
      assert_not_includes output, "synthetic-dotenv-secret"
    end
  end

  private

  def probe(environment)
    Dir.mktmpdir("signflow-dotenv-test") do |directory|
      # A disposable Rails application, never the real repository .env/credentials.
      FileUtils.mkdir_p(File.join(directory, "config"))
      File.write(File.join(directory, ".env"), "GEMINI_API_KEY=synthetic-dotenv-secret\nSIGNFLOW_DOTENV_PRECEDENCE=file-value\n")
      script = <<~RUBY
        require "rails/all"
        require "json"
        Bundler.require(*Rails.groups)
        Dotenv::Rails.logger = Logger.new($stdout) if defined?(Dotenv::Rails)
        class DotenvProbe < Rails::Application
          config.root = #{directory.dump}
        end
        puts JSON.generate(dotenv_loaded: !!defined?(Dotenv::Rails),
          file_loaded: ENV["GEMINI_API_KEY"] == "synthetic-dotenv-secret",
          process_preserved: ENV["SIGNFLOW_DOTENV_PRECEDENCE"] == "process-value")
      RUBY
      path = File.join(directory, "config", "application.rb")
      File.write(path, script)
      output, error, status = Open3.capture3({ "RAILS_ENV" => environment, "RACK_ENV" => nil,
        "RAILS_ROOT" => directory, "GEMINI_API_KEY" => nil,
        "BUNDLE_GEMFILE" => Rails.root.join("Gemfile").to_s,
        "SIGNFLOW_DOTENV_PRECEDENCE" => "process-value" },
        RbConfig.ruby, "-rbundler/setup", path, chdir: directory)
      assert status.success?, "Isolated dotenv probe failed (#{environment}); no secret output printed"
      [ JSON.parse(output.lines.last), output + error ]
    end
  end
end
