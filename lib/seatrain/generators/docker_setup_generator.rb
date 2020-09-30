module Seatrain
  class DockerSetupGenerator < Rails::Generators::Base
    namespace "seatrain:docker"
    source_root File.expand_path("templates", __dir__)

    FILES_TO_FORCE = [
      ".seatrain/Aptfile",
      "docker-compose.yml",
      "dip.yml"
    ]

    FILES_TO_SKIP = [
      ".seatrain/Dockerfile.dev",
      ".seatrain/Dockerfile.prod",
      ".seatrain/.pryrc",
      ".seatrain/vnc.sh"
    ]

    def welcome
      say "🚃 SEATRAIN DOCKER #{invoke? ? "SETUP" : "CLEANUP"} 🌊", :green
    end

    def check_seatrain_yml
      return if revoke?
      unless File.exist?("config/seatrain.yml")
        say "Run `rails generate seatrain:install` first and edit the resulting `config/seatrain.yml`", :red
        exit 0
      end
    end

    def warn_overwrite
      return if revoke?
      FILES_TO_FORCE.each do |file|
        if File.exist?(file)
          exit 1 unless yes?(
            <<~TXT
              ⚠️  #{file} will be overwritten with new defaults. If you modified the original configuration,
              make sure to back up your changes. Continue? (y/n)
            TXT
          )
        end
      end
    end

    def generate_boilerplate
      FILES_TO_FORCE.each do |file|
        template file, force: true
      end

      FILES_TO_SKIP.each do |file|
        template file, skip: true
      end
    end

    def patch_database_yml
      return if invoke? && File.read("config/database.yml").match?(/url: <%= ENV\.fetch\("DATABASE_URL"/)
      inject_into_file "config/database.yml", after: 'pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>' do
        <<~YAML
          \n  url: <%= ENV.fetch("DATABASE_URL", " ") %>
        YAML
      end
      say_status :info, '👌 `url: <%= ENV.fetch("DATABASE_URL", " ") %>` injected into config/database.yml' if invoke?
    end

    def summarize
      return if revoke?
      say "\nAll set, you can run your app in containers locally now! 📦 \nRun `dip provision` to start"
    end

    private

    def method_missing(method, *args, &block)
      if method.to_s.start_with?("seatrain")
        Seatrain.config.send(method.to_s.delete_prefix("seatrain_").to_sym, *args, &block)
      else
        super
      end
    end

    def respond_to_missing?(name, include_private = false)
      if method.to_s.start_with?("seatrain")
        true
      else
        super
      end
    end

    def revoke?
      behavior == :revoke
    end

    def invoke?
      behavior == :invoke
    end
  end
end
