---
doc: "15"
title: "Project Structure"
scope: "Canonical monorepo tree 5 services + packages + infra, naming conventions, module boundaries, Makefile"
key_entities: [backend_core/, ai_engine/, frontend_flutter/, teacher_dashboard_web/, admin_dashboard_web/, Makefile]
depends_on: ["08"]
loaded_by_tasks: ["semua task — validasi target_path sebelum setiap file write"]
---

# FILE: 15_PROJECT_STRUCTURE.md
# PROJECT ALETA: CANONICAL MONOREPO STRUCTURE & FILE INVENTORY

## 1. PENDAHULUAN & FILOSOFI

Dokumen ini adalah **single source of truth** struktur folder dan file untuk seluruh ekosistem ALETA. Sebelum dokumen ini, path referensi tersebar di Doc 02/04/06/07/10/13/14/15 dengan inkonsistensi (mis. `backend_core/ai_engine/...` vs `ai_engine/...`). Doc 15 mengonsolidasikan, dan bagian akhir (§13) berisi tabel perubahan path yang sudah disinkronkan ke dokumen lama.

### Prinsip Desain Monorepo

1. **Satu git repository tunggal** untuk seluruh codebase (backend, frontend, infra, docs). Memudahkan kontrak API/types/tokens disinkronkan dalam satu commit.
2. **Service = top-level folder.** Setiap service deployable berdiri sendiri (`backend_core/`, `ai_engine/`, `frontend_flutter/`, `teacher_dashboard_web/`, `admin_dashboard_web/`). Masing-masing punya `Dockerfile`, dependency lock-file, dan README mini sendiri.
3. **Python package layout: src-style nested.** `backend_core/backend_core/` dan `ai_engine/ai_engine/` — folder luar untuk metadata service (Dockerfile, requirements, alembic.ini, tests), folder dalam adalah Python package importable.
4. **Aset bersama lintas-service** tinggal di `infrastructure/` (design tokens, keycloak realm, nginx, icons, illustrations) dan `packages/` (paket TypeScript shared).
5. **Dokumentasi blueprint tetap di root** (Doc 00–16 + AGENTS.md + CLAUDE.md + README.md).

### Tools Workspace
* **Python:** `uv` untuk dependency resolution per service (cepat & reproducible). Fallback `pip-tools`.
* **TypeScript:** `pnpm workspaces` — root `pnpm-workspace.yaml` mengikat `packages/*`, `teacher_dashboard_web`, `admin_dashboard_web`.
* **Dart/Flutter:** standalone `frontend_flutter/` dengan `flutter_flavorizr` untuk dual flavor.
* **Top-level orchestrator:** `Makefile` dengan target ramah developer (`make dev`, `make test`, `make lint`).

---

## 2. POHON FOLDER KANONIK (KESELURUHAN)

```
aleta/
├── README.md                              # navigasi cepat & quick start
├── CLAUDE.md                              # panduan agent untuk Claude Code
├── AGENTS.md                              # repository guidelines umum
├── LICENSE
├── .gitignore
├── .editorconfig
├── .nvmrc                                 # pin Node version
├── .python-version                        # pin Python version
├── Makefile                               # entrypoint perintah lintas-service
├── pnpm-workspace.yaml                    # pnpm monorepo workspace
├── docker-compose.yml                     # 12 service production (Doc 08)
├── docker-compose.observability.yml       # Loki+Promtail+Grafana (Doc 13 §8)
├── docker-compose.override.example.yml    # template overrides developer lokal
├── .env.example                           # template secret (Doc 08 §4)
│
├── 00_EXECUTIVE_SUMMARY.md
├── 01_CURRICULUM_ONTOLOGY_GRAPH.md
├── 02_ADAPTIVE_ENGINE_SPEC.md
├── 03_DATABASE_SCHEMA_MULTI_TENANTS.md
├── 04_BACKEND_API_CONTRACTS.md
├── 05_FRONTEND_DYNAMIC_UI_FLUTTER.md
├── 06_TEACHER_DASHBOARD_ANALYTICS.md
├── 07_SECURITY_PRIVACY_PASSPORT.md
├── 08_DEVOPS_DEPLOYMENT_LOCAL_CLOUD.md
├── README.md                           # blueprint navigator (legacy)
├── 09_RAG_AND_TUTOR_SPEC.md
├── 10_PARENT_APP_SPEC.md
├── 11_ADMIN_YAYASAN_DASHBOARD.md
├── 12_CROSS_JENJANG_TRANSITION.md
├── 13_MIGRATIONS_AND_CICD.md
├── 14_UI_UX_DESIGN_SYSTEM.md
├── 15_PROJECT_STRUCTURE.md                # <-- file ini
│
├── .github/                               # atau .gitea/ jika self-hosted
│   ├── workflows/
│   │   ├── ci.yml
│   │   ├── release.yml
│   │   └── nightly.yml
│   ├── CODEOWNERS
│   └── pull_request_template.md
│
├── backend_core/                          # Service FastAPI utama → aleta_core_api
├── ai_engine/                             # Service AI (BKT + RAG) → aleta_ai_engine
├── frontend_flutter/                      # Aplikasi Flutter siswa & ortu
├── teacher_dashboard_web/                 # SPA React guru
├── admin_dashboard_web/                   # SPA React admin yayasan
├── packages/                              # Paket TS shared antar SPA
├── infrastructure/                        # Aset infra non-code
├── docs/                                  # Dokumentasi operasional (non-blueprint)
└── scripts/                               # Skrip top-level dev/ops
```

