---
doc: "PRD-01"
title: "PRD Student App"
type: "product-requirements-document"
version: "1.0"
status: "approved"
app: "Student App (Flutter — flavor: student)"
authored: "2026-05-24"
blueprints_consumed: ["02", "03", "04", "05", "07", "09", "14", "15"]
vibe_coding_target: "flutter-coder, ai-engine-coder, backend-coder"
tasks_covered: [T-301, T-302, T-303, T-304, T-305, T-306, T-307, T-308, T-309, T-310, T-311, T-312, T-313, T-509]
---

# PRD — ALETA Student App
### AI-Powered Adaptive Learning · Flutter Mobile · Flavor: `student`

> **Petunjuk penggunaan untuk AI agent:** Dokumen ini adalah **satu-satunya panduan** yang dibutuhkan untuk membangun Student App dari nol. Baca secara urut dari §1 hingga §13. Setiap kode stub dapat langsung digunakan. Nilai numerik (threshold, ukuran, warna) adalah FINAL — jangan mengubah tanpa mengacu ke `STATE.yaml.sentinels`.

---

## DAFTAR ISI

| § | Judul | Isi Kunci |
|---|-------|-----------|
| 1 | Product Overview | Visi, scope, exclusions |
| 2 | User Personas | Profil pengguna per fase |
| 3 | Goals & Success Metrics | KPI dan acceptance criteria |
| 4 | Information Architecture | Peta layar & navigasi |
| 5 | UI/UX Design System | Tokens, tema, komponen |
| 6 | Screen Specifications | Setiap layar detail |
| 7 | Adaptive Learning Loop | BKT state machine + quiz flow |
| 8 | API Contracts | Semua endpoint student |
| 9 | Technical Architecture | Flutter BLoC + struktur folder |
| 10 | State Management | BLoC event-state contracts |
| 11 | Non-Functional Requirements | Performa, keamanan, aksesibilitas |
| 12 | Implementation Task Map | Pemetaan ke T-NNN |
| 13 | Acceptance Criteria Checklist | Definition of Done per fitur |

---

## §1 — PRODUCT OVERVIEW

### 1.1 Visi Produk

Student App adalah aplikasi mobile Flutter yang menjadi **antarmuka utama siswa** dengan ekosistem ALETA. Aplikasi ini memvisualisasikan jalur belajar adaptif berbasis Bayesian Knowledge Tracing (BKT), memungkinkan siswa berlatih soal, berinteraksi dengan AI tutor 24/7, dan melacak pertumbuhan kognitifnya sendiri dari TK hingga SMA.

**Proposisi nilai inti:** Setiap siswa merasakan pengalaman yang berbeda — bukan karena konten berbeda, melainkan karena level kesulitan, gaya visual, dan jalur remedial dikalibrasi ulang setiap kali mereka menjawab satu soal.

### 1.2 Scope (Dalam Cakupan)

| Fitur | Deskripsi |
|-------|-----------|
| Login & session | Keycloak OIDC, JWT RS256, refresh otomatis |
| Home shell adaptif | Layout dan tema berubah sesuai `fase_aktif` dari JWT |
| Quiz player | Tampilkan soal, terima jawaban, kirim ke `/engine/evaluate` |
| Remediation breadcrumb | Tampilkan jalur reroute saat state `IN_REMEDIATION` |
| Cognitive passport viewer | Visualisasi P(L) per TP yang sudah dikuasai |
| AI Tutor chat | SSE streaming dari `/tutor/chat` |
| Progress summary | Statistik misi harian, mastery count, streak |
| Offline skeleton | Layout terakhir di-cache via `hive`; skeleton saat tanpa koneksi |

### 1.3 Exclusions (Di Luar Cakupan Dokumen Ini)

- Parent App (diatur di `10_PARENT_APP_SPEC.md` — build flavor berbeda)
- Teacher Dashboard (React Web — `06_TEACHER_DASHBOARD_ANALYTICS.md`)
- Admin Yayasan Dashboard (React Web — `11_ADMIN_YAYASAN_DASHBOARD.md`)
- Fitur P5 dan portofolio proyek (roadmap Tahun 2)
- Push notifications (roadmap Tahun 2)

---

## §2 — USER PERSONAS

### 2.1 Siswa TK (Fase Fondasi)

| Atribut | Detail |
|---------|--------|
| Usia | 5–6 tahun |
| Literasi digital | Nol — belum bisa membaca |
| Input utama | Tap besar, drag, pilihan gambar |
| Harapan | Menyenangkan, seperti bermain, ada reward |
| Hambatan | Tidak boleh ada teks panjang; ikon wajib besar (min 64dp) |
| Theme mode | `KIDS_GAMIFIED` |

### 2.2 Siswa SD (Fase A–C)

| Atribut | Detail |
|---------|--------|
| Usia | 7–12 tahun |
| Literasi digital | Dasar — bisa membaca teks pendek |
| Input utama | Tap, pilihan ganda, drag-and-drop sederhana |
| Harapan | Petualangan, koleksi badge, misi harian |
| Hambatan | Teks terlalu panjang menurunkan motivasi |
| Theme mode | `JUNIOR_ADVENTURE` |

### 2.3 Siswa SMP/SMA (Fase D–F)

| Atribut | Detail |
|---------|--------|
| Usia | 13–18 tahun |
| Literasi digital | Menengah–mahir |
| Input utama | Tap, teks pendek, pilihan ganda, multi-step |
| Harapan | Data kognitif yang jelas, insight karier, tutor AI |
| Hambatan | Visual "anak-anak" mengurangi kredibilitas |
| Theme mode | `PRO_DASHBOARD` |

---

## §3 — GOALS & SUCCESS METRICS

### 3.1 Product Goals

1. **Engagement harian:** Siswa membuka aplikasi minimal 3× seminggu tanpa dorongan eksternal.
2. **Mastery velocity:** Rata-rata waktu untuk menguasai 1 TP ≤ 3 sesi belajar.
3. **Zero data leak:** 0 insiden pelanggaran data siswa (UU PDP No. 27/2022).
4. **Adoption rate:** ≥ 80% siswa pilot aktif menggunakan quiz player dalam 2 minggu pertama.

