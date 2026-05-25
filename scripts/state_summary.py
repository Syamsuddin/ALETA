#!/usr/bin/env python3
"""
ALETA Workspace Utility: state_summary.py
Deskripsi: Dashboard ringkasan progress pembangunan ekosistem ALETA.
"""
import os
import argparse

try:
    import yaml
except ImportError:
    print("🚨 Error: Modul 'pyyaml' tidak terpasang. Jalankan 'pip install pyyaml' terlebih dahulu.")
    exit(1)

def parse_args():
    parser = argparse.ArgumentParser(description="Ringkasan Progress STATE.yaml")
    parser.add_argument("--state", default="STATE.yaml", help="Path ke STATE.yaml")
    return parser.parse_args()

def main():
    args = parse_args()

    if not os.path.exists(args.state):
        print(f"🚨 Berkas state {args.state} tidak ditemukan!")
        exit(1)

    with open(args.state, "r", encoding="utf-8") as f:
        state = yaml.safe_load(f)

    if not state:
        print("🚨 Gagal memparsing berkas state utama.")
        exit(1)

    project = state.get("project", "ALETA")
    current_phase = state.get("current_phase", 0)
    last_updated = state.get("last_updated", "N/A")
    tasks = state.get("tasks", {})
    metrics = state.get("metrics", {})

    print("=" * 60)
    print(f"🎯  PROJECT {project} STATE SUMMARY DASHBOARD")
    print(f"📅  Terakhir diperbarui: {last_updated}")
    print(f"🔒  Fase Aktif: Phase {current_phase}")
    print("=" * 60)

    # 1. Hitung Status Tugas
    status_counts = {"pending": 0, "in_progress": 0, "done": 0, "blocked": 0, "deferred": 0}
    phase_counts = {}

    for tid, tinfo in tasks.items():
        status = tinfo.get("status", "pending")
        phase = tinfo.get("phase", 0)

        if status in status_counts:
            status_counts[status] += 1
        else:
            status_counts["pending"] += 1

        if phase not in phase_counts:
            phase_counts[phase] = {"pending": 0, "in_progress": 0, "done": 0, "blocked": 0}
        
        pstatus = status if status in ["pending", "in_progress", "done", "blocked"] else "pending"
        phase_counts[phase][pstatus] += 1

    total_tasks = len(tasks)
    done_tasks = status_counts["done"]
    progress_pct = (done_tasks / total_tasks * 100) if total_tasks > 0 else 0

    print("📊 KINERJA EKSEKUSI:")
    # Buat progress bar sederhana
    bar_len = 30
    filled_len = int(bar_len * progress_pct / 100)
    bar = "█" * filled_len + "░" * (bar_len - filled_len)
    print(f"   [{bar}] {progress_pct:.1f}% ({done_tasks}/{total_tasks} Selesai)")
    print("-" * 60)

    # Tampilkan breakdown status
    print("📂 RINGKASAN STATUS TUGAS:")
    print(f"   🟢 Done       : {status_counts['done']}")
    print(f"   🟡 In Progress: {status_counts['in_progress']}")
    print(f"   ⚪ Pending     : {status_counts['pending']}")
    print(f"   🔴 Blocked     : {status_counts['blocked']}")
    if status_counts["deferred"] > 0:
        print(f"   🔵 Deferred    : {status_counts['deferred']}")
    print("-" * 60)

    # Tampilkan breakdown fase
    print("📌 BREAKDOWN PROGRESS PER MILISTONE FASE:")
    for phase in sorted(phase_counts.keys()):
        pinfo = phase_counts[phase]
        ptotal = sum(pinfo.values())
        pdone = pinfo["done"]
        ppct = (pdone / ptotal * 100) if ptotal > 0 else 0
        
        status_str = "🔒 LOCK"
        if phase == current_phase:
            status_str = "⚡ AKTIF"
        elif phase < current_phase:
            status_str = "✅ LULUS"
            
        print(f"   Phase {phase}: {pdone:2d}/{ptotal:2d} ({ppct:5.1f}%) | {status_str} | [D:{pinfo['done']} P:{pinfo['pending']} I:{pinfo['in_progress']} B:{pinfo['blocked']}]")

    print("=" * 60)
    
    # 2. Tampilkan tugas yang saat ini 'in_progress' atau 'blocked'
    active_tasks = [
        (tid, tinfo) for tid, tinfo in tasks.items() 
        if tinfo.get("status") in ["in_progress", "blocked"]
    ]
    if active_tasks:
        print("🚀 TUGAS YANG SEDANG BERJALAN ATAU TERHAMBAT:")
        for tid, tinfo in active_tasks:
            icon = "🟡 [IN_PRG]" if tinfo.get("status") == "in_progress" else "🔴 [BLOCK]"
            print(f"   {icon} {tid}: {tinfo.get('title')} ({tinfo.get('role')})")
        print("=" * 60)

if __name__ == "__main__":
    main()
