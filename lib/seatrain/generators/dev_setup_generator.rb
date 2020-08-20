require "open-uri"
require_relative "../docker_compose_transformer"

module Seatrain
  SEATRAIN_DOCKERDEV_URI = "https://raw.githubusercontent.com/lewagon/rails-base/master/seatrain-templates/Dockerfile.dev"
  SEATRAIN_APTFILE_URI = "https://raw.githubusercontent.com/lewagon/rails-base/master/seatrain-templates/Aptfile"
  SEATRAIN_DOCKERCOMPOSE_URI = "https://raw.githubusercontent.com/lewagon/rails-base/master/seatrain-templates/docker-compose.yml"
  DUMMY_IMAGE_NAME = "seatrain:dev" # TODO: Set as config or ENV?

  class DevSetupGenerator < Rails::Generators::Base
    namespace "seatrain:setup:dev"

    class_option :dockerfile_dev_uri,
      type: :string,
      desc: "URI for the development Dockerfile",
      # Move to config
      default: ENV.fetch("SEATRAIN_DOCKERDEV_URI", SEATRAIN_DOCKERDEV_URI)

    class_option :docker_compose_uri,
      type: :string,
      desc: "URI for the development docker-compose.yml",
      # Move to config
      default: ENV.fetch("SEATRAIN_DOCKECOMPOSE_URI", SEATRAIN_DOCKERCOMPOSE_URI)

    def welcome
      say "🚃 Welcome to seatrain! 🌊", :green
    end

    def place_dockerfile_dev
      dockerfile = URI.open(options[:dockerfile_dev_uri]).read
      create_file ".seatrain/Dockerfile.dev", dockerfile
    end

    def place_aptfile
      path = ".seatrain/Aptfile"
      aptfile = URI.open(SEATRAIN_APTFILE_URI).read

      if (behavior == :revoke) && File.exist?(path)
        create_file path, aptfile
      end

      if (behavior == :invoke) && yes?("Create Aptfile to list non-standard dependencies?")
        create_file path, aptfile
      end
    end

    def place_docker_compose
      path = "docker-compose.yml"
      docker_compose = URI.open(options[:docker_compose_uri]).read
      create_file path, docker_compose
      if File.exist?(path)
        dc = DockerComposeTransformer.new(path)
        dc.replace_image_name(image_name_from_app_name, DUMMY_IMAGE_NAME + ":dev")
      end
    end

    private

    def image_name_from_app_name
      Rails.application.class.parent_name.parameterize.dasherize
    end
  end
end
