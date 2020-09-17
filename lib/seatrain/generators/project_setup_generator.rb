module Seatrain
  class LocalSetupGenerator < Rails::Generators::Base
    namespace "seatrain:setup:project"
    source_root File.expand_path("templates", __dir__)

    def welcome
      say "\t🚃 SEATRAIN LOCAL DOCKER ENVIRONMENT #{invoke? ? "SETUP" : "CLEANUP"} 🌊", :green
    end

    # TODO
    def check_seatrain_yml
      # Check if the seatrain.yml exists and recommend running install generator when not
    end

    def generate_boilerplate
      inside(".seatrain") do
        template "Dockerfile.dev"
        template "Dockerfile.prod"
        template "Aptfile"
        template ".pryrc"
      end

      template "docker-compose.yml"
      template "dip.yml"
    end

    def patch_database_yml
      inject_into_file "config/database.yml", after: 'pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>' do
        <<~YAML
          \n  url: <%= ENV.fetch("DATABASE_URL", " ") %>
        YAML
      end
      say_status :info, '👌 url: <%= ENV.fetch("DATABASE_URL", " ") injected into config/database.yml' if invoke?
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
