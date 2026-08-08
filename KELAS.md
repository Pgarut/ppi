Error: ClientException: Failed to fetch, uri=https://ppi-backend-production.pgarut77.workers.dev/api/admin/siswa?page=1&per_page=20&tingkat_id=1

## Penyebab
extraWhere diawali " AND" tapi base "where" kosong → SQL: " AND siswa.kelas_id IN (...)" → syntax error

## Perbaikan
crud.ts:50 — Jika where kosong, ganti " AND" di extraWhere menjadi "WHERE"

## Status: FIXED
Commit: fix sql syntax error when tingkat_id filter with empty where clause
Deploy: fb1d3f12
