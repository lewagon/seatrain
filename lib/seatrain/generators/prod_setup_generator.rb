require "open-uri"
require_relative "../yaml_transformer"
require_relative "../helm"
require_relative "../kubectl"

module Seatrain
  class ProdSetupGenerator < Rails::Generators::Base
    namespace "seatrain:setup:prod"

    class_option :dockerfile_prod_uri,
      type: :string,
      desc: "URI for the production Dockerfile",
      # Move to config
      default: ENV.fetch("SEATRAIN_DOCKERPROD_URI", SEATRAIN_DOCKERPROD_URI)

    def welcome
      say "\t🚃 SEATRAIN PRODUCTION ENVIRONMENT #{invoke? ? "SETUP" : "CLEANUP"} 🌊", :green

      say "\t⚠️  helm and kubectl executables need to be installed and available in $PATH for generator to continue"
    end

    # TODO
    # def place_dockerfile_prod
    #   dockerfile = URI.open(options[:dockerfile_prod_uri]).read
    #   create_file ".seatrain/Dockerfile.prod", dockerfile
    # end

    def check_tools
      return if revoke?
      # Both initializers will exit if executables not found
      @helm = Helm.new
      @kubectl = Kubectl.new
    end

    def warn_context
      return if revoke?
      ctx = @kubectl.current_context
      say_status :info, "Your Kubernetes context is set to #{ctx}"
      unless yes? "Is this a cluster where you plan to deploy? 👆"
        say "Make sure to select the correct Kubernetes context and re-run this generator", :yellow
        exit 0
      end
    end

    # WIP
    def install_nginx_ingress
      name = namespace = "nginx-ingress"
      return if revoke?
      if @helm.release_exists?(namespace, name)
        say_status :info, "🙌 #{name} already installed in a namespace #{namespace}, skipping..."
        return
      end
      @kubectl.create_namespace(name)
    rescue NamespaceAlreadyExistsError
      # @helm.install ....
    end

    private

    # TODO: DRY
    def invoke?
      behavior == :invoke
    end

    def revoke?
      behavior == :revoke
    end
  end
end
