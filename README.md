# Seatrain

> Rails + Docker + Digital Ocean Kubernetes + GitHub Actions = :heart:

**Developer-friendly DevOps/GitOps boilerplate generator for Rails applications that puts local and production configuration into the repository to make deploying and collaborating on live application as straightforward as possible. Supports Rails 5+, Sidekiq, Webpacker, PosgtreSQL, and Redis.**

Seatrain is a collection of _Rails generators_ and tasks that allow you to:

- Set up containerized development environment with Docker Compose and [Dip](https://github.com/bibendi/dip) that also supports system testing with containerized Chrome and VNC.
- Set up [ingress-nginx](https://kubernetes.github.io/ingress-nginx/) and [cert-manager](https://cert-manager.io) in your cluster for automatic load balancing and SSL.
- Choose between Digital Ocean Container Registry, Quay.io, Docker Hub, or GitHub Container Registry for storing your images. Other providers can be easily supported by manually editing generated files.
- Generate a Helm chart for deploying Rails charts into the cluster with a single command.
- Generate a GitHub Action for continuous deployment into the cluster on `git push` or PR merge that takes advantage of Docker layer caching for faster deploys.

Created at [Le Wagon](https://www.lewagon.com), the best-rated coding bootcamp, to power internal and public-facing learning platforms.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
