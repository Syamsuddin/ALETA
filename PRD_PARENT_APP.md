---
doc: "PRD-02"
title: "PRD Parent App"
type: "product-requirements-document"
version: "1.0"
status: "approved"
app: "Parent App (Flutter — flavor: parent)"
authored: "2026-05-24"
blueprints_consumed: ["04", "05", "07", "09", "10", "14"]
vibe_coding_target: "flutter-coder, backend-coder, ai-engine-coder"
tasks_covered: [T-601, T-602, T-603, T-604, T-605, T-606]
---

# PRD — ALETA Parent App

### AI-Powered Child Progress Companion · Flutter Mobile · Flavor: `parent`

> **Petunjuk untuk AI agent:** Dokumen ini adalah panduan tunggal membangun Parent App dari nol. Codebase identik dengan Student App — hanya `main_parent.dart` dan route guards yang berbeda. Baca §1–§13 secara urut. Semua nilai numerik dan sentinel FINAL dari `STATE.yaml.sentinels`. Jangan tambahkan fitur di luar §1.2 tanpa approval architect.

---

## DAFTAR ISI

| § | Judul | Isi Kunci |
|---|-------|-----------|
| 1 | Product Overview | Visi, scope, exclusions |
| 2 | User Personas | Profil orang tua per konteks |
| 3 | Goals & Success Metrics | KPI dan acceptance criteria |
| 4 | Information Architecture | Peta layar & navigation rules |
| 5 | UI/UX Design System | Token parent, layout PRO_DASHBOARD |
| 6 | Screen Specifications | Detail setiap layar |
| 7 | Privacy & Consent Rules | Kebijakan tampilan data anak |
| 8 | API Contracts | Semua endpoint parent |
| 9 | Technical Architecture | Folder, flavor wiring, dependencies |
| 10 | State Management | BLoC event-state contracts |
| 11 | Non-Functional Requirements | Performa, keamanan, aksesibilitas |
| 12 | Implementation Task Map | Pemetaan ke T-NNN |
| 13 | Acceptance Criteria Checklist | Definition of Done per fitur |

---

## §1 — PRODUCT OVERVIEW

### 1.1 Visi Produk

Parent App adalah jembatan antara ekosistem ALETA dengan rumah tangga siswa. Orang tua mendapatkan **laporan perkembangan bermakna** — bukan sekedar angka rapor — yang menjelaskan pertumbuhan kognitif anak dalam bahasa naratif sehari-hari, sekaligus **saran aktivitas rumah harian** yang dikustomisasi berdasarkan hobi anak dan TP yang sedang dikerjakan di sekolah.

**Proposisi nilai inti:** Orang tua tidak perlu menjadi ahli pendidikan untuk memahami perkembangan anak. ALETA menerjemahkan data BKT yang kompleks menjadi narasi satu kalimat yang dapat langsung ditindaklanjuti.

**Perbedaan dari Student App:** Parent App adalah read-only terhadap data kognitif anak — orang tua tidak dapat mengubah jalur belajar, tetapi dapat memberikan refleksi aktivitas rumah yang memperkaya `interest_vector` siswa untuk personalisasi konten LLM.

### 1.2 Scope (Dalam Cakupan)

| Fitur | Deskripsi |
|-------|-----------|
| Login & session | Keycloak OIDC, JWT RS256, role `ORANG_TUA` |
| Multi-child selector | Tampilkan semua anak dari `student_parent_relations` |
| Headline Insight Card | Narasi LLM 1 kalimat + snapshot kompetensi mingguan |
| Child Report Screen | Laporan detail tanpa angka, per periode (weekly/monthly/semester) |
| Home Activities Screen | 1–3 saran aktivitas rumah berbasis hobi + TP aktif anak |
| Activity Reflection | Feedback 1-tap setelah aktivitas dilakukan |
| Consent Inbox | Daftar persetujuan data anak yang menunggu keputusan |
| Consent Decision | Setujui/tolak dengan konfirmasi 2-tap untuk scope sensitif |
| Settings | Profil, edit hobi anak (dengan audit trail), notifikasi opt-in |

### 1.3 Exclusions (Di Luar Cakupan)

- Quiz / latihan soal (hanya Student App)
- Tutor AI chat (hanya Student App)
- Akses ke transkrip lengkap sesi tutor anak
- Ranking atau perbandingan nilai antar siswa
- Pengelolaan kelas atau kurikulum (Teacher/Admin Dashboard)
- Push notifications (roadmap Tahun 2 — infrastruktur dipersiapkan, tidak diaktifkan di pilot)

---

## §2 — USER PERSONAS

### 2.1 Orang Tua Satu Anak (Mayoritas)

| Atribut | Detail |
|---------|--------|
| Konteks | Orang tua siswa SMP/SMA dengan 1 anak di Yayasan |
| Literasi digital | Menengah — terbiasa WhatsApp, kadang e-commerce |
| Frekuensi buka app | 2–3× seminggu, terutama malam hari |
| Kebutuhan utama | "Bagaimana perkembangan anak saya minggu ini?" |
| Kekhawatiran | Tidak ingin terbebani jargon pendidikan |
| Ekspektasi UI | Bersih, cepat dimuat, tidak ada notifikasi berlebihan |

### 2.2 Orang Tua Multi-Anak

| Atribut | Detail |
|---------|--------|
| Konteks | 2–4 anak di jenjang berbeda dalam satu Yayasan |
| Kebutuhan tambahan | Selector anak yang cepat, highlight yang perlu perhatian |
| Pain point | Tidak ingin scroll panjang untuk ganti anak |
| Ekspektasi UI | Tab atau chip selector anak di header; badge notifikasi per anak |

### 2.3 Wali / Orang Tua Pengganti

| Atribut | Detail |
|---------|--------|
| Konteks | Didaftarkan manual oleh Admin Yayasan di `student_parent_relations` |
| Batasan | Akses identik dengan orang tua kandung — dibatasi oleh relasi di DB |
| Compliance | Data hanya muncul jika `student_parent_relations.is_active = true` |

---

## §3 — GOALS & SUCCESS METRICS

