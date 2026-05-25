#!/usr/bin/env python3
"""
ALETA Workspace Utility: init_state.py
Deskripsi: Inisialisasi atau memperbarui STATE.yaml dari daftar task card di playbook.
"""
import os
import re
import argparse

try:
    import yaml
except ImportError:
    print("🚨 Error: Modul 'pyyaml' tidak terpasang. Jalankan 'pip install pyyaml' terlebih dahulu.")
    exit(1)

def parse_args():
    parser = argparse.ArgumentParser(description="Inisialisasi STATE.yaml dari Playbook")
    parser.add_argument("--catalog", default="16_AI_AGENT_IMPLEMENTATION_PLAYBOOK.md", help="Path playbook")
    parser.add_argument("--output", default="STATE.yaml", help="Path output STATE.yaml")
    return parser.parse_args()

def extract_tasks_from_playbook(playbook_path):
    if not os.path.exists(playbook_path):
        print(f"🚨 Playbook tidak ditemukan di: {playbook_path}")
        return {}

    with open(playbook_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Cari blok task yaml menggunakan regex
    # Task ditulis dalam format:
    # ```yaml
    # - id: T-NNN
    #   ...
    # ```
    yaml_blocks = re.findall(r"```yaml\s*\n(.*?)\n```", content, re.DOTALL)
    
    tasks = {}
    for block in yaml_blocks:
        if "id: T-" in block:
            try:
                parsed = yaml.safe_load(block)
                if isinstance(parsed, list):
                    for item in parsed:
                        if "id" in item:
                            tasks[item["id"]] = item
                elif isinstance(parsed, dict) and "id" in parsed:
                    tasks[parsed["id"]] = parsed
            except Exception as e:
                print(f"⚠️  Gagal memparsing blok YAML: {e}")
                
    return tasks

def main():
    args = parse_args()
    print(f"📖 Membaca task dari playbook: {args.catalog}...")
    
    playbook_tasks = extract_tasks_from_playbook(args.catalog)
    if not playbook_tasks:
        print("⚠️ Tidak ada task yang ditemukan di playbook. Menggunakan default state.")
        return

    print(f"✅ Menemukan {len(playbook_tasks)} task di playbook.")

    # Load existing state if exists to preserve completion statuses
    state = {
        "version": 1,
        "project": "ALETA",
        "current_phase": 0,
        "last_updated": yaml.dump(yaml.load("2026-05-24T00:00:00Z", Loader=yaml.SafeLoader)), # placeholder
        "blueprints": {},
        "sentinels": {},
        "tasks": {},
        "files": {},
        "pending_handoffs": [],
        "open_issues": [],
        "sync_points_passed": [],
        "metrics": {
            "tasks_completed": 0,
            "files_written": 0,
            "tokens_consumed_estimated": 0,
            "sync_points_passed": 0,
            "drift_halts_triggered": 0
        }
    }

    if os.path.exists(args.output):
        print(f"🔄 Berkas {args.output} sudah ada. Membaca data state lama...")
        with open(args.output, "r", encoding="utf-8") as f:
            try:
                old_state = yaml.safe_load(f)
                if old_state:
                    state.update(old_state)
            except Exception as e:
                print(f"🚨 Gagal membaca {args.output} lama: {e}")

    # Sinkronisasi task
    for tid, details in playbook_tasks.items():
        if tid not in state["tasks"]:
            state["tasks"][tid] = {
                "title": details.get("title", "Untitled Task"),
                "phase": details.get("phase", 0),
                "role": details.get("role", "unknown"),
                "status": "pending",
                "depends_on": details.get("depends_on", []),
                "artifacts": [],
                "handoffs_received": [],
                "handoffs_emitted": []
            }
        else:
            # Update meta-properties, keep status
            state["tasks"][tid]["title"] = details.get("title", state["tasks"][tid].get("title"))
            state["tasks"][tid]["phase"] = details.get("phase", state["tasks"][tid].get("phase"))
            state["tasks"][tid]["role"] = details.get("role", state["tasks"][tid].get("role"))
            state["tasks"][tid]["depends_on"] = details.get("depends_on", state["tasks"][tid].get("depends_on"))

    # Update metadata timestamps
    import datetime
    state["last_updated"] = datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")

    with open(args.output, "w", encoding="utf-8") as f:
        yaml.dump(state, f, default_flow_style=False, sort_keys=False)
        
    print(f"🚀 Berhasil menyimpan state ter-update ke: {args.output}")

if __name__ == "__main__":
    main()
