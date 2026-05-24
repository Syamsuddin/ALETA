---
doc: "00"
title: "Executive Summary"
scope: "Vision, problem space, 3-year rollout, arsitektur overview — orientasi saja, tanpa implementation code"
key_entities: [Cognitive Passport, BKT, Multi-tenancy, Yayasan, Adaptive LMS, Kurikulum Merdeka]
depends_on: []
loaded_by_tasks: []
---

# FILE: EXECUTIVE_SUMMARY.md# PROJECT ALETA: EXECUTIVE SUMMARY REPORT

## 1. STRATEGIC OVERVIEW & VISION
**Project ALETA (AI-powered Learning Ecosystem for Tailored Achievement)** adalah proyek rekayasa teknologi instruksional yang dirancang khusus untuk mengonsolidasikan dan merevolusi sistem pendidikan terpadu di bawah naungan satu institusi/Yayasan (mencakup jenjang TK, SD, SMP, hingga SMA).

Mengadopsi filosofi utama Kurikulum Merdeka—yaitu pembelajaran berdiferensiasi berbasis kompetensi (*Teach at the Right Level*)—ALETA hadir untuk memecahkan dilema terbesar guru di kelas: **mengelola heterogenitas kemampuan siswa tanpa mengorbankan waktu produktif untuk beban administrasi.** 

ALETA mengintegrasikan kecerdasan buatan (*Artificial Intelligence*) bukan sebagai pengganti peran guru, melainkan sebagai *AI Co-Pilot* yang mengotomatisasi kerumitan pemetaan data kognitif, mengawal potensi bakat anak secara kontinu selama 12 tahun, dan memanusiakan kembali hubungan antara pendidik dan peserta didik.

## 1.1 ALETA AS AN AI-POWERED ADAPTIVE LMS

ALETA is not designed as an AI module attached to an external LMS. ALETA itself is the LMS vessel: content management, class management, student activity logs, quizzes, progress tracking, teacher dashboards, parent access, identity, privacy, and deployment are native parts of the platform architecture.

The key difference from conventional LMS products is adaptivity. Learning content, quiz flow, recommendations, remediation paths, and UI experiences are not served as static folders or fixed assignments. They are selected dynamically through the Cognitive Passport, CP/TP/ATP prerequisite graph, and Bayesian Knowledge Tracing (BKT). Therefore, Project ALETA should be implemented as a **native AI-Powered Adaptive LMS** for multi-level Yayasan education, not as a separate LMS plus an AI add-on.

---

## 2. THE PROBLEM SPACE: FRAGMENTASI DATA & BEBAN GURU
1.  **Lost Cognitive Tracks (Putusnya Data Lintas Jenjang):** Saat siswa lulus dari TK ke SD, SD ke SMP, atau SMP ke SMA di dalam Yayasan yang sama, rekam jejak kognitif, gaya belajar, dan peta miskonsepsi mereka di masa lalu menguap begitu saja. Guru di jenjang baru terpaksa memulai proses pemetaan dari nol lagi.
2.  **Teacher Burnout (Kelelahan Administrasi):** Kurikulum Merdeka mewajibkan guru membedah dokumen Capaian Pembelajaran (CP) menjadi Tujuan Pembelajaran (TP) dan Alur Tujuan Pembelajaran (ATP) yang unik untuk kelas berdiferensiasi. Melakukan hal ini secara manual untuk 30-40 siswa per kelas setiap hari secara fisik tidak mungkin dilakukan tanpa membuat guru kelelahan.
3.  **One-Size-Fits-All Failure:** Metode pengajaran konvensional yang menyamaratakan materi untuk seluruh kelas membuat siswa yang lambat belajar semakin tertinggal, sementara siswa yang berbakat kehilangan motivasi karena materi yang terlalu mudah.

---

## 3. THE SOLUTION: HYPER-PERSONALIZED ADAPTIVE SYSTEM
ALETA mengubah dokumen teks kurikulum pemerintah menjadi sebuah **Knowledge Graph (Ontologi Kurikulum)** digital yang dinamis. Pada Tahun 1–2, mesin adaptif memakai **Bayesian Knowledge Tracing (BKT) + Rule-Based Multi-Step Rerouting** yang spesifikasinya didefinisikan di `02_ADAPTIVE_ENGINE_SPEC.md`. *Deep Reinforcement Learning* direncanakan sebagai *evolution path* pada Tahun 3 setelah cukup log produksi tersedia untuk training; spesifikasi resminya akan ditulis sebagai `18_DRL_POLICY_ENGINE.md` saat dataset matang. ALETA memberikan solusi sistemik:

*   **Continuous Cognitive Passport:** Sebuah paspor digital terpusat yang merekam probabilitas penguasaan materi siswa sejak Fase Fondasi (TK) hingga Fase F (SMA) tanpa terputus.
*   **Dynamic Learning Rerouting:** Jika seorang siswa SMP atau SMA mengalami kegagalan berulang pada suatu kompetensi, ALETA secara otomatis mendeteksi akar masalahnya (bahkan jika akar miskonsepsi itu berada di level dasar/SD), melakukan *rerouting* jalur belajar untuk menyembuhkan konsep dasar tersebut secara instan (*micro-remediation*), lalu mengembalikannya ke materi utama.
*   **Contextual RAG Ingestion:** AI ALETA memodifikasi wajah soal dan teks materi secara personal berdasarkan hobi siswa (misal: visualisasi pecahan menggunakan takaran resep kue untuk siswa yang hobi memasak, atau analisis statistik operan untuk siswa yang hobi sepak bola) tanpa mengubah esensi Tujuan Pembelajaran.

