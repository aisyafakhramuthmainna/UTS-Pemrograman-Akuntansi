-- Tabel persediaan dan transaksi beserta trigger pembaruan stok.
-- ADJUSTMENT menggunakan qty positif untuk menambah stok dan negatif untuk mengurangi.

CREATE TABLE inventory_items (
    item_id VARCHAR(10) PRIMARY KEY,
    item_name VARCHAR(100),
    stock_qty INT NOT NULL DEFAULT 0,
    unit_cost NUMERIC(15, 2) NOT NULL
);

COMMENT ON TABLE inventory_items IS
    'Master barang persediaan beserta jumlah stok dan biaya per unit.';

CREATE TABLE inventory_transactions (
    trx_id SERIAL PRIMARY KEY,
    item_id VARCHAR(10) NOT NULL,
    trx_type VARCHAR(10) NOT NULL,
    qty INT NOT NULL,
    trx_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_inventory_transactions_item
        FOREIGN KEY (item_id)
        REFERENCES inventory_items (item_id)
        ON DELETE RESTRICT,
    CONSTRAINT ck_inventory_transactions_trx_type
        CHECK (trx_type IN ('PURCHASE', 'SALE', 'ADJUSTMENT'))
);

COMMENT ON TABLE inventory_transactions IS
    'Catatan pembelian, penjualan, dan penyesuaian stok persediaan.';
COMMENT ON CONSTRAINT fk_inventory_transactions_item ON inventory_transactions IS
    'Barang yang sudah memiliki transaksi tidak dapat dihapus.';
COMMENT ON CONSTRAINT ck_inventory_transactions_trx_type ON inventory_transactions IS
    'Jenis transaksi hanya PURCHASE, SALE, atau ADJUSTMENT.';

CREATE OR REPLACE FUNCTION trg_update_stock_and_journal()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    current_stock INT;
    updated_stock INT;
BEGIN
    -- Kunci baris barang agar transaksi bersamaan untuk barang yang sama
    -- membaca dan memperbarui stok secara berurutan.
    SELECT stock_qty
    INTO current_stock
    FROM inventory_items
    WHERE item_id = NEW.item_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Barang dengan item_id % tidak ditemukan', NEW.item_id;
    END IF;

    IF NEW.trx_type = 'PURCHASE' THEN
        IF NEW.qty <= 0 THEN
            RAISE EXCEPTION 'Qty PURCHASE harus lebih besar dari nol';
        END IF;
        updated_stock := current_stock + NEW.qty;
    ELSIF NEW.trx_type = 'SALE' THEN
        IF NEW.qty <= 0 THEN
            RAISE EXCEPTION 'Qty SALE harus lebih besar dari nol';
        END IF;
        IF current_stock < NEW.qty THEN
            RAISE EXCEPTION
                'Stok tidak mencukupi untuk SALE item_id %: stok %, diminta %',
                NEW.item_id, current_stock, NEW.qty;
        END IF;
        updated_stock := current_stock - NEW.qty;
    ELSIF NEW.trx_type = 'ADJUSTMENT' THEN
        IF NEW.qty = 0 THEN
            RAISE EXCEPTION 'Qty ADJUSTMENT tidak boleh nol';
        END IF;
        updated_stock := current_stock + NEW.qty;
        IF updated_stock < 0 THEN
            RAISE EXCEPTION
                'ADJUSTMENT menghasilkan stok negatif untuk item_id %: stok %, penyesuaian %',
                NEW.item_id, current_stock, NEW.qty;
        END IF;
    ELSE
        RAISE EXCEPTION 'Jenis transaksi tidak dikenal: %', NEW.trx_type;
    END IF;

    -- Jika terjadi exception, PostgreSQL membatalkan INSERT transaksi ini
    -- beserta perubahan stok dalam transaksi yang sama.
    UPDATE inventory_items
    SET stock_qty = updated_stock
    WHERE item_id = NEW.item_id;

    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION trg_update_stock_and_journal() IS
    'Memperbarui stok pada INSERT dengan penguncian baris untuk konkurensi; exception membatalkan INSERT dan perubahan stok. Pencatatan jurnal belum diimplementasikan karena metode penilaian dan pemetaan akun belum ditentukan.';

CREATE TRIGGER inventory_transactions_update_stock_after_insert
AFTER INSERT ON inventory_transactions
FOR EACH ROW
EXECUTE FUNCTION trg_update_stock_and_journal();
