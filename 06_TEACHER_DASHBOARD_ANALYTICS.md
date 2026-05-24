---
doc: "06"
title: "Teacher Dashboard Analytics"
scope: "React teacher dashboard: morning briefing endpoint, red flag alert logic, differentiation group cards"
key_entities: [MorningBriefingPage, RedFlagDetector, DifferentiationGroupCard, "/teacher/morning-briefing"]
depends_on: ["04", "14"]
loaded_by_tasks: [T-401, T-405, T-406, T-407, T-408, T-409]
---

# FILE: 06_TEACHER_DASHBOARD_ANALYTICS.md
# PROJECT ALETA: TEACHER DASHBOARD ANALYTICS & LOGIC SPECIFICATION

## 1. PENDAHULUAN & PRINSIP UTAMA DASHBOARD
Dokumen ini menetapkan spesifikasi fungsional dan logika bisnis untuk aplikasi web terpisah pemantauan guru (*Teacher Dashboard*) berbasis React.js. Dashboard admin yayasan juga berada pada web React terpisah dari Flutter mobile, dengan modul dan hak akses berbeda.

Filosofi utama dasbor ALETA adalah **"Data-Driven, Action-Oriented"**. Dasbor ini tidak boleh membebani guru dengan grafik rumit yang membingungkan. Fungsi utamanya adalah menyaring ribuan data log kuis siswa dan menyajikannya dalam bentuk rekomendasi pengajaran langsung di kelas dalam hitungan detik.

---

## 2. METRIK INDIKATOR KRITIS (LOGIKA DETEKSI RED FLAG)
Sistem secara otomatis memindai tabel `student_quiz_logs` pada skema tenant secara asinkron untuk mendeteksi siswa yang membutuhkan bantuan emosional atau kognitif intensif.

### Algoritma Deteksi Frustrasi Kognitif (Stuck Pattern)

> **🛑 Arsitektur kanonik:** logika red flag adalah **logika backend**, bukan frontend. Backend (`backend_core/backend_core/services/red_flag_detector.py`, lihat `15_PROJECT_STRUCTURE.md` §3) menjalankan kalkulasi terjadwal (setiap 10 menit per kelas aktif) dan menulis hasil ke cache Redis `red_flags:{class_id}`. Dashboard React **hanya merender** array `system_red_flags` dari respons `GET /api/v1/teacher/dashboard/summary` — frontend tidak pernah memutuskan apakah seorang siswa "red flag". Hal ini mencegah bypass dan menjaga konsistensi.

Sebuah notifikasi peringatan dini (*Red Flag*) dipicu jika seorang siswa memenuhi kriteria berikut (semua dievaluasi di backend, query Postgres ke `unit_*.student_quiz_logs`):
*   Mengerjakan soal pada **Tujuan Pembelajaran (TP) yang sama** secara berturut-turut sebanyak $\ge 3$ sesi kuis yang berbeda.
*   Proporsi jawaban salah dalam 10 soal terakhir mencapai $> 70\%$.
*   Waktu pengerjaan soal (`response_time_seconds`) melambat secara drastis: rerata 5 soal terakhir > p95 historis siswa pada TP yang sama.
*   Open misconception count untuk siswa pada `student_misconceptions` $\ge 2$ pada TP target (Doc 03 §3.E).

Threshold di atas disimpan sebagai config di `aleta_core.system_config` (lihat `11_ADMIN_YAYASAN_DASHBOARD.md` §5) supaya tim kurikulum yayasan bisa kalibrasi tanpa redeploy.

---

## 3. IMPLEMENTASI KODE LOGIKA JAVASCRIPT/TYPESCRIPT (SIAP KONSUMSI VIBE CODING)
Berikut adalah modul fungsi pemroses data (*data processor*) berbasis TypeScript yang bertugas mengonversi respons API dari backend (`04_BACKEND_API_CONTRACTS.md`) menjadi komponen visual grup diferensiasi kelas.

```typescript
// src/utils/dashboardDataProcessor.ts

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
}

export interface DashboardApiResponse {
  class_name: string;
  total_students: number;
  differentiation_grouping: DifferentiationGroups;
  system_red_flags: RedFlagAlert[];
}

/**
 * Memproses data analisis kelas dari AI Engine dan menghasilkan rekomendasi taktis
 * untuk manajemen pembagian layout meja kelompok di dalam kelas.
 */
export function processClassGroups(data: DashboardApiResponse) {
  const groups = data.differentiation_grouping;
  
  // Menghitung rasio keterisian kelompok untuk rekomendasi alokasi waktu guru
  const total = data.total_students;
  const ratios = {
    fondasi: (groups.kelompok_fondasi.length / total) * 100,
    reguler: (groups.kelompok_reguler.length / total) * 100,
    mahir: (groups.kelompok_mahir.length / total) * 100,
  };

  let instructionalFocus = "Fokus pada zona reguler.";
  if (ratios.fondasi > 30) {
    instructionalFocus = "PERINGATAN: Lebih dari 30% kelas tertahan di level fondasi. Direkomendasikan membagi kelas menjadi model pengajaran tim (Team Teaching) atau intervensi klasikal ulang.";
  } else if (groups.kelompok_fondasi.length > 0) {
    instructionalFocus = `Prioritas mengajar hari ini: Berikan bimbingan langsung secara intensif pada ${groups.kelompok_fondasi.length} anak di Kelompok Fondasi menggunakan alat peraga fisik.`;
  }

  return {
    ratios,
    instructionalFocus,
    totalFondasi: groups.kelompok_fondasi.length,
    totalReguler: groups.kelompok_reguler.length,
    totalMahir: groups.kelompok_mahir.length,
    alerts: data.system_red_flags
  };
}

```

