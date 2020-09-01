module Seatrain
  class Railtie < Rails::Railtie
    generators do
      require File.join(File.dirname(__FILE__), "generators/dev_setup_generator.rb")
      require File.join(File.dirname(__FILE__), "generators/prod_setup_generator.rb")
    end
  end
end
