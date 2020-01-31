serve:
	hugo server \
		--buildDrafts \
		--buildFuture \
		--disableFastRender \
		--bind 0.0.0.0 \
		--port 8080

production-build:
	hugo --minify

preview-build:
	hugo \
		--baseURL $(DEPLOY_PRIME_URL) \
		--buildDrafts \
		--buildFuture \
		--minify
