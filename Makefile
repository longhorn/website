serve:
	HUGO_ENVIRONMENT=development hugo server -D \
		--buildDrafts \
		--buildFuture \
		--disableFastRender \
		--bind 0.0.0.0 \
		--port 8085

production-build:
	HUGO_ENV=production hugo --minify
	make check-internal-links

preview-build:
	HUGO_ENV=production hugo \
		--baseURL "$(or $(DEPLOY_PRIME_URL),/)" \
		--buildDrafts \
		--buildFuture \
		--minify
	make check-internal-links

clean:
	rm -rf public

build:
	hugo

link-checker-setup:
	curl -fsSL -o godownloader.sh https://raw.githubusercontent.com/wjdp/htmltest/568fd1c91202eeeb6f9c89b06fa9a09226cbf129/godownloader.sh
	bash godownloader.sh

run-link-checker:
	bin/htmltest || true

check-internal-links: link-checker-setup run-link-checker

check-all-links: clean build link-checker-setup
	bin/htmltest --conf .htmltest.external.yml
	