### 3.2 Acceptance Criteria (Definition of Launch-Ready)

- [ ] Login → Home dalam < 2 detik (cold start; layout di-cache)
- [ ] Quiz evaluate round-trip (POST → response) < 800ms P95
- [ ] BKT threshold `0.85` mastery bekerja di semua 3 theme mode
- [ ] Remediation breadcrumb muncul saat `session_state = IN_REMEDIATION`
- [ ] Tutor chat streaming dimulai dalam < `800ms` setelah send
- [ ] Semua tap target ≥ 48dp (64dp untuk KIDS mode)
- [ ] WCAG 2.2 AA lulus pada 3 theme mode (uji dengan axe)
- [ ] Tidak ada hardcoded color atau string di widget layer

---

## §4 — INFORMATION ARCHITECTURE

### 4.1 Peta Layar

```
Student App
│
├── /splash                   ← SplashScreen (cek token cache → redirect)
├── /login                    ← LoginScreen
│
└── /home (HomeShell)         ← Adaptive berdasar fase_aktif
    ├── [KIDS] KidsHomeScreen      ← avatar Rive, misi hari ini
    ├── [JUNIOR] AdventureMapScreen ← RPG map, daily mission card
    └── [PRO] ProDashboardScreen    ← grafik BKT, TP progress
    │
    ├── /learn/:subjectId     ← QuizPlayerScreen
    │   └── (overlay) RemediationBreadcrumb
    │
    ├── /tutor                ← TutorChatScreen (SSE streaming)
    │
    ├── /passport             ← CognitivePassportScreen (P(L) per TP)
    │
    └── /profile              ← ProfileScreen (ganti sandi, tema)
```

### 4.2 Navigation Rules

| Kondisi | Aksi Router |
|---------|-------------|
| Token tidak ada / expired | Redirect ke `/login` |
| Login sukses, role `SISWA` | Redirect ke `/home` |
| Login sukses, role bukan `SISWA` | Redirect ke `/login` dengan error `AUTHZ_WRONG_ROLE` |
| `fase_aktif = null` | Tampilkan `PRO_DASHBOARD` (default safe) |
| Quiz `MASTERY_ACHIEVED` | Pop ke `/home` + tampilkan celebration |
| Quiz `REROUTE_TO_PREREQUISITE` | Stay di `/learn/:subjectId`, update breadcrumb |

---

## §5 — UI/UX DESIGN SYSTEM

### 5.1 Tiga Theme Mode (Kontrak Definitif)

| Mode | Fase | Mood | Font | Animasi |
|------|------|------|------|---------|
| `KIDS_GAMIFIED` | Fondasi (TK) | Playful, warm | Fredoka | Tinggi — Rive idle loop |
| `JUNIOR_ADVENTURE` | A–C (SD) | Adventure, exploration | Nunito | Sedang — Rive on-action |
| `PRO_DASHBOARD` | D–F (SMP/SMA) | Focused, data-aware | Inter | Minimal — 200ms transition |

**Decision tree:**
```
JWT.fase_aktif == "FASE_FONDASI"              → KIDS_GAMIFIED
JWT.fase_aktif IN ["FASE_A","FASE_B","FASE_C"] → JUNIOR_ADVENTURE
JWT.fase_aktif IN ["FASE_D","FASE_E","FASE_F"] → PRO_DASHBOARD
null / fallback                                → PRO_DASHBOARD
```

### 5.2 Design Tokens (Source of Truth)

File: `infrastructure/design_tokens/aleta.tokens.json`
Generated Dart: `lib/core/theme/tokens.g.dart`

**Aturan wajib:**
- Tidak ada warna mentah (`#FFB300`) di widget layer — wajib melalui token
- Spacing kelipatan 4 saja (`spacing.4 = 16`, `spacing.8 = 32`)
- Tap target: `touchTarget.min = 48dp`, `touchTarget.kidsGamified = 64dp`

#### Color Tokens

