require "seatrain/version"
require "seatrain/railtie" if defined?(Rails::Railtie)

module Seatrain
  class NamespaceAlreadyExistsError < StandardError; end

  SEATRAIN_DOCKERDEV_URI = "https://raw.githubusercontent.com/lewagon/rails-base/master/seatrain-templates/Dockerfile.dev"
  SEATRAIN_APTFILE_URI = "https://raw.githubusercontent.com/lewagon/rails-base/master/seatrain-templates/Aptfile"
  SEATRAIN_DOCKERCOMPOSE_URI = "https://raw.githubusercontent.com/lewagon/rails-base/master/seatrain-templates/docker-compose.yml"
  SEATRAIN_DIPYML_URI = "https://raw.githubusercontent.com/lewagon/rails-base/master/seatrain-templates/dip.yml"
  DUMMY_IMAGE_NAME = "seatrain:dev" # TODO: Set as config or ENV?
  SEATRAIN_DOCKERPROD_URI = "https://raw.githubusercontent.com/lewagon/rails-base/master/seatrain-templates/Dockerfile.prod"
end
