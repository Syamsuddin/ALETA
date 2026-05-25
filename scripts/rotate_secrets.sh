#!/bin/bash
# ============================================================================
# PROJECT ALETA — Secrets Rotation & Generation Tool
# ============================================================================
# Lokasi: scripts/rotate_secrets.sh
# Deskripsi: Menghasilkan kunci acak yang kuat (kriptografis) untuk PostgreSQL,
#            Redis, Neo4j, Keycloak, dan cadangan sistem.
# ============================================================================

set -e

# Pastikan berada di root repositori
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

ENV_FILE=".env"
ENV_EXAMPLE=".env.example"

# Fungsi membuat string acak kuat (24 bytes hex)
generate_secure_secret() {
    openssl rand -hex 24
}

echo "=== ALETA Secrets Rotation & Generation Tool ==="

# 1. Pastikan .env.example tersedia
if [ ! -f "$ENV_EXAMPLE" ]; then
    echo "🚨 Error: Berkas $ENV_EXAMPLE tidak ditemukan di root proyek!"
    exit 1
fi

# 2. Jika .env belum ada, salin dari example
if [ ! -f "$ENV_FILE" ]; then
    echo "📝 Berkas $ENV_FILE belum ada. Membuat dari template $ENV_EXAMPLE..."
    cp "$ENV_EXAMPLE" "$ENV_FILE"
else
    # Jika sudah ada, buat cadangan sebelum diubah
    BACKUP_FILE="${ENV_FILE}.bak_$(date +%Y%m%d%H%M%S)"
    echo "💾 Berkas $ENV_FILE sudah ada. Mencadangkan ke $BACKUP_FILE..."
    cp "$ENV_FILE" "$BACKUP_FILE"
fi

# 3. Hasilkan nilai acak baru
NEW_POSTGRES_PASS=$(generate_secure_secret)
NEW_NEO4J_PASS=$(generate_secure_secret)
NEW_REDIS_PASS=$(generate_secure_secret)
NEW_KEYCLOAK_ADMIN_PASS=$(generate_secure_secret)
NEW_BACKUP_PASS=$(generate_secure_secret)

# 4. Ganti nilai di dalam berkas .env
# Menggunakan sed portabel yang bekerja baik di macOS (BSD) maupun Linux (GNU)
update_env_var() {
    local key="$1"
    local val="$2"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS sed membutuhkan argumen string kosong setelah -i
        sed -i "" -E "s|^(${key}=).*|\1${val}|" "$ENV_FILE"
    else
        # Linux GNU sed
        sed -i -E "s|^(${key}=).*|\1${val}|" "$ENV_FILE"
    fi
}

echo "🔒 Memperbarui berkas $ENV_FILE dengan kunci kriptografis baru..."

update_env_var "ALETA_POSTGRES_PASSWORD" "$NEW_POSTGRES_PASS"
update_env_var "ALETA_KEYCLOAK_DB_PASSWORD" "$NEW_POSTGRES_PASS"
update_env_var "ALETA_NEO4J_PASSWORD" "$NEW_NEO4J_PASS"
update_env_var "ALETA_REDIS_PASSWORD" "$NEW_REDIS_PASS"
update_env_var "ALETA_KEYCLOAK_ADMIN_PASSWORD" "$NEW_KEYCLOAK_ADMIN_PASS"
update_env_var "ALETA_BACKUP_PASSPHRASE" "$NEW_BACKUP_PASS"

echo "✅ Kunci berhasil di-rotate dengan sukses di berkas $ENV_FILE!"
echo "⚠️  PERINGATAN: Jika layanan Docker sudah aktif, jalankan 'make down && make dev' agar perubahan diterapkan."
