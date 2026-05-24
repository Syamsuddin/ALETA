---
doc: "PRD-03"
title: "PRD Teacher Dashboard"
type: "product-requirements-document"
version: "1.0"
status: "approved"
app: "Teacher Dashboard (React Web)"
authored: "2026-05-24"
blueprints_consumed: ["04", "06", "07", "09", "14", "15"]
vibe_coding_target: "web-coder, backend-coder"
tasks_covered: [T-401, T-402, T-403, T-404, T-405, T-406, T-407, T-408, T-409, T-410, T-411]
---

# PRD — ALETA Teacher Dashboard

### AI Co-Pilot for Differentiated Teaching · React Web App · Role: `GURU`

> **Petunjuk untuk AI agent:** Dokumen ini adalah panduan tunggal membangun Teacher Dashboard dari nol. Stack: React 18 + TypeScript + Vite + TanStack Query + Zustand + Tailwind CSS. Baca §1–§13 urut. Semua nilai sentinel FINAL dari `STATE.yaml.sentinels`. Red flag logic HANYA di backend — frontend hanya render array dari API response.

---

## DAFTAR ISI

| § | Judul | Isi Kunci |
|---|-------|-----------|
| 1 | Product Overview | Visi, scope, exclusions |
| 2 | User Personas | Profil guru per konteks mengajar |
| 3 | Goals & Success Metrics | KPI dan acceptance criteria |
| 4 | Information Architecture | Sitemap & navigation rules |
| 5 | UI/UX Design System | Tokens PRO_DASHBOARD, komponen React |
| 6 | Page Specifications | Detail setiap halaman |
| 7 | Red Flag & Differentiation Logic | Aturan visualisasi data kognitif |
| 8 | API Contracts | Semua endpoint teacher |
| 9 | Technical Architecture | React stack, folder, auth wiring |
| 10 | State Management | TanStack Query + Zustand contracts |
| 11 | Non-Functional Requirements | Performa, keamanan, aksesibilitas |
| 12 | Implementation Task Map | Pemetaan ke T-NNN |
| 13 | Acceptance Criteria Checklist | Definition of Done per fitur |

---

## §1 — PRODUCT OVERVIEW

### 1.1 Visi Produk

Teacher Dashboard adalah **AI Co-Pilot** guru ALETA — aplikasi web yang mengubah ribuan log kuis siswa menjadi **rekomendasi taktis siap pakai** sebelum guru masuk kelas. Filosofi inti: **"Data-Driven, Action-Oriented"** — bukan grafik kompleks yang membingungkan, melainkan instruksi langsung: "Hari ini dudukkan 6 anak di meja Fondasi, berikan kartu peraga bilangan bulat."

Selain analitik kelas, dashboard ini menyediakan generator **Modul Ajar otomatis** berbasis Local LLM yang menghasilkan draf Modul Ajar berformat Kurikulum Merdeka dalam hitungan detik — membebaskan guru dari pekerjaan administrasi berjam-jam.

### 1.2 Scope (Dalam Cakupan)

| Fitur | Deskripsi |
|-------|-----------|
| Login & MFA | Keycloak OIDC, JWT RS256, MFA wajib untuk role `GURU` |
| Morning Briefing | Rekomendasi taktis harian per kelas sebelum jam pelajaran |
| Class Overview | Peta diferensiasi 3 zona + red flag alert |
| Student Detail | Paspor kognitif individu siswa (read-only) |
| Modul Ajar Generator | Generate → polling → preview → download Modul Ajar Kurikulum Merdeka |
| Class Selector | Guru multi-kelas: pilih kelas aktif dengan dropdown |
| Settings & Profile | Preferensi notifikasi, tampilan kelas default |

### 1.3 Exclusions (Di Luar Cakupan)

- Mengubah jalur belajar siswa secara manual (hanya AI engine yang mengubah)
- Membuat atau mengedit TP/CP/ATP (Admin Yayasan Dashboard)
- Akses ke transkrip sesi tutor siswa
- Komunikasi langsung dengan orang tua (roadmap Tahun 3)
- Push notification di browser (roadmap Tahun 2)
- Red flag calculation logic — ini **murni backend**, dashboard hanya render hasil

---

## §2 — USER PERSONAS

### 2.1 Guru Kelas Tunggal (Mayoritas)

| Atribut | Detail |
|---------|--------|
| Konteks | Mengajar 1–2 mata pelajaran di 2–4 kelas |
| Rutinitas | Membuka dashboard 5–10 menit sebelum masuk kelas |
| Kebutuhan utama | "Siapa yang perlu perhatian hari ini? Kelompok mana yang duduk bersama?" |
| Pain point | Tidak ingin baca data mentah — butuh rekomendasi langsung |
| Literasi digital | Menengah — terbiasa Google Classroom, WhatsApp |
| Ekspektasi UI | Bersih, cepat dimuat (< 2 detik), bisa dipakai di tablet |

### 2.2 Guru Senior / Koordinator Kurikulum

| Atribut | Detail |
|---------|--------|
| Konteks | Mengajar + mengawasi konsistensi kurikulum lintas kelas |
| Kebutuhan tambahan | Modul Ajar generator, analitik tren per TP |
| Ekspektasi | Preview dan edit modul ajar hasil AI sebelum digunakan |

### 2.3 Guru Wali Kelas

| Atribut | Detail |
|---------|--------|
| Konteks | Bertanggung jawab atas monitoring sosio-emosional siswa |
| Kebutuhan tambahan | Red flag sosio-emosional + saran intervensi empatik |
| Akses consent | Dapat mengajukan consent request ke orang tua melalui sistem |

---

## §3 — GOALS & SUCCESS METRICS

### 3.1 Product Goals

1. **Time-to-insight:** Guru mendapat rekomendasi diferensiasi kelas dalam < 30 detik setelah login.
2. **Modul Ajar adoption:** ≥ 60% guru pilot menggunakan generator modul ajar minimal 1× per minggu.
3. **Red flag response rate:** ≥ 80% siswa red flag mendapat intervensi guru (dicatat via refleksi) dalam 2 hari.
4. **Zero unauthorized access:** Guru tidak dapat mengakses data kelas yang bukan amanahnya.

### 3.2 Acceptance Criteria (Launch-Ready)

- [ ] Login + MFA → Dashboard dalam < 2 detik
- [ ] `dashboard/summary` polling setiap 30 detik, update tanpa page reload
- [ ] Red flag badge muncul di sidebar dan halaman Overview secara real-time
- [ ] Modul Ajar generator: submit → polling → preview dalam < 60 detik
- [ ] Guru hanya bisa akses `class_id` yang ada di `teaching_assignments` miliknya
- [ ] MFA divalidasi di setiap sesi baru (bukan hanya login pertama)
- [ ] WCAG 2.2 AA lulus (axe-core)
- [ ] Tidak ada Tailwind class warna mentah di komponen — semua melalui token

---

## §4 — INFORMATION ARCHITECTURE

### 4.1 Sitemap

