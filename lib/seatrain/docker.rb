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

    def build(image, tag)
      ok = shell_stream(
        {"DOCKER_BUILDKIT" => "1"},
        "docker",
        "build",
        "-f",
        Rails.root.join(".seatrain", "Dockerfile.prod").to_s,
        Rails.root.to_s,
        "-t",
        "#{image}:#{tag}",
        "--build-arg",
        "RUBY_VERSION=#{Seatrain::Config.new.ruby_version}",
        "--build-arg",
        "PG_MAJOR=#{Seatrain::Config.new.pg_version}",
        "--build-arg",
        "NODE_MAJOR=#{Seatrain::Config.new.node_version}",
        "--build-arg",
        "YARN_VERSION=#{Seatrain::Config.new.yarn_version}",
        "--build-arg",
        "BUNDLER_VERSION=#{Seatrain::Config.new.bundler_version}",
        {chdir: Rails.root.to_s}
      )
      unless ok
        puts "Docker build failed"
        exit 1
      end
    end

    def push(image, tag)
      ok = shell_stream(
        {"DOCKER_BUILDKIT" => "1"},
        "docker",
        "push",
        "#{image}:#{tag}"
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
