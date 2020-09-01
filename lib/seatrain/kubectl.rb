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

    def create_namespace(name)
      ok, out = shell(
        "kubectl",
        "create",
        "namespace",
        name
      )
      unless ok
        raise NamespaceAlreadyExistsError if out.match?(/AlreadyExists/)
        puts "Could not create namespace in the cluster, reason:"
        puts out
        exit 1
      end
      out.match?(/created/)
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

    private

    def executable_not_found
      "Kubectl executable not found in $PATH, refer to setup instructions and re-run this generator after installing Kubectl"
    end
  end
end