```
Teacher Dashboard (React Web)
│
├── /login                    ← LoginPage (+ MFA step)
│
└── / (AppShell)              ← Layout: Sidebar + TopBar + main content
    │
    ├── /dashboard            ← MorningBriefingPage (default setelah login)
    │
    ├── /class/:classId       ← ClassOverviewPage
    │   └── /class/:classId/student/:studentId ← StudentDetailPage
    │
    ├── /modul-ajar           ← ModulAjarPage
    │   └── /modul-ajar/:draftId ← ModulAjarPreviewPage
    │
    └── /settings             ← SettingsPage
```

### 4.2 Navigation Rules

| Kondisi | Aksi |
|---------|------|
| Token tidak ada / expired | Redirect ke `/login` |
| Login sukses, role `GURU` | Redirect ke `/dashboard` |
| Login sukses, role bukan `GURU` | Error toast `AUTHZ_WRONG_APP` + tetap di `/login` |
| Akses `class_id` yang bukan milik guru | API return `403 AUTHZ_NOT_TEACHER` → tampilkan `ErrorPage` |
| MFA belum selesai | Block routing sampai MFA terpenuhi |
| `morning-briefing` data belum siap | Tampilkan skeleton + pesan "Data sedang dikompilasi..." |

### 4.3 Sidebar Navigation

```
[Logo ALETA]
─────────────────
📋  Briefing Pagi     → /dashboard
🏫  Kelas Saya        → expand dropdown kelas
    └─ Kelas 7-A      → /class/{id}
    └─ Kelas 8-B      → /class/{id}
📄  Modul Ajar        → /modul-ajar
─────────────────
⚙️  Pengaturan        → /settings
👤  [Nama Guru]
```

Red flag badge (merah) muncul di item "Kelas Saya" jika ada kelas dengan `system_red_flags.length > 0`.

---

## §5 — UI/UX DESIGN SYSTEM

### 5.1 Theme

Teacher Dashboard **selalu** `PRO_DASHBOARD` — konsisten dengan semua surface non-siswa.

| Atribut | Nilai |
|---------|-------|
| Font | Inter |
| Background | `#FFFFFF` |
| Surface | `#F8FAFC` |
| Primary | `#0F172A` (Slate 900) |
| Accent | `#0EA5E9` (Sky 500) |
| Animasi | Minimal — transisi 200ms |

### 5.2 Design Tokens (Tailwind Config)

File: `infrastructure/design_tokens/aleta.tokens.json` → export TypeScript via Style Dictionary → dikonsumsi di `tailwind.config.ts`.

```typescript
// teacher_dashboard_web/tailwind.config.ts
import tokens from '../../packages/tokens/dist/index';

export default {
  content: ['./src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        primary:    tokens.color.proDashboard.primary,    // '#0F172A'
        onPrimary:  tokens.color.proDashboard.onPrimary,  // '#F8FAFC'
        secondary:  tokens.color.proDashboard.secondary,  // '#0EA5E9'
        background: tokens.color.proDashboard.background, // '#FFFFFF'
        surface:    tokens.color.proDashboard.surface,    // '#F8FAFC'
        success:    tokens.color.proDashboard.success,    // '#16A34A'
        warning:    tokens.color.proDashboard.warning,    // '#D97706'
        error:      tokens.color.proDashboard.error,      // '#DC2626'
        redFlag:    tokens.color.proDashboard.redFlag,    // '#BE123C'
        textHigh:   tokens.color.proDashboard.textHigh,   // '#0F172A'
        textMid:    tokens.color.proDashboard.textMid,    // '#475569'
        textLow:    tokens.color.proDashboard.textLow,    // '#94A3B8'
      },
      fontFamily: {
        sans: [tokens.typography.fontFamily.proDashboard, 'system-ui', 'sans-serif'],
      },
      borderRadius: {
        card:   `${tokens.radius.proDashboard.card}px`,   // 12px
        btn:    `${tokens.radius.proDashboard.button}px`, // 8px
        input:  `${tokens.radius.proDashboard.input}px`,  // 6px
      },
    },
  },
};
```

**Aturan wajib:**
- Tidak ada warna Tailwind bawaan (`bg-red-500`, `text-blue-600`) langsung di komponen
- Semua warna via kelas token: `bg-error`, `text-textMid`, `border-surface`
- Spacing kelipatan 4: `p-1` (4px), `p-2` (8px), `p-4` (16px), `p-6` (24px), `p-8` (32px)

### 5.3 Warna Semantik Zona Diferensiasi

| Zona | Warna token | Tailwind class | Makna |
|------|-------------|----------------|-------|
| Fondasi | `error` `#DC2626` | `bg-error/10 border-error/30 text-error` | Perlu pendampingan langsung |
| Reguler | `secondary` `#0EA5E9` | `bg-secondary/10 border-secondary/30 text-secondary` | Belajar mandiri kolaboratif |
| Mahir | `success` `#16A34A` | `bg-success/10 border-success/30 text-success` | Pengayaan / tutor sebaya |
| Red Flag | `redFlag` `#BE123C` | `bg-redFlag/10 border-redFlag/50 text-redFlag` | Intervensi empatik guru |

### 5.4 Component Inventory

#### Atoms

| Komponen | Variants | States |
|----------|----------|--------|
| `Button` | `primary`, `secondary`, `ghost`, `destructive`, `icon` | default, hover, loading, disabled |
| `Badge` | `count`, `status` | success, warning, error, redFlag |
| `Input` | `text`, `search`, `select` | default, focus, error, disabled |
| `Spinner` | `sm`, `md`, `lg` | — |
| `Skeleton` | `text`, `block`, `circle` | shimmer |
| `Tag` | `zona`, `fase`, `risk` | default |
| `Tooltip` | — | hidden, visible |

#### Molecules

| Komponen | Deskripsi |
|----------|-----------|
| `ZoneCard` | Kartu zona diferensiasi (Fondasi/Reguler/Mahir) dengan jumlah siswa + persentase |
| `RedFlagItem` | Item siswa yang membutuhkan intervensi dengan alasan + saran tindakan |
| `StudentListItem` | Baris siswa dalam list: nama, last TP, level |
| `AIRecommendationBox` | Kotak teks rekomendasi AI dengan style amber/highlight |
| `ModulAjarCard` | Draft modul ajar dengan status badge + tombol aksi |
| `ClassSelectorDropdown` | Dropdown pilih kelas yang diajar guru |
| `PeriodSelector` | Toggle hari ini / minggu ini |

#### Organisms

| Komponen | Deskripsi |
|----------|-----------|
| `AppShell` | Layout sidebar + topbar + main content area |
| `DifferentiationGroupCard` | Card lengkap: 3 zona + AI recommendation + red flag list |
| `MorningBriefingPanel` | Panel briefing taktis harian: sesi plan + red flags |
| `StudentPassportPanel` | Paspor kognitif siswa read-only (embedded di StudentDetailPage) |
| `ModulAjarGenerator` | Form generate → progress poll → preview panel |

