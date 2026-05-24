---
doc: "PRD-04"
title: "PRD Admin Yayasan Dashboard"
scope: "Spesifikasi lengkap React Web Admin Dashboard untuk role ADMIN_YAYASAN dan SUPERADMIN"
key_entities: [ATP_Builder, SystemConfigPanel, AuditLogExplorer, OpsHealthPanel, TransitionOrchestrator, CurriculumEditor]
blueprint_refs: ["11", "12", "07", "04", "01", "14"]
loaded_by_tasks: [T-607, T-608, T-609, T-610, T-611, T-708]
---

# PRD: Admin Yayasan Dashboard
### Project ALETA — AI-Powered Adaptive LMS
**Dokumen Nomor:** PRD-04
**Versi:** 1.0.0
**Tanggal:** 2026-05-24
**Status:** Approved — Vibe Coding Ready
**Audience:** AI Agent (Claude Code), Frontend Engineer (React/TypeScript), Tech Lead

---

## Daftar Isi

1. [Ringkasan Produk](#1-ringkasan-produk)
2. [Target Pengguna & Persona](#2-target-pengguna--persona)
3. [Tech Stack & Dependencies](#3-tech-stack--dependencies)
4. [Struktur Proyek](#4-struktur-proyek)
5. [Authentication, RBAC & MFA](#5-authentication-rbac--mfa)
6. [Peta Modul & Routing](#6-peta-modul--routing)
7. [Aturan Kritis Arsitektur](#7-aturan-kritis-arsitektur)
8. [API Contracts](#8-api-contracts)
9. [State Management](#9-state-management)
10. [TypeScript Interfaces](#10-typescript-interfaces)
11. [Code Stubs — Komponen Utama](#11-code-stubs--komponen-utama)
12. [Aksesibilitas & WCAG 2.2 AA](#12-aksesibilitas--wcag-22-aa)
13. [Acceptance Criteria & Release Gate Checklist](#13-acceptance-criteria--release-gate-checklist)

---

## 1. Ringkasan Produk

### 1.1 Apa Ini

Admin Yayasan Dashboard adalah **aplikasi React Web terpisah** (`admin_dashboard_web/`) khusus untuk role `ADMIN_YAYASAN` dan `SUPERADMIN`. Berbeda dengan Teacher Dashboard yang berorientasi tindakan harian di kelas, dashboard ini berorientasi **governance, strategy, dan operasional sistem**.

### 1.2 Cakupan Tanggung Jawab

| Domain | Fungsi |
| :--- | :--- |
| **Tata Kelola** | KPI lintas unit, health sistem, backup status |
| **Manajemen Unit** | CRUD tenant, schema mapping, aktivasi/deaktivasi unit |
| **Manajemen Pengguna** | CRUD `aleta_core.users`, assignment role, enforce MFA |
| **Kurikulum** | Editor TP/CP/Misconception — ditulis ke Postgres + Neo4j atomik |
| **ATP Builder** | Drag-drop urutan ATP per unit & tahun ajaran (react-flow) |
| **Transisi Siswa** | Individual + bulk transition lintas jenjang, rollback 7 hari |
| **Consent & PDP** | Audit consent, ekspor data subjek (UU PDP No. 27/2022) |
| **Audit Log** | Eksplorasi `audit_events` dengan filter & CSV export |
| **System Config** | Runtime calibration threshold BKT, red flag, LLM model |
| **Ops Health** | Healthcheck PostgreSQL/Neo4j/Ollama/Qdrant/Redis, queue depth |

### 1.3 Prinsip Desain

- **Governance-first UX:** keputusan yang tidak dapat dibatalkan selalu membutuhkan konfirmasi eksplisit (dialog + reason field).
- **Audit everything:** setiap mutasi data menghasilkan baris `audit_events` — ini non-negotiable.
- **Render-only untuk threshold:** nilai threshold BKT/red flag tidak dihitung di frontend; frontend hanya menampilkan nilai yang dikembalikan backend dari `system_config`.
- **SUPERADMIN-only gates:** fitur destruktif (hapus tenant, reset MFA user, force logout, ubah `system_config`) diproteksi tambahan role check di backend dan frontend.

---

## 2. Target Pengguna & Persona

### 2.1 Admin Yayasan (`ADMIN_YAYASAN`)

**Siapa:** Kepala IT / Wakil Direktur Akademik yayasan.
**Tujuan harian:**
- Memantau KPI mastery dan red flag rate lintas semua unit (TK/SD/SMP/SMA).
- Mengelola kurikulum ATP dan urutan TP per jenjang.
- Memproses transisi kenaikan kelas akhir tahun ajaran.
- Menjawab permintaan ekspor data dari orang tua (UU PDP compliance).

**Akses:** Semua modul kecuali `system_config` (SUPERADMIN only untuk write).

### 2.2 Superadmin (`SUPERADMIN`)

**Siapa:** Developer/DevOps internal yayasan.
**Tujuan harian:**
- Mengkalibrasi threshold BKT & red flag tanpa redeploy.
- Memantau Ops Health Panel.
- Mengelola tenant baru saat ada unit sekolah baru dibuka.
- Review audit log high-risk events.

**Akses:** Semua modul termasuk `system_config` (write) dan bulk destructive actions.

---

## 3. Tech Stack & Dependencies

### 3.1 Core

```json
{
  "react": "^18.3.0",
  "react-dom": "^18.3.0",
  "typescript": "^5.5.0",
  "vite": "^5.3.0"
}
```

### 3.2 Data Fetching & State

```json
{
  "@tanstack/react-query": "^5.51.0",
  "@tanstack/react-table": "^8.19.0",
  "zustand": "^4.5.4",
  "axios": "^1.7.3"
}
```

### 3.3 UI & Visualisasi

```json
{
  "tailwindcss": "^3.4.6",
  "@headlessui/react": "^2.1.1",
  "recharts": "^2.12.7",
  "@reactflow/core": "^11.11.3",
  "reactflow": "^11.11.3",
  "react-markdown": "^9.0.1",
  "react-router-dom": "^6.25.0",
  "@aleta/tokens": "workspace:*"
}
```

### 3.4 Auth & Security

```json
{
  "oidc-client-ts": "^3.0.1",
  "react-oidc-context": "^3.1.0"
}
```

### 3.5 Dev Tools

```json
{
  "@vitejs/plugin-react": "^4.3.1",
  "@testing-library/react": "^16.0.0",
  "vitest": "^2.0.3",
  "axe-core": "^4.9.1",
  "@axe-core/react": "^4.9.1",
  "eslint": "^9.7.0",
  "@typescript-eslint/eslint-plugin": "^8.0.0"
}
```

### 3.6 package.json Scripts

```json
{
  "scripts": {
    "dev": "vite --port 5174",
    "build": "tsc -b && vite build",
    "preview": "vite preview",
    "test": "vitest run",
    "test:a11y": "vitest run --reporter=verbose src/**/*.a11y.test.tsx",
    "lint": "eslint . --ext ts,tsx",
    "typecheck": "tsc --noEmit"
  }
}
```

> **Catatan port:** Student/Parent dev server port 5173, Teacher Dashboard 5174, **Admin Dashboard 5175** — jangan konflik.

---

## 4. Struktur Proyek

```
admin_dashboard_web/
├── index.html
├── vite.config.ts
├── tailwind.config.ts
├── tsconfig.json
├── package.json
└── src/
    ├── main.tsx                    # entry point
    ├── App.tsx                     # router + providers
    ├── api/
    │   ├── apiClient.ts            # axios instance + interceptors
    │   ├── admin.ts                # admin API hooks
    │   ├── curriculum.ts           # curriculum API hooks
    │   ├── transitions.ts          # transition API hooks
    │   ├── audit.ts                # audit log API hooks
    │   └── ops.ts                  # ops health API hooks
    ├── auth/
    │   ├── AuthGuard.tsx           # role guard (ADMIN_YAYASAN | SUPERADMIN)
    │   ├── MfaGuard.tsx            # MFA enforcement gate
    │   ├── SuperAdminGuard.tsx     # extra gate untuk fitur SUPERADMIN-only
    │   └── useAuthStore.ts         # Zustand auth slice
    ├── components/
    │   ├── atoms/
    │   │   ├── StatusBadge.tsx     # UP/DEGRADED/DOWN badge
    │   │   ├── RiskBadge.tsx       # LOW/MEDIUM/HIGH/CRITICAL badge
    │   │   ├── KpiCard.tsx
    │   │   └── ConfirmDialog.tsx   # destructive action confirmation
    │   ├── molecules/
    │   │   ├── AuditFilterBar.tsx
    │   │   ├── ServiceHealthRow.tsx
    │   │   ├── TransitionStatusChip.tsx
    │   │   └── ConfigKeyRow.tsx    # system_config key-value row
    │   └── organisms/
    │       ├── KpiOverviewGrid.tsx
    │       ├── AtpBuilderCanvas.tsx    # react-flow canvas
    │       ├── AuditLogTable.tsx       # @tanstack/react-table
    │       ├── OpsHealthPanel.tsx
    │       ├── CurriculumTpEditor.tsx
    │       ├── TransitionWizard.tsx
    │       └── BulkTransitionUploader.tsx
    ├── pages/
    │   ├── OverviewPage.tsx
    │   ├── UnitsPage.tsx
    │   ├── UsersPage.tsx
    │   ├── CurriculumPage.tsx
    │   ├── AtpBuilderPage.tsx
    │   ├── TransitionsPage.tsx
    │   ├── ConsentPage.tsx
    │   ├── AuditLogPage.tsx
    │   ├── SystemConfigPage.tsx    # SUPERADMIN write, ADMIN_YAYASAN read
    │   └── OpsPage.tsx
    ├── state/
    │   ├── authStore.ts
    │   ├── uiStore.ts
    │   └── atpBuilderStore.ts      # react-flow nodes/edges
    └── utils/
        ├── formatters.ts
        ├── riskColor.ts
        └── csvExport.ts
```

---

## 5. Authentication, RBAC & MFA

### 5.1 Keycloak OIDC Setup

```tsx
// src/main.tsx
import { AuthProvider } from 'react-oidc-context';

const oidcConfig = {
  authority: import.meta.env.VITE_KEYCLOAK_URL + '/realms/aleta',
  client_id: 'aleta-admin-dashboard',
  redirect_uri: window.location.origin + '/callback',
  scope: 'openid profile email roles',
  response_type: 'code',
  automaticSilentRenew: true,
};

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <AuthProvider {...oidcConfig}>
      <App />
    </AuthProvider>
  </React.StrictMode>
);
```

### 5.2 JWT Claims Shape

Token JWT dari Keycloak mengandung:
```json
{
  "sub": "uuid-user",
  "realm_access": { "roles": ["ADMIN_YAYASAN"] },
  "aleta_role": "ADMIN_YAYASAN",
  "aleta_yayasan_id": "YAYASAN_UTAMA",
  "mfa_authenticated": true,
  "exp": 1748000000
}
```

**Wajib:** `aleta_role ∈ {ADMIN_YAYASAN, SUPERADMIN}` dan `mfa_authenticated: true`. Jika salah satu tidak terpenuhi, redirect ke error page.

### 5.3 AuthGuard — Role + MFA

```tsx
// src/auth/AuthGuard.tsx
import { useAuth } from 'react-oidc-context';
import { Navigate } from 'react-router-dom';

type Props = { children: React.ReactNode };

export function AuthGuard({ children }: Props) {
  const auth = useAuth();

  if (auth.isLoading) return <div role="status">Memuat...</div>;

  if (!auth.isAuthenticated) {
    auth.signinRedirect();
    return null;
  }

  const claims = auth.user?.profile as Record<string, unknown>;
  const role = claims?.aleta_role as string;
  const mfaOk = claims?.mfa_authenticated === true;

  const allowedRoles = ['ADMIN_YAYASAN', 'SUPERADMIN'];
  if (!allowedRoles.includes(role)) {
    return <Navigate to="/error/forbidden" replace />;
  }

  if (!mfaOk) {
    return <Navigate to="/error/mfa-required" replace />;
  }

  return <>{children}</>;
}
```

### 5.4 SuperAdminGuard — Fitur Destruktif

```tsx
// src/auth/SuperAdminGuard.tsx
import { useAuthStore } from '../state/authStore';

type Props = {
  children: React.ReactNode;
  fallback?: React.ReactNode;
};

export function SuperAdminGuard({ children, fallback = null }: Props) {
  const role = useAuthStore((s) => s.role);
  return role === 'SUPERADMIN' ? <>{children}</> : <>{fallback}</>;
}
```

Gunakan ini untuk membungkus tombol "Simpan" di `SystemConfigPage` dan tombol "Hapus Tenant":
```tsx
<SuperAdminGuard fallback={<ReadOnlyConfigView values={configs} />}>
  <SystemConfigEditor configs={configs} />
</SuperAdminGuard>
```

---

## 6. Peta Modul & Routing

### 6.1 Router Setup

```tsx
// src/App.tsx
import { createBrowserRouter, RouterProvider } from 'react-router-dom';
import { AuthGuard } from './auth/AuthGuard';

const router = createBrowserRouter([
  {
    path: '/',
    element: <AuthGuard><AdminLayout /></AuthGuard>,
    children: [
      { index: true, element: <OverviewPage /> },
      { path: 'units', element: <UnitsPage /> },
      { path: 'users', element: <UsersPage /> },
      { path: 'curriculum', element: <CurriculumPage /> },
      { path: 'curriculum/atp', element: <AtpBuilderPage /> },
      { path: 'transitions', element: <TransitionsPage /> },
      { path: 'transitions/:transitionId', element: <TransitionDetailPage /> },
      { path: 'consent', element: <ConsentPage /> },
      { path: 'audit', element: <AuditLogPage /> },
      { path: 'system', element: <SystemConfigPage /> },
      { path: 'ops', element: <OpsPage /> },
    ],
  },
  { path: '/callback', element: <OidcCallback /> },
  { path: '/error/forbidden', element: <ForbiddenPage /> },
  { path: '/error/mfa-required', element: <MfaRequiredPage /> },
]);
```

### 6.2 Modul & Hak Akses

| Route | Label Nav | ADMIN_YAYASAN | SUPERADMIN |
| :--- | :--- | :---: | :---: |
| `/` | Overview | Read | Read |
| `/units` | Tata Kelola Unit | Read + Write | Read + Write |
| `/users` | Pengguna | Read + Write | Read + Write |
| `/curriculum` | Kurikulum | Read + Write | Read + Write |
| `/curriculum/atp` | ATP Builder | Read + Write | Read + Write |
| `/transitions` | Transisi Siswa | Read + Write | Read + Write |
| `/consent` | Consent & PDP | Read + Ekspor | Read + Ekspor |
| `/audit` | Audit Log | Read + Ekspor | Read + Ekspor |
| `/system` | Sistem Konfigurasi | **Read Only** | **Read + Write** |
| `/ops` | Operasional | Read | Read |

---

## 7. Aturan Kritis Arsitektur

### 7.1 AUDIT-FIRST: Setiap Mutasi Wajib Menghasilkan Audit Event

Backend memastikan ini melalui trigger dan middleware. Namun dari sisi frontend, **setiap mutasi TanStack Query `useMutation` harus ditandai dengan `reason` field** jika modifikasinya high-risk:

```tsx
// Pattern: setiap mutasi yang risk >= HIGH harus sertakan reason
const mutation = useMutation({
  mutationFn: (payload: { config_key: string; config_value: unknown; reason: string }) =>
    apiClient.patch('/admin/system/config', payload),
  onSuccess: () => {
    toast.success('Konfigurasi disimpan');
    queryClient.invalidateQueries({ queryKey: ['system-config'] });
  },
});

// Di UI: dialog konfirmasi dengan reason field sebelum submit
```

### 7.2 RENDER-ONLY untuk Semua Nilai Konfigurasi

Frontend **tidak boleh** memiliki konstanta threshold hardcoded. Semua nilai ambang (BKT mastery, red flag threshold, retention days) dibaca dari `GET /admin/system/config` dan dirender apa adanya.

```tsx
// ✅ Benar: render nilai dari backend
const { data: configs } = useQuery({ queryKey: ['system-config'], queryFn: fetchSystemConfigs });
<span>{configs?.find(c => c.config_key === 'bkt.mastery_threshold')?.config_value}</span>

// ❌ Salah: jangan hardcode sentinel values
const MASTERY_THRESHOLD = 0.85; // DILARANG di frontend
```

### 7.3 DUA-PHASE WRITE untuk Curriculum Editor

Ketika admin menyimpan perubahan TP/CP, backend melakukan transaksi 2-phase:
1. Tulis ke PostgreSQL (audit + source of truth).
2. MERGE ke Neo4j.
3. Jika Neo4j gagal → rollback PostgreSQL, kembalikan error.

Frontend hanya perlu menangani response sukses/error dengan tepat. **Jangan retry otomatis** untuk curriculum mutations — tampilkan error dengan pesan eksplisit:

```tsx
onError: (error) => {
  toast.error('Gagal menyimpan kurikulum. Perubahan Neo4j di-rollback. Coba lagi atau hubungi DevOps.');
}
```

### 7.4 KONFIRMASI EKSPLISIT untuk Aksi Destruktif

Aksi yang membutuhkan `ConfirmDialog` dengan reason field:
- Hapus tenant unit
- Reset MFA pengguna
- Force logout semua sesi pengguna
- Rollback transisi siswa
- Ubah nilai `system_config`
- Ekspor data subjek (CSV audit / consent)

Pattern komponen:
```tsx
// Jangan buka aksi destruktif tanpa konfirmasi
<ConfirmDialog
  title="Rollback Transisi?"
  description={`Siswa ${studentName} akan dikembalikan ke ${fromUnit}.`}
  requireReason
  onConfirm={(reason) => rollbackMutation.mutate({ transitionId, reason })}
  destructive
/>
```

### 7.5 BULK TRANSITION: Concurrency Awareness

Setelah `POST /admin/transition/bulk` dikirim, server mengantri N job dengan concurrency limit 20. Frontend **harus polling** status per `transition_id` — jangan assume selesai seketika:

```tsx
// Poll setiap 5 detik, berhenti saat semua COMPLETED atau ada FAILED
const { data } = useQuery({
  queryKey: ['transition-batch', batchId],
  queryFn: () => fetchTransitionBatch(batchId),
  refetchInterval: (data) => {
    const allDone = data?.transitions.every(t =>
      t.status === 'COMPLETED' || t.status === 'FAILED' || t.status === 'ROLLED_BACK'
    );
    return allDone ? false : 5_000;
  },
});
```

---

## 8. API Contracts

### 8.1 Overview KPI

```
GET /api/v1/admin/yayasan/overview
Authorization: Bearer <token>
```

Response `200 OK`:
```json
{
  "academic_year": "2025/2026",
  "kpi_cards": [
    { "label": "Total Siswa Aktif", "value": 4820 },
    { "label": "Avg Mastery (semua TP)", "value": 0.68 },
    { "label": "Red Flag Rate (7 hari)", "value": 0.04 },
    { "label": "Consent Pending", "value": 12 }
  ],
  "mastery_by_unit": [
    { "unit": "UNIT_SD_01", "avg_mastery": 0.71 },
    { "unit": "UNIT_SMP_01", "avg_mastery": 0.65 }
  ],
  "generated_at": "2026-05-24T06:00:00Z"
}
```

### 8.2 System Config

```
GET  /api/v1/admin/system/config
PATCH /api/v1/admin/system/config
Authorization: Bearer <token>  [SUPERADMIN required for PATCH]
```

GET Response `200 OK`:
```json
[
  {
    "config_key": "bkt.mastery_threshold",
    "config_value": 0.85,
    "description": "Ambang mastery BKT. Mengubah mempengaruhi semua siswa aktif.",
    "updated_by_name": "Superadmin ALETA",
    "updated_at": "2026-01-10T08:00:00Z"
  },
  {
    "config_key": "bkt.remedial_threshold",
    "config_value": 0.20,
    "description": "Ambang reroute remedial."
  },
  {
    "config_key": "redflag.consecutive_sessions",
    "config_value": 3,
    "description": "Sesi berturut dengan kesalahan tinggi sebelum red flag aktif."
  },
  {
    "config_key": "llm.default_model",
    "config_value": "llama3:8b-instruct",
    "description": "Model Ollama aktif untuk tutor & modul ajar."
  },
  {
    "config_key": "retention.quiz_logs_days",
    "config_value": 1095,
    "description": "Retensi quiz logs (hari). Default 3 tahun."
  }
]
```

PATCH Body:
```json
{
  "config_key": "llm.default_model",
  "config_value": "llama3:70b-instruct",
  "reason": "Upgrade model untuk akurasi lebih baik setelah pengujian GPU baru"
}
```

Response `200 OK`:
```json
{ "config_key": "llm.default_model", "config_value": "llama3:70b-instruct", "audit_event_id": "uuid-audit" }
```

### 8.3 Curriculum Editor

```
GET /api/v1/admin/curriculum/tp?subject_id=MAT&fase=D
PUT /api/v1/admin/curriculum/tp
```

PUT Body:
```json
{
  "tp_id": "TP_MAT_7_ALJABAR",
  "competency": "Menyederhanakan bentuk aljabar linear satu variabel",
  "content": "Bentuk Aljabar Linear",
  "bloom_level": 3,
  "derived_from_cp_id": "CP_MAT_SMP_ALJ",
  "prerequisites": ["TP_MAT_6_PERSAMAAN"],
  "may_trigger_misconceptions": ["MIS_OP_ORDER"]
}
```

Response `200 OK`:
```json
{
  "tp_id": "TP_MAT_7_ALJABAR",
  "postgres_saved": true,
  "neo4j_merged": true,
  "audit_event_id": "uuid-audit"
}
```

Response `500` jika Neo4j gagal:
```json
{
  "error": "NEO4J_SYNC_FAILED",
  "message": "Perubahan Postgres di-rollback. Neo4j: connection timeout.",
  "postgres_rolled_back": true
}
```

### 8.4 ATP Builder

```
GET /api/v1/admin/atp?unit_id=UNIT_SMP_01&tahun_ajaran=2025/2026
PUT /api/v1/admin/atp
```

PUT Body (seluruh sequence baru, atomic replace):
```json
{
  "unit_id": "UNIT_SMP_01",
  "tahun_ajaran": "2025/2026",
  "position_map": [
    { "tp_id": "TP_MAT_7_ALJABAR", "position": 1, "week": 1 },
    { "tp_id": "TP_MAT_7_FUNGSI", "position": 2, "week": 3 }
  ]
}
```

### 8.5 Transisi Siswa

```
POST /api/v1/admin/transition        # individual
POST /api/v1/admin/transition/bulk   # bulk
GET  /api/v1/admin/transition/:id    # status polling
POST /api/v1/admin/transition/:id/rollback
```

POST Individual Body:
```json
{
  "student_id": "uuid-student",
  "from_tenant_id": "UNIT_SD_01",
  "to_tenant_id": "UNIT_SMP_01",
  "effective_date": "2026-07-15",
  "force_logout_now": false,
  "reason": "Kenaikan kelas reguler tahun ajaran 2026/2027"
}
```

Response `202 Accepted` (async job):
```json
{
  "transition_id": "uuid-transition",
  "status": "SCHEDULED",
  "message": "Transisi dijadwalkan. Poll GET /admin/transition/:id untuk status."
}
```

GET Status Response:
```json
{
  "transition_id": "uuid-transition",
  "student_id": "uuid-student",
  "student_name": "Ahmad Fadhil",
  "from_tenant_id": "UNIT_SD_01",
  "to_tenant_id": "UNIT_SMP_01",
  "status": "COMPLETED",
  "executed_at": "2026-07-15T08:23:01Z",
  "snapshot_summary": {
    "tp_mastered_count": 47,
    "open_misconceptions": 2,
    "passport_letter_url": "/files/passport-letter-uuid.pdf"
  },
  "rollback_available_until": "2026-07-22T08:23:01Z"
}
```

POST Bulk Body:
```json
{
  "from_tenant_id": "UNIT_SD_01",
  "to_tenant_id": "UNIT_SMP_01",
  "student_ids": ["uuid-1", "uuid-2", "uuid-3"],
  "effective_date": "2026-07-15",
  "consent_assumption": "PRE_COLLECTED",
  "reason": "Kenaikan kelas SD→SMP tahun ajaran 2026/2027"
}
```

### 8.6 Audit Log

```
GET /api/v1/admin/audit?from=2026-05-01&to=2026-05-24&action=SYSTEM_CONFIG_CHANGE&risk_level=HIGH&page=1&per_page=50
GET /api/v1/admin/audit/export?from=...&to=...  # CSV, butuh consent log
```

Response `200 OK`:
```json
{
  "total": 1847,
  "page": 1,
  "per_page": 50,
  "items": [
    {
      "event_id": "uuid-event",
      "occurred_at": "2026-05-24T09:15:22Z",
      "actor_user_id": "uuid-admin",
      "actor_name": "Dewi Rahayu",
      "actor_role": "SUPERADMIN",
      "action": "SYSTEM_CONFIG_CHANGE",
      "target_id": "bkt.mastery_threshold",
      "reason": "Kalibrasi setelah pilot 2 bulan",
      "risk_level": "HIGH",
      "tenant_id": "YAYASAN_UTAMA",
      "ip_address": "192.168.1.10"
    }
  ]
}
```

### 8.7 Ops Health

```
GET /api/v1/admin/ops/health
```

Response `200 OK`:
```json
{
  "services": [
    { "name": "postgres", "status": "UP", "latency_ms": 4 },
    { "name": "neo4j", "status": "UP", "latency_ms": 12 },
    { "name": "ollama", "status": "DEGRADED", "latency_ms": 6800, "note": "GPU offload disabled" },
    { "name": "qdrant", "status": "UP", "latency_ms": 9 },
    { "name": "redis", "status": "UP", "latency_ms": 1 }
  ],
  "queues": [
    { "name": "modul_ajar_generation", "depth": 3 },
    { "name": "transition_jobs", "depth": 0 }
  ],
  "backup": {
    "last_success_at": "2026-05-23T02:01:00Z",
    "size_mb": 4823,
    "status": "OK"
  },
  "checked_at": "2026-05-24T10:00:00Z"
}
```

---

## 9. State Management

### 9.1 Auth Store (Zustand)

```tsx
// src/state/authStore.ts
import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface AuthState {
  userId: string | null;
  role: 'ADMIN_YAYASAN' | 'SUPERADMIN' | null;
  yayasanId: string | null;
  mfaAuthenticated: boolean;
  setFromToken: (claims: Record<string, unknown>) => void;
  clear: () => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      userId: null,
      role: null,
      yayasanId: null,
      mfaAuthenticated: false,
      setFromToken: (claims) =>
        set({
          userId: claims.sub as string,
          role: claims.aleta_role as AuthState['role'],
          yayasanId: claims.aleta_yayasan_id as string,
          mfaAuthenticated: claims.mfa_authenticated === true,
        }),
      clear: () => set({ userId: null, role: null, yayasanId: null, mfaAuthenticated: false }),
    }),
    { name: 'aleta-admin-auth' }
  )
);
```

### 9.2 ATP Builder Store (Zustand — react-flow state)

```tsx
// src/state/atpBuilderStore.ts
import { create } from 'zustand';
import { Node, Edge, applyNodeChanges, applyEdgeChanges, NodeChange, EdgeChange } from 'reactflow';

interface AtpBuilderState {
  nodes: Node[];
  edges: Edge[];
  isDirty: boolean;
  setNodes: (nodes: Node[]) => void;
  setEdges: (edges: Edge[]) => void;
  onNodesChange: (changes: NodeChange[]) => void;
  onEdgesChange: (changes: EdgeChange[]) => void;
  markDirty: () => void;
  markClean: () => void;
}

export const useAtpBuilderStore = create<AtpBuilderState>((set) => ({
  nodes: [],
  edges: [],
  isDirty: false,
  setNodes: (nodes) => set({ nodes }),
  setEdges: (edges) => set({ edges }),
  onNodesChange: (changes) =>
    set((state) => ({
      nodes: applyNodeChanges(changes, state.nodes),
      isDirty: true,
    })),
  onEdgesChange: (changes) =>
    set((state) => ({
      edges: applyEdgeChanges(changes, state.edges),
      isDirty: true,
    })),
  markDirty: () => set({ isDirty: true }),
  markClean: () => set({ isDirty: false }),
}));
```

### 9.3 UI Store (Zustand)

```tsx
// src/state/uiStore.ts
import { create } from 'zustand';

interface UiState {
  sidebarOpen: boolean;
  toggleSidebar: () => void;
  activeConfirmDialog: { title: string; onConfirm: (reason?: string) => void } | null;
  openConfirmDialog: (opts: UiState['activeConfirmDialog']) => void;
  closeConfirmDialog: () => void;
}

export const useUiStore = create<UiState>((set) => ({
  sidebarOpen: true,
  toggleSidebar: () => set((s) => ({ sidebarOpen: !s.sidebarOpen })),
  activeConfirmDialog: null,
  openConfirmDialog: (opts) => set({ activeConfirmDialog: opts }),
  closeConfirmDialog: () => set({ activeConfirmDialog: null }),
}));
```

### 9.4 TanStack Query: Query Keys & Polling

| Query | Key | Poll |
| :--- | :--- | :--- |
| Overview KPI | `['admin-overview']` | 60 000 ms |
| Ops Health | `['ops-health']` | 15 000 ms |
| Transition status | `['transition', id]` | 5 000 ms (self-stop saat done) |
| System Config | `['system-config']` | tidak di-poll (manual refetch) |
| Audit Log | `['audit-log', filters]` | tidak di-poll |

```tsx
// Ops Health dengan 15s polling
const { data: health } = useQuery({
  queryKey: ['ops-health'],
  queryFn: fetchOpsHealth,
  refetchInterval: 15_000,
  staleTime: 10_000,
});
```

---

## 10. TypeScript Interfaces

```tsx
// src/api/types.ts

export type ServiceStatus = 'UP' | 'DEGRADED' | 'DOWN';
export type RiskLevel = 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';
export type TransitionStatus = 'SCHEDULED' | 'EXECUTING' | 'COMPLETED' | 'FAILED' | 'ROLLED_BACK';
export type AdminRole = 'ADMIN_YAYASAN' | 'SUPERADMIN';

export interface KpiCard {
  label: string;
  value: number;
}

export interface OverviewData {
  academic_year: string;
  kpi_cards: KpiCard[];
  mastery_by_unit: Array<{ unit: string; avg_mastery: number }>;
  generated_at: string;
}

export interface SystemConfig {
  config_key: string;
  config_value: string | number | boolean;
  description?: string;
  updated_by_name?: string;
  updated_at?: string;
}

export interface ServiceHealth {
  name: string;
  status: ServiceStatus;
  latency_ms: number;
  note?: string;
}

export interface QueueInfo {
  name: string;
  depth: number;
}

export interface OpsHealthData {
  services: ServiceHealth[];
  queues: QueueInfo[];
  backup: { last_success_at: string; size_mb: number; status: string };
  checked_at: string;
}

export interface TransitionEvent {
  transition_id: string;
  student_id: string;
  student_name: string;
  from_tenant_id: string;
  to_tenant_id: string;
  status: TransitionStatus;
  executed_at?: string;
  snapshot_summary?: {
    tp_mastered_count: number;
    open_misconceptions: number;
    passport_letter_url?: string;
    error?: string;
  };
  rollback_available_until?: string;
}

export interface AuditEvent {
  event_id: string;
  occurred_at: string;
  actor_user_id: string;
  actor_name: string;
  actor_role: string;
  action: string;
  target_id?: string;
  reason?: string;
  risk_level: RiskLevel;
  tenant_id: string;
  ip_address?: string;
}

export interface TpNode {
  tp_id: string;
  competency: string;
  content: string;
  bloom_level: number;
  derived_from_cp_id: string;
  prerequisites: string[];
  may_trigger_misconceptions: string[];
}

export interface AtpPositionEntry {
  tp_id: string;
  position: number;
  week: number;
}
```

---

## 11. Code Stubs — Komponen Utama

### 11.1 API Client

```tsx
// src/api/apiClient.ts
import axios, { AxiosInstance } from 'axios';

let _getAccessToken: (() => string | null) | null = null;

export function setTokenGetter(fn: () => string | null) {
  _getAccessToken = fn;
}

export const apiClient: AxiosInstance = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL,
  timeout: 30_000,
});

apiClient.interceptors.request.use((config) => {
  const token = _getAccessToken?.();
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

apiClient.interceptors.response.use(
  (res) => res,
  async (error) => {
    if (error.response?.status === 403) {
      window.location.href = '/error/forbidden';
    }
    return Promise.reject(error);
  }
);
```

### 11.2 KpiOverviewGrid — Recharts

```tsx
// src/components/organisms/KpiOverviewGrid.tsx
import { useQuery } from '@tanstack/react-query';
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer } from 'recharts';
import { KpiCard } from '../atoms/KpiCard';
import { apiClient } from '../../api/apiClient';
import type { OverviewData } from '../../api/types';

async function fetchOverview(): Promise<OverviewData> {
  const { data } = await apiClient.get('/admin/yayasan/overview');
  return data;
}

export function KpiOverviewGrid() {
  const { data, isLoading } = useQuery({
    queryKey: ['admin-overview'],
    queryFn: fetchOverview,
    refetchInterval: 60_000,
  });

  if (isLoading) return <div role="status" aria-live="polite">Memuat KPI...</div>;

  return (
    <section aria-labelledby="kpi-heading">
      <h2 id="kpi-heading" className="text-xl font-semibold mb-4">
        KPI Yayasan — {data?.academic_year}
      </h2>

      <div className="grid grid-cols-2 gap-4 md:grid-cols-4 mb-8">
        {data?.kpi_cards.map((card) => (
          <KpiCard key={card.label} label={card.label} value={card.value} />
        ))}
      </div>

      <div className="bg-white rounded-lg p-4 shadow-sm">
        <h3 className="text-sm font-medium text-gray-600 mb-3">Rata-rata Mastery per Unit</h3>
        <ResponsiveContainer width="100%" height={200}>
          <BarChart data={data?.mastery_by_unit}>
            <XAxis dataKey="unit" tick={{ fontSize: 12 }} />
            <YAxis domain={[0, 1]} tickFormatter={(v) => `${Math.round(v * 100)}%`} />
            <Tooltip formatter={(v: number) => [`${Math.round(v * 100)}%`, 'Avg Mastery']} />
            <Bar dataKey="avg_mastery" fill="var(--color-primary)" radius={[4, 4, 0, 0]} />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </section>
  );
}
```

### 11.3 OpsHealthPanel

```tsx
// src/components/organisms/OpsHealthPanel.tsx
import { useQuery } from '@tanstack/react-query';
import { StatusBadge } from '../atoms/StatusBadge';
import { apiClient } from '../../api/apiClient';
import type { OpsHealthData } from '../../api/types';

async function fetchOpsHealth(): Promise<OpsHealthData> {
  const { data } = await apiClient.get('/admin/ops/health');
  return data;
}

export function OpsHealthPanel() {
  const { data } = useQuery({
    queryKey: ['ops-health'],
    queryFn: fetchOpsHealth,
    refetchInterval: 15_000,
    staleTime: 10_000,
  });

  const hasDown = data?.services.some((s) => s.status === 'DOWN');
  const hasDegraded = data?.services.some((s) => s.status === 'DEGRADED');

  return (
    <section aria-labelledby="ops-heading">
      <div className="flex items-center justify-between mb-4">
        <h2 id="ops-heading" className="text-xl font-semibold">Status Sistem</h2>
        {hasDown && (
          <a
            href="/docs/incidents/runbook.md"
            target="_blank"
            rel="noopener noreferrer"
            className="text-sm text-red-600 underline"
          >
            Buka Runbook Insiden
          </a>
        )}
      </div>

      <div className="space-y-2">
        {data?.services.map((svc) => (
          <div
            key={svc.name}
            className="flex items-center justify-between rounded-lg bg-white p-3 shadow-sm"
            role="row"
          >
            <span className="font-mono text-sm">{svc.name}</span>
            <div className="flex items-center gap-4">
              <span className="text-xs text-gray-500">{svc.latency_ms} ms</span>
              <StatusBadge status={svc.status} />
            </div>
            {svc.note && (
              <span className="text-xs text-amber-600 ml-2">{svc.note}</span>
            )}
          </div>
        ))}
      </div>

      <div className="mt-4 grid grid-cols-2 gap-4">
        {data?.queues.map((q) => (
          <div key={q.name} className="bg-white rounded-lg p-3 shadow-sm">
            <p className="text-xs text-gray-500">{q.name}</p>
            <p className="text-2xl font-bold">{q.depth}</p>
            <p className="text-xs text-gray-400">item dalam antrian</p>
          </div>
        ))}
      </div>

      {data?.backup && (
        <div className="mt-4 bg-white rounded-lg p-3 shadow-sm text-sm">
          Backup terakhir:{' '}
          <span className="font-medium">
            {new Date(data.backup.last_success_at).toLocaleString('id-ID')}
          </span>{' '}
          — {data.backup.size_mb.toLocaleString()} MB
        </div>
      )}
    </section>
  );
}
```

### 11.4 ATP Builder Canvas — react-flow

```tsx
// src/components/organisms/AtpBuilderCanvas.tsx
import ReactFlow, {
  Background,
  Controls,
  MiniMap,
  Panel,
} from 'reactflow';
import 'reactflow/dist/style.css';
import { useAtpBuilderStore } from '../../state/atpBuilderStore';

type Props = {
  onSave: () => void;
  isSaving: boolean;
};

export function AtpBuilderCanvas({ onSave, isSaving }: Props) {
  const { nodes, edges, onNodesChange, onEdgesChange, isDirty } = useAtpBuilderStore();

  return (
    <div className="h-[70vh] w-full rounded-xl border border-gray-200 overflow-hidden">
      <ReactFlow
        nodes={nodes}
        edges={edges}
        onNodesChange={onNodesChange}
        onEdgesChange={onEdgesChange}
        fitView
        aria-label="ATP Builder — seret node untuk mengatur urutan TP"
      >
        <Background />
        <Controls />
        <MiniMap />
        <Panel position="top-right">
          {isDirty && (
            <button
              onClick={onSave}
              disabled={isSaving}
              className="bg-primary text-white px-4 py-2 rounded-lg text-sm font-medium disabled:opacity-50"
              aria-label="Simpan susunan ATP"
            >
              {isSaving ? 'Menyimpan...' : 'Simpan Susunan ATP'}
            </button>
          )}
        </Panel>
      </ReactFlow>
    </div>
  );
}
```

### 11.5 Audit Log Table — @tanstack/react-table

```tsx
// src/components/organisms/AuditLogTable.tsx
import {
  useReactTable,
  getCoreRowModel,
  flexRender,
  createColumnHelper,
} from '@tanstack/react-table';
import { RiskBadge } from '../atoms/RiskBadge';
import type { AuditEvent } from '../../api/types';

const ch = createColumnHelper<AuditEvent>();

const columns = [
  ch.accessor('occurred_at', {
    header: 'Waktu',
    cell: (info) => new Date(info.getValue()).toLocaleString('id-ID'),
  }),
  ch.accessor('actor_name', { header: 'Aktor' }),
  ch.accessor('actor_role', { header: 'Peran' }),
  ch.accessor('action', { header: 'Aksi', cell: (info) => <code className="text-xs">{info.getValue()}</code> }),
  ch.accessor('target_id', { header: 'Target' }),
  ch.accessor('risk_level', {
    header: 'Risiko',
    cell: (info) => <RiskBadge level={info.getValue()} />,
  }),
  ch.accessor('reason', { header: 'Alasan', cell: (info) => info.getValue() ?? '—' }),
];

type Props = { data: AuditEvent[] };

export function AuditLogTable({ data }: Props) {
  const table = useReactTable({
    data,
    columns,
    getCoreRowModel: getCoreRowModel(),
  });

  return (
    <div className="overflow-x-auto rounded-lg border border-gray-200">
      <table className="min-w-full text-sm" role="table" aria-label="Audit Log Events">
        <thead className="bg-gray-50">
          {table.getHeaderGroups().map((hg) => (
            <tr key={hg.id}>
              {hg.headers.map((h) => (
                <th
                  key={h.id}
                  className="px-4 py-2 text-left font-semibold text-gray-600"
                  scope="col"
                >
                  {flexRender(h.column.columnDef.header, h.getContext())}
                </th>
              ))}
            </tr>
          ))}
        </thead>
        <tbody className="divide-y divide-gray-100">
          {table.getRowModel().rows.map((row) => (
            <tr key={row.id} className="hover:bg-gray-50">
              {row.getVisibleCells().map((cell) => (
                <td key={cell.id} className="px-4 py-2 text-gray-700">
                  {flexRender(cell.column.columnDef.cell, cell.getContext())}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
```

### 11.6 System Config Page — dengan SuperAdminGuard

```tsx
// src/pages/SystemConfigPage.tsx
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { SuperAdminGuard } from '../auth/SuperAdminGuard';
import { ConfirmDialog } from '../components/atoms/ConfirmDialog';
import { apiClient } from '../api/apiClient';
import type { SystemConfig } from '../api/types';
import { useState } from 'react';

async function fetchConfigs(): Promise<SystemConfig[]> {
  const { data } = await apiClient.get('/admin/system/config');
  return data;
}

export function SystemConfigPage() {
  const queryClient = useQueryClient();
  const { data: configs } = useQuery({ queryKey: ['system-config'], queryFn: fetchConfigs });
  const [pendingChange, setPendingChange] = useState<{ key: string; newValue: unknown } | null>(null);

  const saveMutation = useMutation({
    mutationFn: (payload: { config_key: string; config_value: unknown; reason: string }) =>
      apiClient.patch('/admin/system/config', payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['system-config'] });
      setPendingChange(null);
    },
    onError: () => {
      alert('Gagal menyimpan konfigurasi. Coba lagi.');
    },
  });

  return (
    <main aria-labelledby="syscfg-heading">
      <h1 id="syscfg-heading" className="text-2xl font-bold mb-6">Konfigurasi Sistem</h1>

      <SuperAdminGuard
        fallback={
          <div role="alert" className="bg-amber-50 border border-amber-200 rounded-lg p-4 text-sm text-amber-800">
            Anda memiliki hak baca saja. Ubah konfigurasi sistem membutuhkan akses SUPERADMIN.
          </div>
        }
      >
        <p className="text-sm text-red-600 mb-4">
          Perubahan konfigurasi bersifat global dan langsung aktif. Setiap perubahan dicatat di audit log.
        </p>
      </SuperAdminGuard>

      <div className="space-y-2">
        {configs?.map((cfg) => (
          <div key={cfg.config_key} className="bg-white rounded-lg p-4 shadow-sm flex items-center justify-between">
            <div>
              <code className="text-sm font-mono text-gray-800">{cfg.config_key}</code>
              <p className="text-xs text-gray-500 mt-0.5">{cfg.description}</p>
              {cfg.updated_by_name && (
                <p className="text-xs text-gray-400 mt-0.5">
                  Diubah oleh {cfg.updated_by_name} — {new Date(cfg.updated_at!).toLocaleDateString('id-ID')}
                </p>
              )}
            </div>
            <div className="flex items-center gap-3">
              <code className="bg-gray-100 px-2 py-1 rounded text-sm font-bold">{String(cfg.config_value)}</code>
              <SuperAdminGuard>
                <button
                  onClick={() => setPendingChange({ key: cfg.config_key, newValue: cfg.config_value })}
                  className="text-sm text-primary underline"
                  aria-label={`Ubah ${cfg.config_key}`}
                >
                  Ubah
                </button>
              </SuperAdminGuard>
            </div>
          </div>
        ))}
      </div>

      {pendingChange && (
        <ConfirmDialog
          title={`Ubah ${pendingChange.key}?`}
          description="Perubahan ini bersifat global dan langsung aktif untuk semua siswa dan sesi yang sedang berjalan."
          requireReason
          destructive
          onConfirm={(reason) =>
            saveMutation.mutate({
              config_key: pendingChange.key,
              config_value: pendingChange.newValue,
              reason: reason!,
            })
          }
          onCancel={() => setPendingChange(null)}
        />
      )}
    </main>
  );
}
```

### 11.7 TransitionWizard — Individual Transition

```tsx
// src/components/organisms/TransitionWizard.tsx
import { useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { apiClient } from '../../api/apiClient';
import type { TransitionEvent } from '../../api/types';

type Step = 'form' | 'confirm' | 'polling';

export function TransitionWizard() {
  const [step, setStep] = useState<Step>('form');
  const [transitionId, setTransitionId] = useState<string | null>(null);

  const submitMutation = useMutation({
    mutationFn: (payload: {
      student_id: string;
      from_tenant_id: string;
      to_tenant_id: string;
      effective_date: string;
      force_logout_now: boolean;
      reason: string;
    }) => apiClient.post('/admin/transition', payload).then((r) => r.data),
    onSuccess: (data: { transition_id: string }) => {
      setTransitionId(data.transition_id);
      setStep('polling');
    },
  });

  const { data: transitionStatus } = useQuery({
    queryKey: ['transition', transitionId],
    queryFn: () =>
      apiClient.get<TransitionEvent>(`/admin/transition/${transitionId}`).then((r) => r.data),
    enabled: step === 'polling' && !!transitionId,
    refetchInterval: (data) => {
      const terminal = ['COMPLETED', 'FAILED', 'ROLLED_BACK'];
      return data && terminal.includes(data.status) ? false : 5_000;
    },
  });

  if (step === 'polling') {
    return (
      <div aria-live="polite" aria-atomic="true">
        <TransitionStatusDisplay transition={transitionStatus} />
      </div>
    );
  }

  return (
    <TransitionFormView
      onSubmit={(formData) => submitMutation.mutate(formData)}
      isSubmitting={submitMutation.isPending}
    />
  );
}
```

### 11.8 ConfirmDialog — Destructive Action Safeguard

```tsx
// src/components/atoms/ConfirmDialog.tsx
import { useState } from 'react';
import { Dialog } from '@headlessui/react';

type Props = {
  title: string;
  description: string;
  requireReason?: boolean;
  destructive?: boolean;
  onConfirm: (reason?: string) => void;
  onCancel: () => void;
};

export function ConfirmDialog({
  title,
  description,
  requireReason = false,
  destructive = false,
  onConfirm,
  onCancel,
}: Props) {
  const [reason, setReason] = useState('');
  const canSubmit = !requireReason || reason.trim().length >= 10;

  return (
    <Dialog open onClose={onCancel} className="fixed inset-0 z-50 flex items-center justify-center">
      <div className="fixed inset-0 bg-black/30" aria-hidden="true" />
      <Dialog.Panel className="relative bg-white rounded-xl p-6 max-w-md w-full mx-4 shadow-xl">
        <Dialog.Title className="text-lg font-bold mb-2">{title}</Dialog.Title>
        <p className="text-sm text-gray-600 mb-4">{description}</p>

        {requireReason && (
          <div className="mb-4">
            <label htmlFor="reason" className="block text-sm font-medium text-gray-700 mb-1">
              Alasan perubahan (min. 10 karakter)
            </label>
            <textarea
              id="reason"
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:ring-2 focus:ring-primary"
              rows={3}
              placeholder="Jelaskan alasan perubahan ini..."
            />
          </div>
        )}

        <div className="flex justify-end gap-3">
          <button
            onClick={onCancel}
            className="px-4 py-2 text-sm text-gray-600 hover:text-gray-800"
          >
            Batal
          </button>
          <button
            onClick={() => onConfirm(requireReason ? reason : undefined)}
            disabled={!canSubmit}
            className={`px-4 py-2 text-sm font-medium rounded-lg text-white disabled:opacity-50 ${
              destructive ? 'bg-red-600 hover:bg-red-700' : 'bg-primary hover:bg-primary/90'
            }`}
          >
            {destructive ? 'Ya, Lanjutkan' : 'Konfirmasi'}
          </button>
        </div>
      </Dialog.Panel>
    </Dialog>
  );
}
```

### 11.9 StatusBadge & RiskBadge

```tsx
// src/components/atoms/StatusBadge.tsx
import type { ServiceStatus } from '../../api/types';

const styleMap: Record<ServiceStatus, string> = {
  UP: 'bg-green-100 text-green-800',
  DEGRADED: 'bg-amber-100 text-amber-800',
  DOWN: 'bg-red-100 text-red-800',
};

export function StatusBadge({ status }: { status: ServiceStatus }) {
  return (
    <span
      className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${styleMap[status]}`}
      aria-label={`Status: ${status}`}
    >
      {status}
    </span>
  );
}

// src/components/atoms/RiskBadge.tsx
import type { RiskLevel } from '../../api/types';

const riskStyle: Record<RiskLevel, string> = {
  LOW: 'bg-gray-100 text-gray-600',
  MEDIUM: 'bg-blue-100 text-blue-700',
  HIGH: 'bg-amber-100 text-amber-800',
  CRITICAL: 'bg-red-100 text-red-800 font-bold',
};

export function RiskBadge({ level }: { level: RiskLevel }) {
  return (
    <span
      className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs ${riskStyle[level]}`}
      aria-label={`Risk level: ${level}`}
    >
      {level}
    </span>
  );
}
```

### 11.10 tailwind.config.ts

```ts
// tailwind.config.ts
import type { Config } from 'tailwindcss';
import tokens from '@aleta/tokens/dist/tokens.json';

export default {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        primary: tokens.color.brand.primary.value,
        secondary: tokens.color.brand.secondary.value,
        error: tokens.color.semantic.error.value,
        success: tokens.color.semantic.success.value,
        surface: tokens.color.surface.default.value,
      },
      fontFamily: {
        sans: [tokens.typography.fontFamily.sans.value, 'sans-serif'],
      },
    },
  },
  plugins: [],
} satisfies Config;
```

---

## 12. Aksesibilitas & WCAG 2.2 AA

### 12.1 Persyaratan Minimum

- Semua interactive elements minimum 44dp × 44dp touch target.
- Color contrast ratio ≥ 4.5:1 untuk teks normal, ≥ 3:1 untuk teks besar dan UI components.
- Semua status operasional (UP/DEGRADED/DOWN, HIGH/CRITICAL) tidak boleh bergantung hanya pada warna — harus ada teks label atau ikon.
- Semua tabel harus punya `role="table"`, header `scope="col"`, dan `aria-label`.
- Loading state harus `role="status"` dan `aria-live="polite"`.
- Dialog/modal: fokus harus dikembalikan ke trigger saat dialog ditutup.

### 12.2 axe-core Setup (Dev + CI)

```tsx
// src/main.tsx — dev only
if (import.meta.env.DEV) {
  const axe = await import('@axe-core/react');
  axe.default(React, ReactDOM, 1000);
}
```

### 12.3 Keyboard Navigation

| Komponen | Behaviour |
| :--- | :--- |
| ATP Builder Canvas | `Tab` untuk fokus node, `Arrow` untuk geser posisi, `Enter` untuk edit label |
| Audit Log Table | `Tab` melalui baris, `Space`/`Enter` untuk buka detail |
| ConfirmDialog | `Esc` untuk tutup (kecuali `destructive=true` — harus klik tombol) |
| Nav Sidebar | `Tab`/`Shift+Tab`, semua link accessible |

---

## 13. Acceptance Criteria & Release Gate Checklist

### 13.1 Setup & Build

- [ ] `npm run dev` berjalan di port 5175 tanpa error
- [ ] `npm run build` sukses, `dist/` terbentuk
- [ ] `npm run typecheck` zero error
- [ ] `npm run lint` zero error

### 13.2 Authentication & MFA Gate

- [ ] Login dengan Keycloak OIDC berhasil (redirect → callback → dashboard)
- [ ] Akun dengan role `GURU` menerima `403 Forbidden` page setelah login
- [ ] Akun dengan MFA belum diselesaikan diarahkan ke MFA required page
- [ ] `ADMIN_YAYASAN` tidak dapat melihat atau mengakses tombol "Ubah" di SystemConfigPage
- [ ] `SUPERADMIN` dapat melihat dan mengakses tombol "Ubah" di SystemConfigPage

### 13.3 Overview KPI

- [ ] KPI cards menampilkan 4 nilai dari `GET /admin/yayasan/overview`
- [ ] Bar chart mastery per unit render dengan label unit dan persentase
- [ ] Auto-refresh berjalan setiap 60 detik (verifikasi dengan Network tab)
- [ ] Tidak ada nilai threshold hardcoded (0.85, 0.20) di source code React

### 13.4 Curriculum Editor

- [ ] Form editor TP menampilkan semua field (competency, bloom_level, prerequisites, misconceptions)
- [ ] Save sukses: toast konfirmasi + query invalidate
- [ ] Save saat Neo4j error: pesan error eksplisit "rollback terjadi", tidak ada retry otomatis
- [ ] Setiap save menghasilkan baris `audit_events` (verifikasi di Audit Log page)

### 13.5 ATP Builder

- [ ] react-flow canvas render nodes TP dari GET ATP
- [ ] Drag-drop node mengubah posisi dan mengaktifkan state `isDirty`
- [ ] Tombol "Simpan" hanya muncul saat `isDirty === true`
- [ ] Setelah save, reload halaman mempertahankan susunan ATP yang disimpan (snapshot test)

### 13.6 Transisi Siswa

- [ ] Form individual transition mengirim `POST /admin/transition` dengan `reason` field
- [ ] Setelah submit, UI beralih ke polling mode
- [ ] Polling berhenti otomatis saat status `COMPLETED` atau `FAILED`
- [ ] Status `COMPLETED` menampilkan link download Cognitive Passport Letter
- [ ] Rollback button muncul hanya jika `rollback_available_until` > sekarang
- [ ] Rollback memerlukan ConfirmDialog dengan reason field
- [ ] Bulk transition: progress bar menampilkan N dari total selesai

### 13.7 System Config

- [ ] Semua key-value dari backend ditampilkan dengan deskripsi
- [ ] Klik "Ubah" → ConfirmDialog muncul dengan kolom reason (min 10 karakter)
- [ ] Submit ConfirmDialog → PATCH dikirim dengan payload `{ config_key, config_value, reason }`
- [ ] Perubahan tercatat di Audit Log dengan `action: SYSTEM_CONFIG_CHANGE`, `risk_level: HIGH`

### 13.8 Audit Log

- [ ] Table menampilkan data dari GET `/admin/audit` dengan pagination
- [ ] Filter by `risk_level=HIGH` menampilkan hanya event HIGH
- [ ] Filter by `action=SYSTEM_CONFIG_CHANGE` menampilkan hanya event tersebut
- [ ] CSV export hanya tersedia setelah ConfirmDialog disetujui
- [ ] CSV export menghasilkan baris `audit_events` dengan `action=AUDIT_EXPORT`

### 13.9 Ops Health Panel

- [ ] Panel auto-refresh setiap 15 detik
- [ ] Service `status=DOWN` menampilkan badge merah + link "Buka Runbook Insiden"
- [ ] Service `status=DEGRADED` menampilkan badge kuning
- [ ] Queue depth ditampilkan per nama queue
- [ ] Backup last success date dan ukuran ditampilkan

### 13.10 Aksesibilitas

- [ ] `npm run test:a11y` zero violations pada semua page utama
- [ ] Semua status badge (UP/DEGRADED/DOWN, LOW/HIGH/CRITICAL) memiliki label teks, bukan hanya warna
- [ ] ConfirmDialog: `Esc` tidak menutup dialog dengan `destructive=true`
- [ ] ATP Builder canvas: node dapat difokus dengan keyboard
- [ ] Kontras warna 4.5:1 pada semua teks (verifikasi dengan axe-core)

### 13.11 Aturan Pra-Commit

- [ ] `grep -r "0\.85\|0\.20\|0\.70" src/` tidak menghasilkan match (tidak ada threshold hardcoded)
- [ ] `grep -r "student_id.*log\|pii\|name.*student" src/` tidak ada string PII dalam request body
- [ ] Setiap `useMutation` untuk aksi destruktif menyertakan `reason` field dalam payload

---

*PRD ini adalah dokumen tunggal untuk vibe coding Admin Yayasan Dashboard ALETA. Baca bersama `11_ADMIN_YAYASAN_DASHBOARD.md`, `12_CROSS_JENJANG_TRANSITION.md`, `07_SECURITY_PRIVACY_PASSPORT.md`, dan `04_BACKEND_API_CONTRACTS.md` untuk konteks sistem lengkap.*
