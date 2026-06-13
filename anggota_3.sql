-- ==========================================
-- ANGGOTA 3
-- ==========================================

-- Searching: Pelanggan di toko X pada tanggal Y
SELECT DISTINCT pl.nama
FROM Pelanggan pl
JOIN Pesanan p ON pl.id_pelanggan = p.id_pelanggan
WHERE p.id_toko = 1 AND p.waktu_pesan::DATE = '2026-06-12';

-- Searching: Menu di bawah 15.000
SELECT m.nama_menu, m.harga, t.nama AS nama_toko
FROM Menu m
JOIN Toko t ON m.id_toko = t.id_toko
WHERE m.harga < 15000;

-- View: Antrean Pesanan Aktif
CREATE OR REPLACE VIEW v_antrean_pesanan AS
SELECT p.id_pesanan, pl.nama AS pelanggan, t.nama AS toko, p.status_pesanan
FROM Pesanan p
JOIN Pelanggan pl ON p.id_pelanggan = pl.id_pelanggan
JOIN Toko t ON p.id_toko = t.id_toko
WHERE p.status_pesanan IN ('Diproses');

-- View: Distribusi Pelanggan per Departemen
CREATE OR REPLACE VIEW v_distribusi_pelanggan_dept AS
SELECT d.nama_departemen, COUNT(pl.id_pelanggan) AS jumlah_mhs
FROM Departemen d
LEFT JOIN Pelanggan pl ON d.id_departemen = pl.id_departemen
GROUP BY d.id_departemen, d.nama_departemen;

-- Trigger: Validasi Jam Operasional Toko
CREATE OR REPLACE FUNCTION fn_tr_cek_jam_toko() RETURNS TRIGGER AS $$
DECLARE
    v_buka  TIME;
    v_tutup TIME;
    v_sekarang TIME := CURRENT_TIME;
BEGIN
    SELECT waktu_buka, waktu_tutup
    INTO v_buka, v_tutup
    FROM Toko
    WHERE id_toko = NEW.id_toko;

    IF v_sekarang < v_buka OR v_sekarang > v_tutup THEN
        RAISE EXCEPTION 'Toko sudah tutup atau belum buka';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tr_cek_jam_toko
BEFORE INSERT ON Pesanan
FOR EACH ROW EXECUTE FUNCTION fn_tr_cek_jam_toko();

-- Trigger: Cegah Hapus Departemen Jika Ada Mahasiswa
CREATE OR REPLACE FUNCTION fn_tr_cegah_hapus_dept() RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM Pelanggan WHERE id_departemen = OLD.id_departemen) THEN
        RAISE EXCEPTION 'Tidak bisa menghapus departemen yang masih memiliki anggota';
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tr_cegah_hapus_dept
BEFORE DELETE ON Departemen
FOR EACH ROW EXECUTE FUNCTION fn_tr_cegah_hapus_dept();

-- Function: Ambil Nama Kantin dari Toko
CREATE OR REPLACE FUNCTION fn_get_nama_kantin(p_id_toko INT) RETURNS VARCHAR AS $$
DECLARE
    v_nama VARCHAR;
BEGIN
    SELECT k.nama_kantin INTO v_nama
    FROM Kantin k
    JOIN Toko t ON k.id_kantin = t.id_kantin
    WHERE t.id_toko = p_id_toko;
    RETURN v_nama;
END;
$$ LANGUAGE plpgsql;

-- Procedure: Hapus Pesanan Lama (Cleanup)
CREATE OR REPLACE PROCEDURE sp_hapus_pesanan_lama() AS $$
BEGIN
    DELETE FROM Pesanan WHERE waktu_pesan < CURRENT_DATE - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql;