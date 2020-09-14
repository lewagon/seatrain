require_relative "../docker.rb"

namespace :seatrain do
  desc "Build production image with a latest tag"
  task build_production_latest: :environment do
    Seatrain::Docker.new.build(Seatrain.config.production_image_name, "latest")
  end

  desc "Push production image with a latest tag"
  task push_production_latest: :environment do
    Seatrain::Docker.new.push(Seatrain.config.production_image_name, "latest")
  end
end