---

## 3. SERVICE: `backend_core/` (FastAPI — `aleta_core_api`)

Container Docker → service `aleta_core_api` di Doc 08 §3. Bertanggung jawab atas seluruh REST API publik di `04_BACKEND_API_CONTRACTS.md`.

```
backend_core/
├── README.md
├── Dockerfile
├── .dockerignore
├── pyproject.toml                         # build metadata, ruff/pytest config
├── requirements.txt                       # production deps
├── requirements-dev.txt                   # dev/test deps
├── alembic.ini                            # Alembic config (Doc 13 §2)
├── openapi.yaml                           # generated; gate CI (Doc 13 §4)
│
├── alembic/                               # Postgres migrations (Doc 13 §2)
│   ├── env.py
│   ├── script.py.mako
│   ├── versions/
│   │   ├── 20260101_0001_initial_core_schema.py
│   │   ├── 20260101_0002_passport_and_affective.py
│   │   ├── 20260101_0003_misconceptions_session_state.py
│   │   ├── 20260101_0004_consent_transition.py
│   │   ├── 20260101_0005_tutor_modul_ajar.py
│   │   ├── 20260101_0006_audit_events.py
│   │   ├── 20260101_0007_unit_schema_template.py
│   │   └── 20260101_0008_system_config.py
│   └── tenant_template/                   # SQL parametrik untuk skema unit baru
│       ├── 001_classes.sql
│       ├── 002_enrollment.sql
│       └── 003_quiz_logs.sql
│
├── neo4j_migrations/                      # Cypher migration (Doc 13 §3)
│   ├── V001__constraints.cypher
│   ├── V002__seed_institution.cypher
│   └── V003__misconception_indexes.cypher
│
├── backend_core/                          # === Python package importable ===
│   ├── __init__.py
│   ├── __main__.py                        # uvicorn entrypoint
│   ├── app.py                             # FastAPI factory + middleware mount
│   ├── config.py                          # pydantic-settings
│   ├── logging_setup.py
│   │
│   ├── api/                               # Route handlers (1 file per resource)
│   │   ├── __init__.py
│   │   ├── deps.py                        # Depends() injectors
│   │   ├── auth.py                        # /api/v1/auth/* (Doc 04 §3.A)
│   │   ├── student.py                     # /api/v1/student/* (Doc 04 §3.B,E)
│   │   ├── engine.py                      # /api/v1/engine/* (Doc 04 §3.C)
│   │   ├── tutor.py                       # /api/v1/tutor/* SSE (Doc 04 §3.F)
│   │   ├── teacher.py                     # /api/v1/teacher/* (Doc 04 §3.D,G,H)
│   │   ├── parent.py                      # /api/v1/parent/* (Doc 04 §3.I,J)
│   │   ├── consent.py                     # /api/v1/consent/* (Doc 04 §3.K)
│   │   ├── admin.py                       # /api/v1/admin/* (Doc 04 §3.L,M)
│   │   └── health.py                      # /api/v1/health
│   │
│   ├── schemas/                           # Pydantic request/response models
│   │   ├── __init__.py
│   │   ├── auth.py
│   │   ├── engine.py
│   │   ├── passport.py
│   │   ├── parent.py
│   │   ├── teacher.py
│   │   ├── consent.py
│   │   ├── transition.py
│   │   └── errors.py                      # standar error (Doc 04 §1)
│   │
│   ├── security/                          # Doc 07
│   │   ├── __init__.py
│   │   ├── guard.py                       # SecurityGuard (Doc 07 §3)
│   │   ├── jwks_cache.py                  # JWKS caching (Doc 07 §B)
│   │   ├── rls.py                         # SET LOCAL helpers (Doc 07 §D)
│   │   ├── idempotency.py                 # Redis idempotency (Doc 04 §1)
│   │   └── rate_limit.py                  # Redis token-bucket
│   │
│   ├── db/
│   │   ├── __init__.py
│   │   ├── session.py                     # SQLAlchemy session factory
│   │   ├── tenant_scope.py                # search_path manager (Doc 07 §D)
│   │   ├── models/                        # ORM models, 1 file per agg root
│   │   │   ├── __init__.py
│   │   │   ├── users.py
│   │   │   ├── tenants.py
│   │   │   ├── passport.py
│   │   │   ├── affective.py
│   │   │   ├── misconceptions.py
│   │   │   ├── consent.py
│   │   │   ├── transition.py
│   │   │   ├── tutor.py
│   │   │   ├── modul_ajar.py
│   │   │   ├── audit.py
│   │   │   ├── system_config.py
│   │   │   └── unit_smp.py                # tenant-scoped table models
│   │   └── triggers/
│   │       └── check_tp_mastery.sql       # Doc 03 §4.B
│   │
│   ├── neo4j/
│   │   ├── __init__.py
│   │   ├── client.py                      # neo4j async driver wrapper
│   │   ├── repositories.py                # query functions (Doc 01 §6)
│   │   └── queries/                       # Cypher dalam file terpisah
│   │       ├── prerequisite.cypher
│   │       ├── misconception_lookup.cypher
│   │       └── atp_for_class.cypher
│   │
│   ├── repositories/                      # Repository pattern (DB-agnostic API)
│   │   ├── __init__.py
│   │   ├── passport.py
│   │   ├── tenants.py
│   │   ├── users.py
│   │   ├── consent.py
│   │   ├── transition.py
│   │   ├── audit.py
│   │   ├── tutor.py
│   │   └── system_config.py
│   │
│   ├── services/                          # Business logic, di atas repositories
│   │   ├── __init__.py
│   │   ├── auth_service.py
│   │   ├── passport_service.py
│   │   ├── next_content_service.py        # Doc 04 §3.E
│   │   ├── morning_briefing.py            # Doc 04 §3.G
│   │   ├── red_flag_detector.py           # Doc 06 §2 (canonical backend)
│   │   ├── modul_ajar.py                  # Doc 04 §3.H
│   │   ├── parent_report.py
│   │   ├── consent_service.py
│   │   └── tenant_provisioner.py          # apply_tenant_template (Doc 13 §2)
│   │
│   ├── clients/                           # External service adapters
│   │   ├── __init__.py
│   │   ├── keycloak_client.py
│   │   ├── ollama_client.py
│   │   ├── qdrant_client.py
│   │   ├── ai_engine_client.py            # internal HTTP ke aleta_ai_engine
│   │   └── redis_client.py
│   │
│   ├── jobs/                              # Celery/RQ background tasks
│   │   ├── __init__.py
│   │   ├── worker.py                      # entrypoint worker
│   │   ├── transition_orchestrator.py     # Doc 12 §5
│   │   ├── bkt_calibration.py             # Doc 02 §6
│   │   ├── difficulty_rerating.py         # Doc 02 §6.C
│   │   ├── retention.py                   # Doc 07 §E
│   │   ├── red_flag_recompute.py          # Doc 06
│   │   ├── focus_score_recompute.py       # Doc 09 §5.D
│   │   └── interest_decay.py              # Doc 09 §5.C
│   │
│   ├── middleware/
│   │   ├── __init__.py
│   │   ├── request_id.py
│   │   ├── audit_logger.py
│   │   └── error_handler.py               # standar error (Doc 04 §1)
│   │
│   └── scripts/                           # Module-level CLI scripts
│       ├── __init__.py
│       ├── export_openapi.py              # Doc 13 §4
│       ├── run_neo4j_migrations.py        # Doc 13 §3
│       ├── seed_dev_data.py
│       └── neo4j_bootstrap.cypher         # constraints + seed (Doc 13 §3)
│
└── tests/
    ├── conftest.py
    ├── unit/
    │   ├── api/
    │   ├── services/
    │   ├── repositories/
    │   └── security/
    ├── integration/
    │   ├── test_engine_evaluate_flow.py
    │   ├── test_remediation_state_machine.py
    │   ├── test_tenant_isolation.py
    │   ├── test_transition_e2e.py
    │   └── test_consent_flow.py
    ├── security/
    │   ├── test_idor.py
    │   ├── test_role_bypass.py
    │   ├── test_tenant_leakage.py
    │   └── test_jwt_validation.py
    ├── smoke/
    │   └── test_health_endpoints.py
    └── fixtures/
        ├── seed.sql
        ├── users.json
        └── neo4j_seed.cypher
```

