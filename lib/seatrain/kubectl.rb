require_relative "system_helpers"

module Seatrain
  class Kubectl
    include SystemHelpers

    def initialize
      ok, _ = shell("which", "kubectl")
      unless ok
        puts executable_not_found
        exit 1
      end
    end

    # Digital Ocean specific
    # Apparently not required anymore.
    def patch_do_load_balancer
      ok, out = shell(
        "kubectl",
        "patch",
        "services",
        "nginx-ingress-ingress-nginx-controller",
        "--namespace",
        "ingress-nginx",
        "-p",
        '{"spec":{"externalTrafficPolicy":"Cluster"}}'
      )
      unless ok
        puts "Could not patch load balancer, reason:"
        puts out
        exit 1
      end
    end

    def get_load_balancer_ip
      _, out = shell(
        "kubectl",
        "get",
        "service",
        "--namespace=ingress-nginx",
        "nginx-ingress-ingress-nginx-controller",
        "--template='{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}'"
      )
      out.tr("'", "") # otherwise IP addr is single-quoted
    end

    def resource_exists?(type, name)
      ok, out = shell(
        "kubectl",
        "get",
        type.to_s,
        name
      )
      unless ok
        return false if out.match?(/NotFound/)
        puts "Could not get #{type} in the cluster, reason:"
        puts out
        exit 1
      end
      out.match?(/#{name}/)
    end

    def delete_resource(type, selector)
      ok, out = shell(
        "kubectl",
        "delete",
        type.to_s,
        "--selector",
        selector
      )
      unless ok
        puts "Could not delete pods, reason:"
        puts out
        exit 1
      end
    end

    def create_namespace(name)
      ok, out = shell(
        "kubectl",
        "create",
        "namespace",
        name
      )
      unless ok
        puts "Could not create namespace in the cluster, reason:"
        puts out
        exit 1
      end
    end

    def current_context
      ok, out = shell(
        "kubectl",
        "config",
        "current-context"
      )
      unless ok
        puts "could not fetch current Kubernetes context, aborting"
        exit 1
      end
      out
    end

    def create_pull_secret(server, login, password)
      ok, out = shell(
        "kubectl",
        "create",
        "secret",
        "docker-registry",
        "#{Seatrain.config.app_name}-pull-secret",
        "--docker-server=#{Seatrain.config.docker_registry}",
        "--docker-username=#{Seatrain.config.docker_username}",
        "--docker-password=#{Seatrain.config.docker_password}"
      )
      unless ok
        puts "Could not create pull secret in a cluster, reason:"
        puts out
        exit 1
      end
    end

    private

    def executable_not_found
      "Kubectl executable not found in $PATH, refer to setup instructions and re-run this generator after installing Kubectl"
    end
  end
end
