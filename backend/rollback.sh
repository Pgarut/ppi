#!/bin/bash
# ============================================================
# Rollback Script — PPI Madrasah
# Cara pakai:  bash rollback.sh [backend|frontend|all]
# ============================================================

set -e

show_help() {
  echo ""
  echo "PPI Madrasah — Rollback Script"
  echo ""
  echo "Usage: bash rollback.sh [option]"
  echo ""
  echo "Options:"
  echo "  backend       Rollback Cloudflare Workers ke versi sebelumnya"
  echo "  frontend      Panduan rollback Cloudflare Pages (manual via Dashboard)"
  echo "  all           Rollback backend + frontend"
  echo "  help          Tampilkan panduan ini"
  echo ""
}

rollback_backend() {
  echo "=== Rollback Backend (Cloudflare Workers) ==="
  echo ""
  echo "Opsi 1: Rollback ke versi sebelumnya"
  echo "  npx wrangler rollback --env production"
  echo ""
  echo "Opsi 2: Rollback ke versi spesifik"
  echo "  npx wrangler versions list --env production"
  echo "  npx wrangler rollback --env production --version <version-id>"
  echo ""
  echo "Opsi 3: Deploy ulang versi lama"
  echo "  git checkout <commit-hash>"
  echo "  cd backend && npx wrangler deploy --env production"
  echo "  cd .. && git checkout main"
  echo ""
}

rollback_frontend() {
  echo "=== Rollback Frontend (Cloudflare Pages) ==="
  echo ""
  echo "1. Buka https://dash.cloudflare.com"
  echo "2. Klik Workers & Pages → ppi"
  echo "3. Klik tab Deployments"
  echo "4. Cari deployment stabil terakhir"
  echo "5. Klik ikon ▶️ (play) untuk aktivasi"
  echo ""
  echo "Cloudflare Pages menyimpan 10 deployment terakhir."
  echo ""
}

case "${1:-help}" in
  backend)
    rollback_backend
    ;;
  frontend)
    rollback_frontend
    ;;
  all)
    rollback_backend
    echo "----------------------"
    rollback_frontend
    ;;
  help|--help|-h)
    show_help
    ;;
  *)
    echo "Error: Unknown option '$1'"
    show_help
    exit 1
    ;;
esac
