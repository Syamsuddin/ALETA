# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Status

This directory is **blueprint-only** — no application code, package manager, runtime, or CI is checked in yet. It is also **not a git repository**. The deliverables are eighteen numbered Markdown blueprint specifications (`00_EXECUTIVE_SUMMARY.md` through `17_MASTER_PROMPT_AND_STATE.md`), plus `README.md` (blueprint navigator), `AGENTS.md` (general repo guidelines), and two operational artifacts at repo root: `MASTER_PROMPT.md` (canonical agent prompt) and `STATE.yaml` (multi-agent state ledger).

The blueprints are written in Indonesian and are intentionally "Vibe Coding Ready" — code blocks are tagged with their target language (`sql`, `yaml`, `python`, `dart`, `tsx`, `cypher`) and are meant to be copy-paste seeds for an eventual implementation.

When real implementation starts, keep code **outside** the blueprint files and follow the planned module layout: `backend_core/`, `ai_engine/`, `frontend_flutter/`, `teacher_dashboard_web/`, `admin_dashboard_web/`, `nginx/`, `docker-compose.yml`.

## Critical Documents (Read First)

Before diving into numbered blueprints, read these two canonical references:

- **`GLOSSARY.md`** (frozen 2026-05-24) — Single source of truth untuk semua naming conventions, enums, error codes, adaptive_status values, consent_scope, design tokens, dan konstanta. Semua blueprint WAJIB follow GLOSSARY. Jika ada konflik: GLOSSARY menang.
- **`MVP_SCOPE.md`** — Scope pilot MVP Phase 1. Jangan implement full blueprint sekaligus — mulai dari irisan end-to-end kecil (1 SMP, 10–200 siswa, 1 mata pelajaran Matematika). Dokumen ini memisahkan MVP vs Post-MVP features dengan jelas dan definisi success metrics.

## Reading Order

The documents are tightly coupled — reading one without its neighbours produces broken mental models. The canonical sequence is:

- `00_EXECUTIVE_SUMMARY.md` — vision, problem space, 3-year rollout.
- `01_CURRICULUM_ONTOLOGY_GRAPH.md` — Neo4j schema for CP/TP/ATP and the `HAS_PREREQUISITE` graph.
- `02_ADAPTIVE_ENGINE_SPEC.md` — BKT math + `ALETA_BKT_Engine` / `MatchmakerEngine` Python reference, multi-step remediation state machine, per-TP calibration spec.
- `03_DATABASE_SCHEMA_MULTI_TENANTS.md` — PostgreSQL `aleta_core` + `unit_*` schemas.
- `04_BACKEND_API_CONTRACTS.md` — FastAPI REST contracts.
- `05_FRONTEND_DYNAMIC_UI_FLUTTER.md` — Flutter mobile (BLoC + Clean Architecture).
- `06_TEACHER_DASHBOARD_ANALYTICS.md` — React teacher web dashboard.
- `07_SECURITY_PRIVACY_PASSPORT.md` — UU PDP compliance, Keycloak OIDC, RLS, audit, OWASP/ASVS baseline, retention table, breach playbook.
- `08_DEVOPS_DEPLOYMENT_LOCAL_CLOUD.md` — docker-compose (12 services) + nginx multi-subdomain.
- `09_RAG_AND_TUTOR_SPEC.md` — Qdrant + Ollama RAG, hobby-aware content rewrite, 24/7 tutor chat with prompt-injection guards.
- `10_PARENT_APP_SPEC.md` — parent build flavor of Flutter, no-numeric-grade reports, consent inbox.
- `11_ADMIN_YAYASAN_DASHBOARD.md` — React admin dashboard, ATP Builder, `system_config` table for runtime calibration.
- `12_CROSS_JENJANG_TRANSITION.md` — state-machine orchestrator for TK→SD→SMP→SMA transition (idempotent, reversible 7 days, bulk).
- `13_MIGRATIONS_AND_CICD.md` — Alembic + Neo4j migrations, OpenAPI gate, Gitea Actions CI, Keycloak realm export, backup off-site.
- `14_UI_UX_DESIGN_SYSTEM.md` — design tokens JSON (canonical SoT), component+state matrix, user flows per persona, microcopy library, WCAG 2.2 AA checklist, motion/illustration budget, Figma file index.
- `15_PROJECT_STRUCTURE.md` — **canonical monorepo tree** (5 services + packages + infra + docs + scripts), naming conventions per language, module boundaries, ownership map folder ↔ blueprint, path inconsistency resolution table, Makefile. **Always consult this before placing any new file.**
- `16_AI_AGENT_IMPLEMENTATION_PLAYBOOK.md` — **execution playbook** for AI agents (single Claude session or multi-agent). 5 anti-drift rules, dependency graph, 8 phase milestones (Day 0–56), task card YAML format with 60+ tasks, role definitions (architect/backend-coder/ai-engine-coder/flutter-coder/web-coder/dba/devops/security-reviewer/qa/doc-keeper), model selection per task type, sample prompts per role, anti-drift checklists, handoff contracts, failure modes. **Consult this before starting any implementation task.**
- `17_MASTER_PROMPT_AND_STATE.md` — **master prompt spec & state file architecture**. Defines the canonical `MASTER_PROMPT.md` (10 layers: Identity / Constitution / Decision / Execution / Output Schema / Token-Frugal / Role Overlays / Halt / Session End) and `STATE.yaml` schema (blueprints / sentinels / tasks ledger / files ledger / pending_handoffs / open_issues / metrics). Introduces 10 novel ALETA-OPS techniques (TRD, Phase Lock, Sentinel Honor, JIT loading, Self-Quote, Adversarial Skeptic, Atomic Patches, Shorthand, Budget-Aware Compaction, Output Minimization).