---

## 4. SERVICE: `ai_engine/` (BKT + RAG Orchestrator — `aleta_ai_engine`)

Container Docker → service `aleta_ai_engine` di Doc 08 §3 (port internal, **tidak diekspos** ke gateway). Hanya `backend_core` yang boleh memanggilnya via `clients/ai_engine_client.py`.

```
ai_engine/
├── README.md
├── Dockerfile
├── .dockerignore
├── pyproject.toml
├── requirements.txt
├── requirements-dev.txt
│
├── ai_engine/                             # === Python package importable ===
│   ├── __init__.py
│   ├── __main__.py
│   ├── app.py                             # FastAPI internal-only
│   ├── config.py
│   │
│   ├── adaptive_engine.py                 # ALETA_BKT_Engine + MatchmakerEngine (Doc 02 §4)
│   ├── bkt_params_provider.py             # baca tp_bkt_params dari Postgres
│   ├── graph_client.py                    # Neo4j adapter untuk engine
│   ├── session_repository.py              # student_session_state I/O (Doc 03 §3.G)
│   │
│   ├── api/                               # Endpoint internal (tidak public)
│   │   ├── __init__.py
│   │   ├── evaluate.py                    # POST /internal/evaluate (dipanggil core_api)
│   │   ├── scaffold.py                    # POST /internal/scaffold/generate (Doc 09)
│   │   ├── rewrite.py                     # POST /internal/rewrite/content
│   │   └── tutor.py                       # POST /internal/tutor/chat (SSE upstream)
│   │
│   ├── rag/                               # Doc 09
│   │   ├── __init__.py
│   │   ├── ingest.py                      # Doc 09 §3.D
│   │   ├── chunker.py                     # paragraph-aware (Doc 09 §3.C)
│   │   ├── embedder.py                    # Ollama nomic-embed-text
│   │   ├── retriever.py                   # Qdrant query
│   │   ├── rewriter.py                    # rewrite_for_student (Doc 09 §5)
│   │   └── validator.py                   # ensure_tp_alignment (Doc 09 §5.B)
│   │
│   ├── tutor/                             # Doc 09 §4
│   │   ├── __init__.py
│   │   ├── conversation.py
│   │   ├── system_prompt.py               # build_system_prompt (Doc 09 §4.C)
│   │   └── streaming.py                   # SSE proxy
│   │
│   ├── safety/                            # Doc 09 §4.D
│   │   ├── __init__.py
│   │   ├── input_sanitizer.py             # lapis 1
│   │   ├── role_enforcer.py               # lapis 2
│   │   ├── output_filter.py               # lapis 3
│   │   └── handoff.py                     # TUTOR_HANDOFF_REQUIRED (Doc 09 §4.E)
│   │
│   ├── clients/
│   │   ├── __init__.py
│   │   ├── ollama_client.py
│   │   ├── qdrant_client.py
│   │   └── redis_cache.py
│   │
│   └── prompts/                           # Template prompt (versioned)
│       ├── tutor_system_v1.txt
│       ├── scaffold_v1.txt
│       └── rewrite_v1.txt
│
└── tests/
    ├── conftest.py
    ├── unit/
    │   ├── test_bkt_math.py
    │   ├── test_remediation_state_machine.py
    │   ├── test_chunker.py
    │   └── test_validator.py
    ├── integration/
    │   ├── test_rag_pipeline.py
    │   └── test_tutor_streaming.py
    ├── security/
    │   ├── prompt_injection_corpus.md     # Doc 09 §8
    │   └── test_prompt_injection.py
    └── fixtures/
        └── sample_curriculum.txt
```

