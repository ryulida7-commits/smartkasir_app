// Mengimpor pustaka antarmuka Material Design utama Flutter[cite: 9]
import 'package:flutter/material.dart';
// Mengimpor pustaka pemformat angka dan mata uang[cite: 9]
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
// Mengimpor model data dan database helper[cite: 9]
import '../models/produk.dart';
import '../helpers/database_helper.dart';

// Halaman formulir kasir dwifungsi: Tambah Produk Baru ATAU Edit Produk[cite: 9]
class FormProdukPage extends StatefulWidget {
  // Deklarasi variabel produk opsional: Jika bernilai null = Tambah Baru, Jika terisi = Edit[cite: 9, 15]
  final Produk? produk;
  const FormProdukPage({super.key, this.produk});

  @override
  State<FormProdukPage> createState() => _FormProdukPageState();
}

class _FormProdukPageState extends State<FormProdukPage> {
  // --- KUNCI GLOBAL VALIDASI FORMULIR[cite: 10]
  final _formKey = GlobalKey<FormState>();

  // KONTROLER INPUT TEKS FORMULIR ---[cite: 10]
  final _kodeController = TextEditingController();
  final _namaController = TextEditingController();
  final _hargaBeliController = TextEditingController();
  final _hargaJualController = TextEditingController();
  final _stokController = TextEditingController();
  final _diskonController = TextEditingController(text: '0');

  // Variabel kategori terpilih[cite: 10]
  String _kategoriTerpilih = 'Makanan';
 final List<String> _kategoriList = ['Makanan', 'Minuman', 'Snack', 'Dessert'];

  // Status proses simpan[cite: 10]
  bool _sedangMenyimpan = false;

  // Format rupiah tampilan[cite: 10]
  final _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

  // KONTROL PERCABANGAN: Cek apakah halaman berada dalam Mode Edit[cite: 10, 15]
  bool get _isEditMode => widget.produk != null;

