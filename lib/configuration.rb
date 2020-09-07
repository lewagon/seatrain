module Seatrain
  class Configuration
    attr_accessor :ruby_version, :pg_version, :node_version, :bundler_version
  end

  class << self
    attr_writer :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield configuration
  end
end