---

## 5. SERVICE: `frontend_flutter/` (Aplikasi Mobile Siswa & Ortu)

Single codebase Flutter, dua build flavor (Doc 05 §5.E):
* `flutter run --flavor student -t lib/main_student.dart`
* `flutter run --flavor parent  -t lib/main_parent.dart`

```
frontend_flutter/
├── README.md
├── pubspec.yaml
├── pubspec.lock
├── analysis_options.yaml                  # lints + dart_code_metrics
├── flutter_native_splash.yaml
├── flutterfire.json                       # FCM config (opsional)
├── .flutter_flavorizr.yaml                # flavor generator
├── l10n.yaml                              # config localization
│
├── android/                               # ditangani Flutter
├── ios/                                   # ditangani Flutter
├── web/                                   # opsional
├── macos/, windows/, linux/               # disable di pubspec
│
├── lib/
│   ├── main_student.dart                  # entrypoint siswa
│   ├── main_parent.dart                   # entrypoint ortu (Doc 10)
│   │
│   ├── core/
│   │   ├── routing/
│   │   │   ├── app_router.dart            # go_router config (Doc 05 §5.A)
│   │   │   └── route_guards.dart
│   │   ├── network/
│   │   │   ├── aleta_api_client.dart      # Doc 05 §5.B
│   │   │   ├── interceptors/
│   │   │   │   ├── auth_interceptor.dart
│   │   │   │   ├── refresh_interceptor.dart
│   │   │   │   └── logging_interceptor.dart
│   │   │   └── generated/                 # OpenAPI Dart client (Doc 13 §4.B)
│   │   ├── theme/
│   │   │   ├── fase_theme_config.dart     # Doc 05 §3.A
│   │   │   ├── tokens.g.dart              # generated dari design_tokens (Doc 14)
│   │   │   └── motion.dart
│   │   ├── auth/
│   │   │   ├── token_store.dart           # secure_storage wrapper
│   │   │   └── auth_bloc.dart
│   │   ├── cache/
│   │   │   └── hive_setup.dart
│   │   ├── analytics/
│   │   │   └── focus_score_tracker.dart   # Doc 09 §5.D
│   │   └── error/
│   │       └── error_to_microcopy.dart    # Doc 14 §11
│   │
│   ├── data/
│   │   ├── models/                        # generated + hand-written DTO
│   │   └── repositories/
│   │       ├── passport_repository.dart
│   │       ├── engine_repository.dart
│   │       └── tutor_repository.dart
│   │
│   ├── domain/
│   │   ├── entities/
│   │   └── usecases/
│   │       ├── fetch_next_content.dart
│   │       ├── submit_evaluation.dart
│   │       └── send_tutor_message.dart
│   │
│   ├── presentation/
│   │   ├── splash/
│   │   ├── auth/
│   │   ├── home/                          # mode-aware shells
│   │   │   ├── kids_home_shell.dart
│   │   │   ├── junior_home_shell.dart
│   │   │   └── pro_home_shell.dart
│   │   ├── quiz_player/                   # Doc 05 §5.C
│   │   │   ├── quiz_player_screen.dart
│   │   │   ├── outcome_banner.dart
│   │   │   └── remediation_breadcrumb.dart
│   │   ├── tutor/
│   │   │   └── tutor_chat_screen.dart
│   │   ├── parent/                        # hanya untuk main_parent.dart
│   │   │   ├── parent_home_shell.dart
│   │   │   ├── headline_insight_card.dart
│   │   │   ├── home_activities_screen.dart
│   │   │   └── consent_inbox_screen.dart
│   │   └── shared/
│   │       ├── widgets/                   # implementasi komponen Doc 14 §4
│   │       │   ├── atoms/
│   │       │   ├── molecules/
│   │       │   └── organisms/
│   │       └── states/                    # empty/error/loading (Doc 14 §11)
│   │
│   └── l10n/                              # Doc 05 §5.F + Doc 14 §6.C
│       ├── intl_id.arb
│       ├── intl_en.arb
│       └── intl_id_AC.arb                 # Aceh roadmap
│
├── assets/
│   ├── images/
│   │   ├── bg_forest_kids.png
│   │   ├── bg_space_adventure.png
│   │   └── logo/
│   ├── rive/
│   │   ├── nara.riv                       # mirror dari infrastructure/illustrations
│   │   ├── bima.riv
│   │   ├── sari.riv
│   │   └── pak_wira.riv
│   ├── lottie/
│   │   ├── celebration.json
│   │   └── loading_kid.json
│   └── fonts/
│       ├── Fredoka/                       # KIDS_GAMIFIED
│       ├── Nunito/                        # JUNIOR_ADVENTURE
│       └── Inter/                         # PRO_DASHBOARD
│
├── test/
│   ├── core/
│   ├── data/
│   ├── presentation/
│   └── widget_book/                       # Widgetbook stories (Doc 14 §14.C)
│
└── integration_test/
    ├── golden_paths/
    │   ├── tk_morning_routine_test.dart
    │   └── smp_remediation_flow_test.dart
    └── a11y/
        └── accessibility_test.dart        # Doc 14 §9
```

