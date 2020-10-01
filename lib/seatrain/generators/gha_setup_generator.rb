module Seatrain
  class GhaSetupGenerator < Rails::Generators::Base
    namespace "seatrain:github_actions"
    source_root File.expand_path("templates", __dir__)

    def welcome
      say "🚃 SEATRAIN GHA #{invoke? ? "SETUP" : "CLEANUP"} 🌊", :green
    end

    def check_seatrain_yml
      return if revoke?
      unless File.exist?("config/seatrain.yml")
        say "Run `rails generate seatrain:install` first and edit the resulting `config/seatrain.yml`", :red
        exit 0
      end
    end

    def generate_boilerplate
      inside ".github/workflows" do
        template "deploy.yaml"
      end
    end

    # TODO:
    def print_instructions
      puts "You need to set the following secrets in your GitHub repository: "
    end

    private

    def generate_upgrade_string
      Seatrain::Helm.new.safe_upgrade_command_string
    end

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