```json
{
  "color": {
    "kidsGamified": {
      "primary":    "#FFB300",
      "onPrimary":  "#3E2723",
      "secondary":  "#FF7043",
      "background": "#EFFFEC",
      "surface":    "#FFFFFF",
      "success":    "#66BB6A",
      "warning":    "#FFCA28",
      "error":      "#EF5350",
      "textHigh":   "#3E2723",
      "textMid":    "#5D4037"
    },
    "juniorAdventure": {
      "primary":    "#1976D2",
      "onPrimary":  "#FFFFFF",
      "secondary":  "#00897B",
      "background": "#F0F4F8",
      "surface":    "#FFFFFF",
      "success":    "#2E7D32",
      "warning":    "#F57C00",
      "error":      "#C62828",
      "textHigh":   "#102A43",
      "textMid":    "#486581"
    },
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

#### Typography Scale

```json
{
  "typography": {
    "fontFamily": {
      "kidsGamified":    "Fredoka",
      "juniorAdventure": "Nunito",
      "proDashboard":    "Inter"
    },
    "scale": {
      "kidsGamified":    { "display": 40, "title": 28, "body": 20, "caption": 16 },
      "juniorAdventure": { "display": 30, "title": 22, "body": 16, "caption": 13 },
      "proDashboard":    { "display": 28, "title": 20, "body": 14, "caption": 12 }
    }
  }
}
```

#### Border Radius

```json
{
  "radius": {
    "kidsGamified":    { "card": 24, "button": 32, "input": 20 },
    "juniorAdventure": { "card": 16, "button": 16, "input": 10 },
    "proDashboard":    { "card": 12, "button": 8,  "input": 6 }
  }
}
```

#### Spacing

```json
{ "spacing": { "1": 4, "2": 8, "3": 12, "4": 16, "5": 20, "6": 24, "8": 32, "10": 40, "12": 48, "16": 64 } }
```

#### Motion

```json
{
  "motion": {
    "duration": { "instant": 80, "fast": 150, "base": 220, "slow": 320 },
    "easing": {
      "standard":   "cubic-bezier(0.2, 0.0, 0.0, 1.0)",
      "emphasized": "cubic-bezier(0.2, 0.0, 0.0, 1.4)"
    },
    "reducedMotion": { "duration": 0, "easing": "linear" }
  }
}
```

### 5.3 Component Inventory

#### Atoms (dibutuhkan Student App)

| Komponen | Variants | States Wajib | Platform |
|----------|----------|--------------|----------|
| `Button` | `primary`, `secondary`, `ghost`, `icon` | default, pressed, loading, disabled | Flutter |
| `TextField` | `text`, `numeric`, `password` | default, focus, error, disabled | Flutter |
| `Avatar` | `initial`, `image`, `emoji` (KIDS only) | default | Flutter |
| `Badge` | `count`, `dot`, `status` | success, warning, error | Flutter |
| `ProgressBar` | `linear`, `circular` | indeterminate, determinate | Flutter |
| `Skeleton` | `text`, `block`, `circle` | shimmer | Flutter |
| `Toast` | `success`, `info`, `warning`, `error` | enter, idle, exit | Flutter |
| `LottieView` | `celebration`, `idle_avatar`, `loading_kid` | playing, paused | Flutter |

#### Molecules (dibutuhkan Student App)

| Komponen | Deskripsi | Dipakai di |
|----------|-----------|------------|
| `QuizOption` | Pilihan jawaban dengan feedback warna | QuizPlayerScreen |
| `MissionCard` | Kartu misi harian (JUNIOR mode) | AdventureMapScreen |
| `BreadcrumbATP` | Breadcrumb jalur remedial | QuizPlayerScreen overlay |
| `EmptyState` | Layar kosong dengan ilustrasi | Semua layar |
| `LoadingState` | Full-screen skeleton | Transition |
| `ErrorState` | Error dengan tombol retry | Semua layar |

#### Organisms (dibutuhkan Student App)

| Komponen | Deskripsi |
|----------|-----------|
| `HomeShellSiswa` | Wrapper adaptive home berdasar theme mode |
| `QuizPlayer` | Lengkap dengan state machine visual (LOADING → ANSWERING → EVALUATING → OUTCOME) |
| `RemediationBreadcrumb` | Overlay breadcrumb saat `IN_REMEDIATION` |
| `TutorChatPanel` | Panel chat dengan SSE token streaming |
| `CognitivePassportCard` | Kartu P(L) per TP dengan progress ring |

---

## §6 — SCREEN SPECIFICATIONS

### 6.1 SplashScreen (`/splash`)

**Tujuan:** Cek token cache → redirect tanpa flickering.

**Alur:**
1. Tampilkan logo ALETA (1.5 detik atau hingga token tervalidasi)
2. Baca cache `hive` key `auth.last_fase_aktif` → render home shell sementara (mencegah white flash)
3. Validasi token ke Keycloak JWKS secara background
4. Jika valid → navigate `/home`; jika expired → refresh token; jika gagal → navigate `/login`

**Kode stub:**
```dart
// lib/presentation/splash/splash_screen.dart
class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (ctx, state) {
        if (state is Authenticated) ctx.go('/home');
        if (state is AuthError) ctx.go('/login');
      },
      child: Scaffold(
        body: Center(child: Image.asset('assets/images/logo_aleta.png', width: 120)),
      ),
    );
  }
}
```

---

### 6.2 LoginScreen (`/login`)

**Tujuan:** Autentikasi via Keycloak; hidupkan sesi BLoC.

**Elemen UI:**
- Logo ALETA
- TextField email (`TextInputType.emailAddress`)
- TextField password (`obscureText: true`, toggle visibility)
- Button "Masuk" (primary, full-width)
- Link "Lupa kata sandi?" (navigasi ke Keycloak self-service)
- Toast error jika `AUTH_INVALID_CREDENTIALS` atau `RATE_LIMIT`

**API:** `POST /api/v1/auth/login`

**Kode stub:**
```dart
// lib/presentation/auth/login_screen.dart
class LoginScreen extends StatelessWidget {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (ctx, state) {
        if (state is Authenticated) ctx.go('/home');
        if (state is AuthError) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text(state.errorMessage)),
          );
        }
      },
      builder: (ctx, state) => Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/logo_aleta.png', width: 100),
              const SizedBox(height: 32),
              TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 16),
              TextField(controller: _passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Kata Sandi')),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: state is AuthLoading ? null : () {
                    ctx.read<AuthBloc>().add(LoginRequested(
                      email: _emailCtrl.text.trim(),
                      password: _passCtrl.text,
                    ));
                  },
                  child: state is AuthLoading
                      ? const CircularProgressIndicator()
                      : const Text('Masuk'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

### 6.3 HomeShell (`/home`) — Adaptive

**Tujuan:** Entry point post-login. Layout berubah total sesuai `fase_aktif`.

**Decision logic:**
```dart
// lib/presentation/home/widgets/home_hydrator_factory.dart
UiThemeMode _detectMode(String faseAktif) {
  if (faseAktif == 'FASE_FONDASI') return UiThemeMode.kidsGamified;
  if (['FASE_A','FASE_B','FASE_C'].contains(faseAktif)) return UiThemeMode.juniorAdventure;
  return UiThemeMode.proDashboard; // FASE_D, E, F + fallback
}
```

#### 6.3.1 KidsHomeScreen (KIDS_GAMIFIED)

**Elemen:**
- Avatar Rive animasi idle (file: `assets/rive/avatar_kids_idle.riv`)
- Teks sambutan besar: "Halo [nama]! 👋" — Fredoka 40px, textHigh color
- 1 tombol besar: "Mulai Belajar!" — radius 32, min 64dp height
- Row koin reward (jumlah XP/koin hari ini)
- Tanpa bottom navigation (terlalu kompleks untuk TK)

#### 6.3.2 AdventureMapScreen (JUNIOR_ADVENTURE)

**Elemen:**
- Header: nama siswa + badge "Petualang Hari Ini"
- `MissionCard` horizontal scroll: 3 misi harian dengan subject icon
- Progress ring per misi (circular progress dari token)
- Leaderboard mini: 3 nama teratas di kelas (nama disingkat demi privasi)
- Bottom nav: Home | Belajar | Tutor | Paspor

#### 6.3.3 ProDashboardScreen (PRO_DASHBOARD)

**Elemen:**
- Header: "Dasbor Akademik" + nama siswa
- `CognitivePassportCard` — menampilkan 3 TP terakhir aktif dengan P(L) bar
- Grafik ringkas progress `fl_chart` — mastery count 30 hari terakhir
- Button "Lanjut Belajar" → navigasi ke `/learn/:lastSubjectId`
- Bottom nav: Home | Belajar | Tutor | Paspor | Profil

---

### 6.4 QuizPlayerScreen (`/learn/:subjectId`)

**Tujuan:** Inti aplikasi — tampilkan soal, terima jawaban, visualisasikan hasil BKT.

**4 State Visual:**

```
LOADING_NEXT_CONTENT
  → Skeleton card + ProgressBar indeterminate
  → API: GET /api/v1/student/next-content?subject_id={id}

ANSWERING
  → Tampilkan ContentItem berdasar content_type:
    - "QUIZ"        → Multiple choice (QuizOption widgets)
    - "VIDEO"       → VideoPlayer widget
    - "READING"     → ScrollableText widget
  → Tampilkan remediation_breadcrumb jika session_state = "IN_REMEDIATION"

EVALUATING
  → Disable semua opsi
  → Animasi "Menghitung..." (150ms shimmer)
  → API: POST /api/v1/engine/evaluate

OUTCOME_BANNER
  → Berdasar next_action dari respons:
    MASTERY_ACHIEVED        → Celebration Lottie + "TP Dikuasai! 🎉" → back /home
    CONTINUE_PRACTICE       → "Lanjutkan!" → LOADING_NEXT_CONTENT
    REROUTE_TO_PREREQUISITE → "Ayo mundur sebentar..." → update breadcrumb → LOADING
    REMEDIATION_COMPLETED   → "Kamu sudah kembali ke jalur utama!" → LOADING
    SCAFFOLD_REQUIRED       → Tampilkan scaffolding_hint + link ke /tutor
```

**Kode stub BLoC:**
```dart
// lib/presentation/quiz/bloc/quiz_state.dart
abstract class QuizState {}
class QuizLoadingContent extends QuizState {}
class QuizAnswering extends QuizState {
  final ContentItem content;
  final String? remediationBreadcrumb;   // null = not in remediation
  final List<String> breadcrumbPath;     // e.g. ["TP_MAT_7_ALJABAR", "TP_MAT_6_PERSAMAAN"]
  QuizAnswering({required this.content, this.remediationBreadcrumb, this.breadcrumbPath = const []});
}
class QuizEvaluating extends QuizState {}
class QuizOutcome extends QuizState {
  final String nextAction;      // MASTERY_ACHIEVED | CONTINUE_PRACTICE | ...
  final double calculatedPl;
  final String? scaffoldingHint;
  QuizOutcome({required this.nextAction, required this.calculatedPl, this.scaffoldingHint});
}
class QuizError extends QuizState { final String message; QuizError(this.message); }
```

**Kode stub RemediationBreadcrumb:**
```dart
// lib/presentation/quiz/widgets/remediation_breadcrumb.dart
class RemediationBreadcrumb extends StatelessWidget {
  final List<String> path; // ["TP Utama", "TP Prasyarat 1", "TP Prasyarat 2 (aktif)"]

  const RemediationBreadcrumb({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Row(
        children: [
          const Icon(Icons.route_outlined, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              path.join(' → '),
              style: Theme.of(context).textTheme.labelSmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

### 6.5 TutorChatScreen (`/tutor`)

**Tujuan:** Tutor AI 24/7 via Ollama — streaming SSE.

**Elemen:**
- AppBar: "Tutor ALETA 🤖"
- ListView chat bubble (siswa = kanan, tutor = kiri)
- TextField input + tombol kirim
- Tombol kirim di-disable saat streaming aktif
- Typing indicator (animated dots) saat streaming
- Token streaming di-append char-by-char ke bubble terakhir

**API:** `POST /api/v1/tutor/chat` → `text/event-stream`

**Kode stub streaming handler:**
```dart
// lib/presentation/tutor/bloc/tutor_bloc.dart
on<TutorMessageSent>((event, emit) async {
  emit(TutorStreaming(messages: [...state.messages, UserMessage(event.text)]));
  final assistantMsg = AssistantMessage(content: '');

  await for (final chunk in _apiClient.streamTutorChat(
    contextTpId: event.contextTpId,
    message: event.text,
    conversationId: state.conversationId,
  )) {
    assistantMsg.content += chunk.delta;
    emit(TutorStreaming(messages: [...state.messages, assistantMsg]));
  }

  emit(TutorIdle(messages: [...state.messages, assistantMsg]));
});
```

---

### 6.6 CognitivePassportScreen (`/passport`)

**Tujuan:** Visualisasi perjalanan kognitif 12 tahun siswa.

**Elemen:**
- Header: "Paspor Kognitif Saya"
- Ringkasan: total TP dikuasai, fase aktif, streak hari ini
- List grouped by `elemen` (Matematika, IPA, dst.)
- Per TP: nama TP, progress ring P(L) value, badge "Dikuasai ✓" jika `is_mastered = true`
- Filter by `is_mastered` toggle

**API:** `GET /api/v1/student/passport`

**Tampilan P(L):**
- `P(L) < 0.20` → warna `error` + label "Butuh Bantuan"
- `0.20 ≤ P(L) < 0.50` → warna `warning` + label "Sedang Belajar"
- `0.50 ≤ P(L) < 0.85` → warna `secondary` + label "Hampir Dikuasai"
- `P(L) ≥ 0.85` → warna `success` + label "Dikuasai ✓"

---

## §7 — ADAPTIVE LEARNING LOOP

### 7.1 Gambaran Besar

```
Siswa jawab soal
       │
       ▼
POST /engine/evaluate
       │
       ▼
Backend: BKT update P(L_{t+1})
       │
  ┌────┴────────────────────────┐
  │    MatchmakerEngine evaluasi │
  └────┬────────────────────────┘
       │
  ┌────▼──────────────────────────────────────────────────────┐
  │  P(L) ≥ 0.85 && state == IN_REMEDIATION                  │
  │    → REMEDIATION_COMPLETED → pop stack → kembali ke main │
  ├────────────────────────────────────────────────────────────┤
  │  P(L) ≥ 0.85 && state == NORMAL                          │
  │    → MASTERY_ACHIEVED → buka TP berikutnya di ATP         │
  ├────────────────────────────────────────────────────────────┤
  │  P(L) < 0.20                                              │
  │    → REROUTE_TO_PREREQUISITE → push prerequisite ke stack │
  │    → jika tidak ada prerequisite → SCAFFOLD_REQUIRED      │
  ├────────────────────────────────────────────────────────────┤
  │  otherwise                                                 │
  │    → CONTINUE_PRACTICE → soal berikutnya pada TP saat ini │
  └────────────────────────────────────────────────────────────┘
```

### 7.2 BKT Parameters (Default — Sentinel Values)

| Parameter | Nilai | Makna |
|-----------|-------|-------|
| `p_init` | `0.15` | Probabilitas awal penguasaan (cold start) |
| `p_transit` | `0.20` | Probabilitas berpindah dari belum → menguasai per soal |
| `p_guess` | `0.20` | Probabilitas menjawab benar meski belum menguasai |
| `p_slip` | `0.10` | Probabilitas menjawab salah meski sudah menguasai |
| **Mastery threshold** | **`0.85`** | P(L) ≥ 0.85 → TP dianggap dikuasai |
| **Remedial threshold** | **`0.20`** | P(L) < 0.20 → trigger rerouting ke prasyarat |

> **CRITICAL:** Nilai `0.85` dan `0.20` adalah sentinel. Jangan ganti tanpa mengubah `STATE.yaml.sentinels` dan berkonsultasi dengan architect.

### 7.3 Session States

```dart
enum SessionState {
  normal,           // Jalur utama ATP
  inRemediation,    // Sedang mengerjakan TP prasyarat
  returningToMain,  // Prasyarat selesai, kembali ke TP utama
}
```

### 7.4 Visualisasi State di UI

| `next_action` dari API | Tampilan UI | Aksi Selanjutnya |
|------------------------|-------------|------------------|
| `MASTERY_ACHIEVED` | 🎉 Celebration Lottie + teks "TP Dikuasai!" | Kembali ke Home |
| `CONTINUE_PRACTICE` | ✅ Feedback hijau singkat | Load soal berikutnya |
| `REROUTE_TO_PREREQUISITE` | 🔄 "Ayo segarkan dulu konsep dasarnya!" + breadcrumb muncul | Load TP prasyarat |
| `REMEDIATION_COMPLETED` | ⬆️ "Kamu sudah kembali ke jalur utama!" | Load TP utama lagi |
| `SCAFFOLD_REQUIRED` | 💡 Tampilkan `scaffolding_hint` + tombol "Tanya Tutor" | Navigate ke `/tutor` |

---

## §8 — API CONTRACTS

### 8.1 Global Protocol

- Base URL: `https://api.{tenant}.aleta.sch.id/api/v1`
- Auth header: `Authorization: Bearer <JWT>` (RS256, dari Keycloak)
- Idempotency header wajib untuk mutasi: `Idempotency-Key: <uuid-v4>`
- Content-Type: `application/json` kecuali SSE
- Error envelope:

```json
{
  "success": false,
  "error": {
    "code": "AUTH_TOKEN_EXPIRED",
    "message": "Sesi Anda telah berakhir. Silakan login kembali.",
    "request_id": "req_8f3a2b1c"
  }
}
```

### 8.2 `POST /api/v1/auth/login`

**Request:**
```json
{
  "email": "sandi.putra@yayasan.sch.id",
  "password": "PasswordRahasia123"
}
```

**Response 200:**
```json
{
  "success": true,
  "data": {
    "token": "eyJ...",
    "user_id": "7b8971f4-3d0b-4813-bc7c-d6981881e1a1",
    "full_name": "Sandi Putra",
    "role": "SISWA",
    "fase_aktif": "FASE_D",
    "tenant_id": "UNIT_SMP_01"
  }
}
```

**Error codes:** `AUTH_INVALID_CREDENTIALS` (401), `RATE_LIMIT` (429)

---

### 8.3 `POST /api/v1/auth/refresh`

**Request:** Cookie `refresh_token` (httpOnly)

**Response 200:**
```json
{ "success": true, "data": { "token": "eyJ..." } }
```

**Error codes:** `AUTH_REFRESH_EXPIRED` (401) → redirect ke `/login`

---

### 8.4 `GET /api/v1/student/passport`

**Headers:** `Authorization: Bearer <JWT>`

**Query params:** `student_id` (opsional — siswa tidak perlu, guru/ortu wajib)

**Response 200:**
```json
{
  "success": true,
  "data": {
    "student_id": "7b8971f4-...",
    "fase_aktif": "FASE_D",
    "total_mastered_tps": 42,
    "passports": [
      {
        "tp_id": "TP_MAT_7_ALJABAR",
        "elemen": "Aljabar",
        "current_p_l": 0.4251,
        "is_mastered": false,
        "last_updated": "2026-05-23T09:15:00Z"
      }
    ]
  }
}
```

---

### 8.5 `GET /api/v1/student/next-content`

**Query params:** `subject_id` (Required, contoh: `MATEMATIKA`)

**Response 200:**
```json
{
  "success": true,
  "data": {
    "content_item_id": "a4b2c1d0-...",
    "content_type": "QUIZ",
    "tp_id": "TP_MAT_6_PERSAMAAN",
    "render_mode": "JUNIOR_ADVENTURE",
    "session_state": "IN_REMEDIATION",
    "remediation_breadcrumb": ["TP_MAT_7_ALJABAR", "TP_MAT_6_PERSAMAAN"],
    "scaffolding_hint": "Ingat: persamaan = dua sisi seimbang.",
    "url_path": "/content/quiz/persamaan_lvl1.json"
  }
}
```

---

### 8.6 `POST /api/v1/engine/evaluate`

**Headers:** `Idempotency-Key: <uuid>`

**Request:**
```json
{
  "tp_id": "TP_MAT_7_ALJABAR",
  "content_item_id": "a4b2c1d0-...",
  "is_correct": false,
  "response_time_seconds": 45
}
```

**Response 200 — Remedial triggered:**
```json
{
  "success": true,
  "data": {
    "calculated_p_l": 0.1850,
    "status": "REMEDIAL_TRIGGERED",
    "next_action": "REROUTE_TO_PREREQUISITE",
    "target_next_tp_id": "TP_MAT_TK_COUNT",
    "scaffolding_hint": "Jangan berkecil hati! Mari kita segarkan ingatanmu tentang konsep dasar membilang."
  }
}
```

**Response 200 — Mastery:**
```json
{
  "success": true,
  "data": {
    "calculated_p_l": 0.9120,
    "status": "MASTERED",
    "next_action": "MASTERY_ACHIEVED",
    "target_next_tp_id": "TP_MAT_7_FUNGSI",
    "scaffolding_hint": null
  }
}
```

**Semua possible `next_action`:**
```
MASTERY_ACHIEVED        P(L) ≥ 0.85, state normal
REMEDIATION_COMPLETED   P(L) ≥ 0.85, state in_remediation
REROUTE_TO_PREREQUISITE P(L) < 0.20, prasyarat tersedia
SCAFFOLD_REQUIRED       P(L) < 0.20, tidak ada prasyarat
CONTINUE_PRACTICE       semua kondisi lainnya
```

---

### 8.7 `POST /api/v1/tutor/chat` (SSE)

**Request:**
```json
{
  "conversation_id": null,
  "context_tp_id": "TP_MAT_7_ALJABAR",
  "message": "Aku belum paham kenapa minus dikali minus jadi plus."
}
```

**Response (`text/event-stream`):**
```
event: start
data: {"conversation_id": "9b...", "message_id": 4421}

event: token
data: {"delta": "Bayangkan minus sebagai arah "}

event: token
data: {"delta": "berlawanan..."}

event: end
data: {"finish_reason": "stop", "safety_flags": {}}
```

> **Keamanan:** Backend menerapkan 3-layer safety (Doc 09 §4.D). Jika siswa mengirim konten berbahaya, respons adalah `event: error, data: {"code": "SAFETY_BLOCK"}`. Flutter harus handle event ini dan tampilkan pesan default.

---

## §9 — TECHNICAL ARCHITECTURE

### 9.1 Build Flavors

```
frontend_flutter/
├── lib/
│   ├── main_student.dart    ← flutter run --flavor student -t lib/main_student.dart
│   └── main_parent.dart     ← flutter run --flavor parent -t lib/main_parent.dart
```

`main_student.dart` mengaktifkan semua route termasuk `/learn` dan `/tutor`.
`main_parent.dart` menonaktifkan route `/learn` dan `/tutor`, mengaktifkan `/parent/report`.

### 9.2 Clean Architecture Layers

```
lib/
├── core/
│   ├── network/
│   │   ├── aleta_api_client.dart       ← Dio wrapper, semua API call
│   │   ├── auth_interceptor.dart       ← inject Bearer token
│   │   └── refresh_interceptor.dart    ← handle 401 → refresh
│   ├── theme/
│   │   ├── tokens.g.dart               ← GENERATED — jangan edit manual
│   │   └── fase_theme_config.dart      ← UiThemeMode enum + ThemeData
│   ├── routing/
│   │   └── app_router.dart             ← GoRouter table
│   └── storage/
│       └── token_store.dart            ← hive store untuk JWT + fase cache
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   └── auth_repository.dart
│   │   ├── domain/
│   │   │   └── use_cases/login_use_case.dart
│   │   └── presentation/
│   │       ├── bloc/auth_bloc.dart
│   │       └── screens/login_screen.dart
│   │
│   ├── home/
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── kids_home_screen.dart
│   │       │   ├── adventure_map_screen.dart
│   │       │   └── pro_dashboard_screen.dart
│   │       └── widgets/
│   │           └── home_hydrator_factory.dart
│   │
│   ├── quiz/
│   │   ├── data/
│   │   │   └── quiz_repository.dart
│   │   ├── domain/
│   │   │   ├── entities/content_item.dart
│   │   │   └── use_cases/evaluate_answer_use_case.dart
│   │   └── presentation/
│   │       ├── bloc/quiz_bloc.dart
│   │       └── screens/quiz_player_screen.dart
│   │
│   ├── tutor/
│   │   └── presentation/
│   │       ├── bloc/tutor_bloc.dart
│   │       └── screens/tutor_chat_screen.dart
│   │
│   └── passport/
│       └── presentation/
│           └── screens/cognitive_passport_screen.dart
│
└── shared/
    └── widgets/
        ├── atoms/
        ├── molecules/
        └── organisms/
```

### 9.3 Key Dependencies (`pubspec.yaml`)

```yaml
dependencies:
  flutter_bloc: ^8.1.5        # state management
  go_router: ^13.2.0          # navigation
  dio: ^5.4.3                 # HTTP client
  hive_flutter: ^1.1.0        # local cache
  lottie: ^3.1.2              # animasi celebration
  rive: ^0.13.7               # animasi avatar (KIDS/JUNIOR)
  fl_chart: ^0.68.0           # grafik BKT (PRO mode)
  uuid: ^4.4.0                # idempotency key
  flutter_localizations:       # l10n
    sdk: flutter
  intl: ^0.19.0

dev_dependencies:
  build_runner: ^2.4.9
  hive_generator: ^2.0.1
  flutter_gen_runner: ^5.4.0  # asset generation
```

### 9.4 API Client Pattern

```dart
// lib/core/network/aleta_api_client.dart
class AletaApiClient {
  final Dio _dio;
  final TokenStore _tokenStore;

  AletaApiClient(this._dio, this._tokenStore);

  Future<NextContentResponse> getNextContent(String subjectId) async {
    final resp = await _dio.get('/api/v1/student/next-content',
        queryParameters: {'subject_id': subjectId});
    return NextContentResponse.fromJson(resp.data['data']);
  }

  Future<EvaluateResponse> evaluate(EvaluateRequest req) async {
    final resp = await _dio.post('/api/v1/engine/evaluate',
        data: req.toJson(),
        options: Options(headers: {'Idempotency-Key': const Uuid().v4()}));
    return EvaluateResponse.fromJson(resp.data['data']);
  }

  Stream<TutorChunk> streamTutorChat({
    required String message,
    required String contextTpId,
    String? conversationId,
  }) async* {
    final response = await _dio.post<ResponseBody>(
      '/api/v1/tutor/chat',
      data: {'message': message, 'context_tp_id': contextTpId, 'conversation_id': conversationId},
      options: Options(responseType: ResponseType.stream),
    );
    await for (final line in response.data!.stream.transform(utf8.decoder).transform(const LineSplitter())) {
      if (line.startsWith('data: ')) {
        final json = jsonDecode(line.substring(6));
        if (json['delta'] != null) yield TutorChunk(delta: json['delta']);
      }
    }
  }
}
```

---

## §10 — STATE MANAGEMENT (BLoC CONTRACTS)

### 10.1 AuthBloc

```dart
// EVENTS
abstract class AuthEvent {}
class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  LoginRequested({required this.email, required this.password});
}
class TokenRefreshRequested extends AuthEvent {}
class LogoutRequested extends AuthEvent {}
class AppStarted extends AuthEvent {} // cek cache di startup

// STATES
abstract class AuthState {}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class Authenticated extends AuthState {
  final String userId;
  final String token;
  final String faseAktif;   // "FASE_D" — krusial untuk theme selection
  final String tenantId;
  final String fullName;
  Authenticated({required this.userId, required this.token,
    required this.faseAktif, required this.tenantId, required this.fullName});
}
class AuthError extends AuthState {
  final String errorMessage;
  final String errorCode;   // "AUTH_INVALID_CREDENTIALS", "RATE_LIMIT", dll.
  AuthError({required this.errorMessage, required this.errorCode});
}
```

### 10.2 QuizBloc

```dart
// EVENTS
abstract class QuizEvent {}
class QuizStarted extends QuizEvent { final String subjectId; QuizStarted(this.subjectId); }
class AnswerSubmitted extends QuizEvent {
  final String contentItemId;
  final String tpId;
  final bool isCorrect;
  final int responseTimeSeconds;
  AnswerSubmitted({required this.contentItemId, required this.tpId,
    required this.isCorrect, required this.responseTimeSeconds});
}
class NextContentRequested extends QuizEvent {}

// STATES
abstract class QuizState {}
class QuizLoadingContent extends QuizState {}
class QuizAnswering extends QuizState {
  final ContentItem content;
  final String sessionState;         // "NORMAL" | "IN_REMEDIATION" | "RETURNING_TO_MAIN"
  final List<String> breadcrumbPath; // kosong jika NORMAL
  QuizAnswering({required this.content, required this.sessionState,
    this.breadcrumbPath = const []});
}
class QuizEvaluating extends QuizState {}
class QuizOutcome extends QuizState {
  final String nextAction;
  final double calculatedPl;
  final String? scaffoldingHint;
  QuizOutcome({required this.nextAction, required this.calculatedPl, this.scaffoldingHint});
}
class QuizError extends QuizState { final String message; QuizError(this.message); }
```

### 10.3 TutorBloc

```dart
// EVENTS
abstract class TutorEvent {}
class TutorMessageSent extends TutorEvent {
  final String text;
  final String contextTpId;
  TutorMessageSent({required this.text, required this.contextTpId});
}

// STATES
abstract class TutorState {}
class TutorIdle extends TutorState { final List<ChatMessage> messages; TutorIdle(this.messages); }
class TutorStreaming extends TutorState { final List<ChatMessage> messages; TutorStreaming(this.messages); }
class TutorError extends TutorState { final String code; TutorError(this.code); }

// Data Models
abstract class ChatMessage { final String content; ChatMessage(this.content); }
class UserMessage extends ChatMessage { UserMessage(String content) : super(content); }
class AssistantMessage extends ChatMessage {
  String content; // mutable — di-append saat streaming
  AssistantMessage({String content = ''}) : super(content);
}
```

---

## §11 — NON-FUNCTIONAL REQUIREMENTS

### 11.1 Performance

| Metrik | Target | Ukur via |
|--------|--------|----------|
| Cold start → home rendered | < 2 detik | Flutter DevTools |
| Quiz evaluate round-trip | < 800ms P95 | Dio stopwatch interceptor |
| Tutor streaming first token | < 800ms | SSE event timestamp |
| RAG/tutor end-to-end | < 3.5 detik P95 | Backend monitoring |
| Frame rate | ≥ 60fps (Jank < 2%) | Flutter Performance overlay |

### 11.2 Keamanan

| Aturan | Implementasi |
|--------|--------------|
| JWT algorithm | RS256 atau ES256 saja — Dio interceptor validasi `alg` header sebelum parse |
| Token storage | `hive` dengan `FlutterSecureStorage` untuk key encryption |
| PII di log | `LoggingInterceptor` wajib redact field: `password`, `token`, `full_name`, `email` |
| Certificate pinning | Aktifkan di production build menggunakan `dart:io` `SecurityContext` |
| LLM calls | Semua via `aleta_ollama` — tidak ada direct call ke OpenAI/Gemini dari Flutter |

### 11.3 Aksesibilitas

| Aturan | Nilai | Sumber |
|--------|-------|--------|
| Standar aksesibilitas | WCAG 2.2 AA | Doc 14 §9 |
| Tap target minimum | 48dp | Doc 14 §9 |
| Tap target KIDS mode | 64dp | Doc 14 §8.B |
| Text scaling dukungan | 1.0 – 1.8× | `MediaQuery.textScaler` |
| Semantics label | Wajib pada semua `GestureDetector` & `ElevatedButton` | |
| TalkBack/VoiceOver | Semua elemen interaktif wajib punya label terlokalisasi | |
| Kontras warna | ≥ WCAG AA di 3 theme mode | |
| `reducedMotion` | Jika `MediaQuery.disableAnimations == true` → gunakan `motion.reducedMotion` token | |

### 11.4 Offline Behavior

| Kondisi | Perilaku |
|---------|----------|
| Pertama kali tanpa koneksi | Tampilkan `ErrorState` dengan tombol retry |
| Session sudah pernah login | Render home shell dari cache `hive` (`auth.last_fase_aktif`) |
| Kirim jawaban tanpa koneksi | Queue di local `hive` store, sync saat kembali online |
| Tutor chat tanpa koneksi | Tampilkan toast: "Koneksi diperlukan untuk Tutor AI" |

### 11.5 Lokalisasi

- Default locale: `id_ID`
- ARB file: `lib/l10n/intl_id.arb`
- Tidak ada string literal di widget layer — semua melalui `AppLocalizations.of(context)`
- Roadmap: `id_AC` (Aceh), `id_PA` (Papua), `en_US`

---

## §12 — IMPLEMENTATION TASK MAP

| Task | Judul | Layer yang Dibuat |
|------|-------|-------------------|
| T-301 | Flutter skeleton + 2 flavor + main entry | `main_student.dart`, `main_parent.dart`, `pubspec.yaml` |
| T-302 | Design tokens build (Style Dictionary) | `aleta.tokens.json`, `tokens.g.dart`, `tokens/index.ts` |
| T-303 | Theme system + 3 mode rendering | `fase_theme_config.dart`, `HomeHydratorFactory` |
| T-304 | AuthBloc + token store | `auth_bloc.dart`, `token_store.dart` |
| T-305 | API client Dio + interceptors | `aleta_api_client.dart`, semua interceptors |
| T-306 | go_router config + route guards | `app_router.dart` dengan redirect guard |
| T-307 | OpenAPI Dart client generation | Generated dari `backend_core/openapi.yaml` |
| T-308 | Home shell per mode (KIDS/JUNIOR/PRO) | 3 home screens + `HomeHydratorFactory` |
| T-309 | Quiz player screen + state transitions | `quiz_player_screen.dart`, `quiz_bloc.dart` |
| T-310 | Shared widgets atoms/molecules | `lib/shared/widgets/` — semua atoms & molecules |
| T-311 | i18n setup + intl_id.arb | `lib/l10n/intl_id.arb`, semua `AppLocalizations` calls |
| T-312 | Widget tests untuk core flows | Test: auth, home hydration, quiz state transitions |
| T-313 | Integration test — golden path SMP | End-to-end: login → quiz → remediation → mastery |
| T-509 | TutorChatScreen (Flutter) | `tutor_chat_screen.dart`, `tutor_bloc.dart` |

---

## §13 — ACCEPTANCE CRITERIA CHECKLIST

### Setup & Foundation

- [ ] `flutter run --flavor student` berjalan tanpa error
- [ ] `flutter run --flavor parent` berjalan, route `/learn` & `/tutor` tidak tersedia
- [ ] `tokens.g.dart` di-generate dari `aleta.tokens.json` via Style Dictionary
- [ ] Tidak ada warna hardcoded (`Color(0xFF...)`) di luar `tokens.g.dart`
- [ ] Tidak ada string literal di widget — semua via `AppLocalizations`

### Auth Flow

- [ ] Login berhasil → JWT disimpan di FlutterSecureStorage
- [ ] `fase_aktif` dari JWT di-parse dan disimpan ke cache `hive`
- [ ] Token expired → refresh otomatis tanpa user action
- [ ] Refresh gagal → navigate ke `/login`
- [ ] 3 kali salah password → toast `RATE_LIMIT`

### Home Shell

- [ ] `fase_aktif = FASE_FONDASI` → render `KidsHomeScreen` dengan Fredoka font
- [ ] `fase_aktif = FASE_A/B/C` → render `AdventureMapScreen` dengan Nunito font
- [ ] `fase_aktif = FASE_D/E/F` atau null → render `ProDashboardScreen` dengan Inter font
- [ ] Cold start menampilkan layout cached sebelum network response
- [ ] Tap target semua tombol ≥ 64dp di KIDS mode, ≥ 48dp di mode lain

### Quiz Player

- [ ] `GET /student/next-content` dipanggil saat quiz start dan setelah setiap evaluate
- [ ] Skeleton muncul saat loading, menghilang saat content siap
- [ ] Semua opsi di-disable saat state `QuizEvaluating`
- [ ] `REROUTE_TO_PREREQUISITE` → `RemediationBreadcrumb` muncul dengan path benar
- [ ] `MASTERY_ACHIEVED` → Lottie celebration diputar, navigate kembali ke home setelah 2 detik
- [ ] `SCAFFOLD_REQUIRED` → `scaffolding_hint` tampil + tombol "Tanya Tutor" aktif
- [ ] `Idempotency-Key` header dikirim di setiap `POST /engine/evaluate`

### Tutor Chat

- [ ] Pesan mulai streaming dalam < 800ms setelah send
- [ ] Token-by-token di-append ke bubble terakhir (bukan replace)
- [ ] Tombol send di-disable selama streaming aktif
- [ ] `event: error` dari SSE → tampilkan toast "Tutor tidak dapat merespons saat ini"
- [ ] `conversation_id` dikirim kembali untuk sesi berikutnya (kontinuitas konteks)

### Cognitive Passport

- [ ] P(L) ≥ 0.85 ditampilkan dengan warna `success` dan badge "Dikuasai ✓"
- [ ] P(L) < 0.20 ditampilkan dengan warna `error` dan label "Butuh Bantuan"
- [ ] Filter toggle "Tampilkan yang dikuasai saja" berfungsi

### Aksesibilitas & Performa

- [ ] Axe / Accessibility Inspector: tidak ada critical violation di 3 theme mode
- [ ] `MediaQuery.disableAnimations = true` → semua animasi menggunakan `motion.reducedMotion`
- [ ] Quiz evaluate round-trip P95 < 800ms di jaringan 4G (ukur dengan Dio interceptor)
- [ ] Frame rate ≥ 60fps di quiz player (no jank saat transisi state)
- [ ] `LoggingInterceptor` tidak mencatat field PII ke console

---

> **Untuk AI agent yang mengimplementasikan:** Mulai dari T-301 (skeleton). Jalankan `flutter run --flavor student` sebagai smoke test setelah setiap task selesai. Refer ke `STATE.yaml.sentinels` untuk semua nilai numerik — jangan mengarang nilai sendiri. Setiap screen wajib lulus widget test sebelum marking task `done`.