---

## §6 — PAGE SPECIFICATIONS

### 6.1 LoginPage (`/login`)

**Alur:**
1. Email + password form
2. Submit → Keycloak validate
3. Jika MFA wajib (selalu untuk `GURU`) → tampilkan OTP/TOTP input step
4. MFA berhasil → issue JWT → navigate `/dashboard`

**Komponen:**
- Card centered, width 400px, shadow `level2`
- Logo ALETA (atas card)
- Input email + password
- Button "Masuk" (primary, full-width)
- Step 2: Input TOTP 6-digit dengan countdown timer
- Error toast: `AUTH_INVALID_CREDENTIALS`, `AUTH_MFA_FAILED`, `RATE_LIMIT`

**MFA note untuk implementasi:**
```typescript
// src/auth/authService.ts
// MFA dihandle via Keycloak — setelah submit login, Keycloak redirect ke MFA challenge
// JWT tidak diterbitkan sampai MFA selesai
// Gunakan Keycloak JS adapter atau standard OIDC flow dengan code_challenge (PKCE)
```

---

### 6.2 MorningBriefingPage (`/dashboard`) — Default Landing

**Tujuan:** Berikan rekomendasi taktis kelas hari ini dalam < 10 detik baca.

**Layout (2-column pada desktop, stack pada tablet):**

```
┌────────────────────────────────────────────────────────────────┐
│ TOPBAR: "Selamat pagi, Pak Budi 👋  |  Rabu, 24 Mei 2026"     │
│         Class selector: [Kelas 7-A ▾]                         │
├─────────────────────────────┬──────────────────────────────────┤
│  SESSION PLAN               │  RED FLAG ALERTS                 │
│                             │                                  │
│  Mata Pelajaran: MATEMATIKA │  ⚠ 2 siswa butuh intervensi     │
│  Focus TP: TP_MAT_7_ALJABAR │                                  │
│  Grup: Fondasi 6 | Reg 18   │  🔴 Rani Wijaya                  │
│        Mahir 6              │  Stuck Aljabar 3 sesi beruntun   │
│                             │  💡 Kartu peraga bilangan bulat  │
│  ────────────────────       │                                  │
│  🤖 AI RECOMMENDATION       │  🔴 Deni Kusuma                  │
│  "Mulai dengan refresher    │  Kecepatan jawab menurun drastis │
│   visual 5 menit untuk      │  💡 Cek kondisi anak sebelum     │
│   kelompok fondasi..."      │   pelajaran dimulai              │
├─────────────────────────────┴──────────────────────────────────┤
│  [Lihat Detail Kelas →]   [Generate Modul Ajar →]              │
└────────────────────────────────────────────────────────────────┘
```

**Behavior:**
- Data diambil dari `GET /api/v1/teacher/morning-briefing?class_id={id}&date={today}`
- Class selector di topbar menggunakan Zustand `selectedClassId` — ganti kelas → refetch otomatis
- Polling setiap **30 detik** via TanStack Query `refetchInterval: 30_000`
- Skeleton shimmer saat loading pertama; data lama tetap tampil saat background refetch

**Kode stub MorningBriefingPage:**

```tsx
// src/pages/MorningBriefingPage.tsx
import { useQuery } from '@tanstack/react-query';
import { useClassStore } from '../state/classStore';
import { getMorningBriefing } from '../api/teacherApi';
import { MorningBriefingPanel } from '../components/organisms/MorningBriefingPanel';
import { RedFlagList } from '../components/organisms/RedFlagList';
import { PageSkeleton } from '../components/molecules/PageSkeleton';

export default function MorningBriefingPage() {
  const { selectedClassId } = useClassStore();

  const { data, isLoading, isError } = useQuery({
    queryKey: ['morning-briefing', selectedClassId],
    queryFn: () => getMorningBriefing(selectedClassId),
    refetchInterval: 30_000,
    staleTime: 25_000,
    enabled: !!selectedClassId,
  });

  if (isLoading) return <PageSkeleton />;
  if (isError) return <ErrorState message="Gagal memuat briefing. Coba refresh halaman." />;

  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 p-6">
      <MorningBriefingPanel briefing={data.data} />
      <RedFlagList flags={data.data.red_flags} />
      <div className="col-span-full flex gap-3">
        <Button variant="secondary" onClick={() => navigate(`/class/${selectedClassId}`)}>
          Lihat Detail Kelas
        </Button>
        <Button variant="primary" onClick={() => navigate('/modul-ajar')}>
          Generate Modul Ajar
        </Button>
      </div>
    </div>
  );
}
```

---

### 6.3 ClassOverviewPage (`/class/:classId`)

**Tujuan:** Visualisasi lengkap distribusi kompetensi kelas + daftar siswa per zona.

**Layout:**

```
┌──────────────────────────────────────────────────────────┐
│  Kelas 7-A SMP · 30 Siswa · MATEMATIKA                   │
│  Last updated: 2 menit lalu  [Refresh ↻]                │
├──────────────────────────────────────────────────────────┤
│  [AI RECOMMENDATION BOX - amber highlight]               │
│  "PERINGATAN: 33% kelas di zona Fondasi. Pertimbangkan   │
│   Team Teaching atau intervensi klasikal ulang."         │
├─────────────────┬──────────────┬────────────────────────┤
│  ZONA FONDASI   │  ZONA REGULER │  ZONA MAHIR            │
│  🔴 6 siswa 20% │  🔵 18 siswa  │  🟢 6 siswa 20%       │
│  ─────────────  │  60%          │  ─────────────        │
│  • Rani Wijaya  │  ─────────────│  • Ahmad Dani          │
│  • Deni Kusuma  │  • Budi S.    │  • Sari Indah          │
│  • ...          │  • ...        │  • ...                 │
├──────────────────────────────────────────────────────────┤
│  RED FLAG ALERTS (2)                                     │
│  [RedFlagItem] [RedFlagItem]                             │
└──────────────────────────────────────────────────────────┘
```

**Kode stub DifferentiationGroupCard:**

