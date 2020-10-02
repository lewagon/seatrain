module Seatrain
  class GhaSetupGenerator < Rails::Generators::Base
    namespace "seatrain:github_actions"
    source_root File.expand_path("templates", __dir__)

    def welcome
      prompt.say "🚃 SEATRAIN GITHUB ACTIONS DEPLOY #{invoke? ? "SETUP" : "CLEANUP"} 🌊"
    end

    def check_seatrain_yml
      return if revoke?
      unless File.exist?("config/seatrain.yml")
        prompt.warn "Run `rails generate seatrain:install` first and edit the resulting `config/seatrain.yml`", :red
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
      prompt.warn "⚠️  You need to set the following secrets in your GitHub repository:"
      prompt.say "👉  DIGITALOCEAN_ACCESS_TOKEN"
      prompt.say "👉  DOCKER_USERNAME" unless Seatrain.config.uses_docr? || Seatrain.config.docker_username.empty?
      prompt.say "👉  DOCKER_PASSWORD" unless Seatrain.config.uses_docr?
      prompt.say "👉  RAILS_MASTER_KEY"
      Seatrain.config.required_secrets.each do |name|
        prompt.say "👉  #{name.upcase}"
      end
    end

    private

    def prompt
      @prompt ||= TTY::Prompt.new
    end

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