---

## 4. SKEMA KOMPONEN ANTARMUKA REACT STYLES (UI FACTORY)

Gunakan komponen fungsional React (TSX) di bawah ini sebagai draf struktur tampilan utama untuk modul komponen pengelompokan siswa otomatis.

```tsx
// src/components/DifferentiationGroupCard.tsx
import React from 'react';
import { DashboardApiResponse, processClassGroups } from '../utils/dashboardDataProcessor';

interface CardProps {
  apiData: DashboardApiResponse;
}

export const DifferentiationGroupCard: React.FC<CardProps> = ({ apiData }) => {
  const analysis = processClassGroups(apiData);

  return (
    <div className="p-6 bg-slate-900 text-white rounded-xl shadow-md border border-slate-800">
      <h2 className="text-xl font-bold mb-2">Peta Strategi Diferensiasi: {apiData.class_name}</h2>
      <p className="text-sm text-slate-400 mb-6">Total Peserta Didik: {apiData.total_students} Siswa</p>

      
      <div className="mb-6 p-4 bg-amber-950/40 border border-amber-800/60 rounded-lg">
        <span className="text-xs font-semibold uppercase tracking-wider text-amber-400 block mb-1">🔍 REKOMENDASI ASISTEN AI</span>
        <p className="text-sm text-amber-200">{analysis.instructionalFocus}</p>
      </div>

      
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
        <div className="p-4 bg-rose-950/20 border border-rose-900/50 rounded-lg">
          <h3 className="font-semibold text-rose-400">Zona A: Kelompok Fondasi ({analysis.totalFondasi} Anak)</h3>
          <div className="text-xs text-slate-400 mt-1">Metode: Pendampingan Guru Langsung</div>
          <p className="text-2xl font-bold mt-2 text-rose-300">{analysis.ratios.fondasi.toFixed(0)}%</p>
        </div>

        <div className="p-4 bg-sky-950/20 border border-sky-900/50 rounded-lg">
          <h3 className="font-semibold text-sky-400">Zona B: Kelompok Reguler ({analysis.totalReguler} Anak)</h3>
          <div className="text-xs text-slate-400 mt-1">Metode: Kolaborasi Kelompok Mandiri</div>
          <p className="text-2xl font-bold mt-2 text-sky-300">{analysis.ratios.reguler.toFixed(0)}%</p>
        </div>

        <div className="p-4 bg-emerald-950/20 border border-emerald-900/50 rounded-lg">
          <h3 className="font-semibold text-emerald-400">Zona C: Kelompok Mahir ({analysis.totalMahir} Anak)</h3>
          <div className="text-xs text-slate-400 mt-1">Metode: Pengayaan Mandiri / Tutor Sebaya</div>
          <p className="text-2xl font-bold mt-2 text-emerald-300">{analysis.ratios.mahir.toFixed(0)}%</p>
        </div>
      </div>

      
      {analysis.alerts.length > 0 && (
        <div>
          <h3 className="text-sm font-semibold text-rose-400 uppercase tracking-wider mb-2">⚠️ SISWA BUTUH INTERVENSI KHUSUS</h3>
          <div className="space-y-2">
            {analysis.alerts.map((alert) => (
              <div key={alert.student_id} className="p-3 bg-rose-950/40 border border-rose-900 text-sm rounded">
                <span className="font-bold text-rose-200">{alert.student_name}</span>: {alert.trigger_reason}
                <div className="text-xs font-medium text-slate-300 mt-1 bg-slate-950/50 p-2 rounded">
                  💡 Tindakan Guru: {alert.recommended_action}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};

```

---

## 5. STACK & STRUKTUR APLIKASI REACT

* **Build:** Vite + React 18 + TypeScript.
* **State server:** TanStack Query (`@tanstack/react-query`) untuk semua data API; cache stale-time 30s.
* **State client:** Zustand untuk preferensi UI lokal (kelas terpilih, filter).
* **Routing:** React Router 6 dengan route guards berbasis `role` di JWT.
* **Styling:** Tailwind CSS + design tokens di `tailwind.config.ts` mengikuti `proDashboard` theme dari Doc 05 untuk konsistensi visual lintas surface.
* **Realtime updates:** Polling 30 detik untuk `dashboard/summary`. Roadmap: pindah ke WebSocket subscriber Redis pub-sub setelah Tahun 2.
* **Auth flow:** sama dengan Flutter (`/api/v1/auth/login` + refresh token via httpOnly cookie).

Struktur folder yang direkomendasikan:
```
teacher_dashboard_web/
  src/
    api/          # TanStack Query hooks per endpoint
    components/   # presentational, no business logic
    pages/        # ClassOverview, MorningBriefing, ModulAjar, Students
    state/        # Zustand stores
    utils/        # formatters (NO red flag logic)
    auth/         # token store, refresh interceptor
  tailwind.config.ts
  vite.config.ts
```

---

## 6. FITUR GENERATOR MODUL AJAR (KURIKULUM MERDEKA AUTOMATION)

Dasbor ini menyediakan fungsi satu klik bagi guru untuk membuat draf Modul Ajar otomatis yang ditenagai oleh Local LLM dengan struktur parameter sebagai berikut:

```typescript
// Fungsi pemanggil generator modul ajar dari frontend React ke API Backend
async function generateModulAjar(tpId: string, classId: string) {
  const response = await fetch('/api/v1/teacher/modul-ajar/generate', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      target_tp_id: tpId,
      target_class_id: classId,
      output_format: "MARKDOWN_STANDARD_MERDEKA"
    })
  });
  return response.json();
}

```

---
