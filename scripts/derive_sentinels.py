#!/usr/bin/env python3
"""
ALETA Workspace Utility: derive_sentinels.py
Deskripsi: Memverifikasi kekonsistenan nilai sakral/sentinel di STATE.yaml terhadap blueprint.
"""
import os
import argparse

try:
    import yaml
except ImportError:
    print("🚨 Error: Modul 'pyyaml' tidak terpasang. Jalankan 'pip install pyyaml' terlebih dahulu.")
    exit(1)

def parse_args():
    parser = argparse.ArgumentParser(description="Validasi Sentinel Kunci ALETA")
    parser.add_argument("--state", default="STATE.yaml", help="Path ke STATE.yaml")
    parser.add_argument("--update-state", action="store_true", help="Otomatis update state sentinels")
    return parser.parse_args()

def main():
    args = parse_args()

    if not os.path.exists(args.state):
        print(f"🚨 Berkas state {args.state} tidak ditemukan!")
        exit(1)

    with open(args.state, "r", encoding="utf-8") as f:
        state_data = yaml.safe_load(f)

    sentinels = state_data.get("sentinels", {})
    
    print("=" * 60)
    print("🛡️  ALETA SENTINEL CONSISTENCY AUDITOR")
    print("=" * 60)
    print(f"Mengaudit {len(sentinels)} parameter sakral terdaftar...")

    # Definisikan referensi deterministik dari blueprints
    blueprint_sentinels = {
        "0.85": "Doc 02 §2 — BKT mastery threshold (P(L) ≥ 0.85)",
        "0.20": "Doc 02 §2 — BKT remedial threshold (P(L) < 0.20)",
        "0.15": "Doc 02 §4 — BKT p_init default (cold start)",
        "0.30": "Doc 02 §6.B — p_guess max constraint",
        "0.10": "Doc 02 §6.B — p_slip max constraint",
        "RS256": "Doc 07 §B — required JWT algorithm (RS256 or ES256 only)",
        "ES256": "Doc 07 §B — alternate JWT algorithm",
        "HS256_FORBIDDEN": "Doc 07 §B — HS256 explicitly forbidden in production",
        "15 menit": "Doc 07 §B — access token TTL",
        "30 hari": "Doc 07 §B — refresh token TTL with rotation",
        "10 menit": "Doc 07 §B — JWKS cache TTL",
        "90 hari": "Doc 07 §E — tutor_messages retention before hard delete",
        "3 tahun": "Doc 07 §E — student_quiz_logs rolling retention",
        "7 tahun": "Doc 07 §E — audit_events retention before offline archive",
        "2 tahun": "Doc 07 §E — passport anonymization after student graduation",
        "SISWA": "Doc 07 §C — student role",
        "GURU": "Doc 07 §C — teacher role",
        "ORANG_TUA": "Doc 07 §C — parent role",
        "ADMIN_YAYASAN": "Doc 07 §C — yayasan admin role",
        "SUPERADMIN": "Doc 07 §C — superadmin role (MFA mandatory)",
        "48dp": "Doc 14 §9 — minimum tap target standard",
        "64dp": "Doc 14 §8.B — minimum tap target in KIDS_GAMIFIED mode",
        "WCAG 2.2 AA": "Doc 14 §9 — accessibility standard",
        "3.5 detik": "Doc 09 §8 — P95 latency target for RAG/tutor end-to-end",
        "800 ms": "Doc 09 §4.F — streaming start latency target",
        "7 hari": "Doc 12 §2 — transition rollback window"
    }

    drift_detected = False
    
    for key, spec_desc in blueprint_sentinels.items():
        if key not in sentinels:
            print(f"❌ MISMATCH: Nilai Sentinel '{key}' ({spec_desc}) tidak terdefinisi di STATE.yaml!")
            drift_detected = True
        else:
            print(f"✅ VERIFIED: {key} -> {sentinels[key]}")

    print("-" * 60)
    if drift_detected:
        if args.update_state:
            print("🔄 Opsi --update-state aktif. Memperbarui berkas STATE.yaml...")
            state_data["sentinels"] = blueprint_sentinels
            with open(args.state, "w", encoding="utf-8") as f:
                yaml.dump(state_data, f, default_flow_style=False, sort_keys=False)
            print("🎉 Sentinels di STATE.yaml berhasil diperbarui!")
        else:
            print("🚨 Drift terdeteksi! Jalankan 'make derive_sentinels' dengan opsi update untuk membetulkan.")
            exit(1)
    else:
        print("🛡️  Selamat! Seluruh nilai sakral selaras 100% dengan spesifikasi blueprint.")
    print("=" * 60)

if __name__ == "__main__":
    main()