  @override
  void initState() {
    super.initState();
    // KONTROL PERCABANGAN INISIALISASI:[cite: 10]
    if (_isEditMode) {
      // Jika mode Edit, isi seluruh controller dengan data produk yang diedit[cite: 10]
      final p = widget.produk!;
      _kodeController.text = p.kodeProduk;
      _namaController.text = p.nama;
      _kategoriTerpilih = _kategoriList.contains(p.kategori) ? p.kategori : 'Makanan';
      _hargaBeliController.text = p.hargaBeli.toInt().toString();
      _hargaJualController.text = p.hargaJual.toInt().toString();
      _stokController.text = p.stok.toString();
      _diskonController.text = p.diskonPersen.toString();
    } else {
      // Jika mode Tambah Baru, hasilkan kode otomatis kasir[cite: 10]
      _kodeController.text = 'PRD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    }
  }

  @override
  void dispose() {
    // Membersihkan seluruh controller dari memori[cite: 10]
    _kodeController.dispose();
    _namaController.dispose();
    _hargaBeliController.dispose();
    _hargaJualController.dispose();
    _stokController.dispose();
    _diskonController.dispose();
    super.dispose();
  }

  // --- METODE SIMPAN / PERBARUI DATA KE SQLITE ---[cite: 10]
  void _simpanKeDatabase() async {
    // Validasi form: Periksa apakah seluruh input valid[cite: 10]
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sedangMenyimpan = true);

    try {
      final double beli = double.parse(_hargaBeliController.text.trim());
      final double jual = double.parse(_hargaJualController.text.trim());
      final int stok = int.parse(_stokController.text.trim());
      final int diskon = int.tryParse(_diskonController.text.trim()) ?? 0;

      // Konstruksi objek Produk[cite: 10]
      final produkData = Produk(
        id: _isEditMode ? widget.produk!.id : null, // Pertahankan ID asli jika edit[cite: 10]
        kodeProduk: _kodeController.text.trim(),
        nama: _namaController.text.trim(),
        kategori: _kategoriTerpilih,
        hargaBeli: beli,
        hargaJual: jual,
        stok: stok,
        gambarUrl: _isEditMode
            ? widget.produk!.gambarUrl
            : 'https://images.unsplash.com/photo-1541167760496-1628856ab772?w=500', //[cite: 10, 11]
        diskonPersen: diskon,
      );

      // KONTROL PERCABANGAN LOGIKA DML:[cite: 10, 11, 15]
      if (_isEditMode) {
        // Eksekusi UPDATE ke SQLite[cite: 10, 11, 15]
        await DatabaseHelper.instance.updateProduk(produkData);
      } else {
        // Eksekusi INSERT ke SQLite[cite: 11]
        await DatabaseHelper.instance.insertProduk(produkData);
      }

      if (!mounted) return;
      // Beri notifikasi sukses SnackBar kepada kasir[cite: 11]
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditMode
              ? 'Data produk "${produkData.nama}" berhasil diperbarui!'
              : 'Produk "${produkData.nama}" berhasil disimpan ke SQLite!'),
          backgroundColor: const Color(0xFF1E3A8A),
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Kembali ke Dashboard dengan sinyal refresh true[cite: 11]
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _sedangMenyimpan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Data Produk' : 'Tambah Produk Baru'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // BANNER INFO IDENTITAS KASIR[cite: 11]
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isEditMode ? Icons.edit_note : Icons.playlist_add_check,
                      color: const Color(0xFF1E3A8A),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _isEditMode
                            ? 'Anda sedang mengedit produk: ${widget.produk!.nama}'
                            : 'Pastikan harga jual kasir lebih besar dari harga beli modal toko.',
                        style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1E3A8A),
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // 1. INPUT KODE PRODUK / SKU[cite: 12]
              TextFormField(
                controller: _kodeController,
                readOnly: _isEditMode, // Kode produk terkunci pada mode edit[cite: 12]
                decoration: InputDecoration(
                  labelText: 'Kode SKU Produk',
                  prefixIcon: const Icon(Icons.qr_code),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: _isEditMode ? Colors.grey.shade100 : Colors.white,
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Kode wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              // 2. INPUT NAMA BARANG[cite: 12]
              TextFormField(
                controller: _namaController,
                decoration: InputDecoration(
                  labelText: 'Nama Produk Barang',
                  prefixIcon: const Icon(Icons.shopping_bag_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Nama barang tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              // 3. DROPDOWN KATEGORI PRODUK[cite: 12, 13]
              DropdownButtonFormField<String>(
                value: _kategoriTerpilih,
                decoration: InputDecoration(
                  labelText: 'Kelompok Kategori',
                  prefixIcon: const Icon(Icons.category_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: _kategoriList.map((kat) {
                  return DropdownMenuItem(value: kat, child: Text(kat));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _kategoriTerpilih = val);
                },
              ),
              const SizedBox(height: 16),
              // 4. BARIS INPUT HARGA BELI & HARGA JUAL (2 KOLOM)[cite: 13]
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _hargaBeliController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Harga Modal (Rp)',
                        prefixIcon: const Icon(Icons.monetization_on_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Wajib diisi';
                        if (double.tryParse(val) == null || double.parse(val) <= 0) return 'Harus > 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _hargaJualController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Harga Jual (Rp)',
                        prefixIcon: const Icon(Icons.price_check),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Wajib diisi';
                        final jual = double.tryParse(val) ?? 0;
                        final beli = double.tryParse(_hargaBeliController.text) ?? 0;
                        if (jual <= 0) return 'Harus > 0';
                        if (jual <= beli) return 'Harus > Modal'; //[cite: 13, 15]
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 5. BARIS STOK FISIK & PROMO DISKON (2 KOLOM)[cite: 13, 14]
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stokController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Stok Fisik',
                        prefixIcon: const Icon(Icons.inventory_2_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Stok wajib diisi' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _diskonController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Diskon (%)',
                        prefixIcon: const Icon(Icons.discount_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                     validator: (val) {
                      final d = int.tryParse(val ?? '0') ?? 0;
                      if (d < 0 || d > 50) return 'Diskon maksimal 50%'; // Batasan baru
                      return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              // TOMBOL AKSI EKSEKUSI DATABASE[cite: 14]
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _sedangMenyimpan ? null : _simpanKeDatabase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _sedangMenyimpan
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Icon(_isEditMode ? Icons.check_circle_outline : Icons.save_outlined),
                  label: Text(
                    _isEditMode ? 'PERBARUI DATA PRODUK' : 'SIMPAN PRODUK KE DATABASE',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}