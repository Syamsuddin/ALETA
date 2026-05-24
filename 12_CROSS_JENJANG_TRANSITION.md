---
doc: "12"
title: "Cross-Jenjang Transition"
scope: "State-machine orchestrator TK→SD→SMP→SMA, idempotent design, 7-day rollback window, bulk mode"
key_entities: [TransitionOrchestrator, TransitionValidator, SnapshotGenerator, passport_snapshot, rollback_7_hari]
depends_on: ["03", "07"]
loaded_by_tasks: [T-701, T-702, T-703, T-704, T-705, T-706, T-708]
---

# FILE: 12_CROSS_JENJANG_TRANSITION.md
# PROJECT ALETA: CROSS-JENJANG TRANSITION & LIFECYCLE SPECIFICATION

## 1. PENDAHULUAN

Janji bisnis utama Yayasan: *"Sekali Anda mendaftarkan anak di TK kami, bakat dan kognitifnya akan dikawal oleh sistem kecerdasan buatan terpadu hingga ia lulus SMA."* (`00_EXECUTIVE_SUMMARY.md` §6).

Dokumen ini menetapkan **alur teknis** bagaimana seorang siswa berpindah dari satu unit ke unit lain dalam Yayasan yang sama (TK → SD → SMP → SMA/SMK) **tanpa kehilangan rekam jejak kognitif**.

---

## 2. PRINSIP DESAIN

1. **Data inti tidak berpindah, scope yang berpindah.** `aleta_core.users` dan `aleta_core.student_cognitive_passports` adalah satu baris seumur hidup siswa — tidak di-duplikasi. Yang berubah hanya `tenant_id` aktif di JWT dan enrollment di skema unit baru.
2. **Audit lengkap.** Setiap transisi tercatat di `aleta_core.student_transition_events` (Doc 03 §3.J) dengan `snapshot_summary` JSON yang membekukan jumlah TP mastered dan miskonsepsi terbuka pada momen transisi.
3. **Idempotent.** Pengulangan request transisi dengan parameter yang sama tidak menghasilkan side effect kedua.
4. **Reversibel pada 7 hari.** Status `ROLLED_BACK` tersedia jika kesalahan administrasi terjadi sebelum 7 hari pasca transisi.

---

## 3. PRA-SYARAT TRANSISI

Sebelum endpoint `POST /api/v1/admin/transition` (Doc 04 §3.L) dapat diterima, validator backend memeriksa:

| Check | Aksi jika gagal |
| :--- | :--- |
| Siswa aktif di `from_tenant_id` (enrollment status `ACTIVE`) | `409 CONFLICT_NOT_ENROLLED` |
| `to_tenant_id` ada di `aleta_core.tenants` | `404 NOT_FOUND_TENANT` |
| Fase `to_tenant_id` adalah fase yang valid setelah fase `from_tenant_id` | `422 BUSINESS_INVALID_FASE_TRANSITION` |
| Tidak ada transition `EXECUTING` lain untuk siswa yang sama | `409 CONFLICT_TRANSITION_IN_PROGRESS` |
| Consent ortu untuk `DATA_EXPORT` sudah `APPROVED` (Doc 03 §3.I) | `422 BUSINESS_CONSENT_REQUIRED` |

---

## 4. STATE MACHINE TRANSISI

```
SCHEDULED ─► EXECUTING ─► COMPLETED
   │            │
   │            └──► FAILED ──► (manual retry → SCHEDULED) atau ROLLED_BACK
   │
   └──► ROLLED_BACK (≤ 7 hari sejak COMPLETED)
```

Implementasi: orchestrator job (`backend_core/backend_core/jobs/transition_orchestrator.py`) menjalankan task di Celery/RQ worker.

---

## 5. LANGKAH ORCHESTRATOR