```tsx
// src/components/organisms/DifferentiationGroupCard.tsx
import React from 'react';
import { processClassGroups } from '../../utils/dashboardDataProcessor';
import type { DashboardSummary } from '../../api/types';

interface Props {
  data: DashboardSummary;
}

export const DifferentiationGroupCard: React.FC<Props> = ({ data }) => {
  const analysis = processClassGroups(data);

  return (
    <div className="rounded-card bg-surface border border-surface shadow-md p-6 space-y-6">
      <div>
        <h2 className="text-title font-semibold text-textHigh">{data.class_name}</h2>
        <p className="text-caption text-textMid">Total: {data.total_students} siswa</p>
      </div>

      {/* AI Recommendation */}
      <div className="p-4 bg-amber-50 border border-amber-200 rounded-card">
        <span className="text-xs font-semibold uppercase tracking-wider text-amber-700 block mb-1">
          Rekomendasi AI
        </span>
        <p className="text-sm text-amber-800">{analysis.instructionalFocus}</p>
      </div>

      {/* Three zones */}
      <div className="grid grid-cols-3 gap-4">
        <ZoneCard
          label="Zona Fondasi"
          count={analysis.totalFondasi}
          percent={analysis.ratios.fondasi}
          method="Pendampingan Guru Langsung"
          variant="fondasi"
          students={data.differentiation_grouping.kelompok_fondasi}
        />
        <ZoneCard
          label="Zona Reguler"
          count={analysis.totalReguler}
          percent={analysis.ratios.reguler}
          method="Kolaborasi Kelompok Mandiri"
          variant="reguler"
          students={data.differentiation_grouping.kelompok_reguler}
        />
        <ZoneCard
          label="Zona Mahir"
          count={analysis.totalMahir}
          percent={analysis.ratios.mahir}
          method="Pengayaan / Tutor Sebaya"
          variant="mahir"
          students={data.differentiation_grouping.kelompok_mahir}
        />
      </div>

      {/* Red flags */}
      {data.system_red_flags.length > 0 && (
        <div>
          <h3 className="text-sm font-semibold text-redFlag uppercase tracking-wider mb-3">
            Siswa Butuh Intervensi ({data.system_red_flags.length})
          </h3>
          <div className="space-y-2">
            {data.system_red_flags.map(flag => (
              <RedFlagItem key={flag.student_id} flag={flag} />
            ))}
          </div>
        </div>
      )}
    </div>
  );
};
```

**Klik nama siswa** → navigate ke `/class/:classId/student/:studentId`

---

### 6.4 StudentDetailPage (`/class/:classId/student/:studentId`)

**Tujuan:** Paspor kognitif individu siswa — read-only untuk guru.

**Elemen:**
- Header: nama siswa + fase aktif + kelas
- Breadcrumb: Kelas 7-A → [nama siswa]
- `StudentPassportPanel`:
  - Grouped by elemen (Matematika, IPA, dst.)
  - Per TP: nama TP + P(L) progress bar + badge status
  - P(L) di sini **boleh** ditampilkan sebagai progress bar (berbeda dari Parent App — guru adalah profesional pendidikan)
  - Badge: "Dikuasai ✓" jika `is_mastered = true`
- Section "Miskonsepsi Aktif": list dari `student_misconceptions` (nama miskonsepsi + TP terdampak)
- Section "Riwayat Sesi Terakhir": 5 sesi terakhir (tanggal, TP, hasil)

**Authorization guard:**
```typescript
// src/pages/StudentDetailPage.tsx
// WAJIB: student_id di URL harus milik kelas yang diajar guru
// Backend akan return 403 AUTHZ_NOT_TEACHER jika tidak cocok
// Frontend: tangkap 403 → render ErrorPage "Akses ditolak"
```

---

### 6.5 ModulAjarPage & Generator (`/modul-ajar`)

**Tujuan:** Generate draf Modul Ajar Kurikulum Merdeka dalam 1 klik.

**Alur 4 langkah:**

```
STEP 1: FORM INPUT
  ├─ Dropdown pilih TP target (dari kelas aktif)
  ├─ Checkbox diferensiasi: [✓] Fondasi  [✓] Reguler  [✓] Mahir
  └─ Button "Generate Modul Ajar" → POST /teacher/modul-ajar/generate

STEP 2: GENERATING (polling)
  ├─ Spinner + teks "Sedang menyusun modul ajar..."
  ├─ Poll GET /teacher/modul-ajar/{draft_id} setiap 5 detik
  └─ status "GENERATING" → terus poll; "READY" → STEP 3

STEP 3: PREVIEW
  ├─ Render markdown modul ajar di panel kanan
  ├─ Highlight bagian: Tujuan Pembelajaran, Kegiatan per zona diferensiasi
  └─ Tombol aksi: [Download Markdown] / [Download PDF] / [Buat Ulang]

STEP 4: DONE (opsional save)
  └─ Toast "Modul ajar tersimpan ke riwayat"
```

**Kode stub generator hook:**

```typescript
// src/api/teacherApi.ts
import { useMutation, useQuery } from '@tanstack/react-query';
import { apiClient } from './apiClient';

export function useGenerateModulAjar() {
  return useMutation({
    mutationFn: async (params: {
      tpId: string;
      classId: string;
      levels: ('FONDASI' | 'REGULER' | 'MAHIR')[];
    }) => {
      const res = await apiClient.post('/api/v1/teacher/modul-ajar/generate', {
        target_tp_id: params.tpId,
        target_class_id: params.classId,
        output_format: 'MARKDOWN_STANDARD_MERDEKA',
        differentiation_levels: params.levels,
      });
      return res.data.data as { draft_id: string; status: string };
    },
  });
}

export function useModulAjarDraft(draftId: string | null) {
  return useQuery({
    queryKey: ['modul-ajar-draft', draftId],
    queryFn: () =>
      apiClient
        .get(`/api/v1/teacher/modul-ajar/${draftId}`)
        .then(r => r.data.data),
    enabled: !!draftId,
    refetchInterval: (data) =>
      data?.status === 'READY' ? false : 5_000, // stop polling saat READY
    staleTime: Infinity,
  });
}
```

**Kode stub ModulAjarPage:**

```tsx
// src/pages/ModulAjarPage.tsx
export default function ModulAjarPage() {
  const { selectedClassId } = useClassStore();
  const [draftId, setDraftId] = useState<string | null>(null);
  const generateMutation = useGenerateModulAjar();
  const { data: draft } = useModulAjarDraft(draftId);

  const handleGenerate = (tpId: string, levels: string[]) => {
    generateMutation.mutate(
      { tpId, classId: selectedClassId, levels },
      { onSuccess: (d) => setDraftId(d.draft_id) }
    );
  };

  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 p-6">
      {/* Kolom kiri: Form */}
      <ModulAjarForm onSubmit={handleGenerate} isLoading={generateMutation.isPending} />

      {/* Kolom kanan: Preview */}
      {draftId && (
        <ModulAjarPreviewPanel
          status={draft?.status ?? 'GENERATING'}
          content={draft?.content}
          draftId={draftId}
        />
      )}
    </div>
  );
}
```

**ModulAjarPreviewPanel:**

```tsx
// src/components/organisms/ModulAjarPreviewPanel.tsx
import ReactMarkdown from 'react-markdown';

export const ModulAjarPreviewPanel: React.FC<{
  status: string;
  content?: string;
  draftId: string;
}> = ({ status, content, draftId }) => {
  if (status === 'GENERATING') {
    return (
      <div className="flex flex-col items-center justify-center h-64 gap-4">
        <Spinner size="lg" />
        <p className="text-textMid text-sm">Sedang menyusun modul ajar via AI lokal...</p>
      </div>
    );
  }

  return (
    <div className="bg-surface rounded-card border p-6 space-y-4">
      <div className="flex items-center justify-between">
        <h3 className="font-semibold text-textHigh">Draf Modul Ajar</h3>
        <div className="flex gap-2">
          <Button
            variant="secondary"
            size="sm"
            onClick={() => downloadMarkdown(content!, draftId)}
          >
            Download Markdown
          </Button>
          <Button
            variant="ghost"
            size="sm"
            onClick={() => window.print()}
          >
            Print / PDF
          </Button>
        </div>
      </div>
      <div className="prose prose-sm max-w-none overflow-y-auto max-h-[600px]">
        <ReactMarkdown>{content ?? ''}</ReactMarkdown>
      </div>
    </div>
  );
};
```

