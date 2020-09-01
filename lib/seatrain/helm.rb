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
