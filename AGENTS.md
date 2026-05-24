# Repository Guidelines

## Project Structure & Module Organization

This repository is currently a blueprint and architecture package for Project ALETA, not an implemented application. The root contains numbered Markdown specifications that should be read in sequence:

- `00_EXECUTIVE_SUMMARY.md`: product vision, architecture, rollout plan.
- `01_CURRICULUM_ONTOLOGY_GRAPH.md` through `08_DEVOPS_DEPLOYMENT_LOCAL_CLOUD.md`: domain, backend, frontend, security, and deployment blueprints.
- `README.md`: document index and onboarding prompt.

When implementation begins, keep code outside the blueprint files and follow the planned modules, for example `backend_core/`, `ai_engine/`, `frontend_flutter/`, `teacher_dashboard_web/`, `admin_dashboard_web/`, and `docker-compose.yml`.

## Build, Test, and Development Commands

No package manager, application runtime, or CI configuration is currently checked in. Useful local checks for this documentation repo:

- `ls -la`: confirm the expected blueprint files exist.
- `rg "TODO|FIXME|TBD" .`: find unresolved specification gaps.
- `rg "aleta_" .`: inspect service, schema, and container naming consistency.

After implementation files are added, document exact commands such as `docker compose up -d`, `pytest`, `npm test`, or `flutter test`.

## Coding Style & Naming Conventions

Keep blueprint documents in Markdown with clear numbered headings and implementation-ready examples. Preserve the uppercase numbered filename pattern, for example `04_BACKEND_API_CONTRACTS.md`. Use fenced code blocks with language tags such as `sql`, `yaml`, `python`, `dart`, `tsx`, and `json`.

For future code, follow the stack-specific conventions in the blueprints: Python/FastAPI modules use `snake_case`, Flutter/Dart classes use `PascalCase`, React components use `PascalCase`, and database schemas/tables use lowercase `snake_case`.

## Testing Guidelines

For documentation changes, verify links, code block syntax, and cross-file terminology manually before submitting. When executable code is introduced, add tests beside the relevant module and name them predictably, for example `test_adaptive_engine.py`, `*.test.tsx`, or Flutter `*_test.dart`.

## Commit & Pull Request Guidelines

This directory is not currently a Git repository, so no local commit history is available to infer conventions. Use clear, imperative commit messages such as `docs: clarify API contract examples` or `feat: add adaptive engine scaffold`.

Pull requests should include a short summary, affected blueprint files, linked issue or decision record if available, and screenshots only when UI artifacts are changed. Call out any security, privacy, or student-data implications explicitly.

## Security & Configuration Tips

Do not commit real secrets, production credentials, student data, or private school records. Example passwords in the DevOps blueprint are placeholders and must be replaced through environment-specific configuration before deployment. Keep AI processing aligned with the local Ollama and data-sovereignty requirements described in `07_SECURITY_PRIVACY_PASSPORT.md`.