---

### 6.6 SettingsPage (`/settings`)

**Elemen:**
- Profil guru: nama, email (read-only — ubah via Keycloak self-service)
- Kelas default (pilih kelas yang langsung tampil saat login)
- Preferensi notifikasi browser (disabled di pilot, enabled Tahun 2)
- Zona display: tampilkan nama siswa lengkap / inisial saja (preferensi privasi)
- Tombol "Keluar"

---

## §7 — RED FLAG & DIFFERENTIATION LOGIC

### 7.1 Prinsip: Red Flag adalah Tanggung Jawab Backend

```
BACKEND (backend_core/services/red_flag_detector.py):
  ├─ Kalkulasi setiap 10 menit per kelas aktif
  ├─ Query: student_quiz_logs, student_misconceptions, student_cognitive_passports
  ├─ Kriteria (semua harus terpenuhi):
  │   ├─ ≥ 3 sesi beruntun pada TP yang sama
  │   ├─ > 70% jawaban salah dalam 10 soal terakhir
  │   ├─ Rata-rata response_time_seconds 5 soal terakhir > p95 historis
  │   └─ open misconception count ≥ 2 pada TP target
  ├─ Hasil ditulis ke Redis cache: red_flags:{class_id}
  └─ Threshold semua bisa dikonfigurasi via aleta_core.system_config

FRONTEND (React Dashboard):
  ├─ HANYA baca array system_red_flags dari API response
  ├─ TIDAK menghitung, menginterpretasi, atau memodifikasi red flag
  └─ Render RedFlagItem per entry dalam array
```

**Rule wajib untuk implementasi:**
- Jangan tambahkan filter atau logika threshold di TypeScript
- Jangan cache red flag > 30 detik (data harus segar)
- `RedFlagItem` adalah presentational-only — tidak ada business logic

### 7.2 Visualisasi Zona Diferensiasi

**ZoneCard component rules:**

```typescript
// src/components/molecules/ZoneCard.tsx
type ZoneVariant = 'fondasi' | 'reguler' | 'mahir';

const zoneConfig: Record<ZoneVariant, { label: string; colorClass: string; method: string }> = {
  fondasi: {
    label: 'Zona Fondasi',
    colorClass: 'bg-error/10 border-error/30 text-error',
    method: 'Pendampingan Guru Langsung',
  },
  reguler: {
    label: 'Zona Reguler',
    colorClass: 'bg-secondary/10 border-secondary/30 text-secondary',
    method: 'Kolaborasi Kelompok Mandiri',
  },
  mahir: {
    label: 'Zona Mahir',
    colorClass: 'bg-success/10 border-success/30 text-success',
    method: 'Pengayaan / Tutor Sebaya',
  },
};
```

### 7.3 Threshold AI Recommendation (dari backend)

Rekomendasi teks ("PERINGATAN: Lebih dari 30% kelas di zona Fondasi...") dihasilkan oleh `processClassGroups()` di backend — field `ai_recommendations` pada response API. Frontend hanya render teks ini di `AIRecommendationBox`.

**Jangan hardcode threshold % di React** — gunakan hanya teks dari `data.ai_recommendations[0]`.

---

## §8 — API CONTRACTS

### 8.1 Global Protocol

- Base URL: `https://api.{tenant}.aleta.sch.id/api/v1`
- Auth: `Authorization: Bearer <JWT>` (RS256, Keycloak, role = `GURU`)
- MFA: wajib setiap sesi baru — JWT tidak diterbitkan sebelum MFA selesai
- Object-level auth: `class_id` divalidasi backend terhadap `teaching_assignments`
- Polling: TanStack Query `refetchInterval` — jangan buat polling manual

### 8.2 `POST /api/v1/auth/login`

Identik dengan Student App. Respons mengandung `"role": "GURU"`.

MFA dihandle via Keycloak OIDC flow (redirect/challenge) — bukan endpoint terpisah di ALETA API.

---

### 8.3 `GET /api/v1/teacher/morning-briefing`

**Query params:**

| Param | Tipe | Wajib | Keterangan |
|-------|------|-------|------------|
| `class_id` | UUID | Ya | Divalidasi terhadap `teaching_assignments` |
| `date` | ISO date | Tidak | Default: hari ini |

**Response 200:**

```json
{
  "success": true,
  "data": {
    "class_id": "9d3a...",
    "class_name": "Kelas 7-A",
    "session_plan": {
      "subject": "MATEMATIKA",
      "focus_tp_id": "TP_MAT_7_ALJABAR",
      "focus_tp_name": "Operasi Aljabar Dasar",
      "expected_groups": {
        "fondasi": 6,
        "reguler": 18,
        "mahir": 6
      }
    },
    "red_flags": [
      {
        "student_id": "9a12...",
        "student_name": "Rani Wijaya",
        "reason": "Stuck pada Aljabar selama 3 sesi beruntun. Indikasi miskonsepsi kronis.",
        "priority": "HIGH",
        "recommended_action": "Berikan bimbingan tatap muka individual menggunakan media kartu peraga bilangan bulat."
      }
    ],
    "ai_recommendations": [
      "Mulai dengan refresher visual 5 menit untuk kelompok fondasi.",
      "Berikan tantangan PJBL untuk kelompok mahir."
    ],
    "generated_at": "2026-05-24T06:30:00Z"
  }
}
```

**Error codes:** `AUTHZ_NOT_TEACHER` (403), `NOT_FOUND_CLASS` (404)

---

### 8.4 `GET /api/v1/teacher/dashboard/summary`

**Query params:** `class_id` (UUID, wajib)

**Response 200:**

```json
{
  "success": true,
  "data": {
    "class_name": "Kelas 7-A SMP",
    "total_students": 30,
    "differentiation_grouping": {
      "kelompok_fondasi": [
        { "student_id": "9a12b3c4-...", "name": "Rani Wijaya", "last_active_tp": "TP_MAT_7_ALJABAR" }
      ],
      "kelompok_reguler": [
        { "student_id": "8e7d6c5b-...", "name": "Budi Santoso", "last_active_tp": "TP_MAT_7_ALJABAR" }
      ],
      "kelompok_mahir": [
        { "student_id": "1a2b3c4d-...", "name": "Ahmad Dani", "last_active_tp": "TP_MAT_8_FUNGSI" }
      ]
    },
    "system_red_flags": [
      {
        "student_id": "9a12b3c4-...",
        "student_name": "Rani Wijaya",
        "trigger_reason": "Stuck pada materi Aljabar selama 3 sesi beruntun.",
        "recommended_action": "Bimbingan tatap muka individual dengan kartu peraga bilangan bulat."
      }
    ],
    "last_computed_at": "2026-05-24T07:45:00Z"
  }
}
```

