---
doc: "05"
title: "Frontend Flutter Architecture"
scope: "Flutter BLoC + Clean Architecture, 2 build flavors (student/parent), 3 theme modes (KIDS/JUNIOR/PRO)"
key_entities: [AuthBloc, QuizBloc, ThemeBloc, student_flavor, parent_flavor, KIDS_GAMIFIED, go_router]
depends_on: ["04", "14"]
loaded_by_tasks: [T-301, T-303, T-304, T-305, T-306, T-308, T-309]
---

# FILE: 05_FRONTEND_DYNAMIC_UI_FLUTTER.md
# PROJECT ALETA: FRONTEND DYNAMIC UI & FLUTTER ARCHITECTURE SPECIFICATION

## 1. PENDAHULUAN & STRATEGI STRUKTUR REPO
Dokumen ini menetapkan standar arsitektur pengembangan aplikasi mobile ALETA menggunakan Flutter untuk siswa dan orang tua. Dashboard guru dan dashboard admin yayasan dikembangkan sebagai aplikasi web React terpisah, bukan bagian dari Flutter mobile.

Aplikasi ini menggunakan satu basis kode (*Single Codebase*) untuk melayani seluruh jenjang usia (TK sampai SMA). Kuncinya terletak pada **Dynamic Layout Hydration**, di mana komponen visual tidak ditulis secara kaku (*hardcoded*), melainkan dirender secara kondisional berdasarkan metadata `fase_aktif` yang dikirim oleh backend setelah proses autentikasi berhasil.

### Pola Manajemen State (State Management Pattern):
Sistem wajib menggunakan **BLoC (Business Logic Component)** dikombinasikan dengan **Clean Architecture** yang memisahkan kode menjadi tiga layer: `Data` (Repository, Provider), `Domain` (UseCases, Entity), dan `Presentation` (BLoC, UI Widgets).

---

## 2. ARSITEKTUR FASE-DRIVEN DYNAMIC UI (TEMA & LAYOUT)

Sistem membagi gaya UI menjadi tiga variasi klaster besar (*UI Theme Modes*):

| Fase Aktif | Mode Visual | Karakteristik Komponen UI | Paket Animasi Eksternal |
| :--- | :--- | :--- | :--- |
| **Fase Fondasi (TK)** | `KIDS_GAMIFIED` | Avatar interaktif, tanpa teks panjang, berbasis suara, *reward* koin, ikon berukuran besar. | `lottie`, `rive` |
| **Fase A - C (SD)** | `JUNIOR_ADVENTURE` | Peta petualangan (*RPG Map Progress*), kartu misi harian, papan peringkat (*leaderboard*) ramah anak. | `flutter_svg`, `rive` |
| **Fase D - F (SMP/SMA)**| `PRO_DASHBOARD` | Visual bersih (*Clean Minimalist*), grafik analitik kompetensi (BKT), fokus pada linimasa proyek P5 dan karier. | `fl_chart` |

---

## 3. IMPLEMENTASI KODE DART (SIAP KONSUMSI VIBE CODING)

### A. Model Skema Konfigurasi Tema (`fase_theme_config.dart`)
Gunakan enumerasi dan ekstensi kelas ini untuk mengatur konfigurasi skema warna dan aset visual secara terpusat berdasarkan data Fase.

