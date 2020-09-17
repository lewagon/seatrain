module Seatrain
  class Railtie < Rails::Railtie
    rake_tasks do
      Dir[File.join(File.dirname(__FILE__), "tasks/*.rake")].each { |f| load f }
    end

    generators do
      require File.join(File.dirname(__FILE__), "generators/project_setup_generator.rb")
      require File.join(File.dirname(__FILE__), "generators/cluster_setup_generator.rb")
    end
  end
end
