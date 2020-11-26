# Seatrain

> Rails + Docker + Digital Ocean Kubernetes + Helm + GitHub Actions = :heart:

**Developer-friendly DevOps/GitOps boilerplate generator for Rails applications that puts local and production configuration into the repository to make deploying and collaborating on live application as straightforward as possible. Supports Rails 5+, Sidekiq, Webpacker, PosgtreSQL, and Redis.**

Seatrain is a collection of _Rails generators_ and tasks that allow you to:

- Set up containerized development environment with Docker Compose and [Dip](https://github.com/bibendi/dip) that also supports system testing with containerized Chrome and VNC. The environment largely borrows from the popular [Ruby on Whales](https://evilmartians.com/chronicles/ruby-on-whales-docker-for-ruby-rails-development) setup by @palkan from Evil Martians.
- Set up [ingress-nginx](https://kubernetes.github.io/ingress-nginx/) and [cert-manager](https://cert-manager.io) in your cluster for automatic load balancing and SSL.
- Choose between Digital Ocean Container Registry, Quay.io, Docker Hub, or GitHub Container Registry for storing your images. Other providers can be easily supported by manually editing generated files.
- Generate a Helm chart for deploying Rails charts into the cluster with a single command.
- Generate a GitHub Action for continuous deployment into the cluster on `git push` or PR merge that takes advantage of Docker layer caching for faster deploys.

Created at [Le Wagon](https://www.lewagon.com), the best-rated coding bootcamp, to power internal and public-facing learning platforms. Partly powered by [Evil Martians OSS](https://evilmartians.com/#oss).

## Table of Contents

- Installation
- Seatrain config
- Local development environment with Docker Compose and Dip
- Handling secret values

## Installation

Add this to your `Gemfile`:

```
group :development do
  gem 'seatrain', git: "https://github.com/lewagon/seatrain"
end
```

Note that you only need `seatrain` under development group, it does not belong in `test` group or main section of your Gemfile.

## Seatrain config.

Run `rails g seatrain:install`.

![Interactive CLI wizard](media/install.gif)

It creates a file `config/seatrain.yml` that contains settings that further generators and tasks will rely upon. Feel free to modify it by hand, if necessary:

- Add more APT packages that your application runtime might need by adding their names to `with_apt_packages` key.
- Seatrain flow assumes that most of the credentials that you'd like to keep secret will be handled by `rails credentials` mechanism. However, it is not wise to keep **really critical credentials**

```yml
# Set versions for Ruby, Postgres, Node, Yarn and Bundler
# They will be used inside development and production containers.
ruby_version: 2.6.6
pg_major_version: 10
node_major_version: 12
yarn_version: 1.22.5
bundler_version: 2.1.4

# Additional apt packages to add into Docker containers (both development and production)
with_apt_packages:
  - vim
  - redis-tools

# Change to false if you are not using Sidekiq or Webpacker with your app.
use_sidekiq: true
use_webpacker: true

# Set the server for your container registry.
# To build and push from local machine you need to make sure you are logged into registry locally (`docker login`)
# When deploying with `rails seatrain:release:deploy` you will be prompted for any missing data
# that is required to create a pull secret inside the cluster.
docker_registry: registry.digitalocean.com
docker_repository: lewagon

# A full name of the production image to be used inside the cluster (e.g., quay.io/account_name/image_name).
# Will be used to push the production image during the deploy.
# Generated Helm configuration will expect this image too.
production_image_name: registry.digitalocean.com/lewagon/geocoding_489

# A name of the Digital Ocean cluster to be used for deployment.
do_cluster_name: demo

# A domain name which will point to your application in production.
# Make sure the DNS A-record points to Digital Ocean's Load Balancer.
# The Load Balancer will be created for you automatically after running `rails g seatrain cluster:prepare`.
# Don't include http(s)://
hostname: geo.lewagon.co
# An email for Let's Encrypt certificate reminders.
certificate_email: andrey@lewagon.org

# Names of Kubernetes secret values that your Rails and Sidekiq pods will rely on.
# You will be interactively prompted for each value when running `rails seatrain:release:deploy`.
# You will need to set the same names as secrets in your GitHub repository settings to use Github Actions deployment.
# Names should be in UPPER CASE.
required_secrets:
  - DATABASE_URL
```

#### :warning: Known issues

- The possible `.ruby-version` in the root and/or `ruby 'x.x.x'` statement in `Gemfile` (Heroku specific) need to match the Ruby version chosen in the CLI wizard.

## Local development environment with Docker Compose and Dip

Run `rails g seatrain:docker`. Here's the output with a list of created files:

```
🚃 SEATRAIN DOCKER SETUP 🌊
create  .seatrain/Aptfile ##
create  docker-compose.yml
create  dip.yml
create  .seatrain/Dockerfile.dev
create  .seatrain/Dockerfile.prod
create  .seatrain/.pryrc
create  .seatrain/vnc.sh
insert  config/database.yml
👌 `url: <%= ENV.fetch("DATABASE_URL", " ") %>` injected into config/database.yml

All set, you can run your app in containers locally now! 📦
Run `dip provision` to start
```

#### :warning: Known issues

- Sprockets need to be downgraded to 3.7.4 to avoid `sassc` segfault in a Debian container. (https://github.com/lewagon/seatrain/issues/2)

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