```dart
// lib/core/theme/fase_theme_config.dart
import 'package:flutter/material.dart';

enum UiThemeMode { kidsGamified, juniorAdventure, proDashboard }

extension FaseThemeExtension on UiThemeMode {
  // Mengatur skema warna dasar aplikasi secara dinamis
  ThemeData get themeData {
    switch (this) {
      case UiThemeMode.kidsGamified:
        return ThemeData(
          primaryColor: Colors.amber,
          scaffoldBackgroundColor: const Color(0xFFEFFFEC), // Hijau pastel cerah
          fontFamily: 'ComicSans', // Font ramah anak
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber, secondary: Colors.orange),
        );
      case UiThemeMode.juniorAdventure:
        return ThemeData(
          primaryColor: Colors.black,
          scaffoldBackgroundColor: const Color(0xFFF0F4F8), // Biru langit pucat
          fontFamily: 'Nunito',
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, secondary: Colors.teal),
        );
      case UiThemeMode.proDashboard:
        return ThemeData(
          primaryColor: const Color(0xFF1E293B), // Slate gelap maskulin
          scaffoldBackgroundColor: Colors.white,
          fontFamily: 'Inter', // Font profesional modern
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F172A)),
        );
    }
  }

  String get backgroundAsset {
    switch (this) {
      case UiThemeMode.kidsGamified:
        return 'assets/images/bg_forest_kids.png';
      case UiThemeMode.juniorAdventure:
        return 'assets/images/bg_space_adventure.png';
      case UiThemeMode.proDashboard:
        return ''; // Tanpa background gambar dekoratif, bersih
    }
  }
}

```

---

### B. Komponen Factory Layar Beranda Utama (`home_hydrator_factory.dart`)

Komponen bertindak sebagai *router* tampilan internal yang merender struktur halaman utama secara dinamis setelah menerima status BLoC Auth.

```dart
// lib/presentation/home/widgets/home_hydrator_factory.dart
import 'package:flutter/material.dart';
import '../../theme/fase_theme_config.dart';

class HomeHydratorFactory extends StatelessWidget {
  final String faseAktif;

  const HomeHydratorFactory({super.key, required this.faseAktif});

  UiThemeMode _determineMode() {
    if (faseAktif == 'FASE_FONDASI') return UiThemeMode.kidsGamified;
    if (['FASE_A', 'FASE_B', 'FASE_C'].contains(faseAktif)) return UiThemeMode.juniorAdventure;
    return UiThemeMode.proDashboard; // Default untuk FASE_D, E, F (SMP/SMA)
  }

  @override
  Widget build(BuildContext context) {
    final mode = _determineMode();

    // Memanfaatkan Theme widget lokal untuk mengubah nuansa instan tanpa restart aplikasi
    return Theme(
      data: mode.themeData,
      child: Scaffold(
        body: Container(
          decoration: mode.backgroundAsset.isNotEmpty
              ? BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(mode.backgroundAsset),
                    fit: BoxFit.cover,
                  ),
                )
              : null,
          child: SafeArea(
            child: _buildLayoutByMode(mode),
          ),
        ),
      ),
    );
  }

  Widget _buildLayoutByMode(UiThemeMode mode) {
    switch (mode) {
      case UiThemeMode.kidsGamified:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Halo Teman Kecil! 👋', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              // [Vibe Coding Note]: Injeksikan komponen Rive Animation di bawah ini
              Icon(Icons.face, size: 120, color: Colors.orange), 
            ],
          ),
        );
      case UiThemeMode.juniorAdventure:
        return const Center(
          child: Text('Misi Petualangan Belajarmu Hari Ini 🚀', style: TextStyle(fontSize: 22)),
        );
      case UiThemeMode.proDashboard:
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Dasbor Akademik Fase F', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Pantau target capaian kompetensi personal berbasis AI.', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              // Contoh visualisasi kartu analitik BKT menggunakan kontainer tiruan
              Container(
                height: 150,
                width: double.infinity,
                color: const Color(0xFF334155),
                child: const Center(
                  child: Text('Grafik Progres Kognitif (FL Chart Placeholder)', style: TextStyle(color: Colors.white)),
                ),
              )
            ],
          ),
        );
    }
  }
}

```

---

## 4. STRATEGI MANAJEMEN STATE (BLOC EVENT-STATE CONTRACT)

Untuk menghubungkan aliran data dari API Backend (`04_BACKEND_API_CONTRACTS.md`), pastikan state BLoC Anda mengalirkan parameter `faseAktif` ke dalam komponen UI Factory di atas.

