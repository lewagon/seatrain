require_relative "../prompters"
require_relative "../docker"
require_relative "../kubectl"
require_relative "../helm"

namespace :seatrain do
  namespace :release do
    desc "Build production image. `rails seatrain:release:build tag=mytag` to customize image tag"
    task build: :environment do
      Seatrain::Docker.new.build(Seatrain.config.production_image_name, ENV["tag"] || "latest")
    end

    desc "Push production image. `rails seatrain:release:push tag=mytag` to customize image tag"
    task push: :environment do
      Seatrain::Docker.new.push(Seatrain.config.production_image_name, ENV["tag"] || "latest")
    end

    desc "Upgrade or install release. `rails seatrain:release:deploy tag=mytag` to customize image tag"
    task deploy: :environment do
      # TODO: delete pods if the tag is latest or tag with timestamps?
      secrets = Seatrain::SecretsPrompter.new.prompt_all
      puts "\nInstalling helm release, this may take some time..."
      out = Seatrain::Helm.new.ugrade_install(ENV["tag"] || "latest", secrets)
      puts out
    end

    # TODO: Task that does everything, checking/creating pull secret in namespace first
  end

  namespace :cluster do
    desc "Create the image pull secret in a cluster"
    task create_pull_secret: :environment do
      prompter = Seatrain::ConfigPrompter.new
      server = prompter.prompt("docker_server")
      login = prompter.prompt("docker_login")
      password = prompter.prompt("docker_password", secure: true)
      Seatrain::Kubectl.new.create_pull_secret(server, login, password)
    end
  end
end
