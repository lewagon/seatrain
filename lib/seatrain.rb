require "seatrain/version"
require "seatrain/railtie" if defined?(Rails::Railtie)
require "seatrain/docker"
require "seatrain/config"

module Seatrain
  SEATRAIN_DOCKERDEV_URI = "https://raw.githubusercontent.com/lewagon/rails-base/master/seatrain-templates/Dockerfile.dev"
  SEATRAIN_DOCKERPROD_URI = "https://raw.githubusercontent.com/lewagon/rails-base/master/seatrain-templates/Dockerfile.prod"
  SEATRAIN_APTFILE_URI = "https://raw.githubusercontent.com/lewagon/rails-base/master/seatrain-templates/Aptfile"
  SEATRAIN_DOCKERCOMPOSE_URI = "https://raw.githubusercontent.com/lewagon/rails-base/master/seatrain-templates/docker-compose.yml"
  SEATRAIN_DIPYML_URI = "https://raw.githubusercontent.com/lewagon/rails-base/master/seatrain-templates/dip.yml"
  DUMMY_IMAGE_NAME = "seatrain:dev" # TODO: Set as config or ENV?

  class << self
    def config
      @config ||= begin
        require "seatrain/config"
        Config.new
      end
    end

    def configure
      yield(config) if block_given?
    end
  end
end