---

## 4. ARCHITECTURE & TECHNOLOGY STACK (YAYASAN SCALE)
ALETA dirancang dengan arsitektur **Hybrid-Modular (API-First)** yang dirasionalisasi agar memiliki keandalan tinggi namun sangat hemat biaya operasional bagi skala Yayasan:


```

[ Frontend Apps: Flutter Mobile + React Web ] <───> [ API Gateway: Nginx ] <───> [ Backend: FastAPI ]
│
┌───────────────────────┬─────────────────────────────┴────────────────────────────┐
▼                       ▼                                                          ▼
[ Relational DB: Postgres ]   [ Graph DB: Neo4j ]                                    [ Local LLM: Ollama ]
(Multi-Tenant Schema per Unit) (Peta Jalur CP-TP-ATP)                                 (RAG Tutor & Generator Modul)

```

*   **Frontend:** Aplikasi **Flutter Mobile** digunakan untuk siswa dan orang tua. **Dashboard guru** dan **dashboard admin yayasan** dibangun sebagai aplikasi web React.js terpisah agar workflow operasional sekolah tidak bercampur dengan pengalaman mobile siswa.
*   **Backend & Multi-Tenancy:** Menggunakan **FastAPI (Python)** sebagai backend final untuk `backend_core` dan integrasi `ai_engine`, dengan pemisahan database terisolasi per unit sekolah (`unit_tk`, `unit_sd`, `unit_smp`, `unit_sma`) menggunakan satu core database fisik PostgreSQL terpusat.
*   **Kedaulatan & Efisiensi AI:** Seluruh pemrosesan bahasa alami (Chatbot Tutor 24/7 dan Generator Modul Ajar otomatis) ditenagai oleh **Local LLM (Ollama/Llama 3)** yang di-host mandiri pada server internal Yayasan. **0 Rupiah biaya API pihak ketiga per bulan**, dan 100% aman mematuhi **UU Perlindungan Data Pribadi (UU PDP) No. 27 Tahun 2022** tentang perlindungan data anak di bawah umur.

---

## 5. EXPERIENTIAL REALITY: TIGA WAJAH APLIKASI
*   **Bagi Siswa:** Pembelajaran terasa seperti petualangan individu yang menyenangkan. Siswa berkompetisi dengan versi terbaik dari diri mereka sendiri melalui rekomendasi misi harian cerdas yang pas dengan tingkat pemahaman mereka.
*   **Bagi Guru (*The AI Co-Pilot*):** Setiap pagi sebelum masuk kelas, aplikasi web ALETA menyajikan rekomendasi taktis: mengelompokkan kelas secara otomatis menjadi 3 zona meja kelompok (Fondasi, Reguler, Mahir) serta menyalakan lampu peringatan (*Red Flag Alert*) bagi siswa yang membutuhkan sentuhan empati dan konseling sosio-emosional tatap muka.
*   **Bagi Orang Tua:** Mendapatkan laporan perkembangan kompetensi riil anak tanpa angka mati, lengkap dengan saran aktivitas kontekstual harian yang bisa dilakukan bersama anak di rumah untuk memperkuat pelajaran sekolah.

---

## 6. NILAI STRATEGIS & BUSINESS ADVANTAGE BAGI YAYASAN
1.  **Ultimate Customer Retention:** Yayasan memiliki nilai jual (*branding*) eksklusif yang sangat kuat untuk menarik minat orang tua murid baru: *"Sekali Anda mendaftarkan anak di TK kami, bakat dan kognitifnya akan dikawal oleh sistem kecerdasan buatan terpadu hingga ia lulus SMA."*
2.  **Operational Efficiency:** Menghilangkan biaya pelaksanaan tes diagnostik atau seleksi akademik berulang saat masa transisi kelulusan siswa internal (dari SD Yayasan menuju SMP Yayasan), karena seluruh data historis berpindah secara mulus.
3.  **Pionir Pendidikan Masa Depan:** Menempatkan Yayasan sebagai institusi terdepan yang berhasil mendemonstrasikan pemanfaatan AI mutakhir secara mandiri dan aman dalam ekosistem pendidikan nasional.

---

## 7. TIMELINE & STRATEGI ROLL-OUT (3-YEAR PLAN)
Untuk memastikan keberhasilan manajemen perubahan (*change management*) budaya guru dan kesiapan operasional, implementasi ALETA dibagi menjadi tiga fase:

*   **Tahun 1 (Fase Pilot):** Penerapan terbatas hanya pada kelas-kelas awal di setiap unit sekolah (**TK B, Kelas 1 SD, Kelas 7 SMP, Kelas 10 SMA**). Fokus pada kalibrasi model AI dan pelatihan guru penggerak internal.
*   **Tahun 2 (Fase Integrasi):** Sistem bergerak naik secara vertikal bersama siswa ke tingkat kelas berikutnya. Uji coba pengaliran data Paspor Kognitif lintas unit (transisi kelulusan internal) resmi diaktifkan.
*   **Tahun 3 (Full Deployment):** Seluruh kelas dari jenjang TK hingga SMA aktif menggunakan ekosistem ALETA secara penuh dan mandiri, menciptakan siklus data pendidikan terpadu yang matang.

```
