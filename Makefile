serve:
	hugo server -D \
		--buildDrafts \
		--buildFuture \
		--disableFastRender \
		--bind 0.0.0.0 \
		--port 8085

production-build:
	hugo --minify
	make check-internal-links

preview-build:
	hugo \
		--baseURL $(DEPLOY_PRIME_URL) \
		--buildDrafts \
		--buildFuture \
		--minify
	make check-internal-links

clean:
	rm -rf public

build:
	hugo

link-checker-setup:
	curl https://raw.githubusercontent.com/wjdp/htmltest/master/godownloader.sh | bash

run-link-checker:
	bin/htmltest

check-internal-links: link-checker-setup run-link-checker

check-all-links: clean build link-checker-setup
	bin/htmltest --conf .htmltest.external.yml
