## Deskripsi Perubahan
*Jelaskan secara ringkas perubahan yang dilakukan, alasan bisnis/teknisnya, dan nomor task (T-NNN) yang diselesaikan.*

## Jenis Perubahan
- [ ] Perbaikan Bug (Bug Fix)
- [ ] Penambahan Fitur Baru (New Feature)
- [ ] Refactoring / Pemeliharaan (Maintenance)
- [ ] Pembaruan Infrastruktur / DevOps (CI/CD)

## Daftar Task & Validasi Anti-Drift (Wajib)
Sesuai tata tertib **ALETA-OPS v1.0** (Doc 16 §11 & Doc 17):
- [ ] File yang disentuh/dibuat sesuai dengan path kanonik **Doc 15 §3-11** (Aturan 2)
- [ ] Seluruh nilai sakral/sensitif dirujuk ke **STATE.yaml Sentinels** (Aturan 4)
- [ ] Berkas `STATE.yaml` telah diperbarui menggunakan `make apply_patches` (atau manual)
- [ ] Modul yang disentuh mematuhi **Aturan Import & Module Boundaries** (Doc 15 §12.B)

## Cara Menguji (Verification Log)
*Sebutkan perintah atau pengujian manual yang telah dijalankan:*
```bash
# Contoh:
# make test
# make lint
```

## Dampak Keamanan & UU PDP (Doc 07)
- [ ] Apakah perubahan menyentuh data pribadi siswa (Paspor Kognitif)?
- [ ] Apakah authz token claims valid diuji terhadap bypass role?
- [ ] Apakah RLS policy terdampak?