### 3.1 Product Goals

1. **Keterbacaan laporan:** ≥ 90% orang tua pilot menilai laporan "mudah dipahami" (survei onboarding).
2. **Adopsi consent digital:** ≥ 85% consent diselesaikan dalam aplikasi (bukan via kertas/verbal).
3. **Engagement aktivitas rumah:** ≥ 40% kartu aktivitas mendapat refleksi 1-tap dalam 48 jam.
4. **Zero PII violation:** 0 insiden kebocoran data anak (UU PDP No. 27/2022).

### 3.2 Acceptance Criteria (Launch-Ready)

- [ ] Login → Home dalam < 2 detik
- [ ] `child-report` API response → render layar dalam < 1 detik
- [ ] Tidak ada angka 0–100 atau nilai mentah tampil di seluruh aplikasi
- [ ] Consent decision memerlukan 2 tap untuk scope `EXTERNAL_PSYCHOLOGY` dan `DATA_EXPORT`
- [ ] Multi-child: ganti anak < 1 tap, laporan refresh otomatis
- [ ] Semua tap target ≥ 48dp
- [ ] WCAG 2.2 AA lulus (mode PRO_DASHBOARD)
- [ ] Edit hobi anak memicu `audit_events` `action='PARENT_EDIT_INTEREST'`

---

## §4 — INFORMATION ARCHITECTURE

### 4.1 Peta Layar

```
Parent App (flavor: parent)
│
├── /splash                        ← SplashScreen (shared dengan Student App)
├── /login                         ← LoginScreen (shared, role guard ORANG_TUA)
│
└── /parent/home (ParentHomeShell) ← HomeScreen utama
    ├── HeadlineInsightCard           (top card, LLM narrative)
    ├── HomeActivityCard              (saran aktivitas hari ini)
    ├── ChildSelectorStrip            (jika multi-anak)
    │
    ├── /parent/report                ← ChildReportScreen
    │   └── CompetencySnapshotList
    │
    ├── /parent/activities            ← HomeActivitiesScreen
    │   └── ActivityDetailModal
    │       └── ReflectionSheet       (bottom sheet 1-tap feedback)
    │
    ├── /parent/consents              ← ConsentInboxScreen
    │   └── ConsentDetailModal
    │       └── ConsentDecisionSheet  (2-tap untuk scope sensitif)
    │
    └── /parent/settings              ← SettingsScreen
        ├── InterestEditorSheet       (edit hobi anak)
        └── NotificationPrefsScreen
```

### 4.2 Navigation Rules

| Kondisi | Aksi Router |
|---------|-------------|
| Token tidak ada / expired | Redirect ke `/login` |
| Login sukses, role `ORANG_TUA` | Redirect ke `/parent/home` |
| Login sukses, role `SISWA` | Reject → `/login` + error `AUTHZ_WRONG_APP` |
| Login sukses, role `GURU`/`ADMIN` | Reject → `/login` + error `AUTHZ_WRONG_APP` |
| Akses route `/learn`, `/tutor`, `/quiz` | 404 (route tidak terdaftar di flavor parent) |
| `student_parent_relations` kosong | Tampilkan `EmptyState` "Belum ada anak terhubung — hubungi Admin Yayasan" |
| Consent baru masuk | Badge merah di bottom nav ikon Inbox |

### 4.3 Bottom Navigation (4 Tab)

| Tab | Icon | Route |
|-----|------|-------|
| Beranda | home_outlined | `/parent/home` |
| Laporan | bar_chart_outlined | `/parent/report` |
| Aktivitas | lightbulb_outlined | `/parent/activities` |
| Inbox | inbox_outlined | `/parent/consents` (badge jika ada PENDING) |

---

## §5 — UI/UX DESIGN SYSTEM

### 5.1 Theme Mode Parent App

Parent App **selalu** menggunakan `PRO_DASHBOARD` — tidak ada adaptive theme.

> Alasan: Orang tua adalah pengguna dewasa yang membutuhkan kejelasan data, bukan gamifikasi. Konsistensi tampilan penting untuk membangun kepercayaan terhadap laporan.

| Atribut | Nilai |
|---------|-------|
| Font | Inter |
| Theme mode | `PRO_DASHBOARD` (fixed) |
| Animasi | Minimal — transisi 200ms |
| Density | Padat tapi rapi |

### 5.2 Design Tokens (PRO_DASHBOARD — kutipan relevan)

Semua nilai dari `infrastructure/design_tokens/aleta.tokens.json`. Generated Dart: `lib/core/theme/tokens.g.dart`.

**Warna:**

```json
{
  "color": {
    "proDashboard": {
      "primary":    "#0F172A",
      "onPrimary":  "#F8FAFC",
      "secondary":  "#0EA5E9",
      "background": "#FFFFFF",
      "surface":    "#F8FAFC",
      "success":    "#16A34A",
      "warning":    "#D97706",
      "error":      "#DC2626",
      "textHigh":   "#0F172A",
      "textMid":    "#475569",
      "textLow":    "#94A3B8"
    }
  }
}
```

**Status kompetensi (warna semantik khusus Parent App):**

| Level | Warna token | Label tampil |
|-------|-------------|--------------|
| `MAHIR` | `success` `#16A34A` | Mahir |
| `REGULER` | `secondary` `#0EA5E9` | Berkembang |
| `FONDASI` | `warning` `#D97706` | Perlu Dukungan |
| `BUTUH_PERHATIAN` | `error` `#DC2626` | Butuh Perhatian |

> **PENTING:** Label di atas adalah **satu-satunya** representasi level. Angka P(L) seperti `0.42` **tidak boleh ditampilkan** ke orang tua.

**Typography (PRO_DASHBOARD scale):**

```json
{
  "display": { "size": 28, "lineHeight": 34, "weight": 700 },
  "title":   { "size": 20, "lineHeight": 28, "weight": 600 },
  "body":    { "size": 14, "lineHeight": 20, "weight": 400 },
  "caption": { "size": 12, "lineHeight": 16, "weight": 500 }
}
```

**Border Radius & Spacing:**

