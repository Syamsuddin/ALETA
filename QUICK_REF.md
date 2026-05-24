# QUICK_REF.md — ALETA Agent Quick Reference

> **Untuk agent:** Load file ini (~3K token) sebagai pengganti multi-doc load untuk sesi orientasi.
> Semua nilai di sini di-derive dari STATE.yaml dan blueprint. Jika konflik → trust STATE.yaml.

---

## 1. Document Scope Map

| Doc | File | Scope (1 kalimat) | Loaded by Tasks |
|-----|------|-------------------|-----------------|
| 00 | 00_EXECUTIVE_SUMMARY.md | Vision, problem space, 3-year rollout, arsitektur overview — orientasi saja, tanpa kode | (sesi pertama semua role) |
| 01 | 01_CURRICULUM_ONTOLOGY_GRAPH.md | Neo4j schema: Institution→Unit→Fase→CP→TP + HAS_PREREQUISITE edges + Cypher seed | T-103, T-203 |
| 02 | 02_ADAPTIVE_ENGINE_SPEC.md | BKT math + ALETA_BKT_Engine + MatchmakerEngine state machine + remediation logic | T-201, T-202, T-208 |
| 03 | 03_DATABASE_SCHEMA_MULTI_TENANTS.md | PostgreSQL aleta_core + unit_* schemas, RLS, trigger check_tp_mastery, SET LOCAL pattern | T-101, T-102, T-105 |
| 04 | 04_BACKEND_API_CONTRACTS.md | FastAPI REST endpoint specs, request/response schemas, SecurityGuard, error envelope | T-106–T-108, T-207–T-210 |
| 05 | 05_FRONTEND_DYNAMIC_UI_FLUTTER.md | Flutter BLoC + Clean Architecture, 2 build flavors (student/parent), 3 theme modes | T-301–T-312 |
| 06 | 06_TEACHER_DASHBOARD_ANALYTICS.md | React teacher dashboard: morning briefing, red flag alerts, differentiation group cards | T-401–T-411 |
| 07 | 07_SECURITY_PRIVACY_PASSPORT.md | UU PDP compliance, Keycloak OIDC, authorization matrix, RLS, audit, retention, breach | T-107, T-511, T-801, T-805 |
| 08 | 08_DEVOPS_DEPLOYMENT_LOCAL_CLOUD.md | docker-compose 12 services + healthchecks, nginx multi-subdomain, secrets pattern | T-001–T-005 |
| 09 | 09_RAG_AND_TUTOR_SPEC.md | Qdrant+Ollama RAG pipeline, hobby-aware content rewrite, 24/7 tutor chat, 3-layer safety | T-501–T-511 |
| 10 | 10_PARENT_APP_SPEC.md | Parent Flutter flavor, no-numeric-grade reports, consent inbox, LLM home activities | T-601–T-606 |
| 11 | 11_ADMIN_YAYASAN_DASHBOARD.md | React admin: ATP Builder (react-flow), system_config runtime calibration, audit explorer | T-607–T-611 |
| 12 | 12_CROSS_JENJANG_TRANSITION.md | State-machine TK→SD→SMP→SMA, idempotent, 7-day rollback, bulk mode | T-701–T-709 |
| 13 | 13_MIGRATIONS_AND_CICD.md | Alembic + Neo4j migrations, OpenAPI CI gate, Gitea Actions, backup off-site | T-005, T-109, T-803 |
| 14 | 14_UI_UX_DESIGN_SYSTEM.md | Design tokens JSON (canonical SoT), component matrix, WCAG 2.2 AA, Figma index | T-302, T-303, T-310 |
| 15 | 15_PROJECT_STRUCTURE.md | Canonical monorepo tree, naming conventions, module boundaries, Makefile | Semua task (validasi path) |
| 16 | 16_AI_AGENT_IMPLEMENTATION_PLAYBOOK.md | 60+ task cards (T-NNN), 8 phase milestones, role definitions, anti-drift rules | Meta-doc (baca §8 entry T-NNN saja) |
| 17 | 17_MASTER_PROMPT_AND_STATE.md | MASTER_PROMPT.md 10-layer spec, STATE.yaml schema, ALETA-OPS 10 techniques | Meta-doc (orchestrator) |

---

## 2. Sentinel Values

> Sumber kebenaran: `STATE.yaml.sentinels`. Apapun output yang menyebut nilai berbeda → HALT.

| Nilai | Makna | Sumber |
|-------|-------|--------|
| `0.85` | BKT mastery threshold — P(L) ≥ 0.85 → mastered | Doc 02 §2 |
| `0.20` | BKT remedial threshold — P(L) < 0.20 → reroute | Doc 02 §2 |
| `0.15` | BKT p_init default (cold start) | Doc 02 §4 |
| `0.30` | p_guess max constraint | Doc 02 §6.B |
| `0.10` | p_slip max constraint | Doc 02 §6.B |
| `RS256` / `ES256` | JWT algorithm yang diizinkan | Doc 07 §B |
| `HS256` | **DILARANG** di production | Doc 07 §B |
| `15 menit` | Access token TTL | Doc 07 §B |
| `30 hari` | Refresh token TTL (with rotation) | Doc 07 §B |
| `10 menit` | JWKS cache TTL | Doc 07 §B |
| `90 hari` | tutor_messages retention → hard delete | Doc 07 §E |
| `3 tahun` | student_quiz_logs rolling retention | Doc 07 §E |
| `7 tahun` | audit_events retention → offline archive | Doc 07 §E |
| `2 tahun` | passport anonymization setelah kelulusan | Doc 07 §E |
| `7 hari` | Transition rollback window | Doc 12 §2 |
| `48dp` | Min tap target (standar) | Doc 14 §9 |
| `64dp` | Min tap target (KIDS_GAMIFIED mode) | Doc 14 §8.B |
| `WCAG 2.2 AA` | Standar aksesibilitas yang diwajibkan | Doc 14 §9 |
| `3.5 detik` | P95 latency target RAG/tutor end-to-end | Doc 09 §8 |
| `800 ms` | Streaming start latency target | Doc 09 §4.F |