```dart
// lib/presentation/auth/bloc/auth_state.dart
abstract class AuthState {}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final String userId;
  final String token;
  final String faseAktif; // Data krusial paspor kognitif (e.g., 'FASE_D')
  final String tenantId;

  Authenticated({
    required this.userId,
    required this.token,
    required this.faseAktif,
    required this.tenantId,
  });
}

class AuthError extends AuthState {
  final String errorMessage;
  AuthError(this.errorMessage);
}

```

---

## 5. NAVIGATION, API CLIENT, & ACCESSIBILITY

### A. Routing
Gunakan **`go_router`** dengan route table tunggal:

```dart
// lib/core/routing/app_router.dart
final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/home', builder: (_, __) => const HomeShell()),
    GoRoute(path: '/learn/:subjectId', builder: (_, s) => QuizPlayerScreen(subjectId: s.pathParameters['subjectId']!)),
    GoRoute(path: '/tutor', builder: (_, __) => const TutorChatScreen()),
    GoRoute(path: '/parent/report', builder: (_, __) => const ParentReportScreen()),
  ],
  redirect: _authRedirect, // arahkan ke /login jika AuthBloc bukan Authenticated
);
```

### B. API Client (Dio + Interceptors)
```dart
// lib/core/network/aleta_api_client.dart
class AletaApiClient {
  AletaApiClient(this._dio, this._tokenStore);
  final Dio _dio;
  final TokenStore _tokenStore;

  Future<EvaluateResponse> evaluate(EvaluateRequest req) async {
    final resp = await _dio.post(
      '/api/v1/engine/evaluate',
      data: req.toJson(),
      options: Options(headers: {
        'Idempotency-Key': const Uuid().v4(),
      }),
    );
    return EvaluateResponse.fromJson(resp.data['data']);
  }
}
```
Interceptors wajib: `AuthInterceptor` (inject Bearer), `RefreshInterceptor` (handle 401 → `/api/v1/auth/refresh`), `LoggingInterceptor` (redact body untuk PII).

### B-1. Offline Queue & Sync Strategy

> **CRITICAL**: Offline queue wajib mengikuti contract GLOSSARY.md §8 untuk avoid duplikasi BKT update.

**Problem**: Siswa jawab quiz offline → app store lokal → sync saat online → risk: submit ulang attempt yang sama → corrupt P(L).

**Solution**: Setiap jawaban generate `attempt_id` (UUID v4) **sebelum** submit.

```dart
// lib/features/quiz/domain/entities/queued_answer.dart
class QueuedAnswer {
  final String attemptId;           // UUID client-generated (idempotency key)
  final String studentId;
  final String contentItemId;
  final int contentVersion;         // Versi soal saat dijawab
  final DateTime answeredAt;        // Client timestamp
  final int syncOrder;              // Local sequence number for batch
  final Map<String, dynamic> answer;
  
  QueuedAnswer({
    String? attemptId,
    required this.studentId,
    required this.contentItemId,
    required this.contentVersion,
    required this.answeredAt,
    required this.syncOrder,
    required this.answer,
  }) : attemptId = attemptId ?? const Uuid().v4();
}
```

**Offline Behavior**:
1. User tap submit → check connectivity.
2. Jika offline → save to local DB (`drift` / `sqflite`) dengan status `QUEUED`.
3. Jika online → POST `/api/v1/engine/evaluate` dengan `Idempotency-Key: attemptId`.
4. Background sync worker (via `workmanager`) upload queue saat kembali online.

**Sync Logic** (`lib/core/sync/answer_sync_worker.dart`):
```dart
Future<void> syncQueuedAnswers() async {
  final queued = await _localDb.getQueuedAnswers(status: 'QUEUED');
  
  for (final answer in queued) {
    try {
      final response = await _apiClient.evaluate(
        EvaluateRequest.fromQueued(answer),
        idempotencyKey: answer.attemptId,
      );
      
      // Success: mark synced
      await _localDb.updateAnswerStatus(answer.attemptId, 'SYNCED');
      
    } on ConflictException catch (e) {
      // Server return 409 OFFLINE_CONFLICT: attempt already exists
      // Show user dialog: "Jawaban ini sudah pernah dikirim. Server punya skor X. Hapus dari queue?"
      await _showConflictDialog(answer, e.serverState);
      
    } on ContentVersionMismatchException {
      // Server return 422: soal sudah berubah sejak offline
      await _localDb.updateAnswerStatus(answer.attemptId, 'INVALID_VERSION');
      _showSnackBar("Soal sudah diperbarui. Jawaban offline tidak bisa dikirim.");
      
    } catch (e) {
      // Network error: retry next sync
      continue;
    }
  }
}
```