```json
{
  "radius":  { "card": 12, "button": 8, "input": 6 },
  "spacing": { "1": 4, "2": 8, "3": 12, "4": 16, "6": 24, "8": 32 },
  "touchTarget": { "min": 48 }
}
```

### 5.3 Component Inventory (Parent App)

#### Atoms yang dibutuhkan

| Komponen | Variants | States Wajib |
|----------|----------|--------------|
| `Button` | `primary`, `secondary`, `ghost`, `destructive` | default, pressed, loading, disabled |
| `Badge` | `count`, `dot` | success, warning, error, neutral |
| `Chip` | `filter` (pilih periode) | default, selected |
| `ProgressBar` | `linear` | determinate |
| `Skeleton` | `text`, `block` | shimmer |
| `Toast` | `success`, `info`, `warning`, `error` | enter, idle, exit |

#### Molecules yang dibutuhkan

| Komponen | Deskripsi |
|----------|-----------|
| `CompetencySnapshotCard` | Elemen + level label (tanpa angka) + warna semantik |
| `ActivityCard` | Kartu aktivitas rumah: judul, durasi, bahan, tombol Mulai |
| `ConsentItem` | Item consent: pemohon, scope dalam bahasa awam, tombol Setujui/Tolak |
| `ChildSelectorChip` | Chip nama anak untuk multi-child switcher |
| `HeadlineInsightCard` | Narasi LLM + strip snapshot kompetensi |
| `EmptyState` | Gambar + pesan + optional CTA |

#### Organisms yang dibutuhkan

| Komponen | Deskripsi |
|----------|-----------|
| `ParentHomeShell` | Layout utama dengan ChildSelector (jika multi) + 2 card utama |
| `ConsentInbox` | List `ConsentItem` dengan filter PENDING/RESOLVED |
| `ReflectionBottomSheet` | 3 emoji tap + label + submit |
| `ConsentDecisionSheet` | Konfirmasi decision: 1-tap biasa, 2-tap untuk scope sensitif |

---

## §6 — SCREEN SPECIFICATIONS

### 6.1 SplashScreen (`/splash`)

Identik dengan Student App — shared widget. Hanya entry point berbeda (`main_parent.dart`). Setelah validasi token, jika role `ORANG_TUA` → navigate `/parent/home`.

---

### 6.2 LoginScreen (`/login`)

Shared dengan Student App (`login_screen.dart`). Role guard di `app_router.dart`:

```dart
// lib/core/routing/app_router.dart (flavor: parent)
redirect: (context, state) {
  final authState = context.read<AuthBloc>().state;
  if (authState is Authenticated && authState.role != 'ORANG_TUA') {
    return '/login?error=AUTHZ_WRONG_APP';
  }
  return null;
},
```

Error `AUTHZ_WRONG_APP` → tampilkan toast: "Gunakan aplikasi siswa untuk login sebagai pelajar."

---

### 6.3 HomeScreen (`/parent/home`)

**Tujuan:** Berikan gambaran cepat kondisi anak hari ini dalam < 5 detik baca.

**Layout (single-child):**

```
┌─────────────────────────────────────────────────┐
│  Selamat pagi, Bu Rini 👋                        │
│  [Sandi · Kelas 7-A · SMP]                      │
├─────────────────────────────────────────────────┤
│  HEADLINE INSIGHT CARD                          │
│  "Sandi membuat lompatan besar di Aljabar       │
│   minggu ini. Konsep geometri masih berkembang." │
│  [Aljabar: MAHIR] [Geometri: BERKEMBANG]        │
│  → Lihat laporan lengkap                        │
├─────────────────────────────────────────────────┤
│  AKTIVITAS HARI INI                             │
│  🏃 Hitung Operan Sepak Bola · 15 mnt           │
│  Bantu Sandi menghitung persentase operan...    │
│  [Mulai →]                                      │
├─────────────────────────────────────────────────┤
│  Beranda  |  Laporan  |  Aktivitas  |  Inbox🔴  │
└─────────────────────────────────────────────────┘
```

**Layout multi-child (tambahan di bawah header):**

```dart
// lib/features/parent/presentation/widgets/child_selector_strip.dart
class ChildSelectorStrip extends StatelessWidget {
  final List<ChildProfile> children;
  final String selectedChildId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: children.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final child = children[i];
          final isSelected = child.studentId == selectedChildId;
          return FilterChip(
            label: Text(child.name),
            selected: isSelected,
            onSelected: (_) => onSelect(child.studentId),
          );
        },
      ),
    );
  }
}
```

**Kode stub HeadlineInsightCard:**

```dart
// lib/features/parent/presentation/widgets/headline_insight_card.dart
class HeadlineInsightCard extends StatelessWidget {
  final String studentName;
  final String insight;
  final List<CompetencySnapshot> snapshots;
  final VoidCallback onTapDetail;

  const HeadlineInsightCard({
    super.key,
    required this.studentName,
    required this.insight,
    required this.snapshots,
    required this.onTapDetail,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cerita $studentName minggu ini',
              style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(insight, style: t.textTheme.bodyMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: snapshots.map((s) => CompetencyLevelChip(snapshot: s)).toList(),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onTapDetail,
              child: const Text('Lihat laporan lengkap →'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### 6.4 ChildReportScreen (`/parent/report`)

**Tujuan:** Laporan detail perkembangan anak per periode — tanpa satu pun angka mentah.

**Elemen:**

- AppBar: nama anak + periode selector (Chip: Minggu Ini / Bulan Ini / Semester)
- Summary row: 3 kartu kecil — "Dikuasai: 5", "Berkembang: 3", "Butuh Perhatian: 1"
- Section "Perkembangan per Bidang Studi": grouped by `elemen`
  - Per elemen: nama elemen + `CompetencyLevelChip` (MAHIR/REGULER/FONDASI/BUTUH_PERHATIAN)
  - Deskripsi naratif singkat (dari `headline_insight` API)
- Section "Miskonsepsi yang Perlu Diperhatikan": narasi positif, bukan list kesalahan
  - Contoh tampil: "Sandi masih memperkuat pemahaman tentang operasi bilangan negatif."
  - **DILARANG tampil:** "Sandi salah 7 kali pada tipe soal operasi bilangan negatif."

**Kode stub CompetencyLevelChip:**

```dart
// lib/features/parent/presentation/widgets/competency_level_chip.dart
class CompetencyLevelChip extends StatelessWidget {
  final CompetencySnapshot snapshot;

