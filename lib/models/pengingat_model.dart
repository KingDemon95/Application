import 'package:cloud_firestore/cloud_firestore.dart';

class PengingatModel {
  final String id;
  final String obatId;
  final String namaObat;
  final String penyakitId;
  final String dosisAturanPakai;
  final int frekuensiPerHari;
  final int intervalJam;
  final String jamPertama;
  final List<String> jadwalLengkap;
  final bool isAktif;
  final DateTime? createdAt;
  final DateTime? terakhirDiminum; // timestamp terakhir klik "sudah minum"
  final int hariPenggunaan; // sudah berapa hari

  PengingatModel({
    required this.id,
    required this.obatId,
    required this.namaObat,
    required this.penyakitId,
    required this.dosisAturanPakai,
    required this.frekuensiPerHari,
    required this.intervalJam,
    required this.jamPertama,
    required this.jadwalLengkap,
    required this.isAktif,
    this.createdAt,
    this.terakhirDiminum,
    this.hariPenggunaan = 0,
  });

  factory PengingatModel.fromMap(String id, Map<String, dynamic> map) {
    return PengingatModel(
      id: id,
      obatId: map['obatId'] ?? '',
      namaObat: map['namaObat'] ?? '',
      penyakitId: map['penyakitId'] ?? '',
      dosisAturanPakai: map['dosisAturanPakai'] ?? '-',
      frekuensiPerHari: (map['frekuensiPerHari'] ?? 1) as int,
      intervalJam: (map['intervalJam'] ?? 24) as int,
      jamPertama: map['jamPertama'] ?? '08:00',
      jadwalLengkap: List<String>.from(map['jadwalLengkap'] ?? []),
      isAktif: map['isAktif'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      terakhirDiminum: (map['terakhirDiminum'] as Timestamp?)?.toDate(),
      hariPenggunaan: (map['hariPenggunaan'] ?? 0) as int,
    );
  }

  // Hitung hari penggunaan dari tanggal createdAt
  int get hariPenggunaanDihitung {
    if (createdAt == null) return hariPenggunaan;
    final diff = DateTime.now().difference(createdAt!).inDays;
    return diff + 1; // hari pertama = hari ke-1
  }

  // Cek apakah sudah 3 hari atau lebih
  bool get sudah3Hari => hariPenggunaanDihitung >= 3;

  // Jadwal berikutnya setelah jam sekarang
  String? get jadwalBerikutnya {
    final now = DateTime.now();
    final nowMenit = now.hour * 60 + now.minute;

    for (final j in jadwalLengkap) {
      final parts = j.split(':');
      if (parts.length != 2) continue;
      final jam = int.tryParse(parts[0]) ?? 0;
      final menit = int.tryParse(parts[1]) ?? 0;
      final jadwalMenit = jam * 60 + menit;
      if (jadwalMenit > nowMenit) return j;
    }
    // Semua jadwal hari ini sudah lewat → jadwal pertama besok
    return jadwalLengkap.isNotEmpty ? jadwalLengkap.first : null;
  }

  // Cek apakah jadwal ini adalah "saat ini" (dalam range ±30 menit)
  bool isJadwalSaatIni(String jadwal) {
    final now = DateTime.now();
    final parts = jadwal.split(':');
    if (parts.length != 2) return false;
    final jam = int.tryParse(parts[0]) ?? 0;
    final menit = int.tryParse(parts[1]) ?? 0;
    final jadwalDt = DateTime(now.year, now.month, now.day, jam, menit);
    return now.difference(jadwalDt).abs().inMinutes <= 30;
  }
}