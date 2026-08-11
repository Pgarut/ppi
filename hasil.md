Deploy Backend (Cloudflare Workers)
Run npx wrangler d1 migrations apply ppi-db-prod --env production

 ⛅️ wrangler 3.114.17 (update available 4.120.0)
------------------------------------------------

▲ [WARNING] The version of Wrangler you are using is now out-of-date.

  Please update to the latest version to prevent critical errors.
  Run `npm install --save-dev wrangler@4` to update to the latest version.
  After installation, run Wrangler with `npx wrangler`.


Migrations to be applied:
┌──────────────────────────────────────┐
│ name                                 │
├──────────────────────────────────────┤
│ 0001_initial.sql                     │
├──────────────────────────────────────┤
│ 0002_add_mapel_kelas.sql             │
├──────────────────────────────────────┤
│ 0003_add_rate_limits.sql             │
├──────────────────────────────────────┤
│ 0004_guru_kesiapan.sql               │
├──────────────────────────────────────┤
│ 0005_add_jam_absensi.sql             │
├──────────────────────────────────────┤
│ 0006_update_nilai_jenis.sql          │
├──────────────────────────────────────┤
│ 0007_fix_bakat_minat_jenis.sql       │
├──────────────────────────────────────┤
│ 0008_pengaturan_kenaikan_kelas.sql   │
├──────────────────────────────────────┤
│ 0009_add_sessions_device_limit.sql   │
├──────────────────────────────────────┤
│ 0010_add_dauroh_tables.sql           │
├──────────────────────────────────────┤
│ 0011_add_musyrifah_role.sql          │
├──────────────────────────────────────┤
│ 0012_add_unique_mapel_nama.sql       │
├──────────────────────────────────────┤
│ 0012_update_tingkat_jenjang.sql      │
├──────────────────────────────────────┤
│ 0013_add_unique_nilai.sql            │
├──────────────────────────────────────┤
│ 0014_add_nilai_published.sql         │
├──────────────────────────────────────┤
│ 0015_add_siswa_orang_tua_columns.sql │
└──────────────────────────────────────┘
? About to apply 16 migration(s)
Your database may not be available to serve requests during the migration, continue?
🤖 Using fallback value in non-interactive context: yes

✘ [ERROR] A request to the Cloudflare API (/accounts/7823639b7112dadf24b9329aaef36692/d1/database/f4f8e08d-1d77-4cd4-8021-225e88ae233c) failed.

  Authentication error [code: 10000]


📎 It looks like you are authenticating Wrangler via a custom API token set in an environment variable.
Please ensure it has the correct permissions for this operation.

Getting User settings...
ℹ️  The API Token is read from the CLOUDFLARE_API_TOKEN environment variable.
👋 You are logged in with an User API Token, associated with the email pgarut77@gmail.com.
┌──────────────────────────────┬──────────────────────────────────┐
│ Account Name                 │ Account ID                       │
├──────────────────────────────┼──────────────────────────────────┤
│ Pgarut77@gmail.com's Account │ 7823639b7112dadf24b9329aaef36692 │
└──────────────────────────────┴──────────────────────────────────┘
🔓 To see token permissions visit https://dash.cloudflare.com/profile/api-tokens.
🎢 Membership roles in "Pgarut77@gmail.com's Account": Contact account super admin to change your permissions.
- Super Administrator - All Privileges
🪵  Logs were written to "/home/runner/.config/.wrangler/logs/wrangler-2026-08-09_05-03-22_984.log"
Error: Process completed with exit code 1.


console 
GET
https://ppi-backend-production.pgarut77.workers.dev/api/admin/guru-wali-kelas/34
[HTTP/3 404  19ms]
XHR 
PUT
https://ppi-backend-production.pgarut77.workers.dev/api/admin/guru-wali-kelas/34
[HTTP/3 404  27ms]

​PUT
	https://ppi-backend-production.pgarut77.workers.dev/api/admin/guru-wali-kelas/34
	
	
	Status
404
VersiHTTP/3
Ditransfer859 B (ukuran 73 B)
Kebijakan Perujukstrict-origin-when-cross-origin
Resolusi DNSSistem

access-control-allow-headers
	Content-Type, Authorization
access-control-allow-methods
	GET, POST, PUT, DELETE, OPTIONS
access-control-allow-origin
	https://ppi-bo8.pages.dev
alt-svc
	h3=":443"; ma=86400
cf-ray
	a2843f57dedcfe0d-SIN
content-encoding
	zstd
content-type
	application/json
date
	Sun, 09 Aug 2026 05:09:13 GMT
nel
	{"report_to":"cf-nel","success_fraction":0.0,"max_age":604800}
priority
	u=4,i=?0
report-to
	{"group":"cf-nel","max_age":604800,"endpoints":[{"url":"https://a.nel.cloudflare.com/report/v4?s=7lK%2BVXD4UuuFmyxaaRDJcDitEmjWxMT8%2B9og4ZyLpGkNRdT0QLqkrTfbYPXxmi8Wb961x1jlmMVgoBX5PtvHuhQCBxBEBY5OnWpOox90AyC93ZMdUlwPaCkz4hRXOKgI0jWY0Tx2%2BiOYc8YCADHD2QE8Dnxhqpr8F7Zjy1hpVPWIR1w%2F2WCMoTUn"}]}
server
	cloudflare
server-timing
	cfExtPri
	
Accept
	*/*
Accept-Encoding
	gzip, deflate, br, zstd
Accept-Language
	id,en-US;q=0.9,en;q=0.8
Authorization
	Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOjEsInVzZXJuYW1lIjoiYWRtaW4wMTkiLCJyb2xlIjoiYWRtaW4iLCJndXJ1X2lkIjpudWxsLCJzaXN3YV9pZCI6bnVsbCwiaWF0IjoxNzg2MjUyMDk4LCJleHAiOjE3ODYyODA4OTh9.keAvV-0Yu7Oe_1r4uWMXLjf7R3UZ3r4InU_TcGSst_4
Connection
	keep-alive
Content-Length
	14
Content-Type
	application/json
Host
	ppi-backend-production.pgarut77.workers.dev
Origin
	https://ppi-bo8.pages.dev
Priority
	u=4
Referer
	https://ppi-bo8.pages.dev/
Sec-Fetch-Dest
	empty
Sec-Fetch-Mode
	cors
Sec-Fetch-Site
	cross-site
TE
	trailers
User-Agent
	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:153.0) Gecko/20100101 Firefox/153.0
	
	Tasmi 
	
	Ektrakurikuler 
	