SHELL := /bin/bash

.PHONY: gate-0 gate-1 gate-2 gate-3 gate-4 gate-5 gate-6 gate-lint gate-all sync up down test

gate-0:
	@scripts/gate-0.sh

gate-1:
	@if [ -x scripts/gate-1.sh ]; then scripts/gate-1.sh; else echo "gate-1 no implementado todavía (F1)"; exit 1; fi

gate-2:
	@if [ -x scripts/gate-2.sh ]; then scripts/gate-2.sh; else echo "gate-2 no implementado todavía (F2)"; exit 1; fi

gate-3:
	@if [ -x scripts/gate-3.sh ]; then scripts/gate-3.sh; else echo "gate-3 no implementado todavía (F3)"; exit 1; fi

gate-4:
	@if [ -x scripts/gate-4.sh ]; then scripts/gate-4.sh; else echo "gate-4 no implementado todavía (F4)"; exit 1; fi

gate-5:
	@if [ -x scripts/gate-5.sh ]; then scripts/gate-5.sh; else echo "gate-5 no implementado todavía (F5)"; exit 1; fi

gate-6:
	@scripts/gate-6.sh

gate-lint:
	@if [ -x scripts/gate-lint.sh ]; then scripts/gate-lint.sh; else echo "gate-lint no implementado todavía (F1)"; exit 1; fi

gate-all:
	@for n in 0 1 2 3 4 5 6; do \
		echo "==> gate-$$n"; \
		$(MAKE) --no-print-directory gate-$$n || exit 1; \
	done

sync:
	@scripts/sync-progreso.sh

up:
	@docker compose up --build -d

down:
	@docker compose down --remove-orphans

test:
	@(cd KatEye-Front && npm run test:run)
	@mvn test -f KatEye-Back/katEye/pom.xml
