fix(wali-kelas): rapor & catatan wali kelas (R1-R3, S1, S3, S4, K1)

Run npm test

> ppi-backend@1.0.0 test
> vitest run

(!) Your Vite config uses features that are unsupported by `configLoader: 'native'`, which is planned to become the default in a future major version of Vite:
  - ESM syntax in a file loaded as CommonJS (vitest.config.ts:1:1). Use a `.mjs` extension or set `"type": "module"` in the closest package.json
Set `VITE_CONFIG_NATIVE_IGNORE_WARNING=true` to suppress this warning.

 RUN  v4.1.10 /home/runner/work/ppi/ppi/backend

 ✓ tests/routes/wakil_kurikulum.test.ts (29 tests) 58ms
 ❯ tests/routes/guru.test.ts (25 tests | 1 failed) 74ms
       ✓ should list riwayat absensi guru 32ms
       ✓ should input absensi massal 5ms
       ✓ should upsert existing absensi 1ms
       ✓ should get siswa per kelas for absensi form 1ms
       ✓ should return assignments for nilai dropdown 5ms
       ✓ should return active semester with jenis list 1ms
       ✓ should list nilai guru 4ms
       ✓ should input nilai 1ms
       ✓ should reject invalid jenis nilai for semester 4ms
       ✓ should update own nilai 1ms
       ✓ should reject update of other teacher nilai 0ms
       ✓ should get siswa per kelas for nilai form 1ms
       ✓ should input nilai massal 1ms
       ✓ should reject non-wali-kelas user 1ms
       ✓ should check wali kelas status 0ms
       × should get rapor when wali kelas (aggregate from nilai) 9ms
       ✓ should reject rapor without siswa_id or semester_id 0ms
       ✓ should return semester list 0ms
       ✓ should list own pengaduan 1ms
       ✓ should create pengaduan 2ms
       ✓ should reject invalid kategori 0ms
       ✓ should return wali kelas info when user is wali kelas 1ms
       ✓ should handle non-wali kelas user gracefully 1ms
       ✓ should return rekap absensi wali kelas 0ms
       ✓ should update catatan wali kelas 0ms
 ✓ tests/routes/bk_ks.test.ts (13 tests) 34ms
 ✓ tests/routes/remaining.test.ts (15 tests) 37ms
 ✓ tests/integration/routing.test.ts (25 tests) 7ms
 ✓ tests/routes/admin/admin.test.ts (30 tests) 174ms
 ✓ tests/middleware/rate_limit.test.ts (9 tests) 51ms
 ✓ tests/utils/response.test.ts (14 tests) 39ms
 ✓ tests/utils/crud.test.ts (5 tests) 25ms
 ✓ tests/middleware/auth.test.ts (10 tests) 115ms

⎯⎯⎯⎯⎯⎯⎯ Failed Tests 1 ⎯⎯⎯⎯⎯⎯⎯

 FAIL  tests/routes/guru.test.ts > Guru Mapel / Wali Kelas Routes > Rapor > should get rapor when wali kelas (aggregate from nilai)
AssertionError: expected null to be 85 // Object.is equality

- Expected:
85

+ Received:
null

 ❯ tests/routes/guru.test.ts:211:46
    209|       expect(body.data.mapel).toHaveLength(2);
    210|       // Matematika: harian [80,90] → rata 85, pas=85, akhir=85*0.6+85…
    211|       expect(body.data.mapel[0].nilai_akhir).toBe(85);
       |                                              ^
    212|       // IPA: harian [78] → rata 78, pas=82, akhir=82*0.6+78*0.4=80.4
    213|       expect(body.data.mapel[1].nilai_akhir).toBe(80.4);

⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯[1/1]⎯


 Test Files  1 failed | 9 passed (10)
      Tests  1 failed | 174 passed (175)
   Start at  05:46:27
   Duration  1.16s (transform 704ms, setup 138ms, import 1.17s, tests 615ms, environment 1ms)


Error: AssertionError: expected null to be 85 // Object.is equality

- Expected:
85

+ Received:
null

 ❯ tests/routes/guru.test.ts:211:46


Error: Process completed with exit code 1.