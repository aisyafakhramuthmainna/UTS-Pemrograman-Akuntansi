import React, { useMemo, useState } from "react";

const sampleAccounts = [
  { code: "1010", name: "Kas" },
  { code: "1020", name: "Bank" },
  { code: "1100", name: "Piutang Usaha" },
  { code: "1200", name: "Perlengkapan" },
  { code: "1500", name: "Peralatan" },
  { code: "2010", name: "Utang Usaha" },
  { code: "3010", name: "Modal Pemilik" },
  { code: "5010", name: "Beban Gaji" },
  { code: "5020", name: "Beban Sewa" },
  { code: "5030", name: "Beban Listrik dan Air" },
];

const createLine = () => ({
  id: globalThis.crypto?.randomUUID?.() ?? `${Date.now()}-${Math.random()}`,
  accountCode: "",
  debit: "",
  credit: "",
});

const today = new Date();
const localToday = [
  today.getFullYear(),
  String(today.getMonth() + 1).padStart(2, "0"),
  String(today.getDate()).padStart(2, "0"),
].join("-");

function toCents(value) {
  if (value === "" || value == null) return 0;
  const amount = Number(value);
  return Number.isFinite(amount) && amount >= 0
    ? Math.round((amount + Number.EPSILON) * 100)
    : 0;
}

function formatRupiah(cents) {
  return new Intl.NumberFormat("id-ID", {
    style: "currency",
    currency: "IDR",
    maximumFractionDigits: 2,
  }).format(cents / 100);
}

