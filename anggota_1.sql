-- ==========================================
-- ANGGOTA 1
-- ==========================================

-- Searching: Cari menu berdasarkan nama toko
SELECT m.nama_menu, m.harga, t.nama AS nama_toko
FROM Menu m
JOIN Toko t ON m.id_toko = t.id_toko
WHERE t.nama ILIKE '%Kantin Bu Nunun%';

-- Searching: Cari pesanan pelanggan berdasarkan departemen
SELECT p.id_pesanan, pl.nama, d.nama_departemen, p.total_bayar
FROM Pesanan p
JOIN Pelanggan pl ON p.id_pelanggan = pl.id_pelanggan
JOIN Departemen d ON pl.id_departemen = d.id_departemen
WHERE d.nama_departemen = 'Teknik Informatika';

-- View: Daftar Toko dan Lokasinya
CREATE OR REPLACE VIEW v_daftar_toko_kantin AS
SELECT t.id_toko, t.nama AS nama_toko, k.nama_kantin, k.lokasi
FROM Toko t
JOIN Kantin k ON t.id_kantin = k.id_kantin;

-- View: Menu Terlaris
CREATE OR REPLACE VIEW v_menu_terlaris AS
SELECT nama_menu, total_terjual
FROM (
    SELECT m.nama_menu, SUM(pm.quantity) AS total_terjual
    FROM Pesanan_Menu pm
    JOIN Menu m ON pm.id_menu = m.id_menu
    GROUP BY m.id_menu, m.nama_menu
    ORDER BY total_terjual DESC
    LIMIT 5
) sub;

-- Trigger: Kurangi Stok
CREATE OR REPLACE FUNCTION fn_tr_kurangi_stok() RETURNS TRIGGER AS $$
BEGIN
    UPDATE Menu SET stok = stok - NEW.quantity WHERE id_menu = NEW.id_menu;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tr_kurangi_stok
AFTER INSERT ON Pesanan_Menu
FOR EACH ROW EXECUTE FUNCTION fn_tr_kurangi_stok();

-- Trigger: Kembalikan Stok (Jika batal)
CREATE OR REPLACE FUNCTION fn_tr_kembalikan_stok() RETURNS TRIGGER AS $$
BEGIN
    UPDATE Menu SET stok = stok + OLD.quantity WHERE id_menu = OLD.id_menu;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tr_kembalikan_stok
AFTER DELETE ON Pesanan_Menu
FOR EACH ROW EXECUTE FUNCTION fn_tr_kembalikan_stok();

-- Function: Hitung Total Item dalam satu pesanan
CREATE OR REPLACE FUNCTION fn_hitung_total_item(p_id_pesanan INT) RETURNS INT AS $$
DECLARE
    v_total INT;
BEGIN
    SELECT SUM(quantity) INTO v_total FROM Pesanan_Menu WHERE id_pesanan = p_id_pesanan;
    RETURN COALESCE(v_total, 0);
END;
$$ LANGUAGE plpgsql;

-- Procedure: Update Status Pesanan
CREATE OR REPLACE PROCEDURE sp_update_status_pesanan(p_id_pesanan INT, p_status VARCHAR) AS $$
BEGIN
    UPDATE Pesanan SET status_pesanan = p_status WHERE id_pesanan = p_id_pesanan;
END;
$$ LANGUAGE plpgsql;
