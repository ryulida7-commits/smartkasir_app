// Mengimpor pustaka deteksi platform Flutter (untuk memeriksa peramban web kIsWeb)[cite: 6]
import 'package:flutter/foundation.dart';
// Mengimpor pustaka inti SQLite untuk Flutter[cite: 6]
import 'package:sqflite/sqflite.dart';
// Mengimpor pustaka penggabungan path direktori berkas lokal[cite: 6]
import 'package:path/path.dart';
// Mengimpor implementasi SQLite FFI khusus peramban Web Google Chrome[cite: 6]
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
// Mengimpor model data produk[cite: 6]
import '../models/produk.dart';

// Kelas pengelola koneksi dan operasi basis data SQLite lokal SmartKasir[cite: 6]
class DatabaseHelper {
  // --- 1. PENERAPAN DESIGN PATTERN SINGLETON[cite: 6]
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // 2. GETTER DATABASE ASINKRON[cite: 6]
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('smartkasir.db');
    return _database!;
  }

  // --- 3. INISIALISASI BERKAS BASIS DATA (DUAL-PLATFORM CHROME & ANDROID)[cite: 6]
  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      return await openDatabase(
        filePath,
        version: 1,
        onCreate: _createDB,
      );
    }
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  // 4. DDL: PEMBUATAN STRUKTUR TABEL & SEEDING DATA AWAL[cite: 7]
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE produk (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kode_produk TEXT UNIQUE,
        nama_produk TEXT NOT NULL,
        kategori TEXT NOT NULL,
        harga_beli REAL NOT NULL,
        harga_jual REAL NOT NULL,
        stok INTEGER NOT NULL,
        gambar_path TEXT,
        diskon_persen INTEGER DEFAULT 0,
        created_at TEXT
      )
    ''');

    for (final produk in produkAwalSQLite) {
      await db.insert('produk', produk.toMap());
    }
  }

  // 5. DML CREATE: MENAMBAHKAN PRODUK BARU KE SQLITE[cite: 7]
  Future<int> insertProduk(Produk produk) async {
    final db = await instance.database;
    return await db.insert(
      'produk',
      produk.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 6. DML READ: MENGAMBIL SELURUH DAFTAR PRODUK (KATALOG UTAMA)[cite: 7]
  Future<List<Produk>> getAllProduk() async {
  final db = await instance.database;
  final result = await db.query('produk', orderBy: 'harga_jual ASC'); // Diubah dari id DESC
  return result.map((json) => Produk.fromMap(json)).toList();
}

  // 7. DML READ DENGAN FILTER KATEGORI: MENYARING PRODUK SESUAI CHIP[cite: 7, 8]
  Future<List<Produk>> getProdukByKategori(String kategori) async {
    final db = await instance.database;
    if (kategori == 'Semua') {
      return await getAllProduk();
    }
    final result = await db.query(
      'produk',
      where: 'kategori = ?',
      whereArgs: [kategori],
      orderBy: 'id DESC',
    );
    return result.map((json) => Produk.fromMap(json)).toList();
  }

  // 8. DML SEARCH: PENCARIAN PRODUK BERDASARKAN KATA KUNCI (SQL LIKE)[cite: 8]
  Future<List<Produk>> searchProduk(String keyword) async {
    final db = await instance.database;
    final result = await db.query(
      'produk',
      where: 'nama_produk LIKE ?',
      whereArgs: ['%$keyword%'],
      orderBy: 'id DESC',
    );
    return result.map((json) => Produk.fromMap(json)).toList();
  }

  // 9. DML UPDATE: MEMPERBARUI DATA PRODUK DI SQLITE[cite: 8, 9]
  Future<int> updateProduk(Produk produk) async {
    final db = await instance.database;
    return await db.update(
      'produk',
      produk.toMap(),
      where: 'id = ?',
      whereArgs: [produk.id],
    );
  }

  // 10. DML DELETE: MENGHAPUS PRODUK DARI SQLITE BERDASARKAN ID[cite: 9]
  Future<int> deleteProduk(int id) async {
    final db = await instance.database;
    return await db.delete(
      'produk',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}