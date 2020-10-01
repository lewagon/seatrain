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

    # Use to deploy the main application
    def ugrade_install(tag, extra_arguments)
      cmd = base_upgrade_command.concat(
        [
          "--set-string",
          "global.image.tag=#{tag}"
        ]
      ).concat(extra_arguments)
      ok, out = shell(*cmd)
      unless ok
        puts "`helm upgrade --install` failed, reason: "
        puts out
        exit 1
      end
      out
    end

    # Generates string to inject into GitHub actions deploy YML
    def safe_upgrade_command_string(indent: 10)
      str = ""
      base_upgrade_command.each do |seg|
        str << "#{" " * indent}#{seg}\n"
      end
      Seatrain.config.required_secrets.each do |name|
        str << "#{" " * indent}--set-string global.commonSecrets.#{name.upcase}=${{ secrets.#{name.upcase} }}\n"
      end
      str
    end

    # Use to prepare cluster with pre-requisite charts
    def install(release_name, chart_name, namespace, *extra)
      ok, out = shell(
        "helm",
        "install",
        release_name,
        chart_name,
        "--create-namespace",
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

    def update_deps
      ok, out = shell(
        "helm",
        "dep",
        "update",
        ".seatrain/helm"
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

    def version
      ok, out = shell(
        "helm",
        "version",
        "--short"
      )
      unless ok
        puts "`helm version` failed, reason: "
        puts out
        exit 1
      end
      out
    end

    private

    def base_upgrade_command
      [
        "helm",
        "upgrade",
        Seatrain.config.app_name,
        ".seatrain/helm",
        "--install",
        "--create-namespace",
        "--namespace",
        Seatrain.config.release_namespace,
        "--atomic",
        "--cleanup-on-fail",
        "--timeout=#{Seatrain.config.helm_timeout}"
      ]
    end

    def executable_not_found
      "Helm executable not found in $PATH, refer to setup instructions and re-run this generator after installing Helm 3"
    end
  end
end