function App() {
  const currentYear = new Date().getFullYear();
  const [date, setDate] = useState(localToday);
  const [reference, setReference] = useState("");
  const [description, setDescription] = useState("");
  const [lines, setLines] = useState([createLine(), createLine()]);
  const [notice, setNotice] = useState("");

  const totals = useMemo(
    () =>
      lines.reduce(
        (sum, line) => ({
          debit: sum.debit + toCents(line.debit),
          credit: sum.credit + toCents(line.credit),
        }),
        { debit: 0, credit: 0 },
      ),
    [lines],
  );

  const validLines = lines.filter((line) => {
    const debit = toCents(line.debit);
    const credit = toCents(line.credit);
    const hasOneAmount = (debit > 0 && credit === 0) || (credit > 0 && debit === 0);
    return Boolean(line.accountCode) && hasOneAmount;
  });

  const isBalanced = totals.debit === totals.credit;
  const isReady =
    totals.debit > 0 &&
    isBalanced &&
    validLines.length > 0 &&
    validLines.length === lines.length &&
    Boolean(date && reference.trim() && description.trim());

  function updateLine(id, field, value) {
    setNotice("");
    setLines((current) =>
      current.map((line) => (line.id === id ? { ...line, [field]: value } : line)),
    );
  }

  function addLine() {
    setNotice("");
    setLines((current) => [...current, createLine()]);
  }

  function removeLine(id) {
    setNotice("");
    setLines((current) => current.filter((line) => line.id !== id));
  }

  function handleSubmit(event) {
    event.preventDefault();
    if (!isReady) return;

    setNotice(
      "Voucher valid dan seimbang. Belum disimpan: koneksi backend belum tersedia.",
    );
  }

  function handleCancel() {
    setDate(localToday);
    setReference("");
    setDescription("");
    setLines([createLine(), createLine()]);
    setNotice("");
  }

  const difference = totals.debit - totals.credit;

  return (
    <main className="app-shell">
      <aside className="sidebar" aria-label="Navigasi utama">
        <a className="brand" href="#main-content" aria-label="BukuRapi, ke konten utama">
          <span className="brand-mark" aria-hidden="true">b.</span>
          <span>Buku<span className="brand-light">Rapi</span></span>
        </a>
        <div className="workspace-label">WORKSPACE</div>
        <nav>
          <a className="nav-item" href="#dashboard">
            <span aria-hidden="true">▦</span> Ringkasan
          </a>
          <a className="nav-item" href="#jurnal">
            <span aria-hidden="true">▤</span> Jurnal Umum
          </a>
          <a className="nav-item nav-item-active" href="#main-content" aria-current="page">
            <span aria-hidden="true">＋</span> Entri Transaksi
          </a>
          <a className="nav-item" href="#akun">
            <span aria-hidden="true">☷</span> Daftar Akun
          </a>
        </nav>
        <div className="sidebar-bottom">
          <span className="avatar">AK</span>
          <span className="user-details">
            <strong>Admin Keuangan</strong>
            <small>Perusahaan Contoh</small>
          </span>
          <span className="more-icon" aria-hidden="true">···</span>
        </div>
      </aside>

      <section className="main-panel" id="main-content">
        <header className="topbar">
          <div className="breadcrumbs">
            <span>Transaksi</span><span className="crumb-divider">/</span>
            <strong>Kas Keluar</strong>
          </div>
          <div className="topbar-actions">
            <span className="period-pill"><span className="period-dot" /> Periode aktif: {currentYear}</span>
            <button className="icon-button" type="button" aria-label="Notifikasi">
              ♧<span className="notification-dot" />
            </button>
            <span className="topbar-avatar">AK</span>
          </div>
        </header>

        <div className="page-content">
          <div className="page-heading">
            <div>
              <div className="eyebrow"><span className="eyebrow-line" /> FORMULIR TRANSAKSI</div>
              <h1>Voucher Kas Keluar</h1>
              <p>Catat pembayaran dan pengeluaran bisnis Anda dengan rapi.</p>
            </div>
            <div className="draft-badge"><span /> Draf baru</div>
          </div>

          <form onSubmit={handleSubmit}>
            <section className="form-card transaction-card" aria-labelledby="transaction-details-title">
              <div className="card-heading">
                <span className="section-icon" aria-hidden="true">▤</span>
                <div>
                  <h2 id="transaction-details-title">Informasi Transaksi</h2>
                  <p>Lengkapi detail dasar transaksi kas keluar.</p>
                </div>
              </div>

              <div className="metadata-grid">
                <label className="field">
                  <span>Tanggal Transaksi <span className="required">*</span></span>
                  <span className="input-wrap">
                    <input
                      type="date"
                      value={date}
                      onChange={(event) => setDate(event.target.value)}
                      required
                    />
                  </span>
                </label>
                <label className="field">
                  <span>Nomor Referensi <span className="required">*</span></span>
                  <span className="input-wrap reference-wrap">
                    <span className="input-prefix">KK</span>
                    <input
                      type="text"
                      value={reference}
                      onChange={(event) => setReference(event.target.value)}
                      placeholder="Contoh: 2025-001"
                      maxLength={50}
                      required
                    />
                  </span>
                </label>
                <label className="field description-field">
                  <span>Deskripsi <span className="required">*</span></span>
                  <span className="input-wrap">
                    <input
                      type="text"
                      value={description}
                      onChange={(event) => setDescription(event.target.value)}
                      placeholder="Contoh: Pembayaran biaya operasional bulan Januari"
                      maxLength={500}
                      required
                    />
                  </span>
                </label>
              </div>
            </section>

            <section className="form-card journal-card" aria-labelledby="journal-lines-title">
              <div className="journal-heading">
                <div className="card-heading">
                  <span className="section-icon section-icon-blue" aria-hidden="true">≡</span>
                  <div>
                    <h2 id="journal-lines-title">Rincian Jurnal</h2>
                    <p>Pilih akun dan isi nilai debit atau kredit untuk setiap baris.</p>
                  </div>
                </div>
                <button className="button button-outline add-button" type="button" onClick={addLine}>
                  <span aria-hidden="true">＋</span> Tambah Baris
                </button>
              </div>

              <div className="table-scroll">
                <table className="journal-table">
                  <thead>
                    <tr>
                      <th className="number-column">NO.</th>
                      <th className="account-column">AKUN</th>
                      <th className="amount-column">DEBIT (IDR)</th>
                      <th className="amount-column">KREDIT (IDR)</th>
                      <th className="action-column"><span className="sr-only">Aksi</span></th>
                    </tr>
                  </thead>
                  <tbody>
                    {lines.map((line, index) => (
                      <tr key={line.id}>
                        <td className="line-number">{String(index + 1).padStart(2, "0")}</td>
                        <td>
                          <label className="sr-only" htmlFor={`account-${line.id}`}>Pilih akun baris {index + 1}</label>
                          <select
                            id={`account-${line.id}`}
                            value={line.accountCode}
                            onChange={(event) => updateLine(line.id, "accountCode", event.target.value)}
                          >
                            <option value="">Pilih akun...</option>
                            {sampleAccounts.map((account) => (
                              <option key={account.code} value={account.code}>
                                {account.code} — {account.name}
                              </option>
                            ))}
                          </select>
                        </td>
                        <td>
                          <label className="sr-only" htmlFor={`debit-${line.id}`}>Debit baris {index + 1} dalam rupiah</label>
                          <span className="amount-input">
                            <span>Rp</span>
                            <input
                              id={`debit-${line.id}`}
                              type="number"
                              min="0"
                              step="0.01"
                              inputMode="decimal"
                              placeholder="0"
                              value={line.debit}
                              onChange={(event) => updateLine(line.id, "debit", event.target.value)}
                            />
                          </span>
                        </td>
                        <td>
                          <label className="sr-only" htmlFor={`credit-${line.id}`}>Kredit baris {index + 1} dalam rupiah</label>
                          <span className="amount-input">
                            <span>Rp</span>
                            <input
                              id={`credit-${line.id}`}
                              type="number"
                              min="0"
                              step="0.01"
                              inputMode="decimal"
                              placeholder="0"
                              value={line.credit}
                              onChange={(event) => updateLine(line.id, "credit", event.target.value)}
                            />
                          </span>
                        </td>
                        <td>
                          <button
                            className="remove-button"
                            type="button"
                            onClick={() => removeLine(line.id)}
                            disabled={lines.length === 1}
                            aria-label={`Hapus baris jurnal ${index + 1}`}
                            title={lines.length === 1 ? "Minimal satu baris jurnal" : "Hapus baris"}
                          >
                            ×
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                  <tfoot>
                    <tr>
                      <td colSpan="2" className="total-label">TOTAL JURNAL</td>
                      <td className="total-value">{formatRupiah(totals.debit)}</td>
                      <td className="total-value">{formatRupiah(totals.credit)}</td>
                      <td />
                    </tr>
                  </tfoot>
                </table>
              </div>

              <div className={`balance-panel ${isBalanced && totals.debit > 0 ? "balance-panel-ok" : ""}`}>
                <div className="balance-message">
                  <span className="balance-icon" aria-hidden="true">
                    {isBalanced && totals.debit > 0 ? "✓" : "!"}
                  </span>
                  <div>
                    <strong>
                      {isBalanced && totals.debit > 0 ? "Jurnal seimbang" : "Jurnal belum seimbang"}
                    </strong>
                    <span>
                      {isBalanced && totals.debit > 0
                        ? "Total debit dan kredit sudah sama."
                        : totals.debit === 0 && totals.credit === 0
                          ? "Isi baris jurnal agar total debit dan kredit seimbang."
                          : "Sesuaikan nilai debit dan kredit sebelum melanjutkan."}
                    </span>
                  </div>
                </div>
                <div className="difference">
                  <span>SELISIH</span>
                  <strong className={difference === 0 ? "difference-zero" : ""}>
                    {formatRupiah(Math.abs(difference))}
                    {difference !== 0 && (
                      <small>{difference > 0 ? " debit lebih besar" : " kredit lebih besar"}</small>
                    )}
                  </strong>
                </div>
              </div>
            </section>

            <div className="form-footer">
              <p><span className="required">*</span> Wajib diisi</p>
              <div className="footer-actions">
                <button className="button button-ghost" type="button" onClick={handleCancel}>
                  Batal
                </button>
                <button className="button button-submit" type="submit" disabled={!isReady}>
                  Submit Voucher <span aria-hidden="true">→</span>
                </button>
              </div>
            </div>
            {notice && <div className="notice" role="status">{notice}</div>}
            {!isReady && (
              <p className="submit-hint">
                Lengkapi informasi, isi semua baris jurnal dengan akun dan nominal yang valid, lalu seimbangkan totalnya.
              </p>
            )}
          </form>

          <footer className="page-footer">
            <span>© {currentYear} BukuRapi Accounting</span>
            <span className="footer-help">Butuh bantuan? <a href="mailto:bantuan@example.com">Hubungi tim kami</a></span>
          </footer>
        </div>
      </section>
    </main>
  );
}

export default App;