  const CompetencyLevelChip({super.key, required this.snapshot});

  Color _bgColor(BuildContext context) {
    switch (snapshot.level) {
      case 'MAHIR': return const Color(0xFF16A34A);          // success
      case 'REGULER': return const Color(0xFF0EA5E9);        // secondary
      case 'FONDASI': return const Color(0xFFD97706);        // warning
      case 'BUTUH_PERHATIAN': return const Color(0xFFDC2626); // error
      default: return const Color(0xFF94A3B8);               // textLow
    }
  }

  String _label() {
    switch (snapshot.level) {
      case 'MAHIR': return 'Mahir';
      case 'REGULER': return 'Berkembang';
      case 'FONDASI': return 'Perlu Dukungan';
      case 'BUTUH_PERHATIAN': return 'Butuh Perhatian';
      default: return snapshot.level;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bgColor(context).withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _bgColor(context), width: 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(
          snapshot.elemen,
          style: TextStyle(fontSize: 12, color: _bgColor(context), fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 4),
        Text('· ${_label()}', style: TextStyle(fontSize: 12, color: _bgColor(context))),
      ]),
    );
  }
}
```

---

### 6.5 HomeActivitiesScreen (`/parent/activities`)

**Tujuan:** Berikan 1–3 aktivitas rumah yang bisa dilakukan bersama anak hari ini.

**Elemen:**

- Header: "Aktivitas Hari Ini untuk [Nama Anak]"
- `ActivityCard` per aktivitas (max 3 per hari):
  - Judul aktivitas (hobby-aware, contoh: "Hitung Operan Sepak Bola")
  - Durasi + bahan yang dibutuhkan
  - Instruksi singkat 2–3 kalimat
  - Tombol [Mulai →] → buka `ActivityDetailModal`

**ActivityDetailModal (bottom sheet):**

- Judul + instruksi lengkap step-by-step
- Scroll view untuk instruksi panjang
- Tombol [Selesai — Bagaimana jalannya?] → buka `ReflectionBottomSheet`

**ReflectionBottomSheet:**

```dart
// lib/features/parent/presentation/widgets/reflection_bottom_sheet.dart
class ReflectionBottomSheet extends StatelessWidget {
  final String activityId;
  final String studentId;

  const ReflectionBottomSheet({
    super.key,
    required this.activityId,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Bagaimana jalannya?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ReflectionOption(
                emoji: '😀',
                label: 'Berjalan lancar',
                value: 'SMOOTH',
                onTap: (v) => _submit(context, v),
              ),
              _ReflectionOption(
                emoji: '😐',
                label: 'Sedikit kesulitan',
                value: 'STRUGGLED',
                onTap: (v) => _submit(context, v),
              ),
              _ReflectionOption(
                emoji: '😟',
                label: 'Kurang tertarik',
                value: 'DISENGAGED',
                onTap: (v) => _submit(context, v),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Lewati'),
          ),
        ],
      ),
    );
  }

  void _submit(BuildContext context, String value) {
    context.read<ActivitiesBloc>().add(ReflectionSubmitted(
      activityId: activityId,
      studentId: studentId,
      result: value,
    ));
    Navigator.pop(context);
  }
}
```

---

### 6.6 ConsentInboxScreen (`/parent/consents`)

**Tujuan:** Titik tunggal persetujuan data anak sesuai UU PDP No. 27/2022.

**Elemen:**

- Tab filter: [Menunggu] (default) / [Sudah Diputuskan]
- `ConsentItem` per consent PENDING:
  - Avatar inisial pemohon
  - Nama pemohon dalam bahasa awam ("Bu Sri — Guru Wali Kelas")
  - Scope dalam bahasa awam (lihat mapping §7.2)
  - Alasan/reason dari pemohon
  - Tanggal kedaluwarsa (formatted: "Berlaku hingga 31 Des 2026")
  - Tombol [Setujui] (primary, hijau) dan [Tolak] (ghost, merah)
- Consent yang sudah diputuskan tampil dengan badge "Disetujui ✓" atau "Ditolak ✗" (read-only)

**ConsentDecisionSheet (bottom sheet konfirmasi):**

```dart
// lib/features/parent/presentation/widgets/consent_decision_sheet.dart
class ConsentDecisionSheet extends StatefulWidget {
  final ConsentItem consent;
  final String decision; // 'APPROVED' | 'REJECTED'

  const ConsentDecisionSheet({
    super.key,
    required this.consent,
    required this.decision,
  });

  @override
  State<ConsentDecisionSheet> createState() => _ConsentDecisionSheetState();
}

class _ConsentDecisionSheetState extends State<ConsentDecisionSheet> {
  bool _firstTapDone = false;

  bool get _isSensitiveScope =>
      ['EXTERNAL_PSYCHOLOGY', 'DATA_EXPORT'].contains(widget.consent.scope);

  @override
  Widget build(BuildContext context) {
    final actionLabel = widget.decision == 'APPROVED' ? 'Setujui' : 'Tolak';
    final isApprove = widget.decision == 'APPROVED';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isSensitiveScope && !_firstTapDone
                ? 'Perhatian: Permintaan Sensitif'
                : 'Konfirmasi $actionLabel',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            _isSensitiveScope && !_firstTapDone
                ? 'Permintaan ini melibatkan data eksternal. Pastikan Anda memahami implikasinya sebelum melanjutkan.'
                : 'Anda akan ${isApprove ? "menyetujui" : "menolak"}: "${widget.consent.scopeInPlainText}"',
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isApprove
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFDC2626),
              ),
              onPressed: () {
                if (_isSensitiveScope && !_firstTapDone) {
                  setState(() => _firstTapDone = true); // tap pertama: warning
                  return;
                }
                // tap kedua (atau scope non-sensitif): eksekusi
                context.read<ConsentBloc>().add(ConsentDecisionMade(
                  consentId: widget.consent.consentId,
                  decision: widget.decision,
                ));
                Navigator.pop(context);
              },
              child: Text(_isSensitiveScope && !_firstTapDone
                  ? 'Saya Mengerti, Lanjutkan'
                  : '$actionLabel Sekarang'),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