## Architecture Big Picture

ALETA is a **native AI-powered Adaptive LMS** for a single Indonesian Yayasan spanning TK → SD → SMP → SMA/SMK. It is *not* an AI add-on to Moodle/Classroom — content, classes, quizzes, dashboards, identity, and deployment are all native.

Two data stores work in tandem:

- **PostgreSQL** holds the relational reality: tenants, users, the per-student `student_cognitive_passports` (the 12-year P(L) record), quiz logs, classes.
- **Neo4j** holds the curriculum ontology: `Institution → Unit → Fase`, `Subject → Elemen → CP → TP`, `ContentItem -[:TEACHES]-> TP`, and crucially `TP -[:HAS_PREREQUISITE]-> TP` (which may cross Fase boundaries, e.g. a Fase D Aljabar TP depending on a Fase Fondasi counting TP).

The adaptive loop is the system's spine:

1. Student answers a quiz item via `POST /api/v1/engine/evaluate`.
2. `ALETA_BKT_Engine.update_knowledge_state` applies Bayes (per-TP calibrated params from `aleta_core.tp_bkt_params`, defaulting to `p_init=0.15`, `p_transit=0.20`, `p_guess=0.20`, `p_slip=0.10`) to produce a new `P(L_{t+1})`.
3. `MatchmakerEngine.evaluate` runs a **state machine** (`NORMAL` / `IN_REMEDIATION` / `RETURNING_TO_MAIN`) with `remediation_stack`. Branches on thresholds:
   - `P(L) ≥ 0.85` while in remediation → pop stack, ascend (or `REMEDIATION_COMPLETED` if stack empty → return to primary TP).
   - `P(L) ≥ 0.85` on primary TP → `MASTERY_ACHIEVED` → unlock next ATP node.
   - `P(L) < 0.20` → push prerequisite onto stack, `REROUTE_TO_PREREQUISITE`. If no prerequisite exists → `SCAFFOLD_REQUIRED` (triggers LLM tutor).
   - Otherwise → `CONTINUE_PRACTICE`, with optional Ollama-generated scaffolding hint via RAG pipeline (see Doc 09).
4. Session state is persisted in `aleta_core.student_session_state` so remediation survives app close.
5. The new `P(L)` is written to `aleta_core.student_cognitive_passports`; a BEFORE trigger (`check_tp_mastery`) flips `is_mastered` when the value crosses `0.8500`.
6. Any active misconception detected by the graph (Doc 01 `MAY_TRIGGER`) is recorded in `aleta_core.student_misconceptions` and forwarded to the LLM prompt context.