**Error codes:** `AUTHZ_NOT_TEACHER` (403)

---

### 8.5 `GET /api/v1/student/passport` (Teacher View)

**Query params:** `student_id` (UUID, wajib — guru wajib sertakan)

Guru hanya bisa akses siswa di kelas yang diajar — backend validasi via `teaching_assignments`.

**Response 200:** Identik dengan student passport (§8.4 PRD_STUDENT_APP.md) ditambah field `misconceptions`:

```json
{
  "success": true,
  "data": {
    "student_id": "7b8971f4-...",
    "student_name": "Rani Wijaya",
    "fase_aktif": "FASE_D",
    "total_mastered_tps": 42,
    "passports": [...],
    "active_misconceptions": [
      {
        "misconception_id": "mc-1a2b...",
        "tp_id": "TP_MAT_7_ALJABAR",
        "description": "Keliru: menganggap variabel hanya bisa berupa x atau y",
        "detected_at": "2026-05-20T09:00:00Z"
      }
    ]
  }
}
```

**Error codes:** `AUTHZ_NOT_TEACHER` (403) — jika student bukan di kelas yang diajar guru

---

### 8.6 `POST /api/v1/teacher/modul-ajar/generate`

**Request:**

```json
{
  "target_tp_id": "TP_MAT_7_ALJABAR",
  "target_class_id": "9d3a...",
  "output_format": "MARKDOWN_STANDARD_MERDEKA",
  "differentiation_levels": ["FONDASI", "REGULER", "MAHIR"]
}
```

**Response 202 Accepted:**

```json
{
  "success": true,
  "message": "Modul Ajar sedang digenerasi oleh AI lokal.",
  "data": {
    "draft_id": "f1e2d3c4-...",
    "status": "GENERATING",
    "poll_url": "/api/v1/teacher/modul-ajar/f1e2d3c4-..."
  }
}
```

**Error codes:** `AUTHZ_NOT_TEACHER` (403), `BUSINESS_TP_NOT_IN_CLASS` (422)

---

### 8.7 `GET /api/v1/teacher/modul-ajar/{draft_id}`

**Path param:** `draft_id` (UUID)

**Response — status GENERATING:**

```json
{
  "success": true,
  "data": {
    "draft_id": "f1e2d3c4-...",
    "status": "GENERATING",
    "progress_message": "Menyusun bagian Kegiatan Inti..."
  }
}
```

**Response — status READY:**

```json
{
  "success": true,
  "data": {
    "draft_id": "f1e2d3c4-...",
    "status": "READY",
    "tp_id": "TP_MAT_7_ALJABAR",
    "class_name": "Kelas 7-A",
    "content": "# Modul Ajar: Operasi Aljabar Dasar\n\n## A. Informasi Umum\n...",
    "generated_at": "2026-05-24T07:12:00Z"
  }
}
```

**Error codes:** `NOT_FOUND_DRAFT` (404), `AUTHZ_NOT_TEACHER` (403)

---

## §9 — TECHNICAL ARCHITECTURE

### 9.1 Tech Stack

```
teacher_dashboard_web/
├── Framework:     React 18 + TypeScript
├── Build tool:    Vite
├── Routing:       React Router 6
├── Server state:  TanStack Query v5
├── Client state:  Zustand
├── Styling:       Tailwind CSS (design tokens dari @aleta/tokens)
├── HTTP client:   Axios (dengan interceptor auth)
├── Markdown:      react-markdown + remark-gfm
├── Testing:       Vitest + React Testing Library + axe-core
└── Linting:       ESLint + Prettier
```

### 9.2 Folder Structure

```
teacher_dashboard_web/src/
├── api/
│   ├── apiClient.ts              ← Axios instance + auth interceptor + refresh
│   ├── teacherApi.ts             ← TanStack Query hooks untuk teacher endpoints
│   ├── studentApi.ts             ← TanStack Query hooks untuk student passport
│   └── types.ts                  ← TypeScript interface semua API response
│
├── auth/
│   ├── authService.ts            ← Login, logout, token refresh, PKCE flow
│   ├── tokenStore.ts             ← localStorage/sessionStorage token management
│   └── AuthGuard.tsx             ← Route guard komponen
│
├── components/
│   ├── atoms/
│   │   ├── Button.tsx
│   │   ├── Badge.tsx
│   │   ├── Input.tsx
│   │   ├── Spinner.tsx
│   │   ├── Skeleton.tsx
│   │   └── Tag.tsx
│   ├── molecules/
│   │   ├── ZoneCard.tsx
│   │   ├── RedFlagItem.tsx
│   │   ├── StudentListItem.tsx
│   │   ├── AIRecommendationBox.tsx
│   │   ├── ModulAjarCard.tsx
│   │   └── ClassSelectorDropdown.tsx
│   └── organisms/
│       ├── AppShell.tsx
│       ├── Sidebar.tsx
│       ├── DifferentiationGroupCard.tsx
│       ├── MorningBriefingPanel.tsx
│       ├── RedFlagList.tsx
│       ├── StudentPassportPanel.tsx
│       └── ModulAjarGenerator.tsx
│
├── pages/
│   ├── LoginPage.tsx
│   ├── MorningBriefingPage.tsx
│   ├── ClassOverviewPage.tsx
│   ├── StudentDetailPage.tsx
│   ├── ModulAjarPage.tsx
│   └── SettingsPage.tsx
│
├── state/
│   ├── classStore.ts             ← Zustand: selectedClassId, teacherClasses
│   └── uiStore.ts                ← Zustand: sidebarOpen, displayPrefs
│
├── utils/
│   ├── dashboardDataProcessor.ts ← processClassGroups() — NO red flag logic
│   ├── formatters.ts             ← tanggal, nama, persentase
│   └── downloadHelpers.ts        ← markdown download, print trigger
│
└── main.tsx
```

### 9.3 Auth Flow

```typescript
// src/api/apiClient.ts
import axios from 'axios';
import { tokenStore } from '../auth/tokenStore';

const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL,
});

// Request interceptor: inject Bearer token
apiClient.interceptors.request.use((config) => {
  const token = tokenStore.getAccessToken();
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

// Response interceptor: handle 401 → refresh
apiClient.interceptors.response.use(
  (res) => res,
  async (error) => {
    if (error.response?.status === 401 && !error.config._retry) {
      error.config._retry = true;
      try {
        await authService.refreshToken();
        return apiClient(error.config);
      } catch {
        authService.logout(); // redirect ke /login
      }
    }
    return Promise.reject(error);
  }
);

export { apiClient };
```

### 9.4 Route Guard