### 6.7 SettingsScreen (`/parent/settings`)

**Elemen:**

- Profil orang tua (nama, email — read-only, perubahan via Keycloak self-service)
- Section "Hobi Anak": editable list hobi per anak yang terhubung
  - Edit memunculkan `InterestEditorSheet`
  - Setiap save → `POST /api/v1/parent/update-child-interests` + emit `audit_events` `action='PARENT_EDIT_INTEREST'`
- Section "Notifikasi" (opt-in toggle per channel — disabled state untuk pilot, enabled Tahun 2):
  - Ringkasan Mingguan (Senin pagi)
  - Red Flag Alert
  - Consent Baru Masuk
  - Tutor Handoff
- Tombol "Keluar" (logout)

---

## §7 — PRIVACY & CONSENT RULES

### 7.1 Aturan Tampilan Data (WAJIB DIPATUHI)

| Aturan | Detail |
|--------|--------|
| No numeric grade | Tidak ada P(L) value, angka 0–100, atau persentase benar/salah |
| No raw misconception | Miskonsepsi diubah jadi narasi positif: "masih memperkuat X" |
| No ranking | Tidak ada perbandingan dengan siswa lain atau rata-rata kelas |
| No tutor transcript | Transkrip sesi tutor anak tidak dapat diakses orang tua |
| No cross-child data | Orang tua multi-anak hanya bisa lihat satu anak dalam satu tampilan |
| Ownership validation | Setiap request yang mengandung `student_id` divalidasi backend terhadap `student_parent_relations` |

### 7.2 Consent Scope — Mapping ke Bahasa Awam

| Scope (kode API) | Label tampil untuk orang tua |
|------------------|------------------------------|
| `INTERNAL_ASSESSMENT` | Penilaian internal sekolah |
| `TEACHER_VIEW` | Akses laporan oleh guru |
| `EXTERNAL_PSYCHOLOGY` | Tes psikologi oleh lembaga luar (SENSITIF) |
| `DATA_EXPORT` | Ekspor data untuk laporan yayasan (SENSITIF) |
| `RESEARCH` | Partisipasi dalam penelitian pendidikan |

Scope bertanda **(SENSITIF)** membutuhkan konfirmasi 2-tap di `ConsentDecisionSheet`.

### 7.3 Audit Trail untuk Aksi Parent

Setiap aksi berikut WAJIB memunculkan entry di `aleta_core.audit_events`:

| Aksi | `action` di audit_events |
|------|--------------------------|
| Menyetujui consent | `CONSENT_APPROVED` |
| Menolak consent | `CONSENT_REJECTED` |
| Edit hobi anak | `PARENT_EDIT_INTEREST` |
| Export laporan (jika diaktifkan) | `PARENT_REPORT_EXPORT` |

Implementasi audit di backend — Flutter hanya memastikan request dikirim; tidak perlu logika audit di sisi client.

---

## §8 — API CONTRACTS

### 8.1 Global Protocol

- Base URL: `https://api.{tenant}.aleta.sch.id/api/v1`
- Auth: `Authorization: Bearer <JWT>` (RS256, Keycloak, role = `ORANG_TUA`)
- Idempotency: `Idempotency-Key: <uuid-v4>` untuk semua POST mutasi
- `student_id` pada setiap request divalidasi backend terhadap `student_parent_relations` — jika tidak cocok → `403 AUTHZ_NOT_PARENT`

### 8.2 `POST /api/v1/auth/login`

Identik dengan Student App (§8.2 PRD_STUDENT_APP.md). Respons mengandung `"role": "ORANG_TUA"`.

---

### 8.3 `GET /api/v1/parent/child-report`

**Query params:**

| Param | Tipe | Wajib | Keterangan |
|-------|------|-------|------------|
| `student_id` | UUID | Ya | Divalidasi terhadap `student_parent_relations` |
| `period` | ENUM | Tidak | `weekly` (default), `monthly`, `semester` |

**Response 200:**

```json
{
  "success": true,
  "data": {
    "student_id": "7b8971f4-...",
    "student_name": "Sandi",
    "period": "weekly",
    "summary": {
      "mastered_this_period": 5,
      "in_progress": 3,
      "struggling": 1
    },
    "headline_insight": "Sandi membuat lompatan besar di Aljabar minggu ini. Konsep geometri masih berkembang.",
    "no_numeric_grade": true,
    "competency_snapshots": [
      { "elemen": "Aljabar", "level": "MAHIR" },
      { "elemen": "Geometri", "level": "REGULER" },
      { "elemen": "Bilangan", "level": "MAHIR" }
    ],
    "positive_misconception_note": "Sandi masih memperkuat pemahaman tentang operasi bilangan negatif.",
    "generated_at": "2026-05-23T05:00:00Z"
  }
}
```

**Error codes:** `AUTHZ_NOT_PARENT` (403), `NOT_FOUND_STUDENT` (404)

---

### 8.4 `GET /api/v1/parent/home-activities`

**Query params:** `student_id` (UUID, wajib)

**Response 200:**

```json
{
  "success": true,
  "data": {
    "student_id": "7b8971f4-...",
    "anchored_to_tp_id": "TP_MAT_7_ALJABAR",
    "activities": [
      {
        "activity_id": "act-8f3a...",
        "title": "Hitung Operan Sepak Bola",
        "duration_minutes": 15,
        "materials": ["pena", "kertas"],
        "instruction": "Ajak Sandi menghitung persentase keberhasilan operan saat menonton pertandingan bola bersama.",
        "interest_match": "SEPAK_BOLA"
      }
    ],
    "generated_at": "2026-05-23T05:00:00Z"
  }
}
```

---

### 8.5 `POST /api/v1/parent/activity-reflection`

**Headers:** `Idempotency-Key: <uuid>`

