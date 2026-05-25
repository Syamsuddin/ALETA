.PHONY: help dev down logs test lint format openapi tokens init_state apply_patches state_summary derive_sentinels

help:                  ## Tampilkan target tersedia
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'

dev:                   ## Nyalakan full stack untuk dev
	docker compose up -d
	@echo "Stack ready. API → https://api.aleta.localhost"

down:                  ## Matikan seluruh stack tanpa hapus volume
	docker compose down

logs:                  ## Tail log core_api
	docker compose logs -f aleta_core_api

test:                  ## Jalankan tes lintas-service
	cd backend_core && pytest
	cd ai_engine && pytest
	cd frontend_flutter && flutter test
	pnpm --filter "./teacher_dashboard_web" test
	pnpm --filter "./admin_dashboard_web" test

lint:                  ## Jalankan linter lintas-service
	cd backend_core && ruff check .
	cd ai_engine && ruff check .
	cd frontend_flutter && flutter analyze
	pnpm --filter "./teacher_dashboard_web" lint
	pnpm --filter "./admin_dashboard_web" lint

format:                ## Auto-format
	cd backend_core && ruff format .
	cd ai_engine && ruff format .
	cd frontend_flutter && dart format lib test
	pnpm --filter "./*" exec prettier --write src

openapi:               ## Re-export OpenAPI spec
	docker exec aleta_core_api python -m backend_core.scripts.export_openapi > backend_core/openapi.yaml

tokens:                ## Re-build design tokens
	pnpm --filter "./infrastructure/design_tokens" run build

init_state:            ## Inisialisasi STATE.yaml dari Doc 16 catalog (Doc 17)
	python3 scripts/init_state.py --catalog 16_AI_AGENT_IMPLEMENTATION_PLAYBOOK.md --output STATE.yaml

apply_patches:         ## Terapkan agent state_patches ke STATE.yaml (Doc 17)
	python3 scripts/apply_state_patches.py

state_summary:         ## Cetak ringkasan progress (tasks done / pending / blocked)
	python3 scripts/state_summary.py

derive_sentinels:      ## Re-derive sentinels dari blueprint terbaru (Doc 17 T-05)
	python3 scripts/derive_sentinels.py --update-state
