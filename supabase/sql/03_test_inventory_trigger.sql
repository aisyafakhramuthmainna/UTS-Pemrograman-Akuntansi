-- Pengujian manual untuk trg_update_stock_and_journal().
-- Jalankan setelah 02_inventory_trigger.sql berhasil diterapkan.
-- Seluruh data uji berada dalam transaksi yang diakhiri ROLLBACK.

BEGIN;

INSERT INTO inventory_items (item_id, item_name, stock_qty, unit_cost)
VALUES ('UTS-TST-01', 'Barang Uji Trigger', 0, 1000.00);

-- PURCHASE 10 unit harus menaikkan stok dari 0 menjadi 10.
INSERT INTO inventory_transactions (item_id, trx_type, qty)
VALUES ('UTS-TST-01', 'PURCHASE', 10);

DO $$
DECLARE
    actual_stock INT;
    transaction_count BIGINT;
BEGIN
    SELECT stock_qty
    INTO actual_stock
    FROM inventory_items
    WHERE item_id = 'UTS-TST-01';

    SELECT count(*)
    INTO transaction_count
    FROM inventory_transactions
    WHERE item_id = 'UTS-TST-01';

    IF actual_stock IS DISTINCT FROM 10
       OR transaction_count IS DISTINCT FROM 1 THEN
        RAISE EXCEPTION
            'GAGAL: PURCHASE 10 diharapkan menghasilkan stok 10 dan 1 transaksi; stok %, transaksi %',
            actual_stock, transaction_count;
    END IF;
END;
$$;

-- SALE 3 unit harus menurunkan stok dari 10 menjadi 7.
INSERT INTO inventory_transactions (item_id, trx_type, qty)
VALUES ('UTS-TST-01', 'SALE', 3);

DO $$
DECLARE
    actual_stock INT;
    transaction_count BIGINT;
BEGIN
    SELECT stock_qty
    INTO actual_stock
    FROM inventory_items
    WHERE item_id = 'UTS-TST-01';

    SELECT count(*)
    INTO transaction_count
    FROM inventory_transactions
    WHERE item_id = 'UTS-TST-01';

    IF actual_stock IS DISTINCT FROM 7
       OR transaction_count IS DISTINCT FROM 2 THEN
        RAISE EXCEPTION
            'GAGAL: SALE 3 diharapkan menghasilkan stok 7 dan 2 transaksi; stok %, transaksi %',
            actual_stock, transaction_count;
    END IF;
END;
$$;

-- SALE 8 unit harus ditolak; stok dan jumlah transaksi harus tetap.
DO $$
DECLARE
    stock_before INT;
    stock_after INT;
    transactions_before BIGINT;
    transactions_after BIGINT;
    expected_error TEXT;
    rejected BOOLEAN := FALSE;
BEGIN
    SELECT stock_qty
    INTO stock_before
    FROM inventory_items
    WHERE item_id = 'UTS-TST-01';

    SELECT count(*)
    INTO transactions_before
    FROM inventory_transactions
    WHERE item_id = 'UTS-TST-01';

    expected_error := format(
        'Stok tidak mencukupi untuk SALE item_id %s: stok %s, diminta 8',
        'UTS-TST-01', stock_before
    );

    BEGIN
        INSERT INTO inventory_transactions (item_id, trx_type, qty)
        VALUES ('UTS-TST-01', 'SALE', 8);
    EXCEPTION
        WHEN SQLSTATE 'P0001' THEN
            IF SQLERRM <> expected_error THEN
                RAISE EXCEPTION
                    'GAGAL: SALE ditolak dengan pesan yang tidak diharapkan: %',
                    SQLERRM;
            END IF;
            rejected := TRUE;
    END;

    IF NOT rejected THEN
        RAISE EXCEPTION 'GAGAL: SALE melebihi stok tidak ditolak';
    END IF;

    SELECT stock_qty
    INTO stock_after
    FROM inventory_items
    WHERE item_id = 'UTS-TST-01';

    SELECT count(*)
    INTO transactions_after
    FROM inventory_transactions
    WHERE item_id = 'UTS-TST-01';

    IF stock_after IS DISTINCT FROM stock_before
       OR transactions_after IS DISTINCT FROM transactions_before THEN
        RAISE EXCEPTION
            'GAGAL: SALE yang ditolak mengubah stok atau catatan transaksi; stok sebelum/sesudah %/%, transaksi sebelum/sesudah %/%',
            stock_before, stock_after, transactions_before, transactions_after;
    END IF;
END;
$$;

-- ADJUSTMENT -8 dari stok 7 harus ditolak; stok dan jumlah transaksi harus tetap.
DO $$
DECLARE
    stock_before INT;
    stock_after INT;
    transactions_before BIGINT;
    transactions_after BIGINT;
    expected_error TEXT;
    rejected BOOLEAN := FALSE;
BEGIN
    SELECT stock_qty
    INTO stock_before
    FROM inventory_items
    WHERE item_id = 'UTS-TST-01';

    SELECT count(*)
    INTO transactions_before
    FROM inventory_transactions
    WHERE item_id = 'UTS-TST-01';

    expected_error := format(
        'ADJUSTMENT menghasilkan stok negatif untuk item_id %s: stok %s, penyesuaian -8',
        'UTS-TST-01', stock_before
    );

    BEGIN
        INSERT INTO inventory_transactions (item_id, trx_type, qty)
        VALUES ('UTS-TST-01', 'ADJUSTMENT', -8);
    EXCEPTION
        WHEN SQLSTATE 'P0001' THEN
            IF SQLERRM <> expected_error THEN
                RAISE EXCEPTION
                    'GAGAL: ADJUSTMENT ditolak dengan pesan yang tidak diharapkan: %',
                    SQLERRM;
            END IF;
            rejected := TRUE;
    END;

    IF NOT rejected THEN
        RAISE EXCEPTION 'GAGAL: ADJUSTMENT yang menghasilkan stok negatif tidak ditolak';
    END IF;

    SELECT stock_qty
    INTO stock_after
    FROM inventory_items
    WHERE item_id = 'UTS-TST-01';

    SELECT count(*)
    INTO transactions_after
    FROM inventory_transactions
    WHERE item_id = 'UTS-TST-01';

    IF stock_after IS DISTINCT FROM stock_before
       OR transactions_after IS DISTINCT FROM transactions_before THEN
        RAISE EXCEPTION
            'GAGAL: ADJUSTMENT yang ditolak mengubah stok atau catatan transaksi; stok sebelum/sesudah %/%, transaksi sebelum/sesudah %/%',
            stock_before, stock_after, transactions_before, transactions_after;
    END IF;
END;
$$;

DO $$
BEGIN
    RAISE NOTICE 'LULUS: semua pengujian trigger persediaan berhasil.';
END;
$$;

ROLLBACK;
