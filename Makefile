# Vitals — the targets CI runs, so local and CI cannot disagree.

FLUTTER ?= $(HOME)/development/flutter/bin/flutter
DART    ?= $(HOME)/development/flutter/bin/dart
DOTNET  ?= $(HOME)/.dotnet/dotnet
APP     := app
DOMAIN  := packages/vitals_domain
SERVER  := server

.DEFAULT_GOAL := help

.PHONY: help
help: ## Show this help
	@grep -hE '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) \
	  | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

# --- the gate ---------------------------------------------------------------

.PHONY: ci
ci: doc-check design-check counts-check copy-check domain-purity brandmark-check analyze test parity coverage-gate ## Everything CI runs

.PHONY: gates
gates: doc-check design-check counts-check copy-check domain-purity brandmark-check coverage-gate ## The blocking gates alone

.PHONY: doc-check
doc-check: ## Fail if a required document is missing, untracked, or stale
	@bash scripts/doc-check.sh

.PHONY: design-check
design-check: ## Fail if DESIGN.md and palette.dart disagree, or a screen names a colour of its own
	@python3 scripts/design-check.py

.PHONY: counts-check
counts-check: ## Fail if README quotes a figure the repository does not have
	@python3 scripts/counts-check.py

.PHONY: copy-check
copy-check: ## Fail on any string that interprets or overclaims
	@python3 scripts/copy-check.py

.PHONY: domain-purity
domain-purity: ## Fail if the domain package imports anything, or reads a clock
	@python3 scripts/domain-purity.py

.PHONY: brandmark
brandmark: ## Draw the mark at every size
	@python3 scripts/brandmark.py

.PHONY: brandmark-check
brandmark-check: ## Fail if the committed mark is not what the script draws
	@python3 scripts/brandmark.py --check

# --- build and test ---------------------------------------------------------

.PHONY: analyze
analyze: ## Static analysis: the domain, the app, the server (warnings are errors)
	cd $(DOMAIN) && $(DART) analyze --fatal-infos
	cd $(APP) && $(FLUTTER) analyze --fatal-infos
	cd $(SERVER) && $(DOTNET) build --nologo -v q

.PHONY: test
test: test-domain test-app test-server ## Run every test suite

.PHONY: test-domain
test-domain: ## The domain's five invariants over generated worlds, in seconds
	cd $(DOMAIN) && $(DART) test

.PHONY: test-app
test-app: ## The app's widget tests: flow, contrast, lock, one primary action, 200% text
	cd $(APP) && $(FLUTTER) test

.PHONY: test-server
test-server: ## The server's tests: parity with the Dart, and the API
	cd $(SERVER) && $(DOTNET) test --nologo -v q

.PHONY: parity
parity: ## Fail if the Dart and the C# merge disagree on one byte of the fixture
	@cd $(SERVER) && $(DOTNET) test tests/Vitals.Domain.Tests --nologo -v q --filter "FullyQualifiedName~Parity" > /dev/null && printf '\033[0;32m✓\033[0m the C# merge reaches the Dart bytes on every world of the parity fixture\n'

.PHONY: parity-fixture
parity-fixture: ## Rewrite docs/parity from the Dart (refuses to overwrite; delete it first, deliberately)
	cd $(DOMAIN) && VITALS_WRITE_PARITY=$(CURDIR)/docs/parity $(DART) test test/parity_test.dart

.PHONY: coverage
coverage: ## Line coverage of the domain
	cd $(DOMAIN) && $(DART) test --coverage=coverage >/dev/null && $(DART) run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --report-on=lib >/dev/null 2>&1 || true

.PHONY: coverage-gate
coverage-gate: ## Fail if the domain's line coverage is under 95%
	@python3 scripts/coverage-gate.py

.PHONY: run
run: ## Run the app on the connected device or simulator
	cd $(APP) && $(FLUTTER) run

.PHONY: server-run
server-run: ## Run the server on 127.0.0.1:5120 with the in-memory store
	cd $(SERVER) && $(DOTNET) run --project src/Vitals.Api --urls http://127.0.0.1:5120

.PHONY: adr
adr: ## Start a new ADR:  make adr T="the title"
	@bash scripts/new-adr.sh "$(T)"

.PHONY: phase
phase: ## Print the current phase and its exit gate
	@p=$$(cat PHASE); echo "Phase $$p"; awk "/^## Phase $$p /,/^## Phase $$((p+1)) /" docs/ROADMAP.md | grep -A3 'Exit gate' | head -4