**Conflict Policy** (user decision):
* **Keep local** (override): re-submit dengan flag `force_override=true` (admin decision).
* **Discard**: delete dari local queue, accept server state.

**Test Cases**:
```dart
// test/features/quiz/sync_test.dart
test('Duplicate attempt_id rejected by server', () async {
  final answer = QueuedAnswer(attemptId: 'test-uuid-123', ...);
  await localDb.insertQueued(answer);
  
  // First sync: success
  await syncWorker.syncQueuedAnswers();
  expect(await localDb.getStatus('test-uuid-123'), 'SYNCED');
  
  // Second sync (same attempt_id): should be skipped
  await syncWorker.syncQueuedAnswers();
  // No duplicate POST
});
```

**UI Indicator**:
* Quiz player show badge "X jawaban belum tersinkron" jika ada queue.
* Tap badge → show list queued answers dengan status masing-masing.

---

### C. Quiz Player Screen Blueprint
Tiga state visual transisi seamless:
* `LOADING_NEXT_CONTENT` (skeleton).
* `ANSWERING` (render ContentItem berdasarkan `content_type`).
* `EVALUATING` (animasi singkat sambil POST `/engine/evaluate`).
* `OUTCOME_BANNER` (mastery / continue / remedial / scaffold) → memicu navigasi state-machine yang konsisten dengan Doc 02 §4.

Untuk transisi `REROUTE_TO_PREREQUISITE` dan `RETURN_TO_PRIMARY_TP`, tampilkan breadcrumb `remediation_breadcrumb` dari payload Doc 04 §3.E.

### D. Accessibility (Wajib untuk TK & Inklusi)
* `MediaQuery.textScaler` minimum 1.0, dukung scaling sampai 1.8 untuk Fase Fondasi.
* Semua tombol interaktif memiliki `Semantics(label: ...)`.
* Kontras warna ≥ WCAG AA pada ketiga theme mode.
* Aktifkan `TalkBack`/`VoiceOver` dengan label terlokalisasi (lihat §F).
* Tombol minimum 48×48 dp.

### E. Aplikasi Parent (Branching Build)
Single codebase Flutter, dua build flavor:
* `flutter run --flavor student -t lib/main_student.dart`
* `flutter run --flavor parent -t lib/main_parent.dart`

`main_parent.dart` menonaktifkan route `/learn`, `/tutor` dan mengganti home shell dengan `ParentHomeShell` (lihat `10_PARENT_APP_SPEC.md`). AuthBloc identik; perbedaannya hanya role guard pada router.

### F. Localization
* Gunakan `flutter_localizations` + `intl` dengan ARB files di `lib/l10n/intl_id.arb`.
* Default locale `id_ID`; tambahkan `id_AC` (Aceh), `id_PA` (Papua), `en_US` untuk roadmap multi-lingual.

---

## 6. STRATEGI CACHING LOKAL UNTUK PRE-RENDERING CEPAT

Mengingat data Paspor Kognitif 12 tahun bersifat kumulatif, simpan string konfigurasi UI terakhir di penyimpanan lokal perangkat (*Local Storage*) menggunakan pustaka `shared_preferences` atau `hive`.

## Saat aplikasi pertama kali dibuka (*Cold Start*), sistem akan merender layout sesuai fase terakhir yang tersimpan sebelum jaringan internet memvalidasi ulang token JWT ke server. Hal ini menjamin pengalaman pengguna yang instan tanpa efek layar berkedip kosong (*zero layout flickering*).

```