---

## 6. SERVICE: `teacher_dashboard_web/` (SPA React — Guru)

```
teacher_dashboard_web/
├── README.md
├── Dockerfile
├── .dockerignore
├── package.json
├── pnpm-lock.yaml                         # via root workspace
├── vite.config.ts
├── tailwind.config.ts                     # konsumsi tokens dari packages/tokens
├── postcss.config.cjs
├── tsconfig.json
├── tsconfig.node.json
├── index.html
├── .eslintrc.cjs
│
├── public/
│   ├── favicon.svg
│   └── robots.txt
│
├── src/
│   ├── main.tsx
│   ├── App.tsx
│   ├── routes.tsx                         # React Router 6 config
│   │
│   ├── api/                               # TanStack Query hooks per endpoint
│   │   ├── client.ts                      # axios + interceptors
│   │   ├── auth.ts
│   │   ├── dashboard.ts                   # GET /teacher/dashboard/summary
│   │   ├── briefing.ts                    # GET /teacher/morning-briefing
│   │   ├── modul_ajar.ts                  # POST /teacher/modul-ajar/generate
│   │   └── consent.ts
│   │
│   ├── auth/
│   │   ├── token_store.ts
│   │   ├── refresh_interceptor.ts
│   │   └── route_guard.tsx
│   │
│   ├── components/                        # presentational, no business logic
│   │   ├── atoms/
│   │   ├── molecules/
│   │   └── organisms/
│   │       ├── DifferentiationGroupCard.tsx   # Doc 06 §4
│   │       ├── RedFlagPanel.tsx
│   │       ├── ModulAjarComposer.tsx
│   │       └── ConsentRequestModal.tsx
│   │
│   ├── pages/
│   │   ├── Login.tsx
│   │   ├── ClassOverview.tsx
│   │   ├── MorningBriefing.tsx            # Doc 04 §3.G
│   │   ├── ModulAjar.tsx
│   │   ├── Students.tsx
│   │   └── Settings.tsx
│   │
│   ├── state/                             # Zustand stores
│   │   ├── selected_class.ts
│   │   └── ui_preferences.ts
│   │
│   ├── utils/
│   │   ├── formatters.ts
│   │   └── microcopy.ts                   # konsumsi @aleta/microcopy
│   │
│   └── styles/
│       └── globals.css                    # tailwind base + tokens.css import
│
└── tests/
    ├── setup.ts
    ├── unit/
    ├── integration/
    └── a11y/
        └── axe.spec.ts                    # Doc 14 §9
```

---

## 7. SERVICE: `admin_dashboard_web/` (SPA React — Admin Yayasan)

