module Seatrain
  class ChartSetupGenerator < Rails::Generators::Base
    namespace "seatrain:helm"
    source_root File.expand_path("templates", __dir__)

    def welcome
      prompt.say "🚃 SEATRAIN HELM #{invoke? ? "SETUP" : "CLEANUP"} 🌊", :green
    end

    def check_tools
      return if revoke?
      @helm = Helm.new
    end

    def check_helm_version
      return if revoke?
      current_version = @helm.version
      if current_version.match(/v(\d)/)[1].to_i < 2
        prompt.error "Helm version needs to be 3 or greater, current version: #{current_version}"
        exit 0
      end
    end

    def check_seatrain_yml
      return if revoke?
      unless File.exist?("config/seatrain.yml")
        prompt.warn "Run `rails generate seatrain:install` first and edit the resulting `config/seatrain.yml`"
        exit 0
      end
    end

    def generate_boilerplate
      inside ".seatrain/helm" do
        template "values.yaml", force: true
        template "Chart.yaml", force: true
        template "templates/cron-example.yaml", force: true
      end
    end

    def install_helm_deps
      return if revoke?
      @helm.update_deps
      prompt.ok "👏  Seatrain base Helm chart downloaded"
    end

    # Only called on `rails destroy seatrain:setup:helm`
    def remove_helm_folder
      return if invoke?
      if prompt.ask "Remove `.seatrain/helm` folder and all its contents entirely?"
        FileUtils.rm_rf(Rails.root.join(".seatrain", "helm"))
      end
    end

    private

    def prompt
      @prompt ||= TTY::Prompt.new
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
