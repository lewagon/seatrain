package-index:
	helm package helm/seatrain-base --destination ./docs
	helm repo index docs --url  https://lewagon.github.io/seatrain/