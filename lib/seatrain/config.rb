require "anyway_config"

module Seatrain
  # PRE-RELEASE: To be removed once the anyway_config 2.1 becomes available
  Anyway.loaders.override :yml, Anyway::Loaders::YAML

  class Config < Anyway::Config
    DOCR_URL = "registry.digitalocean.com"

    attr_config(
      :ruby_version,
      :pg_major_version,
      :node_major_version,
      :yarn_version,
      :bundler_version,
      :app_name,
      :production_image_name,
      :docker_registry,
      :docker_username,
      :docker_password,
      :docker_repository,
      :do_cluster_name,
      :hostname,
      :certificate_email,
      use_sidekiq: true,
      use_webpacker: true,
      release_namespace: "default",
      helm_timeout: "3m0s",
      required_secrets: [],
      secrets: {},
      with_apt_packages: []
    )

    def uses_docr?
      docker_registry == DOCR_URL
    end

    def app_name
      super || Rails.application.class.module_parent_name.titleize.parameterize
    end
  end
end
