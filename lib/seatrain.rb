require "seatrain/version"
require "seatrain/railtie" if defined?(Rails::Railtie)
require "seatrain/docker"
require "seatrain/config"
require "seatrain/helm"
require "seatrain/kubectl"

module Seatrain
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
