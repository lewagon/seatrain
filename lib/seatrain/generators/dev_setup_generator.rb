require "open-uri"
require_relative "../yaml_transformer"

module Seatrain
  class DevSetupGenerator < Rails::Generators::Base
    namespace "seatrain:setup:dev"

    # TODO: move defaults to config?
    class_option :dockerfile_dev_uri,
      type: :string,
      desc: "URI for the development Dockerfile",
      default: ENV.fetch("SEATRAIN_DOCKERDEV_URI", SEATRAIN_DOCKERDEV_URI)

    class_option :dockerfile_prod_uri,
      type: :string,
      desc: "URI for the production Dockerfile",
      default: ENV.fetch("SEATRAIN_DOCKERPROD_URI", SEATRAIN_DOCKERPROD_URI)

    class_option :docker_compose_uri,
      type: :string,
      desc: "URI for the development docker-compose.yml",
      default: ENV.fetch("SEATRAIN_DOCKECOMPOSE_URI", SEATRAIN_DOCKERCOMPOSE_URI)

    class_option :dip_yml_uri,
      type: :string,
      desc: "URI for the development dip.yml",
      default: ENV.fetch("SEATRAIN_DIPYML_URI", SEATRAIN_DIPYML_URI)

    def welcome
      say "\t🚃 SEATRAIN LOCAL DOCKER ENVIRONMENT #{invoke? ? "SETUP" : "CLEANUP"} 🌊", :green
    end

    def place_dockerfile_dev
      dockerfile = URI.open(options[:dockerfile_dev_uri]).read
      create_file ".seatrain/Dockerfile.dev", dockerfile
    end

    def place_dockerfile_prod
      dockerfile = URI.open(options[:dockerfile_prod_uri]).read
      create_file ".seatrain/Dockerfile.prod", dockerfile
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
        @dc_transformer.deep_replace_key("image", DUMMY_IMAGE_NAME, Seatrain.config.image_name + ":dev")
        @dc_transformer.deep_replace_unique_key("RUBY_VERSION", Seatrain.config.ruby_version)
        @dc_transformer.deep_replace_unique_key("PG_MAJOR", Seatrain.config.pg_version)
        @dc_transformer.deep_replace_unique_key("NODE_MAJOR", Seatrain.config.node_version)
        @dc_transformer.deep_replace_unique_key("YARN_VERSION", Seatrain.config.yarn_version)
        @dc_transformer.deep_replace_unique_key("BUNDLER_VERSION", Seatrain.config.bundler_version)
      end
    end

    def decide_on_sidekiq
      return if revoke?

      unless Seatrain.config.use_sidekiq?
        @dc_transformer.deep_delete_key("sidekiq")
        say_status :info, "👌 sidekiq service removed from docker-compose file", :red
      end
    end

    def decide_on_webpacker
      return if revoke?

      unless Seatrain.config.use_webpacker?
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
  end
end
