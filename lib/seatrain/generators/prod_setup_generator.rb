require "open-uri"
require "ipaddr"
require_relative "../yaml_transformer"
require_relative "../helm"
require_relative "../kubectl"

module Seatrain
  class ProdSetupGenerator < Rails::Generators::Base
    NGINX_RETRIES = 18
    NGINX_RETRY_INTERVAL = 30

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

    def check_helm_version
      # TODO
    end

    def warn_context
      return if revoke?
      ctx = @kubectl.current_context
      say_status :info, "Your Kubernetes context is set to \e[1m#{ctx}\e[22m"
      unless yes? "\tIs this a cluster where you plan to deploy? 👆"
        say "Make sure to select the correct Kubernetes context and re-run this generator", :yellow
        exit 0
      end
    end

    # WIP
    def install_nginx_ingress
      return if revoke?
      name = namespace = "nginx-ingress"

      if @helm.release_exists?(namespace, name)
        say_status :info, "🙌 #{name} already installed in a namespace #{namespace}, skipping..."
        return
      end

      unless @kubectl.namespace_exists?(name)
        say_status :info, "[KUBECTL] Creating nginx-ingress namespace..."
        @kubectl.create_namespace(name)
      end

      out = @helm.add_repo(
        "nginx-stable",
        "https://helm.nginx.com/stable"
      )
      say_status :info, "[HELM] #{out}"
      say_status :info, "[HELM] repositories succesfully updated" if @helm.update_repo

      say_status :info, "Installing NGINX Ingress Controller"
      out = @helm.install(name, "nginx-stable/nginx-ingress", namespace)
      say_status :info, "[HELM] #{out}"
      say_status :info, "Waiting for LoadBalancer to become available..."

      success = ip = nil
      begin
        NGINX_RETRIES.times do |i|
          out = @kubectl.get_load_balancer_ip
          ip = IPAddr.new(out)
          success = true
        rescue IPAddr::InvalidAddressError
          say_status :info, "Attempt #{i + 1}/#{NGINX_RETRIES} ☕️ Retrying in #{NGINX_RETRY_INTERVAL} seconds..."
          sleep(NGINX_RETRY_INTERVAL)
          next
        end
      end

      if success
        say_status :info, "[KUBECTL] 🎉  Load balancer created, ip #{ip}"
      else
        say_status :error, "Failed to create LoadBalancer in #{NGINX_RETRIES} attempts, check Digital Ocean dashboard", :red
      end
    end

    # TODO: Patch nginx-ingress service for Local/Cluster (DO specific bug)

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
