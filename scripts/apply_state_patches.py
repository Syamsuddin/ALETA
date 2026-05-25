#!/usr/bin/env python3
"""
ALETA Workspace Utility: apply_state_patches.py
Deskripsi: Menerapkan state patch atomic dari agent ke STATE.yaml.
"""
import os
import argparse
import datetime

try:
    import yaml
except ImportError:
    print("🚨 Error: Modul 'pyyaml' tidak terpasang. Jalankan 'pip install pyyaml' terlebih dahulu.")
    exit(1)

def parse_args():
    parser = argparse.ArgumentParser(description="Terapkan state patch ke STATE.yaml")
    parser.add_argument("--state", default="STATE.yaml", help="Path ke STATE.yaml")
    parser.add_argument("--patch", default="state_patch.yaml", help="Path ke berkas patch")
    return parser.parse_args()

def merge_dicts(dict1, dict2):
    """Secara rekursif menggabungkan dua dictionary"""
    for key, val in dict2.items():
        if isinstance(val, dict) and key in dict1 and isinstance(dict1[key], dict):
            merge_dicts(dict1[key], val)
        else:
            dict1[key] = val

def main():
    args = parse_args()

    if not os.path.exists(args.state):
        print(f"🚨 Berkas state utama {args.state} tidak ditemukan!")
        exit(1)

    if not os.path.exists(args.patch):
        print(f"ℹ️ Berkas patch {args.patch} tidak ditemukan. Tidak ada patch yang diterapkan.")
        print("💡 Tips: Untuk menerapkan patch, buat berkas 'state_patch.yaml' berisi updates.")
        exit(0)

    print(f"📖 Membaca state utama dari {args.state}...")
    with open(args.state, "r", encoding="utf-8") as f:
        state_data = yaml.safe_load(f)

    print(f"🩹 Membaca patch dari {args.patch}...")
    with open(args.patch, "r", encoding="utf-8") as f:
        patch_data = yaml.safe_load(f)

    if not patch_data:
        print("⚠️ Berkas patch kosong.")
        exit(0)

    # Lakukan penggabungan atomic
    print("🔄 Menggabungkan data patch ke state...")
    merge_dicts(state_data, patch_data)

    # Perbarui metrik kalkulasi tugas selesai
    completed_count = sum(
        1 for tid, tinfo in state_data.get("tasks", {}).items() 
        if tinfo.get("status") == "done"
    )
    if "metrics" not in state_data:
        state_data["metrics"] = {}
    state_data["metrics"]["tasks_completed"] = completed_count
    
    # Update timestamp
    state_data["last_updated"] = datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")

    # Tulis kembali state utama
    print(f"💾 Menyimpan state ter-patch ke {args.state}...")
    with open(args.state, "w", encoding="utf-8") as f:
        yaml.dump(state_data, f, default_flow_style=False, sort_keys=False)

    # Hapus berkas patch setelah berhasil diterapkan untuk menghindari pengulangan
    try:
        os.remove(args.patch)
        print(f"🧹 Berkas patch {args.patch} berhasil dihapus.")
    except Exception as e:
        print(f"⚠️ Gagal menghapus berkas patch: {e}")

    print("🎉 State patch berhasil diterapkan dengan sukses!")

if __name__ == "__main__":
    main()
