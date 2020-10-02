require_relative "../prompters"

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

    desc "Upgrade or install release. `rails seatrain:release:upgrade tag=mytag` to customize image tag"
    task upgrade: :environment do
      secrets = Seatrain::SecretsPrompter.new.secrets_to_helm_flags
      puts "\nInstalling helm release, this may take some time..."
      out = Seatrain::Helm.new.ugrade_install(ENV["tag"] || "latest", secrets)
      puts out
    end

    desc "Create the image pull secret in a cluster"
    task create_pull_secret: :environment do
      prompter = Seatrain::ConfigPrompter.new
      server = prompter.prompt("docker_registry")
      login = prompter.prompt("docker_username")
      password = prompter.prompt("docker_password", secure: true)
      Seatrain::Kubectl.new.create_pull_secret(server, login, password)
    end

    desc "Create image pull secret in a cluster for Digital Ocean Container Registry"
    task create_pull_secret_docr: :environment do
      # DO-specfic way as per documentation
      unless system("doctl registry kubernetes-manifest | kubectl apply -f -")
        puts "Attempt to create pull-secret with Digital Ocean Container Registry failed"
        puts "Try running `doctl registry kubernetes-manifest | kubectl apply -f -` manually"
        exit 1
      end
    end

    desc "Remove running application pods"
    task remove_pods: :environment do
      Seatrain::Kubectl.new.delete_resource(
        :pods,
        "app.kubernetes.io/name=#{Seatrain.config.app_name}"
      )
    end

    desc "Deploy new release (build and push fresh image, check/create pull secret)"
    task deploy: :environment do
      Rake::Task["seatrain:release:build"].invoke
      Rake::Task["seatrain:release:push"].invoke

      if Seatrain.config.uses_docr?
        Rake::Task["seatrain:release:create_pull_secret_docr"].invoke
      else
        secret_name = "#{Seatrain.config.app_name}-pull-secret"
        unless Seatrain::Kubectl.new.resource_exists?(:secret, secret_name)
          Rake::Task["seatrain:release:create_pull_secret"].invoke
        end
      end

      Rake::Task["seatrain:release:upgrade"].invoke
      Rake::Task["seatrain:release:remove_pods"].invoke
    end
  end
end
