require "ipaddr"
require_relative "../helm"
require_relative "../kubectl"

module Seatrain
  class ClusterSetupGenerator < Rails::Generators::Base
    NGINX_RETRIES = 18
    NGINX_RETRY_INTERVAL = 30

    namespace "seatrain:cluster:prepare"

    def welcome
      prompt.ok "🚃 SEATRAIN CLUSTER PREPARATION 🌊"

      prompt.warn "⚠️  helm and kubectl executables need to be installed and available in $PATH for generator to continue"
    end

    def check_tools
      return if revoke?
      # Initializers will exit if executables not found
      @helm = Helm.new
      @kubectl = Kubectl.new
    end

    def check_helm_version
      return if revoke?
      current_version = @helm.version
      if current_version.match(/v(\d)/)[1].to_i < 2
        prompt.error "Helm version needs to be 3 or greater, current version: #{current_version}"
        exit 0
      end
    end

    def warn_context
      return if revoke?
      ctx = @kubectl.current_context
      prompt.warn "Your Kubernetes context is set to \e[1m#{ctx}\e[22m"
      unless prompt.yes? "Is this a cluster where you plan to deploy? 👆"
        prompt.ok "Make sure to set the correct Kubernetes context and re-run this generator"
        exit 0
      end
    end

    # WIP
    def install_nginx_ingress
      return if revoke?
      name = "nginx-ingress"
      namespace = "ingress-nginx"

      if @helm.release_exists?(namespace, name)
        prompt.say "🙌 #{name} already installed in a namespace #{namespace}, skipping..."
        return
      end

      out = @helm.add_repo(
        "ingress-nginx",
        "https://kubernetes.github.io/ingress-nginx"
      )
      prompt.say "[HELM] #{out}"
      prompt.say "[HELM] repositories succesfully updated" if @helm.update_repo

      prompt.say "[HELM] Installing NGINX Ingress Controller in the #{namespace} namespace"
      @helm.install(name, "ingress-nginx/ingress-nginx ", namespace)
      prompt.say "[HELM]  🎉  NGINX Ingress Controller installed"
      prompt.say "[KUBECTL] Waiting for LoadBalancer to become available..."

      success = ip = nil
      begin
        NGINX_RETRIES.times do |i|
          out = @kubectl.get_load_balancer_ip
          ip = IPAddr.new(out)
          success = true
        rescue IPAddr::InvalidAddressError
          prompt.say "Attempt #{i + 1}/#{NGINX_RETRIES} ☕️ Retrying in #{NGINX_RETRY_INTERVAL} seconds..."
          sleep(NGINX_RETRY_INTERVAL)
          next
        end
      end

      if success
        prompt.say "[KUBECTL]  🎉  Load balancer created, public IP: #{ip}"
      else
        propmt.error "[KUBECTL] Failed to create LoadBalancer in #{NGINX_RETRIES} attempts, check Digital Ocean dashboard"
      end
    end

    # Patch nginx-ingress service in Digital Ocean
    def patch_do_load_balancer
      prompt.say "[KUBECTL] Patching externalTrafficPolicy from Local to Cluster"
      @kubectl.patch_do_load_balancer
      prompt.say "[KUBECTL] 🎉  Success!"
    end

    def install_certmanager
      return if revoke?
      name = namespace = "cert-manager"

      if @helm.release_exists?(namespace, name)
        prompt.say "🙌 #{name} already installed in a namespace #{namespace}, skipping..."
        return
      end

      out = @helm.add_repo(
        "jetstack",
        "https://charts.jetstack.io"
      )
      prompt.say "[HELM] #{out}"
      prompt.say "[HELM] repositories succesfully updated" if @helm.update_repo

      prompt.say "[HELM] Installing cert-manager in #{namespace} namespace"
      @helm.install(
        name,
        "jetstack/cert-manager",
        namespace,
        "--version",
        "v0.16.1",
        "--set",
        "installCRDs=true"
      )
      prompt.say "[HELM]  🎉  cert-manager installed"
    end

    private

    def prompt
      @prompt ||= TTY::Prompt.new
    end

    def invoke?
      behavior == :invoke
    end

    def revoke?
      behavior == :revoke
    end
  end
end