**Request:**

```json
{
  "activity_id": "act-8f3a...",
  "student_id": "7b8971f4-...",
  "result": "SMOOTH"
}
```

`result` ∈ `{ "SMOOTH", "STRUGGLED", "DISENGAGED" }`

**Response 200:**

```json
{
  "success": true,
  "message": "Terima kasih atas refleksinya! Ini membantu kami menyesuaikan aktivitas selanjutnya."
}
```

Refleksi ini diumpan-balikkan ke `interest_vector` siswa (Doc 09 §5.C) oleh backend — Flutter tidak perlu handle logika ini.

---

### 8.6 `GET /api/v1/consent/active`

**Query params:** `student_id` (UUID, wajib)

**Response 200:**

```json
{
  "success": true,
  "data": {
    "consents": [
      {
        "consent_id": "cns-1a2b...",
        "scope": "EXTERNAL_PSYCHOLOGY",
        "scope_plain_text": "Tes psikologi oleh lembaga luar",
        "requested_by_name": "Bu Sri — Guru Wali Kelas",
        "reason": "Penyaringan minat bakat akhir kelas 9 oleh Lembaga Psikologi X.",
        "status": "PENDING",
        "expires_at": "2026-12-31T23:59:59Z",
        "created_at": "2026-05-20T08:00:00Z"
      }
    ],
    "pending_count": 1
  }
}
```

---

### 8.7 `POST /api/v1/consent/{consent_id}/decision`

**Headers:** `Idempotency-Key: <uuid>`

**Path param:** `consent_id` (UUID)

**Request:**

```json
{ "decision": "APPROVED" }
```

`decision` ∈ `{ "APPROVED", "REJECTED" }`

**Response 200:**

```json
{
  "success": true,
  "data": {
    "consent_id": "cns-1a2b...",
    "status": "APPROVED",
    "decided_at": "2026-05-24T10:15:00Z"
  }
}
```

**Error codes:** `AUTHZ_NOT_PARENT` (403), `NOT_FOUND_CONSENT` (404), `CONFLICT_ALREADY_DECIDED` (409)

Backend akan emit `audit_events` `action='CONSENT_APPROVED'` atau `'CONSENT_REJECTED'` secara otomatis.

---

### 8.8 `GET /api/v1/parent/children`

Endpoint untuk list semua anak yang terhubung ke orang tua (multi-child support).

**Response 200:**

```json
{
  "success": true,
  "data": {
    "children": [
      {
        "student_id": "7b8971f4-...",
        "name": "Sandi",
        "fase_aktif": "FASE_D",
        "unit": "SMP",
        "class_name": "Kelas 7-A",
        "has_pending_consent": true
      },
      {
        "student_id": "9c1d2e3f-...",
        "name": "Dewi",
        "fase_aktif": "FASE_B",
        "unit": "SD",
        "class_name": "Kelas 4-B",
        "has_pending_consent": false
      }
    ]
  }
}
```

---

## §9 — TECHNICAL ARCHITECTURE

### 9.1 Build Flavor Wiring

```
frontend_flutter/
├── lib/
│   ├── main_student.dart    ← BUKAN dokumen ini
│   └── main_parent.dart     ← ENTRY POINT Parent App
│       └── runApp(AletaApp(flavor: AppFlavor.parent))
```

**`main_parent.dart`:**

```dart
// lib/main_parent.dart
import 'package:flutter/material.dart';
import 'app.dart';
import 'core/config/app_flavor.dart';

void main() {
  runApp(const AletaApp(flavor: AppFlavor.parent));
}
```

**`AppFlavor` enum:**

```dart
// lib/core/config/app_flavor.dart
enum AppFlavor { student, parent }
```

**Route guard di `app_router.dart` untuk flavor parent:**

```dart
// lib/core/routing/app_router.dart
GoRouter buildRouter(AppFlavor flavor) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login',  builder: (_, __) => const LoginScreen()),

      // === PARENT ROUTES (hanya tersedia di flavor parent) ===
      if (flavor == AppFlavor.parent) ...[
        GoRoute(path: '/parent/home',       builder: (_, __) => const ParentHomeScreen()),
        GoRoute(path: '/parent/report',     builder: (_, s) => ChildReportScreen(
          studentId: s.queryParameters['student_id']!,
        )),
        GoRoute(path: '/parent/activities', builder: (_, __) => const HomeActivitiesScreen()),
        GoRoute(path: '/parent/consents',   builder: (_, __) => const ConsentInboxScreen()),
        GoRoute(path: '/parent/settings',   builder: (_, __) => const SettingsScreen()),
      ],

      // === STUDENT ROUTES (hanya tersedia di flavor student) ===
      if (flavor == AppFlavor.student) ...[
        GoRoute(path: '/home',         builder: (_, __) => const HomeShell()),
        GoRoute(path: '/learn/:subjectId', builder: (_, s) => QuizPlayerScreen(
          subjectId: s.pathParameters['subjectId']!,
        )),
        GoRoute(path: '/tutor',        builder: (_, __) => const TutorChatScreen()),
        GoRoute(path: '/passport',     builder: (_, __) => const CognitivePassportScreen()),
      ],
    ],
    redirect: _buildRedirect(flavor),
  );
}
```

### 9.2 Folder Structure (Parent-Specific)

```
lib/features/parent/
├── data/
│   ├── repositories/
│   │   ├── parent_report_repository.dart
│   │   ├── home_activities_repository.dart
│   │   └── consent_repository.dart
│   └── models/
│       ├── child_report_model.dart
│       ├── activity_model.dart
│       └── consent_model.dart
├── domain/
│   ├── entities/
│   │   ├── child_profile.dart
│   │   ├── competency_snapshot.dart
│   │   └── consent_item.dart
│   └── use_cases/
│       ├── get_child_report_use_case.dart
│       ├── submit_activity_reflection_use_case.dart
│       └── decide_consent_use_case.dart
└── presentation/
    ├── bloc/
    │   ├── parent_home_bloc.dart
    │   ├── child_report_bloc.dart
    │   ├── activities_bloc.dart
    │   └── consent_bloc.dart
    ├── screens/
    │   ├── parent_home_screen.dart
    │   ├── child_report_screen.dart
    │   ├── home_activities_screen.dart
    │   ├── consent_inbox_screen.dart
    │   └── settings_screen.dart
    └── widgets/
        ├── headline_insight_card.dart
        ├── competency_level_chip.dart
        ├── child_selector_strip.dart
        ├── activity_card.dart
        ├── consent_item_tile.dart
        ├── reflection_bottom_sheet.dart
        └── consent_decision_sheet.dart
```