```tsx
// src/auth/AuthGuard.tsx
import { Navigate } from 'react-router-dom';
import { tokenStore } from './tokenStore';

export function AuthGuard({ children }: { children: React.ReactNode }) {
  const token = tokenStore.getAccessToken();
  const role = tokenStore.getRole();

  if (!token) return <Navigate to="/login" replace />;
  if (role !== 'GURU') return <Navigate to="/login?error=AUTHZ_WRONG_APP" replace />;

  return <>{children}</>;
}
```

### 9.5 Key Dependencies (`package.json`)

```json
{
  "dependencies": {
    "react": "^18.3.0",
    "react-dom": "^18.3.0",
    "react-router-dom": "^6.24.0",
    "@tanstack/react-query": "^5.45.0",
    "zustand": "^4.5.4",
    "axios": "^1.7.2",
    "react-markdown": "^9.0.1",
    "remark-gfm": "^4.0.0",
    "@aleta/tokens": "workspace:*"
  },
  "devDependencies": {
    "typescript": "^5.5.0",
    "vite": "^5.3.0",
    "tailwindcss": "^3.4.4",
    "vitest": "^1.6.0",
    "@testing-library/react": "^16.0.0",
    "axe-core": "^4.9.1",
    "@axe-core/react": "^4.9.1"
  }
}
```

---

## §10 — STATE MANAGEMENT

### 10.1 Server State (TanStack Query)

Semua data dari API dikelola TanStack Query. Jangan gunakan `useState` + `useEffect` untuk data server.

```typescript
// src/api/teacherApi.ts — contoh lengkap hook pattern

export const teacherQueryKeys = {
  morningBriefing: (classId: string, date?: string) =>
    ['morning-briefing', classId, date] as const,
  dashboardSummary: (classId: string) =>
    ['dashboard-summary', classId] as const,
  studentPassport: (studentId: string) =>
    ['student-passport', studentId] as const,
  modulAjarDraft: (draftId: string) =>
    ['modul-ajar-draft', draftId] as const,
};

export function useDashboardSummary(classId: string) {
  return useQuery({
    queryKey: teacherQueryKeys.dashboardSummary(classId),
    queryFn: () =>
      apiClient
        .get('/api/v1/teacher/dashboard/summary', { params: { class_id: classId } })
        .then(r => r.data.data as DashboardSummary),
    refetchInterval: 30_000,  // polling 30 detik
    staleTime: 25_000,
    enabled: !!classId,
  });
}

export function useMorningBriefing(classId: string, date?: string) {
  return useQuery({
    queryKey: teacherQueryKeys.morningBriefing(classId, date),
    queryFn: () =>
      apiClient
        .get('/api/v1/teacher/morning-briefing', { params: { class_id: classId, date } })
        .then(r => r.data.data as MorningBriefingData),
    staleTime: 60_000,  // briefing pagi tidak perlu polling sering
    enabled: !!classId,
  });
}

export function useStudentPassport(studentId: string | null) {
  return useQuery({
    queryKey: teacherQueryKeys.studentPassport(studentId!),
    queryFn: () =>
      apiClient
        .get('/api/v1/student/passport', { params: { student_id: studentId } })
        .then(r => r.data.data as StudentPassport),
    enabled: !!studentId,
    staleTime: 120_000,
  });
}
```

### 10.2 Client State (Zustand)

Hanya untuk preferensi UI lokal — bukan data dari server.

```typescript
// src/state/classStore.ts
import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface ClassStore {
  selectedClassId: string;
  teacherClasses: { id: string; name: string }[];
  setSelectedClass: (id: string) => void;
  setTeacherClasses: (classes: { id: string; name: string }[]) => void;
}

export const useClassStore = create<ClassStore>()(
  persist(
    (set) => ({
      selectedClassId: '',
      teacherClasses: [],
      setSelectedClass: (id) => set({ selectedClassId: id }),
      setTeacherClasses: (classes) => set({ teacherClasses: classes }),
    }),
    { name: 'aleta-class-store' }
  )
);
```

```typescript
// src/state/uiStore.ts
interface UiStore {
  sidebarOpen: boolean;
  studentDisplayMode: 'full_name' | 'initials';
  toggleSidebar: () => void;
  setDisplayMode: (mode: 'full_name' | 'initials') => void;
}

export const useUiStore = create<UiStore>()((set) => ({
  sidebarOpen: true,
  studentDisplayMode: 'full_name',
  toggleSidebar: () => set((s) => ({ sidebarOpen: !s.sidebarOpen })),
  setDisplayMode: (mode) => set({ studentDisplayMode: mode }),
}));
```

### 10.3 TypeScript Interfaces (Types)

```typescript
// src/api/types.ts

export interface Student {
  student_id: string;
  name: string;
  last_active_tp: string;
}

export interface DifferentiationGroups {
  kelompok_fondasi: Student[];
  kelompok_reguler: Student[];
  kelompok_mahir: Student[];
}

export interface RedFlagAlert {
  student_id: string;
  student_name: string;
  trigger_reason: string;
  recommended_action: string;
  priority?: 'HIGH' | 'MEDIUM';
}

export interface DashboardSummary {
  class_name: string;
  total_students: number;
  differentiation_grouping: DifferentiationGroups;
  system_red_flags: RedFlagAlert[];
  last_computed_at: string;
}

export interface MorningBriefingData {
  class_id: string;
  class_name: string;
  session_plan: {
    subject: string;
    focus_tp_id: string;
    focus_tp_name: string;
    expected_groups: { fondasi: number; reguler: number; mahir: number };
  };
  red_flags: RedFlagAlert[];
  ai_recommendations: string[];
  generated_at: string;
}

export interface PassportEntry {
  tp_id: string;
  elemen: string;
  current_p_l: number;
  is_mastered: boolean;
  last_updated: string;
}

export interface ActiveMisconception {
  misconception_id: string;
  tp_id: string;
  description: string;
  detected_at: string;
}

export interface StudentPassport {
  student_id: string;
  student_name: string;
  fase_aktif: string;
  total_mastered_tps: number;
  passports: PassportEntry[];
  active_misconceptions: ActiveMisconception[];
}

export interface ModulAjarDraft {
  draft_id: string;
  status: 'GENERATING' | 'READY' | 'FAILED';
  tp_id?: string;
  class_name?: string;
  content?: string;
  progress_message?: string;
  generated_at?: string;
}
```

---

## §11 — NON-FUNCTIONAL REQUIREMENTS

### 11.1 Performance

| Metrik | Target | Ukur via |
|--------|--------|----------|
| Login + MFA → dashboard render | < 2 detik | Chrome DevTools Lighthouse |
| `dashboard/summary` first render | < 1 detik | TanStack Query devtools |
| Polling update (background) | 0 layout shift | CLS score |
| `modul-ajar` first token | < 60 detik total | manual stopwatch |
| Ganti kelas (class selector) | < 500ms | React Profiler |

### 11.2 Keamanan

