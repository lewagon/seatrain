require_relative "system_helpers"

module Seatrain
  class Helm
    include SystemHelpers

    def initialize
      ok, _ = shell("which", "helm")
      unless ok
        puts executable_not_found
        exit 1
      end
    end

    def install(release_name, chart_name, namespace, *extra)
      ok, out = shell(
        "helm",
        "install",
        release_name,
        chart_name,
        "--namespace",
        namespace,
        *extra
      )
      unless ok
        puts "`helm install` failed, reason: "
        puts out
        exit 1
      end
      out
    end

    def add_repo(name, url)
      ok, out = shell(
        "helm",
        "repo",
        "add",
        name,
        url
      )
      unless ok
        puts "`helm repo add` failed, reason: "
        puts out
        exit 1
      end
      out
    end

    def update_repo
      ok, out = shell(
        "helm",
        "repo",
        "update"
      )
      unless ok
        puts "`helm repo update` failed, reason: "
        puts out
        exit 1
      end
      ok
    end

    def release_exists?(namespace, release)
      ok, out = shell(
        "helm",
        "list",
        "--namespace=#{namespace}",
        "--short"
      )
      unless ok
        # TODO: rephrase!
        puts "`helm list` command failed, investigate"
        exit 1
      end

      out.match?(/#{release}/)
    end

    private

    def executable_not_found
      "Helm executable not found in $PATH, refer to setup instructions and re-run this generator after installing Helm 3"
    end
  end
end