Shared widgets (atoms/molecules) di `lib/shared/widgets/` — sama antara flavor student dan parent.

### 9.3 Dependencies Tambahan (selain yang ada di Student App)

Tidak ada dependency tambahan khusus parent. Semua dependency sudah ada di `pubspec.yaml` Student App (flutter_bloc, go_router, dio, hive_flutter, dsb.).

---

## §10 — STATE MANAGEMENT (BLoC CONTRACTS)

### 10.1 ParentHomeBloc

```dart
// EVENTS
abstract class ParentHomeEvent {}
class ParentHomeStarted extends ParentHomeEvent {}
class ChildSelected extends ParentHomeEvent { final String studentId; ChildSelected(this.studentId); }
class HomeRefreshRequested extends ParentHomeEvent {}

// STATES
abstract class ParentHomeState {}
class ParentHomeLoading extends ParentHomeState {}
class ParentHomeLoaded extends ParentHomeState {
  final List<ChildProfile> children;
  final String selectedStudentId;
  final ChildReport report;           // data dari /parent/child-report?period=weekly
  final List<Activity> todayActivities; // top 1 dari /parent/home-activities
  final int pendingConsentCount;
  ParentHomeLoaded({
    required this.children,
    required this.selectedStudentId,
    required this.report,
    required this.todayActivities,
    required this.pendingConsentCount,
  });
}
class ParentHomeError extends ParentHomeState { final String message; ParentHomeError(this.message); }
```

### 10.2 ChildReportBloc

```dart
// EVENTS
abstract class ChildReportEvent {}
class ReportLoaded extends ChildReportEvent {
  final String studentId;
  final String period; // 'weekly' | 'monthly' | 'semester'
  ReportLoaded({required this.studentId, required this.period});
}

// STATES
abstract class ChildReportState {}
class ChildReportLoading extends ChildReportState {}
class ChildReportSuccess extends ChildReportState {
  final ChildReport report;
  ChildReportSuccess(this.report);
}
class ChildReportError extends ChildReportState { final String message; ChildReportError(this.message); }
```

### 10.3 ActivitiesBloc

```dart
// EVENTS
abstract class ActivitiesEvent {}
class ActivitiesLoaded extends ActivitiesEvent { final String studentId; ActivitiesLoaded(this.studentId); }
class ReflectionSubmitted extends ActivitiesEvent {
  final String activityId;
  final String studentId;
  final String result; // 'SMOOTH' | 'STRUGGLED' | 'DISENGAGED'
  ReflectionSubmitted({required this.activityId, required this.studentId, required this.result});
}

// STATES
abstract class ActivitiesState {}
class ActivitiesLoading extends ActivitiesState {}
class ActivitiesLoaded extends ActivitiesState {
  final List<Activity> activities;
  ActivitiesLoaded(this.activities);
}
class ReflectionSent extends ActivitiesState {} // transient state, kembali ke Loaded setelahnya
class ActivitiesError extends ActivitiesState { final String message; ActivitiesError(this.message); }
```

### 10.4 ConsentBloc

```dart
// EVENTS
abstract class ConsentEvent {}
class ConsentInboxLoaded extends ConsentEvent { final String studentId; ConsentInboxLoaded(this.studentId); }
class ConsentDecisionMade extends ConsentEvent {
  final String consentId;
  final String decision; // 'APPROVED' | 'REJECTED'
  ConsentDecisionMade({required this.consentId, required this.decision});
}

// STATES
abstract class ConsentState {}
class ConsentLoading extends ConsentState {}
class ConsentInboxReady extends ConsentState {
  final List<ConsentItem> pendingConsents;
  final List<ConsentItem> resolvedConsents;
  ConsentInboxReady({required this.pendingConsents, required this.resolvedConsents});
}
class ConsentDecisionInProgress extends ConsentState {}
class ConsentDecisionSuccess extends ConsentState { final String consentId; ConsentDecisionSuccess(this.consentId); }
class ConsentError extends ConsentState { final String message; ConsentError(this.message); }
```

---

## §11 — NON-FUNCTIONAL REQUIREMENTS

### 11.1 Performance

| Metrik | Target | Ukur via |
|--------|--------|----------|
| Login → Home rendered | < 2 detik | Flutter DevTools |
| child-report response → render | < 1 detik | Dio stopwatch interceptor |
| Ganti anak (ChildSelectorStrip) | < 500ms | stopwatch |
| Consent decision (tap → feedback) | < 800ms | |
| Frame rate | ≥ 60fps | Flutter Performance overlay |

### 11.2 Keamanan

| Aturan | Implementasi |
|--------|--------------|
| JWT algorithm | RS256 / ES256 saja — validasi `alg` header di interceptor |
| `student_id` ownership | Backend validasi `student_parent_relations` — Flutter tidak bypass |
| 2-tap consent | `ConsentDecisionSheet` wajib untuk scope `EXTERNAL_PSYCHOLOGY`, `DATA_EXPORT` |
| Token storage | `hive` + `FlutterSecureStorage` untuk key encryption |
| Log redaction | `LoggingInterceptor` redact: `token`, `full_name`, `email` |
| No raw P(L) | Frontend guard: jika response mengandung field `current_p_l`, jangan render ke UI |

### 11.3 Aksesibilitas

| Aturan | Nilai |
|--------|-------|
| Standar | WCAG 2.2 AA |
| Tap target minimum | 48dp (PRO_DASHBOARD mode) |
| Text scaling | 1.0 – 1.5× |
| Semantics | Wajib pada semua CTA: "Setujui consent tes psikologi", "Tolak consent" |
| Kontras warna | ≥ WCAG AA — terutama `CompetencyLevelChip` (warna-status kecil) |

