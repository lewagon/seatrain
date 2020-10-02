require "tty-prompt"
require "seatrain/version"
require "seatrain/railtie" if defined?(Rails::Railtie)
require "seatrain/docker"
require "seatrain/config"
require "seatrain/helm"
require "seatrain/kubectl"

module Seatrain
  DEFAULT_RUBY_VERSION = "2.6.6"
  DEFAULT_PG_MAJOR_VERSION = "11"
  DEFAULT_NODE_MAJOR_VERSION = "12"
  DEFAULT_YARN_VERSION = "1.22.5"
  DEFAULT_BUNDLER_VERSION = "2.1.4"

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
