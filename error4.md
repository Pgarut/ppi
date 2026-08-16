chore(migrations): v6 tanpa BEGIN TRANSACTION agar kompatibel dengan … #87
Run npm test

> ppi-backend@1.0.0 test
> vitest run

(!) Your Vite config uses features that are unsupported by `configLoader: 'native'`, which is planned to become the default in a future major version of Vite:
  - ESM syntax in a file loaded as CommonJS (vitest.config.ts:1:1). Use a `.mjs` extension or set `"type": "module"` in the closest package.json
Set `VITE_CONFIG_NATIVE_IGNORE_WARNING=true` to suppress this warning.

 RUN  v4.1.10 /home/runner/work/ppi/ppi/backend

 ❯ tests/routes/guru.test.ts (25 tests | 1 failed) 68ms
       ✓ should list riwayat absensi guru 32ms
       ✓ should input absensi massal 2ms
       ✓ should upsert existing absensi 1ms
       ✓ should get siswa per kelas for absensi form 1ms
       ✓ should return assignments for nilai dropdown 2ms
       ✓ should return active semester with jenis list 2ms
       ✓ should list nilai guru 1ms
       ✓ should input nilai 1ms
       ✓ should reject invalid jenis nilai for semester 4ms
       ✓ should update own nilai 1ms
       ✓ should reject update of other teacher nilai 1ms
       ✓ should get siswa per kelas for nilai form 1ms
       ✓ should input nilai massal 1ms
       ✓ should reject non-wali-kelas user 1ms
       ✓ should check wali kelas status 1ms
       × should get rapor when wali kelas (aggregate from nilai) 9ms
       ✓ should reject rapor without siswa_id or semester_id 0ms
       ✓ should return semester list 1ms
       ✓ should list own pengaduan 1ms
       ✓ should create pengaduan 1ms
       ✓ should reject invalid kategori 1ms
       ✓ should return wali kelas info when user is wali kelas 1ms
       ✓ should handle non-wali kelas user gracefully 1ms
       ✓ should return rekap absensi wali kelas 1ms
       ✓ should update catatan wali kelas 1ms
 ✓ tests/routes/wakil_kurikulum.test.ts (29 tests) 63ms
 ✓ tests/routes/bk_ks.test.ts (13 tests) 45ms
 ✓ tests/routes/remaining.test.ts (15 tests) 70ms
 ✓ tests/integration/routing.test.ts (25 tests) 16ms
 ✓ tests/routes/admin/admin.test.ts (30 tests) 232ms
 ✓ tests/middleware/rate_limit.test.ts (9 tests) 60ms
 ✓ tests/utils/response.test.ts (14 tests) 40ms
 ✓ tests/utils/crud.test.ts (5 tests) 32ms
 ✓ tests/middleware/auth.test.ts (10 tests) 117ms

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
 Test Files  1 failed | 9 passed (10)

      Tests  1 failed | 174 passed (175)
⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯[1/1]⎯

   Start at  06:36:09
   Duration  1.41s (transform 711ms, setup 222ms, import 1.26s, tests 744ms, environment 1ms)


Error: AssertionError: expected null to be 85 // Object.is equality

- Expected:
85

+ Received:
null

 ❯ tests/routes/guru.test.ts:211:46


Error: Process completed with exit code 1.