Struktur **identik** dengan `teacher_dashboard_web/` (sama stack), tapi modul/pages-nya khusus admin (Doc 11 §2):

```
admin_dashboard_web/
├── (file konfigurasi sama dengan teacher_dashboard_web)
│
└── src/
    ├── (struktur sama)
    └── pages/
        ├── Overview.tsx
        ├── Units.tsx
        ├── Users.tsx
        ├── Curriculum.tsx                 # Doc 11 §4.B
        ├── AtpBuilder.tsx                 # Doc 11 §4.C, react-flow
        ├── Transitions.tsx                # Doc 12
        ├── Consent.tsx
        ├── AuditLog.tsx                   # Doc 11 §6
        ├── SystemConfig.tsx               # Doc 11 §5
        └── Ops.tsx                        # Doc 11 §7
```

---

## 8. PAKET BERSAMA: `packages/`

pnpm workspace untuk paket TypeScript yang dipakai oleh kedua dashboard React (dan opsional di Node tooling).

```
packages/
├── tokens/                                # Doc 14 §14 — generated dari design_tokens
│   ├── package.json                       # name: "@aleta/tokens"
│   └── dist/
│       ├── index.ts                       # JS object dari Style Dictionary
│       └── tokens.css                     # CSS custom properties
│
├── microcopy/                             # Doc 14 §6.C
│   ├── package.json                       # name: "@aleta/microcopy"
│   ├── src/
│   │   ├── index.ts
│   │   └── types.ts
│   ├── id.json
│   └── en.json
│
└── api-client/                            # Doc 13 §4.B
    ├── package.json                       # name: "@aleta/api-client"
    └── dist/                              # TS client dari openapi-typescript
        └── index.ts
```

---

## 9. INFRASTRUKTUR: `infrastructure/`

Aset non-code yang dipakai oleh banyak service.

```
infrastructure/
├── design_tokens/                         # Doc 14 §3 + §14
│   ├── package.json                       # script "build" pakai style-dictionary
│   ├── style-dictionary.config.cjs
│   ├── aleta.tokens.json                  # SoT canonical
│   ├── figma_links.json                   # gitignored
│   └── platforms/
│       ├── dart.template.dart
│       ├── css.template.css
│       └── ts.template.ts
│
├── icons/
│   └── aleta/                             # custom SVG (Doc 14 §7)
│       ├── atp.svg
│       ├── paspor.svg
│       ├── fase.svg
│       └── remediation.svg
│
├── illustrations/                         # Doc 14 §10.D
│   ├── nara.riv
│   ├── bima.riv
│   ├── sari.riv
│   ├── pak_wira.riv
│   └── characters.fig                     # file Figma source (opsional)
│
├── keycloak/                              # Doc 07 + Doc 13 §6
│   └── aleta-realm.json                   # auto-import saat container start
│
├── nginx/                                 # Doc 08 §4
│   ├── nginx.conf
│   ├── snippets/
│   │   ├── sse.conf
│   │   └── security_headers.conf
│   └── certs/                             # gitignored — disuplai per environment
│
└── observability/                         # Doc 13 §8
    ├── loki/
    │   └── loki-config.yaml
    ├── promtail/
    │   └── promtail-config.yaml
    └── grafana/
        ├── grafana.ini
        └── provisioning/
            ├── datasources/
            └── dashboards/
                ├── auth_events.json
                ├── engine_evaluate_latency.json
                ├── ollama_response_time.json
                └── audit_events_stream.json
```

---

## 10. DOKUMENTASI OPERASIONAL: `docs/`

Berbeda dengan blueprint di root (yang stabil), folder `docs/` berisi runbook + ADR yang aktif diperbarui tim ops.

```
docs/
├── incidents/                             # Doc 07 §E playbook
│   ├── runbook.md
│   ├── 2026-01-15-keycloak-jwks-cache-bug.md  # contoh post-mortem
│   └── template.md
├── ops/
│   ├── restore-tests.md                   # Doc 13 §7.C
│   ├── deploy-checklist.md
│   └── on-call-rotation.md
├── adr/                                   # Architecture Decision Records
│   ├── 0001-monorepo-vs-multi-repo.md
│   ├── 0002-bkt-not-deepRL-for-tahun-1.md
│   ├── 0003-keycloak-vs-self-built-auth.md
│   └── template.md
└── handbook/
    ├── onboarding.md
    ├── coding_conventions.md
    └── i18n_microcopy_review.md
```

---

## 11. SKRIP TOP-LEVEL: `scripts/`

Skrip orchestration lintas-service yang tidak cocok di `Makefile`.

```
scripts/
├── seed_dev.sh                            # populate semua DB untuk dev fresh
├── reset_local.sh                         # docker compose down -v + rebuild
├── deploy_prod.sh                         # wrapper docker compose pull + up
├── ollama_pull_models.sh                  # Doc 09 §7
├── qdrant_init_collections.sh             # Doc 09 §7
├── backup_now.sh                          # trigger manual backup
└── rotate_secrets.sh                      # rotation worker bantu (Doc 07 §A)
```

---

## 12. KONVENSI NAMING & MODULE BOUNDARIES

