-- ==========================================
-- ANGGOTA 4
-- ==========================================

-- Searching: Total belanja pelanggan X di semua toko
SELECT pl.nama, SUM(p.total_bayar) AS total_pengeluaran
FROM Pelanggan pl
JOIN Pesanan p ON pl.id_pelanggan = p.id_pelanggan
WHERE pl.id_pelanggan = 'CUST-001'
GROUP BY pl.nama;

-- Searching: Departemen yang pernah makan di Kantin Pusat
SELECT DISTINCT d.nama_departemen
FROM Departemen d
JOIN Pelanggan pl ON d.id_departemen = pl.id_departemen
JOIN Pesanan p ON pl.id_pelanggan = p.id_pelanggan
JOIN Toko t ON p.id_toko = t.id_toko
JOIN Kantin k ON t.id_kantin = k.id_kantin
WHERE k.nama_kantin = 'Kantin Pusat';

-- View: Toko Terpopuler
CREATE OR REPLACE VIEW v_toko_terpopuler AS
SELECT nama, jumlah_transaksi
FROM (
    SELECT t.nama, COUNT(p.id_pesanan) AS jumlah_transaksi
    FROM Toko t
    JOIN Pesanan p ON t.id_toko = p.id_toko
    GROUP BY t.id_toko, t.nama
    ORDER BY jumlah_transaksi DESC
) sub;

-- View: Rata-rata Belanja Pelanggan
CREATE OR REPLACE VIEW v_rata_rata_belanja AS
SELECT AVG(total_bayar) AS rata_rata_transaksi FROM Pesanan;

-- Trigger: Catatan Default
CREATE OR REPLACE FUNCTION fn_tr_catatan_default() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.catatan IS NULL OR NEW.catatan = '' THEN
        NEW.catatan := 'Tanpa alat makan';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tr_catatan_default
BEFORE INSERT ON Pesanan
FOR EACH ROW EXECUTE FUNCTION fn_tr_catatan_default();

-- Trigger: Cegah Update Stok Negatif
CREATE OR REPLACE FUNCTION fn_tr_cegah_stok_negatif() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.stok < 0 THEN
        RAISE EXCEPTION 'Stok tidak boleh kurang dari nol';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tr_cegah_stok_negatif
BEFORE UPDATE OF stok ON Menu
FOR EACH ROW EXECUTE FUNCTION fn_tr_cegah_stok_negatif();

-- Function: Total Omzet Hari Ini
CREATE OR REPLACE FUNCTION fn_total_omzet_hari_ini() RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT SUM(total_bayar) INTO v_total
    FROM Pesanan
    WHERE waktu_pesan::DATE = CURRENT_DATE;
    RETURN COALESCE(v_total, 0);
END;
$$ LANGUAGE plpgsql;

-- Procedure: Tutup Semua Toko di Kantin X
CREATE OR REPLACE PROCEDURE sp_tutup_kantin(p_id_kantin INT) AS $$
BEGIN
    UPDATE Toko SET is_open = FALSE WHERE id_kantin = p_id_kantin;
END;
$$ LANGUAGE plpgsql;

