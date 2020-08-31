require "open-uri"
require_relative "../yaml_transformer"

module Seatrain
  SEATRAIN_DOCKERDEV_URI = "https://raw.githubusercontent.com/lewagon/rails-base/master/seatrain-templates/Dockerfile.dev"
  SEATRAIN_APTFILE_URI = "https://raw.githubusercontent.com/lewagon/rails-base/master/seatrain-templates/Aptfile"
  SEATRAIN_DOCKERCOMPOSE_URI = "https://raw.githubusercontent.com/lewagon/rails-base/master/seatrain-templates/docker-compose.yml"
  SEATRAIN_DIPYML_URI = "https://raw.githubusercontent.com/lewagon/rails-base/master/seatrain-templates/dip.yml"
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

    class_option :dip_yml_uri,
      type: :string,
      desc: "URI for the development dip.yml",
      # Move to config
      default: ENV.fetch("SEATRAIN_DIPYML_URI", SEATRAIN_DIPYML_URI)

    def welcome
      say "\t🚃 SEATRAIN LOCAL DOCKER ENVIRONMENT #{invoke? ? "SETUP" : "CLEANUP"} 🌊", :green
    end

    def place_dockerfile_dev
      dockerfile = URI.open(options[:dockerfile_dev_uri]).read
      create_file ".seatrain/Dockerfile.dev", dockerfile
    end

    def place_aptfile
      path = ".seatrain/Aptfile"
      aptfile = URI.open(SEATRAIN_APTFILE_URI).read
      create_file path, aptfile
    end

    def place_docker_compose
      path = "docker-compose.yml"
      docker_compose = URI.open(options[:docker_compose_uri]).read
      create_file path, docker_compose

      if invoke?
        @dc_transformer = YamlTransformer.new(path)
        @dc_transformer.deep_replace_key("image", DUMMY_IMAGE_NAME, app_name + ":dev")
      end
    end

    def decide_on_sidekiq
      return if revoke?

      unless yes?("Are you using Sidekiq?")
        @dc_transformer.deep_delete_key("sidekiq")
        say_status :info, "👌 sidekiq service removed from docker-compose file", :red
      end
    end

    def decide_on_webpacker
      return if revoke?

      unless yes?("Are you using webpacker? (Do you need a webpack-dev-server service?)")
        @dc_transformer.deep_delete_key("webpacker")
        say_status :info, "👌 webpacker service removed from docker-compose file", :red
      end
    end

    def place_dip
      path = "dip.yml"
      dip_yml = URI.open(options[:dip_yml_uri]).read
      create_file path, dip_yml

      if invoke?
        @dip_transfomer = YamlTransformer.new(path)
        @dip_transfomer.deep_delete_key("sidekiq") unless @dc_transformer.dig("services", "sidekiq")
        @dip_transfomer.deep_delete_key("webpacker") unless @dc_transformer.dig("services", "webpacker")
      end
    end

    def patch_database_yml
      inject_into_file "config/database.yml", after: 'pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>' do
        <<~YAML
          \n  url: <%= ENV.fetch("DATABASE_URL", " ") %>
        YAML
      end
      say_status :info, '👌 url: <%= ENV.fetch("DATABASE_URL", " ") injected into config/database.yml' if invoke?
    end

    def summarize
      return if revoke?
      say "\nAll set, you can run your app in containers locally now! 📦"

      services = @dc_transformer["services"]&.keys&.join(", ")
      say <<~TXT
        🎉 docker-compose.yml created in your project root with the services:\n\t#{services}
        🎊 dip.yml created in your project root, run `dip provision` to finish installation
      TXT
    end

    private

    def revoke?
      behavior == :revoke
    end

    def invoke?
      behavior == :invoke
    end

    def app_name
      Rails.application.class.parent_name.parameterize.dasherize
    end
  end
end