### A. Konvensi Naming Per Bahasa

| Bahasa/Stack | Files | Identifiers | Folders |
| :--- | :--- | :--- | :--- |
| Python (backend_core, ai_engine) | `snake_case.py` | `snake_case` functions, `PascalCase` classes, `UPPER_SNAKE` constants | `snake_case/` |
| Dart (Flutter) | `snake_case.dart` | `camelCase` vars/functions, `PascalCase` classes | `snake_case/` |
| TypeScript (React) | komponen `PascalCase.tsx`, non-komponen `camelCase.ts` | `camelCase` vars, `PascalCase` types/components | `camelCase/` (kecuali komponen folder `PascalCase/`) |
| SQL | `snake_case.sql` | tabel/kolom `snake_case`, schema `snake_case`, ENUM `UPPER_SNAKE` | n/a |
| Cypher (Neo4j) | `snake_case.cypher` | labels `PascalCase`, relationship `UPPER_SNAKE`, properties `snake_case` | n/a |

### B. Aturan Import (Module Boundaries)

```
api  → services → repositories → db/neo4j
                ↘ clients → (external)

api can never reach into db/* directly.
services NEVER import from api/*.
repositories NEVER import from services/*.
schemas/* are free to be imported by api + services.
```

Untuk Flutter:
```
presentation → domain → data → core
```
Tidak boleh ada import balik (`core` tidak boleh import `presentation`).

Untuk React:
```
pages → components/organisms → components/molecules → components/atoms
       ↘ api (TanStack Query hooks)
       ↘ state (Zustand)
```

### C. Aturan Cross-Service Communication

* `backend_core` ↔ `ai_engine`: HTTP internal saja melalui `clients/ai_engine_client.py`. **Tidak ada shared Python module.**
* `frontend_flutter` ↔ backend: HTTP via OpenAPI client di `core/network/generated/`.
* `*_dashboard_web` ↔ backend: HTTP via `@aleta/api-client`.
* Semua service membaca token desain dari `packages/tokens` atau `tokens.g.dart` (generated dari `infrastructure/design_tokens/`) — **tidak boleh hard-code warna**.

---

## 13. OWNERSHIP MAP (Folder ↔ Blueprint)

Tabel ini memberi tahu blueprint mana yang **memiliki** spec untuk tiap folder. Saat ada konflik, blueprint owner adalah arbiter.

| Folder | Owner Blueprint | Sekunder |
| :--- | :--- | :--- |
| `backend_core/alembic/` | Doc 03, Doc 13 §2 | — |
| `backend_core/neo4j_migrations/` | Doc 01, Doc 13 §3 | — |
| `backend_core/backend_core/api/` | Doc 04 | Doc 07 (security) |
| `backend_core/backend_core/security/` | Doc 07 | — |
| `backend_core/backend_core/db/` | Doc 03 | — |
| `backend_core/backend_core/neo4j/` | Doc 01 | — |
| `backend_core/backend_core/services/red_flag_detector.py` | Doc 06 §2 | — |
| `backend_core/backend_core/services/morning_briefing.py` | Doc 04 §3.G | Doc 06 |
| `backend_core/backend_core/services/modul_ajar.py` | Doc 04 §3.H | Doc 06 §6 |
| `backend_core/backend_core/services/parent_report.py` | Doc 04 §3.I, J | Doc 10 |
| `backend_core/backend_core/services/consent_service.py` | Doc 04 §3.K | Doc 07 §E, Doc 10 |
| `backend_core/backend_core/jobs/transition_orchestrator.py` | Doc 12 §5 | — |
| `backend_core/backend_core/jobs/bkt_calibration.py` | Doc 02 §6 | — |
| `backend_core/backend_core/jobs/retention.py` | Doc 07 §E | — |
| `ai_engine/ai_engine/adaptive_engine.py` | Doc 02 §4 | — |
| `ai_engine/ai_engine/rag/` | Doc 09 §3, §5 | — |
| `ai_engine/ai_engine/tutor/` | Doc 09 §4 | — |
| `ai_engine/ai_engine/safety/` | Doc 09 §4.D, E | — |
| `frontend_flutter/lib/core/theme/` | Doc 05 §3, Doc 14 §3 | — |
| `frontend_flutter/lib/presentation/quiz_player/` | Doc 05 §5.C | Doc 02 §4 (state machine) |
| `frontend_flutter/lib/presentation/parent/` | Doc 10 | Doc 05 §5.E |
| `frontend_flutter/lib/l10n/` | Doc 05 §5.F, Doc 14 §6.C | — |
| `teacher_dashboard_web/src/` | Doc 06 §5 | — |
| `admin_dashboard_web/src/` | Doc 11 | — |
| `packages/tokens/` | Doc 14 §14 | — |
| `packages/microcopy/` | Doc 14 §6.C | — |
| `packages/api-client/` | Doc 13 §4.B | Doc 04 |
| `infrastructure/design_tokens/` | Doc 14 §3, §14 | — |
| `infrastructure/icons/` | Doc 14 §7 | — |
| `infrastructure/illustrations/` | Doc 14 §10.D | — |
| `infrastructure/keycloak/` | Doc 07 §B, Doc 13 §6 | — |
| `infrastructure/nginx/` | Doc 08 §4 | — |
| `infrastructure/observability/` | Doc 13 §8 | — |
| `docker-compose.yml` | Doc 08 §3 | — |
| `docs/incidents/` | Doc 07 §E | — |
| `docs/adr/` | tata kelola tim arsitek | — |

