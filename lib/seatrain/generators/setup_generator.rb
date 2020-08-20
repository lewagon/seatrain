require "open-uri"

module Seatrain
  class SetupGenerator < Rails::Generators::Base
    DEFAULT_DOCKERDEV_URI = "https://raw.githubusercontent.com/lewagon/rails-base/master/seatrain-templates/Dockerfile.dev"

    class_option :dev_dockerfile_uri,
      type: :string,
      desc: "URI for the development Dockerfile",
      # Move to config
      default: DEFAULT_DOCKERDEV_URI

    def welcome
      say "Welcome to seatrain!", :green
    end

    def download_dev_dockerfile
      dockerfile = URI.open(options[:dev_dockerfile_uri]).read
      create_file ".seatrain/Dockerfile.dev" do
        dockerfile
      end
    end
  end
end
