-- Skema awal akuntansi: daftar akun dan jurnal beserta baris detailnya.

CREATE TABLE chart_of_accounts (
    account_id BIGINT GENERATED ALWAYS AS IDENTITY,
    account_code VARCHAR(20) NOT NULL,
    account_name VARCHAR(150) NOT NULL,
    normal_balance VARCHAR(6) NOT NULL,
    report_classification VARCHAR(20) NOT NULL,

    CONSTRAINT pk_chart_of_accounts
        PRIMARY KEY (account_id),
    CONSTRAINT uq_chart_of_accounts_account_code
        UNIQUE (account_code),
    CONSTRAINT ck_chart_of_accounts_normal_balance
        CHECK (normal_balance IN ('debit', 'credit')),
    CONSTRAINT ck_chart_of_accounts_report_classification
        CHECK (report_classification IN ('balance_sheet', 'income_statement'))
);

COMMENT ON TABLE chart_of_accounts IS
    'Daftar akun yang dapat digunakan pada baris jurnal.';
COMMENT ON CONSTRAINT pk_chart_of_accounts ON chart_of_accounts IS
    'Menjamin setiap akun memiliki identitas unik.';
COMMENT ON CONSTRAINT uq_chart_of_accounts_account_code ON chart_of_accounts IS
    'Menjamin setiap kode akun hanya digunakan oleh satu akun.';
COMMENT ON CONSTRAINT ck_chart_of_accounts_normal_balance ON chart_of_accounts IS
    'Saldo normal akun harus debit atau credit.';
COMMENT ON CONSTRAINT ck_chart_of_accounts_report_classification ON chart_of_accounts IS
    'Klasifikasi laporan harus balance_sheet atau income_statement.';

CREATE TABLE journal_headers (
    journal_id BIGINT GENERATED ALWAYS AS IDENTITY,
    journal_date DATE NOT NULL,
    reference_code VARCHAR(50) NOT NULL,
    description TEXT NOT NULL,
    posting_status VARCHAR(10) NOT NULL DEFAULT 'draft',

    CONSTRAINT pk_journal_headers
        PRIMARY KEY (journal_id),
    CONSTRAINT ck_journal_headers_posting_status
        CHECK (posting_status IN ('draft', 'posted'))
);

COMMENT ON TABLE journal_headers IS
    'Informasi utama setiap jurnal, termasuk tanggal, referensi, deskripsi, dan status posting.';
COMMENT ON CONSTRAINT pk_journal_headers ON journal_headers IS
    'Menjamin setiap jurnal memiliki identitas unik.';
COMMENT ON CONSTRAINT ck_journal_headers_posting_status ON journal_headers IS
    'Status posting jurnal hanya boleh draft atau posted.';

CREATE TABLE journal_lines (
    journal_id BIGINT NOT NULL,
    line_number INTEGER NOT NULL,
    account_id BIGINT NOT NULL,
    debit NUMERIC(18, 2) NOT NULL,
    credit NUMERIC(18, 2) NOT NULL,

    CONSTRAINT pk_journal_lines
        PRIMARY KEY (journal_id, line_number),
    CONSTRAINT fk_journal_lines_journal
        FOREIGN KEY (journal_id)
        REFERENCES journal_headers (journal_id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_journal_lines_account
        FOREIGN KEY (account_id)
        REFERENCES chart_of_accounts (account_id)
        ON DELETE RESTRICT,
    CONSTRAINT ck_journal_lines_line_number
        CHECK (line_number > 0),
    CONSTRAINT ck_journal_lines_debit_nonnegative
        CHECK (debit >= 0),
    CONSTRAINT ck_journal_lines_credit_nonnegative
        CHECK (credit >= 0),
    CONSTRAINT ck_journal_lines_debit_or_credit
        CHECK (debit > 0 OR credit > 0)
);

COMMENT ON TABLE journal_lines IS
    'Baris detail jurnal yang menghubungkan jurnal dengan akun dan nilai debit/kredit.';
COMMENT ON CONSTRAINT pk_journal_lines ON journal_lines IS
    'Mengidentifikasi satu baris secara unik berdasarkan jurnal dan nomor barisnya.';
COMMENT ON CONSTRAINT fk_journal_lines_journal ON journal_lines IS
    'Setiap baris harus merujuk ke jurnal yang ada; jurnal dengan baris tidak dapat dihapus.';
COMMENT ON CONSTRAINT fk_journal_lines_account ON journal_lines IS
    'Setiap baris harus merujuk ke akun yang ada; akun yang dipakai jurnal tidak dapat dihapus.';
COMMENT ON CONSTRAINT ck_journal_lines_line_number ON journal_lines IS
    'Nomor baris harus lebih besar dari nol.';
COMMENT ON CONSTRAINT ck_journal_lines_debit_nonnegative ON journal_lines IS
    'Nilai debit tidak boleh negatif.';
COMMENT ON CONSTRAINT ck_journal_lines_credit_nonnegative ON journal_lines IS
    'Nilai kredit tidak boleh negatif.';
COMMENT ON CONSTRAINT ck_journal_lines_debit_or_credit ON journal_lines IS
    'Setidaknya salah satu nilai debit atau kredit harus lebih besar dari nol.';