---

## 14. INKONSISTENSI PATH YANG SUDAH DI-RESOLVE

Tabel di bawah mencatat path lama (sebelum Doc 15) → kanonik baru. Doc 02/04/06/07/10/13/14 sudah diperbarui agar konsisten.

| Dokumen | Path lama | Path kanonik (Doc 15) |
| :--- | :--- | :--- |
| Doc 02 §4 | `backend_core/ai_engine/adaptive_engine.py` | `ai_engine/ai_engine/adaptive_engine.py` |
| Doc 04 §4 | `app/routers/engine.py` | `backend_core/backend_core/api/engine.py` |
| Doc 06 §2 | `backend_core/services/red_flag_detector.py` | `backend_core/backend_core/services/red_flag_detector.py` |
| Doc 07 §3 | `app/middleware/security_guard.py` | `backend_core/backend_core/security/guard.py` |
| Doc 07 §B | `backend_core/security/jwks_cache.py` | `backend_core/backend_core/security/jwks_cache.py` |
| Doc 07 §E | `backend_core/jobs/retention.py` | `backend_core/backend_core/jobs/retention.py` |
| Doc 09 §3 | `ai_engine/rag/ingest.py` | `ai_engine/ai_engine/rag/ingest.py` |
| Doc 12 §5 | `backend_core/jobs/transition_orchestrator.py` | `backend_core/backend_core/jobs/transition_orchestrator.py` |
| Doc 13 §3 | `backend_core/scripts/neo4j_bootstrap.cypher` | `backend_core/backend_core/scripts/neo4j_bootstrap.cypher` |
| Doc 13 §3 | `backend_core/scripts/run_neo4j_migrations.py` | `backend_core/backend_core/scripts/run_neo4j_migrations.py` |

Path yang tetap di service root (tidak nested ke package): `backend_core/alembic/`, `backend_core/alembic.ini`, `backend_core/openapi.yaml`, `backend_core/requirements*.txt`, `backend_core/Dockerfile`, `backend_core/tests/`, `backend_core/neo4j_migrations/`.

---

## 15. .GITIGNORE POLICY (RINGKAS)

```gitignore
# Secrets & local config
.env
.env.local
infrastructure/nginx/certs/*
!infrastructure/nginx/certs/.gitkeep
infrastructure/design_tokens/figma_links.json

# Python
__pycache__/
*.pyc
.venv/
.pytest_cache/
.ruff_cache/
.coverage*

# Node
node_modules/
dist/
.next/
.vite/

# Flutter
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
build/
ios/Pods/
*.iml

# Docker volumes (jika developer mount lokal)
data/

# OS
.DS_Store
Thumbs.db

# IDE
.idea/
.vscode/
!.vscode/extensions.json
```

---

## 16. MAKEFILE TOP-LEVEL (ENTRYPOINT DEVELOPER)

```makefile
.PHONY: help dev down logs test lint format openapi tokens

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
	python scripts/init_state.py --catalog 16_AI_AGENT_IMPLEMENTATION_PLAYBOOK.md --output STATE.yaml

apply_patches:         ## Terapkan agent state_patches ke STATE.yaml (Doc 17)
	python scripts/apply_state_patches.py

state_summary:         ## Cetak ringkasan progress (tasks done / pending / blocked)
	python scripts/state_summary.py

derive_sentinels:      ## Re-derive sentinels dari blueprint terbaru (Doc 17 T-05)
	python scripts/derive_sentinels.py --update-state
```

### Skrip Pendukung Agent Workflow (Doc 17)

```
scripts/
├── init_state.py                  # bootstrap STATE.yaml dari Doc 16 §8
├── apply_state_patches.py         # apply agent output YAML ke STATE.yaml
├── state_summary.py               # progress dashboard CLI
├── derive_sentinels.py            # extract sacred values dari blueprint
└── state_schema.json              # JSON Schema untuk validasi STATE.yaml
```

---

## 17. RELEASE GATE STRUKTUR

Sebelum tag rilis besar (`vX.0.0`):
* [ ] Setiap folder di Doc 15 §3–11 punya owner blueprint yang valid (Doc 15 §13).
* [ ] Tidak ada path yang disebut di blueprint tapi tidak ada di repo (auto-check: `scripts/check_blueprint_paths.sh`).
* [ ] Tidak ada folder di repo yang tidak disebut di Doc 15 (cegah drift).
* [ ] Pohon folder `aleta/` ≤ 4 level kedalaman (selain `lib/`, `test/`, `alembic/versions/`).
* [ ] `Makefile` target `dev`, `test`, `lint` semuanya hijau pada clone fresh.