```python
def execute_transition(transition_id: UUID) -> None:
    with db.transaction() as tx:
        evt = repo.lock_transition(transition_id, expected_status="SCHEDULED")
        evt.status = "EXECUTING"
        repo.save(evt)

    try:
        # 1. Snapshot passport untuk audit
        snapshot = build_snapshot(evt.student_id)
        evt.snapshot_summary = snapshot

        # 2. Tutup enrollment lama
        repo.enrollment(evt.from_tenant_id).end_active(evt.student_id, reason="TRANSITION")

        # 3. Buka enrollment baru (kelas baru ditentukan terpisah oleh admin)
        # Catatan: penempatan kelas adalah keputusan admin, di luar scope orchestrator ini.

        # 4. Update JWT scope di session berikutnya — tidak perlu invalidate token sekarang,
        #    cukup tandai user.flags['pending_tenant_refresh'] = true. Token baru saat
        #    login berikutnya akan membawa tenant_id baru.
        repo.users.set_flag(evt.student_id, "pending_tenant_refresh", True)

        # 5. Generate Cognitive Passport Letter (PDF ringkasan) untuk wali kelas baru
        pdf_url = passport_letter.generate(evt.student_id, snapshot)
        evt.snapshot_summary["passport_letter_url"] = pdf_url

        # 6. Notifikasi guru wali kelas baru + orang tua
        notifier.notify_transition(evt)

        with db.transaction() as tx:
            evt.status = "COMPLETED"
            evt.executed_at = now()
            repo.save(evt)
            audit("TRANSITION_COMPLETED", target=evt.student_id, risk="HIGH")

    except Exception as exc:
        with db.transaction() as tx:
            evt.status = "FAILED"
            evt.snapshot_summary["error"] = str(exc)
            repo.save(evt)
            audit("TRANSITION_FAILED", target=evt.student_id, risk="HIGH", reason=str(exc))
        raise
```

### Catatan tentang `tenant_id` di JWT

Karena `tenant_id` di-embed di JWT (Doc 07 §2), penggantian tidak instan. Strategi:
* **Default:** flag `pending_tenant_refresh=true` → token baru saat login berikutnya membawa tenant baru.
* **Opsional (force logout):** admin centang opsi "Paksa logout sekarang" → backend memanggil Keycloak `logout-all` untuk user, sehingga siswa harus login ulang.

---

## 6. ATURAN AKSES LINTAS-UNIT (HISTORIS)

Setelah transisi, guru unit baru perlu konteks histori. Aturan default (lihat juga Doc 07 §4.1):

| Data Historis | Guru Unit Baru Boleh Lihat? |
| :--- | :--- |
| Ringkasan TP mastered (per Elemen) | ✅ Ya |
| Open misconception map (id + nama) | ✅ Ya |
| Raw quiz logs unit lama (`unit_<old>.student_quiz_logs`) | ❌ Tidak — hanya admin yayasan |
| Transkrip tutor messages | ❌ Tidak |
| Affective profile (`interest_vector`, learning style) | ✅ Ya |
| Audit log akses passport | ✅ Ya (sebatas tindakannya, bukan isi) |

Implementasi: view khusus `aleta_core.v_passport_summary_for_teacher` yang memfilter sesuai matrix di atas.

---

## 7. ROLLBACK

Endpoint `POST /api/v1/admin/transition/{id}/rollback` (Admin Yayasan). Validator:
* Hanya transisi `COMPLETED` ≤ 7 hari yang boleh rollback.
* Tidak ada `student_quiz_logs` baru di unit tujuan (siswa belum mengerjakan apa-apa).

Aksi: restore enrollment lama menjadi `ACTIVE`, set baru menjadi `WITHDRAWN`, status transisi `ROLLED_BACK`. `audit_events` `risk_level='CRITICAL'`.

---

## 8. BULK TRANSITION (KENAIKAN KELAS / KELULUSAN MASSAL)

Untuk kenaikan tahun ajaran (mis. semua siswa kelas 6 SD → kelas 7 SMP secara serempak), admin yayasan memakai modul **Transitions Bulk** di Doc 11.

Endpoint: `POST /api/v1/admin/transition/bulk`
```json
{
  "from_tenant_id": "UNIT_SD_01",
  "to_tenant_id": "UNIT_SMP_01",
  "student_ids": ["uuid-1","uuid-2", "..."],
  "effective_date": "2026-07-15",
  "consent_assumption": "PRE_COLLECTED"
}
```

Server membuat N baris `student_transition_events` dengan `status='SCHEDULED'`. Orchestrator memproses dengan concurrency limit 20 supaya beban DB stabil.

---

## 9. RELEASE GATE TRANSISI

* End-to-end test: TK → SD → SMP → SMA siswa fiktif, periksa passport tetap utuh dan timeline `student_transition_events` lengkap.
* Test rollback (h+1, h+8).
* Test concurrent transition (race condition: dua admin trigger bersamaan → satu sukses, satu `409`).
* Test bulk 500 siswa harus selesai < 30 menit.
