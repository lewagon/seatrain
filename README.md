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

## Installation

Add this to your `Gemfile`:

```
group :development do
  gem 'seatrain', git: "https://github.com/lewagon/seatrain"
end
```

Note that you only need `seatrain` under development group, it does not belong in `test` group or main section of your Gemfile.

## Step 0. Generate Seatrain config.

Run `rails g seatrain:install`.

![Interactive CLI wizard]()

#### :warning: Known issues

- The possible `.ruby-version` in the root and/or `ruby 'x.x.x'` statement in `Gemfile` (Heroku specific) need to match the Ruby version chosen in the CLI wizard.

VIDEO

## Step 1. Local development environment with Docker Compose and Dip

Run `rails g seatrain:docker`. Here's the output with a list of created files:

```sh
🚃 SEATRAIN DOCKER SETUP 🌊
create  .seatrain/Aptfile
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
