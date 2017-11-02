INSTALL_PATH?=/usr/local/bin
INSTALL_SCRIPTS?=$$(find src -name '*.sh')
PWD?=$$(pwd)
SCRIPTS?=$$(find . -name '*.sh')
TESTS?=$$(find . -name '*.bats')

default: test

bats_build:
	docker build -t bats .

install:
	@echo "--- :bat: Installing Cassandra to $(INSTALL_PATH)"
	@mkdir -p $(INSTALL_PATH)
	@for i in $(INSTALL_SCRIPTS); do \
		DEST=$(INSTALL_PATH)/$$(echo $$i | sed -e "s/^src\///" -e "s/\.sh$$//"); \
		cp -v $$i $$DEST; \
		chmod +x $$DEST; \
	done

lint:
	docker run --rm -v $(PWD):/mnt koalaman/shellcheck:v0.4.6 $(SCRIPTS)

test: bats_build
	@echo "--- :bash::bat: testing"
	@for i in $(TESTS); do \
		echo "--- Testing $$i"; \
		docker run --rm \
			bats $$i; \
	done
