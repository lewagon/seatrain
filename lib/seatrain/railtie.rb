module Seatrain
  class Railtie < Rails::Railtie
    generators do
      require File.join(File.dirname(__FILE__), "generators/setup_generator.rb")
    end
  end
end
