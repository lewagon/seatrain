require_relative "system_helpers"

module Seatrain
  class Docker
    include SystemHelpers

    def initialize
      ok, _ = shell("which", "docker")
      unless ok
        puts executable_not_found
        exit 1
      end
    end

    # TODO: Take versions from config
    def build(image, tag)
      # TODO: read build-args dynamically from Dockerfile?
      ok = shell_stream(
        {"DOCKER_BUILDKIT" => "1"},
        "docker",
        "build",
        "-f",
        Rails.root.join(".seatrain", "Dockerfile.prod").to_s,
        "--build-arg",
        "PG_MAJOR=12",
        "--build-arg",
        "NODE_MAJOR=12",
        "--build-arg",
        "YARN_VERSION=1.22.4",
        "--build-arg",
        "BUNDLER_VERSION=2.1.4",
        Rails.root.to_s,
        "--build-arg",
        "RUBY_VERSION=2.6.6",
        "-t",
        "#{image}:#{tag}",
        {chdir: Rails.root.to_s}
      )
      unless ok
        puts "Docker build failed"
        exit 1
      end
    end

    private

    def executable_not_found
      "Docker executable not found in $PATH, refer to setup instructions and re-run this generator after installing Docker"
    end
  end
end
