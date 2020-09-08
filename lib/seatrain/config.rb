require "anyway_config"

module Seatrain
  class Config < Anyway::Config
    attr_config(
      :ruby_version,
      :pg_version,
      :node_version,
      :yarn_version,
      :bundler_version,
      :image_name,
      use_sidekiq: true,
      use_webpacker: true
    )

    def image_name
      Rails.application.class.module_parent_name.titleize.parameterize
    end
  end
end
