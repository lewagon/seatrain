require "anyway_config"

module Seatrain
  class Config < Anyway::Config
    attr_config(
      :ruby_version,
      :pg_version,
      :node_version,
      :yarn_version,
      :bundler_version,
      :app_name,
      :development_image_name,
      :production_image_name,
      :docker_server,
      :docker_login,
      :docker_password,
      use_sidekiq: true,
      use_webpacker: true,
      release_namespace: "default",
      helm_timeout: "3m0s",
      required_secrets: [],
      secrets: {}
    )

    def app_name
      super || Rails.application.class.module_parent_name.titleize.parameterize
    end
  end
end
