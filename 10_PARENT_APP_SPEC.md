---
doc: "10"
title: "Parent App Spec"
scope: "Parent Flutter build flavor, no-numeric-grade reports, consent inbox, LLM-generated home activities"
key_entities: [ParentHomeShell, HeadlineInsightCard, ConsentInbox, "/parent/child-report", "/parent/home-activities"]
depends_on: ["05", "04"]
loaded_by_tasks: [T-601, T-602, T-603, T-604, T-606]
---

# FILE: 10_PARENT_APP_SPEC.md
# PROJECT ALETA: PARENT APP SPECIFICATION

## 1. PENDAHULUAN

Aplikasi Orang Tua ALETA adalah *build flavor* terpisah dari Flutter codebase yang sama (`flutter run --flavor parent`). Tujuannya:
1. Memberi laporan perkembangan **tanpa angka mati** (mengikuti filosofi Kurikulum Merdeka).
2. Menyediakan **saran aktivitas rumah harian** yang kontekstual dengan TP aktif anak.
3. Menjadi titik tunggal **persetujuan UU PDP** (consent flow).

Dokumen ini melengkapi Doc 05 (Flutter shell) dan Doc 04 (`/api/v1/parent/*`).

---

## 2. PETA NAVIGASI APLIKASI

```
ParentHomeShell
├─ HomeScreen
│   ├─ Card: Headline insight (LLM-generated 1 kalimat)
│   ├─ Card: Aktivitas rumah hari ini (top 1)
│   └─ Strip: Daftar anak (jika multi-anak)
├─ ChildReportScreen      (route: /parent/report?student_id=…)
├─ HomeActivitiesScreen   (route: /parent/activities)
├─ ConsentInboxScreen     (route: /parent/consents)
└─ SettingsScreen
```

Tidak ada route `/learn`, `/tutor`, `/quiz` untuk role `ORANG_TUA` — guard di `app_router.dart`.

---

## 3. KOMPONEN UTAMA

### A. Headline Insight Card

Diisi oleh `GET /api/v1/parent/child-report?period=weekly`. Render:

```dart
class HeadlineInsightCard extends StatelessWidget {
  final String studentName;
  final String insight;            // "Sandi membuat lompatan di Aljabar..."
  final List<CompetencySnapshot> snapshots;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Cerita $studentName minggu ini",
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(insight,
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 12),
            CompetencySnapshotStrip(snapshots: snapshots),
          ],
        ),
      ),
    );
  }
}
```

**Kebijakan tampilan**:
- Tidak ada nilai numerik 0–100.
- Status hanya: `Mahir`, `Reguler`, `Fondasi`, `Butuh Perhatian`.
- Tidak ada perbandingan ranking dengan siswa lain.

### B. Aktivitas Rumah Harian

Diisi oleh `GET /api/v1/parent/home-activities`. Struktur kartu:

```
┌────────────────────────────────────────┐
│ Hari ini · 15 menit · Hobi: Sepak Bola │
│                                        │
│ Hitung Operan Sepak Bola               │
│                                        │
│ Ajak Sandi menghitung persentase…      │
│                                        │
│ [Bahan: pena, kertas]   [Mulai →]      │
└────────────────────────────────────────┘
```

Tombol `Mulai` membuka modal step-by-step dan pada akhir meminta refleksi 1 tap:
* 😀 Berjalan lancar
* 😐 Anak sedikit kesulitan
* 😟 Anak tampak tidak tertarik

Refleksi dikirim ke `POST /api/v1/parent/activity-reflection` (tambahan endpoint, dipanggil dari aplikasi parent; tidak diperlukan di dashboard guru) dan diumpan-balikkan ke `interest_vector` siswa (Doc 09 §5.C).

### C. Consent Inbox

Daftar `parental_consent` dengan `status='PENDING'` untuk anak-anak terhubung. Setiap item menampilkan:
* Pemohon (mis. "Bu Sri — Guru Wali Kelas")
* Scope dalam bahasa awam ("Mengizinkan tes minat bakat di Lembaga Psikologi Z?")
* Reason
* Tombol [Setujui] / [Tolak]

Konfirmasi 2-tap untuk action sensitif (`EXTERNAL_PSYCHOLOGY`, `DATA_EXPORT`).

---

## 4. KEBIJAKAN PRIVASI KHUSUS PARENT APP

1. Aplikasi parent **tidak boleh** menampilkan transkrip mentah `tutor_messages` anak.
2. Tampilan miskonsepsi diringkas menjadi narasi positif: "Sandi masih perlu memperkuat konsep …", bukan "Sandi salah X kali pada miskonsepsi Y".
3. Hobi anak dan `interest_vector` ditampilkan dengan disclaimer dan dapat di-edit ortu (memicu `audit_events` `action='PARENT_EDIT_INTEREST'`).
4. Ortu dengan multiple anak hanya bisa melihat anak yang punya baris aktif di `student_parent_relations`.

---

## 5. NOTIFIKASI PUSH

Channel default (opt-in saat onboarding):
| Channel | Trigger | Frekuensi maks |
| :--- | :--- | :--- |
| `weekly_summary` | Cron Senin 06:00 lokal | 1 / minggu |
| `red_flag_alert` | Saat anak masuk red flag list | 1 / hari |
| `consent_pending` | Saat consent baru dibuat | langsung |
| `tutor_handoff` | Saat anak memicu `TUTOR_HANDOFF_REQUIRED` | langsung |

Implementasi via Firebase Cloud Messaging — token disimpan di `aleta_core.user_devices` (tabel disiapkan saat fase implementasi push, tidak diblokir untuk MVP).

---

## 6. ROADMAP FITUR

| Fase | Fitur |
| :--- | :--- |
| **Tahun 1 (Pilot)** | Headline insight, weekly report, consent inbox |
| **Tahun 2 (Integrasi)** | Saran aktivitas rumah, refleksi 1-tap, push weekly summary |
| **Tahun 3 (Full)** | Notifikasi real-time red flag, chat aman dengan wali kelas, journal kolaboratif |