| Aturan | Implementasi |
|--------|--------------|
| JWT algorithm | RS256 / ES256 — Axios interceptor validasi `alg` sebelum gunakan |
| MFA | Wajib untuk GURU — dihandle Keycloak OIDC, bukan bypass dari frontend |
| Token storage | `sessionStorage` (bukan `localStorage`) — hilang saat tab ditutup |
| Class ownership | Backend validasi `teaching_assignments` — 403 → `ErrorPage` |
| CSRF | SameSite=Strict cookie untuk refresh token |
| Log redaction | Axios logger tidak mencatat `Authorization` header ke console |
| Red flag display | Hanya render text dari API — jangan tambahkan interpretasi di frontend |

### 11.3 Aksesibilitas

| Aturan | Nilai |
|--------|-------|
| Standar | WCAG 2.2 AA |
| Tap/click target | ≥ 48dp (44px) |
| Keyboard navigation | Semua fitur dapat diakses via keyboard |
| Focus ring | Visible pada semua elemen interaktif |
| Color contrast | ≥ 4.5:1 untuk teks body, ≥ 3:1 untuk UI komponen |
| ARIA labels | Wajib pada icon-only button (refresh, download, dsb.) |
| axe-core | Auto-run di test suite — zero critical violations |

### 11.4 Responsivitas

| Breakpoint | Layout |
|------------|--------|
| Desktop ≥ 1024px | Sidebar tetap + 2-column content |
| Tablet 768–1023px | Sidebar collapsible + 1-column content |
| Mobile < 768px | Sidebar drawer + 1-column (bukan target utama, tapi harus functional) |

---

## §12 — IMPLEMENTATION TASK MAP

| Task | Judul | Yang Dibuat |
|------|-------|-------------|
| T-401 | Teacher dashboard React scaffold | `vite.config.ts`, `main.tsx`, `AppShell.tsx`, `Sidebar.tsx`, router setup |
| T-402 | Tailwind config konsumsi `@aleta/tokens` | `tailwind.config.ts`, semua color/font token terpasang |
| T-403 | Auth flow web (login + refresh) | `LoginPage.tsx`, `authService.ts`, `tokenStore.ts`, `AuthGuard.tsx` |
| T-404 | TanStack Query + API client typed | `apiClient.ts`, `types.ts`, `teacherApi.ts`, `studentApi.ts` |
| T-405 | RedFlagDetector backend service | (backend task — frontend hanya consume) |
| T-406 | `/teacher/dashboard/summary` endpoint | (backend task — `useDashboardSummary` hook menyambut respons ini) |
| T-407 | `/teacher/morning-briefing` endpoint | (backend task — `useMorningBriefing` hook) |
| T-408 | DifferentiationGroupCard component | `DifferentiationGroupCard.tsx`, `ZoneCard.tsx`, `RedFlagItem.tsx` |
| T-409 | MorningBriefingPage | `MorningBriefingPage.tsx`, `MorningBriefingPanel.tsx`, `RedFlagList.tsx` |
| T-410 | `/teacher/modul-ajar` generator + page | `ModulAjarPage.tsx`, `ModulAjarGenerator.tsx`, `ModulAjarPreviewPanel.tsx`, `useGenerateModulAjar`, `useModulAjarDraft` |
| T-411 | axe-core a11y tests (3 surface) | `LoginPage.test.tsx`, `ClassOverviewPage.test.tsx`, `ModulAjarPage.test.tsx` |

---

## §13 — ACCEPTANCE CRITERIA CHECKLIST

### Setup & Foundation

- [ ] `npm run dev` berjalan tanpa error
- [ ] `npm run build` tanpa TypeScript error
- [ ] Tailwind: semua warna dikonfigurasi dari `@aleta/tokens` — tidak ada `bg-red-500` langsung di komponen
- [ ] `AuthGuard` bekerja: akses `/dashboard` tanpa token → redirect ke `/login`
- [ ] Login role `SISWA` atau `ORANG_TUA` → error toast `AUTHZ_WRONG_APP`

### Auth & MFA

- [ ] Login berhasil → JWT disimpan di `sessionStorage`
- [ ] MFA step muncul setelah submit login (Keycloak challenge)
- [ ] Token expired → Axios interceptor retry dengan refresh token
- [ ] Refresh gagal → redirect ke `/login`

### Morning Briefing

- [ ] `MorningBriefingPage` memuat data dalam < 1 detik pada koneksi normal
- [ ] `ClassSelectorDropdown` di topbar berfungsi: ganti kelas → `useMorningBriefing` refetch dengan `class_id` baru
- [ ] Background polling setiap 30 detik tidak menyebabkan layout shift
- [ ] Skeleton shimmer tampil saat loading pertama
- [ ] Red flag count badge tampil di sidebar dan di panel

### Class Overview

- [ ] 3 `ZoneCard` tampil dengan warna token yang benar (fondasi=error, reguler=secondary, mahir=success)
- [ ] `AIRecommendationBox` menampilkan teks dari `ai_recommendations[0]` — bukan hardcoded
- [ ] `RedFlagItem` tampil untuk setiap entry `system_red_flags`
- [ ] Tidak ada business logic threshold di komponen React (cek: tidak ada if angka > angka di TSX)
- [ ] Klik nama siswa → navigate ke `StudentDetailPage` yang benar

### Student Detail

- [ ] P(L) progress bar tampil per TP (teacher boleh lihat P(L) sebagai angka)
- [ ] `active_misconceptions` tampil dengan deskripsi masing-masing
- [ ] Akses `student_id` dari kelas yang bukan milik guru → API 403 → `ErrorPage` "Akses Ditolak"

### Modul Ajar Generator

- [ ] Submit form → `POST /teacher/modul-ajar/generate` dipanggil
- [ ] Setelah submit: spinner + pesan "Sedang menyusun..."
- [ ] Polling `GET /teacher/modul-ajar/{draft_id}` setiap 5 detik
- [ ] Saat `status = "READY"`: polling berhenti, markdown di-render di preview panel
- [ ] Tombol "Download Markdown" mengunduh file `.md`
- [ ] Tombol "Print / PDF" membuka browser print dialog

### Aksesibilitas (axe-core)

- [ ] `LoginPage`: 0 critical axe violations
- [ ] `ClassOverviewPage`: 0 critical axe violations
- [ ] `ModulAjarPage`: 0 critical axe violations
- [ ] Semua icon-only button memiliki `aria-label`
- [ ] Keyboard navigation: semua fungsi dapat diakses tanpa mouse
- [ ] `ZoneCard` warna: rasio kontras ≥ 3:1 untuk badge text vs background

---

> **Untuk AI agent yang mengimplementasikan:** Mulai dari T-401 (scaffold + routing). Pastikan `AuthGuard` dan role check berfungsi sebelum mengerjakan halaman lain. **Aturan kritis:** `DifferentiationGroupCard` dan `RedFlagList` adalah presentational-only — tidak boleh ada kondisional berdasarkan nilai numerik di dalam komponen React. Semua threshold dan logika ada di backend. Gunakan `npm run test` dengan axe-core sebelum marking setiap halaman sebagai `done`.