### 11.4 Offline Behavior

| Kondisi | Perilaku |
|---------|----------|
| Buka app tanpa koneksi | Render halaman dari cache hive; tampilkan banner "Mode offline" |
| Submit refleksi tanpa koneksi | Queue lokal, sync saat kembali online |
| Submit consent tanpa koneksi | Tampilkan error toast "Koneksi diperlukan untuk keputusan consent" — JANGAN queue (consent tidak boleh disimpan lokal) |

### 11.5 Lokalisasi

- Default: `id_ID` — ARB file: `lib/l10n/intl_id.arb` (shared dengan Student App)
- Semua teks UI via `AppLocalizations` — tidak ada string literal di widget layer
- Scope consent dalam bahasa awam diambil dari API field `scope_plain_text` — tidak di-hardcode di Flutter

---

## §12 — IMPLEMENTATION TASK MAP

| Task | Judul | Layer yang Dibuat |
|------|-------|-------------------|
| T-601 | Parent build flavor wiring | `main_parent.dart`, `app_router.dart` flavor guard |
| T-602 | ParentHomeShell + HeadlineInsightCard | `parent_home_screen.dart`, `headline_insight_card.dart`, `child_selector_strip.dart` |
| T-603 | `/parent/child-report` endpoint + screen | `child_report_repository.dart`, `child_report_bloc.dart`, `child_report_screen.dart` |
| T-604 | `/parent/home-activities` endpoint + screen | `home_activities_repository.dart`, `activities_bloc.dart`, `home_activities_screen.dart`, `reflection_bottom_sheet.dart` |
| T-605 | Headline insight LLM prompt + safety | (backend/AI task — Flutter hanya consume response) |
| T-606 | ConsentInbox screen | `consent_repository.dart`, `consent_bloc.dart`, `consent_inbox_screen.dart`, `consent_decision_sheet.dart` |

---

## §13 — ACCEPTANCE CRITERIA CHECKLIST

### Setup & Flavor

- [ ] `flutter run --flavor parent -t lib/main_parent.dart` berjalan tanpa error
- [ ] Route `/learn`, `/tutor`, `/quiz` tidak terdaftar di router flavor parent
- [ ] Akses dengan role `SISWA` atau `GURU` → error toast `AUTHZ_WRONG_APP`
- [ ] `tokens.g.dart` di-consume — tidak ada `Color(0xFF...)` hardcoded di widget parent

### Home Screen

- [ ] `HeadlineInsightCard` tampil dengan narasi teks (bukan P(L) number)
- [ ] `CompetencyLevelChip` tampil dengan warna dan label yang benar untuk semua 4 level
- [ ] Multi-child: `ChildSelectorStrip` tampil jika `children.length > 1`
- [ ] Ganti anak via chip → `ChildReportBloc` dan `ActivitiesBloc` refresh untuk student baru
- [ ] Badge merah di bottom nav Inbox jika `pending_consent_count > 0`

### Child Report Screen

- [ ] Tidak ada angka P(L), persentase, atau nilai 0–100 di seluruh layar
- [ ] `competency_snapshots` ditampilkan sebagai chip dengan warna semantik
- [ ] Periode selector (Chip) berfungsi: pilih Monthly → API dipanggil ulang dengan `period=monthly`
- [ ] `positive_misconception_note` tampil dalam bahasa positif ("masih memperkuat", bukan "salah X kali")

### Home Activities Screen

- [ ] `ActivityCard` tampil dengan judul, durasi, bahan, tombol [Mulai →]
- [ ] `ActivityDetailModal` terbuka saat tap [Mulai →]
- [ ] `ReflectionBottomSheet` terbuka setelah tap [Selesai] di modal
- [ ] 3 emoji + label tampil dengan benar (SMOOTH / STRUGGLED / DISENGAGED)
- [ ] Tap emoji → `POST /api/v1/parent/activity-reflection` dengan `Idempotency-Key`
- [ ] Toast sukses muncul setelah refleksi terkirim

### Consent Inbox

- [ ] List consent dengan status `PENDING` tampil di tab [Menunggu]
- [ ] Scope consent tampil dalam bahasa awam (dari `scope_plain_text`), bukan kode API
- [ ] Tap [Setujui] scope normal → `ConsentDecisionSheet` 1-tap langsung eksekusi
- [ ] Tap [Setujui] scope `EXTERNAL_PSYCHOLOGY` atau `DATA_EXPORT` → 2-tap wajib (warning dulu)
- [ ] Setelah decision → item pindah ke tab [Sudah Diputuskan] dengan badge status
- [ ] `Idempotency-Key` dikirim di setiap `POST /consent/{id}/decision`
- [ ] Submit consent tanpa koneksi → error toast (tidak di-queue)

### Privacy Compliance

- [ ] Audit events dibuat backend untuk: `CONSENT_APPROVED`, `CONSENT_REJECTED`, `PARENT_EDIT_INTEREST`
- [ ] Field `current_p_l` dari response API tidak dirender ke UI manapun
- [ ] Tidak ada ranking atau perbandingan antar siswa di seluruh layar

### Aksesibilitas & Performa

- [ ] Axe / Accessibility Inspector: tidak ada critical violation
- [ ] `CompetencyLevelChip` lulus kontras warna WCAG AA (warna teks vs background chip)
- [ ] `child-report` API response → layar render < 1 detik di jaringan 4G
- [ ] Semua tombol Consent memiliki `Semantics(label: ...)` yang deskriptif

---

> **Untuk AI agent yang mengimplementasikan:** Mulai dari T-601 (flavor wiring). Pastikan route guard berfungsi sebelum mengerjakan layar. Setiap screen yang mengandung data anak wajib ditest dengan `student_id` yang bukan milik orang tua login — harus mendapat error `AUTHZ_NOT_PARENT` (403), bukan data. Privacy rule §7.1 bersifat non-negotiable: gunakan grep `current_p_l` sebelum commit untuk memastikan tidak ada P(L) value yang lolos ke widget layer.