**Multi-tenancy is per-PostgreSQL-schema, not per-database.** `aleta_core` holds global identity and the cognitive passport (cross-jenjang); `unit_tk`, `unit_sd`, `unit_smp`, `unit_sma` hold per-unit transactional data (classes, parent relations, quiz logs). Every request resolves `tenant_id` → `schema_name` via `aleta_core.tenants` and applies `SET LOCAL search_path TO <unit>, aleta_core` inside the request transaction.

The frontend is **two surfaces**: Flutter mobile and two separate React web apps. The Flutter app is a single codebase with **two build flavors**: `student` and `parent` (`flutter run --flavor parent -t lib/main_parent.dart`). It hydrates one of three theme modes (`KIDS_GAMIFIED` / `JUNIOR_ADVENTURE` / `PRO_DASHBOARD`) based on the `fase_aktif` claim from the JWT.

All LLM calls go to **local Ollama** (`llama3:8b-instruct` for chat, `nomic-embed-text` for embeddings), never to a third-party API. RAG retrieval uses **Qdrant** (`aleta_vector_db`).

**Cross-jenjang transition** (the headline business promise) is orchestrated by a state machine in Doc 12; data does not move, only `tenant_id` scope and enrollment.

## Non-Obvious Cross-Cutting Rules

These come from `AGENTS.md` and `07_SECURITY_PRIVACY_PASSPORT.md` and must be respected once implementation begins:

- **Single source of identity.** Never create a local users table inside a tenant schema. All people (`SISWA`, `GURU`, `ORANG_TUA`, `ADMIN_YAYASAN`, `SUPERADMIN`) reference `aleta_core.users`. ALETA stores only profile + `iam_subject`; password hashes live in **Keycloak** (SSO).
- **JWT validation.** Production tokens must be `RS256` / `ES256` against Keycloak JWKS. Never `HS256`. Backend must validate `iss`, `aud`, `exp`, `iat`, signature, and token type. MFA is mandatory for `SUPERADMIN`, `ADMIN_YAYASAN`, and `GURU`.
- **Tenant isolation pattern.** Inside each request transaction: resolve `tenant_id` → `schema_scope` via `aleta_core.tenants` (whitelist; never trust client/JWT string directly), then `SET LOCAL search_path …` and `SET LOCAL request.jwt.claim.{sub,role}`. Use `SET LOCAL` (not `SET`) so connection-pooled sessions don't leak state.
- **Object-level authorization.** Role alone is insufficient. Any endpoint accepting `student_id`, `class_id`, `tenant_id`, `tp_id`, or other resource ID must enforce ownership: students can't query other students; parents must match `student_parent_relations`; teachers must match the class they teach. The matrix is in §3.C of `07_…`.
- **Prerequisite graph integrity.** Whenever curriculum staff add a TP or CP node, the `HAS_PREREQUISITE` edges must be reviewed — broken edges silently break the adaptive rerouting for every student.
- **Data sovereignty for AI.** Route every LLM call through the local `aleta_ollama` container. Do **not** hardcode commercial AI endpoints for anything touching student PII. Prompts must be PII-minimised (no name / email / NISN) — this is a UU PDP No. 27/2022 obligation, not a preference.
- **Row-Level Security.** RLS is enabled on `aleta_core.student_cognitive_passports`; the policy matches `student_id` against `current_setting('request.jwt.claim.sub')::uuid`. Any new sensitive table follows the same pattern.
- **Audit table is non-optional.** `aleta_core.audit_events` must capture: failed logins, passport access, data export, role/tenant/curriculum changes, consent approvals, account resets, and admin operations.
- **No secrets in source.** Use `.env` (commit only `.env.example` with placeholders), Docker secrets, or a secret manager. The example passwords in `08_…` are placeholders.

## Naming & Style Conventions

