-- Trigger INSERT: auto compute nilai
CREATE TRIGGER IF NOT EXISTS trg_dauroh_nilai_compute_insert
AFTER INSERT ON dauroh_nilai
BEGIN
    UPDATE dauroh_nilai SET
        nilai_bidang1 = 40 - COALESCE(NEW.kelancaran, 0) - COALESCE(NEW.ketepatan_ayat, 0) 
                       - COALESCE(NEW.murojaah_sambung, 0) - COALESCE(NEW.konsistensi_hafalan, 0),
        nilai_bidang2 = 30 - COALESCE(NEW.makhorijul_huruf, 0) - COALESCE(NEW.sifatul_huruf, 0) 
                       - COALESCE(NEW.ahkamul_huruf, 0) - COALESCE(NEW.ahkamul_madd, 0),
        nilai_bidang3 = 30 - COALESCE(NEW.ahkamul_waqfi, 0) - COALESCE(NEW.adabut_tilawah, 0) 
                       - COALESCE(NEW.kerapihan_bacaan, 0) - COALESCE(NEW.ketepatan_tempo, 0),
        total_nilai  = (40 - COALESCE(NEW.kelancaran, 0) - COALESCE(NEW.ketepatan_ayat, 0) 
                       - COALESCE(NEW.murojaah_sambung, 0) - COALESCE(NEW.konsistensi_hafalan, 0))
                     + (30 - COALESCE(NEW.makhorijul_huruf, 0) - COALESCE(NEW.sifatul_huruf, 0) 
                       - COALESCE(NEW.ahkamul_huruf, 0) - COALESCE(NEW.ahkamul_madd, 0))
                     + (30 - COALESCE(NEW.ahkamul_waqfi, 0) - COALESCE(NEW.adabut_tilawah, 0) 
                       - COALESCE(NEW.kerapihan_bacaan, 0) - COALESCE(NEW.ketepatan_tempo, 0))
    WHERE id = NEW.id;
END;

-- Trigger UPDATE: auto compute nilai on scoring field change
CREATE TRIGGER IF NOT EXISTS trg_dauroh_nilai_compute_update
AFTER UPDATE OF kelancaran, ketepatan_ayat, murojaah_sambung, konsistensi_hafalan,
    makhorijul_huruf, sifatul_huruf, ahkamul_huruf, ahkamul_madd,
    ahkamul_waqfi, adabut_tilawah, kerapihan_bacaan, ketepatan_tempo
ON dauroh_nilai
BEGIN
    UPDATE dauroh_nilai SET
        nilai_bidang1 = 40 - COALESCE(NEW.kelancaran, 0) - COALESCE(NEW.ketepatan_ayat, 0) 
                       - COALESCE(NEW.murojaah_sambung, 0) - COALESCE(NEW.konsistensi_hafalan, 0),
        nilai_bidang2 = 30 - COALESCE(NEW.makhorijul_huruf, 0) - COALESCE(NEW.sifatul_huruf, 0) 
                       - COALESCE(NEW.ahkamul_huruf, 0) - COALESCE(NEW.ahkamul_madd, 0),
        nilai_bidang3 = 30 - COALESCE(NEW.ahkamul_waqfi, 0) - COALESCE(NEW.adabut_tilawah, 0) 
                       - COALESCE(NEW.kerapihan_bacaan, 0) - COALESCE(NEW.ketepatan_tempo, 0),
        total_nilai  = (40 - COALESCE(NEW.kelancaran, 0) - COALESCE(NEW.ketepatan_ayat, 0) 
                       - COALESCE(NEW.murojaah_sambung, 0) - COALESCE(NEW.konsistensi_hafalan, 0))
                     + (30 - COALESCE(NEW.makhorijul_huruf, 0) - COALESCE(NEW.sifatul_huruf, 0) 
                       - COALESCE(NEW.ahkamul_huruf, 0) - COALESCE(NEW.ahkamul_madd, 0))
                     + (30 - COALESCE(NEW.ahkamul_waqfi, 0) - COALESCE(NEW.adabut_tilawah, 0) 
                       - COALESCE(NEW.kerapihan_bacaan, 0) - COALESCE(NEW.ketepatan_tempo, 0)),
        updated_at = datetime('now')
    WHERE id = NEW.id;
END;
