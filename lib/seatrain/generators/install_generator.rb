module Seatrain
  class InstallGenerator < Rails::Generators::Base
    namespace "seatrain:install"
    source_root File.expand_path("templates", __dir__)

    def welcome
      prompt.say "🚃 SEATRAIN #{invoke? ? "INSTALL" : "CLEANUP"} 🌊"
    end

    def warn_overwrite
      return if revoke?
      return unless File.exist?("config/seatrain.yml")
      prompt.warn <<~TXT
        ⚠️  Your `config/setrain.yml` will be overwritten.

        If you modified this file manually, make sure to back up your work (e.g., make a git commit)
      TXT

      unless prompt.yes?("Overwrite config/seatrain.yml?")
        prompt.ok("No worries. Re-run this generator once ready.")
        exit 0
      end
    end

    def ask_versions
      return if revoke?
      prompt.say "\n"
      prompt.ok "Decide on software to be installed in containers"
      prompt.ok "------------------------------------------------"
      prompt.say 'Press "Enter" to use default values in brackets'
      config.ruby_version = prompt.ask "Ruby version", default: Seatrain::DEFAULT_RUBY_VERSION
      config.pg_major_version = prompt.ask "PostgreSQL client major version",
        default: Seatrain::DEFAULT_PG_MAJOR_VERSION
      config.node_major_version = prompt.ask "Node.js major version", default: Seatrain::DEFAULT_NODE_MAJOR_VERSION
      config.yarn_version = prompt.ask "Yarn version", default: Seatrain::DEFAULT_YARN_VERSION
      config.bundler_version = prompt.ask "Bundler version", default: Seatrain::DEFAULT_BUNDLER_VERSION
    end

    def ask_sidekiq_webpacker
      return if revoke?
      answer = prompt.multi_select("These features will be kept unless you exclude them:") { |menu|
        menu.default 1, 2
        menu.choice :webpacker, true
        menu.choice :sidekiq, true
      }
      config.use_webpacker = answer.first
      config.use_sidekiq = answer.last
    end

    def ask_docker
      return if revoke?
      prompt.ok "\nContainer registry details"
      prompt.ok "----------------------------"
      registry = prompt.select("Pick the container registry where you want to store a production image:") { |menu|
        menu.choice "Docker Hub", "docker.io"
        menu.choice "GitHub Container Registry", "ghcr.io"
        menu.choice "Quay", "quay.io"
        menu.choice "Digital Ocean Container Registry", "registry.digitalocean.com"
        menu.choice "Other", "OTHER"
      }
      registry = prompt.ask "Enter the base URI of your container registry" if registry == "OTHER"
      config.docker_registry = registry
      repo = prompt.ask(
        "Enter the repository name you have access to where to store your images.\nUsually this is your account name:",
        required: true
      )
      config.docker_repository = repo
      image = config.app_name
      final_image = "#{registry}/#{repo}/#{image}"
      prompt.say "Do you agree with the image name in the brackets that will be used for deployments?"
      final_image = prompt.ask(
        "'Enter' to confirm, provide new full name to change (including registry URI and repo name):",
        default: final_image
      )
      config.production_image_name = final_image
      return if registry == Seatrain::Config::DOCR_URL
      config.docker_username = prompt.ask "Enter username for registry access [can be blank for now]:"
    end

    def ask_cluster
      return if revoke?
      prompt.ok "\n Cluster and hostname details"
      prompt.ok "-------------------------------"
      prompt.warn <<~TXT
        ⚠️  You will be asked to provide a Digital Ocean Kubernetes cluster name where you will deploy your application.
        If you haven't provisioned a cluster yet, make sure you use the same name in your Digital Ocean dashboard.

        You will also be asked for a hostname. Make sure you can point that as DNS A-record to the IP
        of Digital Ocean load balancer. The load balancer will be provisioned in next steps.
        Don't include `http(s)://` in the hostname.

        These values can be left blank for now, but don't forget to put them manually into config/seatrain.yml
        when attempting the first deploy.
      TXT
      config.do_cluster_name = prompt.ask("Name of cluster:")
      config.hostname = prompt.ask("Hostname of your application:")
      config.certificate_email = prompt.ask("Email address for Let's Encrypt certificate reminders:")
    end

    def generate_boilerplate
      inside "config" do
        template "seatrain.yml", force: true
      end
    end

    def confirm
      prompt.ok "🎉 Generated Seatrain configuration can be found in `config/seatrain.yml`"
      prompt.ok "Run `rails g seatrain:docker to generate your local Docker environment and a production Dockerfile"
    end

    private

    def config
      Seatrain.config
    end

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