- Blueprint files keep the uppercase numbered prefix (`04_BACKEND_API_CONTRACTS.md`); preserve that pattern when adding new ones.
- Fenced code blocks must carry a language tag (`sql`, `yaml`, `python`, `dart`, `tsx`, `cypher`).
- Code conventions per stack: Python/FastAPI uses `snake_case`; Dart/Flutter classes use `PascalCase`; React components use `PascalCase`; Postgres schemas/tables use lowercase `snake_case`. Container, service, and schema names use the `aleta_` / `unit_` prefix consistently (e.g. `aleta_core_api`, `aleta_ollama`, `unit_smp`).
- Indonesian is the primary language for blueprint prose. Keep it that way — translating drifts away from the source-of-truth wording that downstream LLM consumers rely on.

## Agent Bootstrap Procedure (When Implementation Starts)

There are **two ways** to bootstrap an implementation session:

### Path A — Canonical (recommended): paste `MASTER_PROMPT.md`
1. Open Claude Code session in the repo.
2. Send the entire content of `MASTER_PROMPT.md` as the first message.
3. Send a `SESSION BOOTSTRAP` block as the second message with `session_id`, `role`, and (optional) `task: T-NNN`.
4. Agent will auto-read `STATE.yaml`, pick eligible task, JIT-load only needed blueprint sections, and execute under ALETA-OPS constitution (10 rules, including TRD, Phase Lock, Sentinel Honor).
5. Agent ends every reply with one mandatory YAML fence (`# ALETA-AGENT-OUTPUT v1`) containing `state_patches`. Apply via `make apply_patches` between sessions.

### Path B — Lightweight (Claude Code default behavior, no master prompt)
If a user just opens a Claude Code session without pasting master prompt:
1. **Identify role.** If user did not specify, ask which Doc 16 §5 role.
2. **Identify task.** If user gave `T-NNN`, look it up in Doc 16 §8. Otherwise find closest match or ask architect to write one.
3. **Read `STATE.yaml`** to check current_phase, eligible tasks, sentinels, pending handoffs.
4. **Verify dependencies.** Check `depends_on` in task card. If upstream not done, refuse and report.
5. **JIT load** only blueprint sections listed in `task.blueprints[]` (use Grep with section anchors).
6. **Apply 5 anti-drift rules** (Doc 16 §2) + 10 ALETA-OPS techniques (Doc 17 §2).
7. **Before commit:** anti-drift checklist (Doc 16 §11), sentinel check against `STATE.yaml.sentinels`, inner skeptic loop.
8. **On completion:** emit YAML output per Doc 17 §4 Layer 5, including `state_patches`.

For multi-agent orchestration (multiple Claude sessions in parallel), see Doc 16 §5 topology, Doc 16 §12 handoff contracts, and Doc 17 §5 end-to-end lifecycle example.

## Useful Commands (Documentation Phase)

Because this is a docs repo today, the meaningful commands are inspection ones:

```bash
ls -la                       # confirm the blueprint set is intact
rg "TODO|FIXME|TBD" .        # find unresolved spec gaps
rg "aleta_" .                # check service/schema/container naming consistency
rg "TP_|CP_|FASE_" .         # cross-check curriculum identifiers across documents
```

When implementation lands, the canonical entrypoints are defined in the top-level `Makefile` (see `15_PROJECT_STRUCTURE.md` §16): `make dev` (start full stack), `make test` (cross-service), `make lint`, `make format`, `make openapi`, `make tokens`. Use these instead of memorizing per-service commands.

## Verifying Documentation Changes

There is no automated link checker or schema validator yet. When editing blueprints:

- Walk every cross-reference (`HAS_PREREQUISITE`, `student_cognitive_passports`, `tenant_id`, `schema_scope`, `fase_aktif`, `TP_MAT_*`) and confirm the new wording stays consistent across all nine files.
- If you touch the BKT formulas, the Python in `02_…`, the SQL trigger in `03_…`, and the example response in `04_…` must all still agree on the `0.85` mastery / `0.20` remedial thresholds.
- If you touch the JWT claim shape in `07_…`, the FastAPI controller stub in `04_…`, the BLoC `Authenticated` state in `05_…`, and the docker-compose env vars in `08_…` need to stay aligned.
