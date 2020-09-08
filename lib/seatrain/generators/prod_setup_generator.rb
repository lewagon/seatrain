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

    # TODO: Make sure destroy does something.
    def welcome
      say "\t🚃 SEATRAIN PRODUCTION ENVIRONMENT #{invoke? ? "SETUP" : "CLEANUP"} 🌊", :green

      say "\t⚠️  helm and kubectl executables need to be installed and available in $PATH for generator to continue"
    end

    def check_tools
      return if revoke?
      # Both initializers will exit if executables not found
      @helm = Helm.new
      @kubectl = Kubectl.new
    end

    def check_helm_version
      # TODO Must be version 3, or else...
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
      name = "nginx-ingress"
      namespace = "ingress-nginx"

      if @helm.release_exists?(namespace, name)
        say_status :info, "🙌 #{name} already installed in a namespace #{namespace}, skipping..."
        return
      end

      unless @kubectl.namespace_exists?(namespace)
        say_status :info, "[KUBECTL] Creating #{namespace} namespace..."
        @kubectl.create_namespace(namespace)
      end

      out = @helm.add_repo(
        "ingress-nginx",
        "https://kubernetes.github.io/ingress-nginx"
      )
      say_status :info, "[HELM] #{out}"
      say_status :info, "[HELM] repositories succesfully updated" if @helm.update_repo

      say_status :info, "[HELM] Installing NGINX Ingress Controller"
      @helm.install(name, "ingress-nginx/ingress-nginx ", namespace)
      say_status :info, "[HELM]  🎉  NGINX Ingress Controller installed"
      say_status :info, "[KUBECTL] Waiting for LoadBalancer to become available..."

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
        say_status :info, "[KUBECTL]  🎉  Load balancer created, public IP: #{ip}"
      else
        say_status :error, "[KUBECTL] Failed to create LoadBalancer in #{NGINX_RETRIES} attempts, check Digital Ocean dashboard", :red
      end
    end

    # Patch nginx-ingress service in Digital Ocean
    def patch_do_load_balancer
      say_status :info, "[KUBECTL] Patching externalTrafficPolicy from Local to Cluster"
      @kubectl.patch_do_load_balancer
      say_status :info, "[KUBECTL] 🎉  Success!"
    end

    def install_certmanager
      return if revoke?
      name = namespace = "cert-manager"

      if @helm.release_exists?(namespace, name)
        say_status :info, "🙌 #{name} already installed in a namespace #{namespace}, skipping..."
        return
      end

      unless @kubectl.namespace_exists?(name)
        say_status :info, "[KUBECTL] Creating #{name} namespace..."
        @kubectl.create_namespace(name)
      end

      out = @helm.add_repo(
        "jetstack",
        "https://charts.jetstack.io"
      )
      say_status :info, "[HELM] #{out}"
      say_status :info, "[HELM] repositories succesfully updated" if @helm.update_repo

      say_status :info, "[HELM] Installing cert-manager..."
      @helm.install(
        name,
        "jetstack/cert-manager",
        namespace,
        "--version",
        "v0.16.1",
        "--set",
        "installCRDs=true"
      )
      say_status :info, "[HELM]  🎉  cert-manager installed"
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