---

## 3. Service Container Names

| Container | Peran |
|-----------|-------|
| `aleta_postgres` | PostgreSQL (multi-tenant schemas) |
| `aleta_neo4j` | Neo4j (curriculum ontology graph) |
| `aleta_redis` | Redis (session cache) |
| `aleta_ollama` | Local LLM (llama3:8b-instruct + nomic-embed-text) |
| `aleta_keycloak` | Keycloak IdP (SSO) |
| `aleta_core_api` | Main FastAPI backend |
| `aleta_ai_engine` | Internal BKT/AI service |
| `aleta_vector_db` | Qdrant vector store |

---

## 4. Phase & Role Map

| Phase | Fokus | Roles Aktif | Task Range |
|-------|-------|-------------|------------|
| 0 | Bootstrap + infra skeleton | devops | T-001–T-005 |
| 1 | DB migrations + FastAPI skeleton | dba, backend-coder, devops | T-101–T-109 |
| 2 | Adaptive core (BKT + Matchmaker) | ai-engine-coder, backend-coder, qa | T-201–T-212 |
| 3 | Student mobile + quiz loop | flutter-coder, web-coder, qa | T-301–T-313 |
| 4 | Teacher dashboard | web-coder, backend-coder, qa | T-401–T-411 |
| 5 | RAG + tutor chat | ai-engine-coder, backend-coder, flutter-coder, security-reviewer, devops | T-501–T-511 |
| 6 | Parent app + admin dashboard | flutter-coder, web-coder, backend-coder, ai-engine-coder | T-601–T-611 |
| 7 | Cross-jenjang transition | backend-coder, dba, web-coder, qa | T-701–T-709 |
| 8 | Security hardening + pilot release | security-reviewer, qa, devops, architect, doc-keeper | T-801–T-810 |

---

## 5. Canonical Format Cheat Sheet

```
Cross-reference (prose):     Doc NN §X.Y          contoh: Doc 07 §B
Cross-reference (YAML/code): "NN#§X.Y"            contoh: "07#§B"
Task ID:                     T-NNN                 contoh: T-208
Schema.table:                aleta_core.table      contoh: aleta_core.student_cognitive_passports
Container name:              aleta_<name>          contoh: aleta_ollama
Service schema:              unit_<jenjang>        contoh: unit_smp
Python/FastAPI:              snake_case
Flutter/Dart class:          PascalCase
React component:             PascalCase
PostgreSQL table/schema:     snake_case
```

---

## 6. Roles & Mandate

| Role | Mandate (1 baris) |
|------|-------------------|
| `architect` | Output ADR only; dilarang tulis implementation code |
| `backend-coder` | FastAPI + SQLAlchemy; wajib run pytest sebelum done |
| `ai-engine-coder` | BKT engine + RAG; semua LLM call via aleta_ollama saja |
| `flutter-coder` | BLoC pattern; tokens dari `tokens.g.dart` saja; min tap 48dp |
| `web-coder` | TanStack Query; tokens via `@aleta/tokens`; no logic in components |
| `dba` | Setiap migration sertakan downgrade path; tabel sensitif baru wajib RLS |
| `devops` | Prefix aleta_*; no secrets in compose; healthcheck mandatory |
| `security-reviewer` | Paranoid bias; auto-approve dilarang untuk auth/security/audit paths |
| `qa` | Test terhadap blueprint spec, bukan implementasi; run thrice |
| `doc-keeper` | Update Doc 16 §8 task status; tambah failure modes ke Doc 16 §13 |

---

## 7. Critical Invariants — Jangan Pernah Dilanggar

```
mastery trigger SQL:   0.8500  (trigger check_tp_mastery, Doc 03)
semua LLM call:        → aleta_ollama saja, bukan third-party API
JWT algorithm:         RS256 atau ES256; HS256 dilarang di production
tenant isolation:      resolve tenant_id → whitelist → SET LOCAL search_path dalam request transaction
RLS:                   aleta_core.student_cognitive_passports — policy match student_id vs request.jwt.claim.sub
identity SoT:          aleta_core.users — jangan buat local users table di tenant schema
audit_events:          wajib untuk: failed login, passport access, export, consent, role change, admin ops
```

---

## 8. JIT Section Loading — Anchor Grep Patterns

```bash
# Grep section anchor (hemat token vs full read)
grep -n "^## 3\. SERVICE" 15_PROJECT_STRUCTURE.md       # service folder tertentu
grep -n "^## §B"          07_SECURITY_PRIVACY_PASSPORT.md  # JWKS section
grep -n "^## §C"          07_SECURITY_PRIVACY_PASSPORT.md  # authorization matrix
grep -n "id: T-208"       16_AI_AGENT_IMPLEMENTATION_PLAYBOOK.md  # task card specific
grep -n "^### 4\\.2"      02_ADAPTIVE_ENGINE_SPEC.md      # subsection BKT
```
