import 'package:cloud_firestore/cloud_firestore.dart';

/// Status jadwal minum obat.
/// - akanDatang   : belum waktunya.
/// - saatIni      : sudah waktunya, belum diminum, belum lewat batas toleransi.
/// - sudahDiminum : sudah tercatat "Sudah Minum" untuk jadwal ini.
/// - terlewat     : sudah lewat batas toleransi dan belum diminum.
enum JadwalStatus { akanDatang, saatIni, sudahDiminum, terlewat }

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
  final List<String> logMinum; // riwayat semua waktu klik "sudah minum" (ISO8601)

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
    this.logMinum = const [],
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
      logMinum: List<String>.from(map['logMinum'] ?? []),
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

  // ─── Jadwal berikutnya (versi baru, day-aware) ────────────────────────────
  // Sebelumnya method ini cuma bandingin "jam:menit" tanpa mikirin tanggal,
  // jadi kalau jam pertama dosis yang lain udah lewat tengah malam, hasilnya
  // bisa salah pilih. Sekarang tiap jam dihitung "kejadian berikutnya yang
  // valid" (bisa hari ini atau besok), baru dibandingin mana yang paling
  // dekat ke sekarang.
  String? get jadwalBerikutnya {
    if (jadwalLengkap.isEmpty) return null;

    if (createdAt == null) {
      // Fallback lama untuk data lama yang belum punya createdAt.
      final now = DateTime.now();
      final nowMenit = now.hour * 60 + now.minute;
      for (final j in jadwalLengkap) {
        final parts = j.split(':');
        if (parts.length != 2) continue;
        final jam = int.tryParse(parts[0]) ?? 0;
        final menit = int.tryParse(parts[1]) ?? 0;
        if (jam * 60 + menit > nowMenit) return j;
      }
      return jadwalLengkap.first;
    }

    final now = DateTime.now();
    String? jamTerdekat;
    DateTime? waktuTerdekat;

    for (final jam in jadwalLengkap) {
      final occ = _nextOccurrenceFrom(jam, now);
      if (occ == null) continue;
      if (waktuTerdekat == null || occ.isBefore(waktuTerdekat)) {
        waktuTerdekat = occ;
        jamTerdekat = jam;
      }
    }

    return jamTerdekat ?? jadwalLengkap.first;
  }

  // Cek apakah jadwal ini adalah "saat ini" (dalam range ±30 menit).
  // Dipertahankan untuk kompatibilitas kalau dipakai di tempat lain,
  // tapi UI jadwal sekarang pakai statusJadwal() di bawah.
  bool isJadwalSaatIni(String jadwal) {
    final now = DateTime.now();
    final parts = jadwal.split(':');
    if (parts.length != 2) return false;
    final jam = int.tryParse(parts[0]) ?? 0;
    final menit = int.tryParse(parts[1]) ?? 0;
    final jadwalDt = DateTime(now.year, now.month, now.day, jam, menit);
    return now.difference(jadwalDt).abs().inMinutes <= 30;
  }

  /// Menentukan status satu baris jadwal secara otomatis.
  ///
  /// [toleransiSaatIniMenit] = berapa menit setelah jam jadwal, status masih
  /// dianggap "Saat ini" sebelum otomatis berubah jadi "Terlewat".
  JadwalStatus statusJadwal(String jam, {int toleransiSaatIniMenit = 30}) {
    final jadwalDt = _relevantOccurrence(jam) ?? _jadwalKeDateTime(jam);
    if (jadwalDt == null) return JadwalStatus.akanDatang;

    // 1) Sudah pernah diklik "Sudah Minum" untuk jadwal ini?
    if (_sudahDiminumUntuk(jadwalDt)) {
      return JadwalStatus.sudahDiminum;
    }

    // 2) Belum diminum -> tentukan posisi waktu sekarang relatif ke jadwal.
    final selisihMenit = DateTime.now().difference(jadwalDt).inMinutes;

    if (selisihMenit < 0) {
      return JadwalStatus.akanDatang;
    } else if (selisihMenit <= toleransiSaatIniMenit) {
      return JadwalStatus.saatIni;
    } else {
      return JadwalStatus.terlewat;
    }
  }

  // ─── Helper baru: hitung tanggal-jam asli tiap dosis (day-aware) ─────────

  // Kejadian PERTAMA KALI jam ini beneran terjadwal, dihitung dari createdAt.
  // Logikanya sama persis kayak _nextInstanceOfTime() di NotificationService:
  // kalau jam itu (di tanggal createdAt) udah lewat dibanding createdAt,
  // berarti kejadian pertamanya itu besok, bukan hari itu juga.
  DateTime? _firstOccurrenceOf(String jam) {
    if (createdAt == null) return null;
    final parts = jam.split(':');
    if (parts.length != 2) return null;
    final jamInt = int.tryParse(parts[0]) ?? 0;
    final menitInt = int.tryParse(parts[1]) ?? 0;

    var t = DateTime(
        createdAt!.year, createdAt!.month, createdAt!.day, jamInt, menitInt);
    if (t.isBefore(createdAt!)) {
      t = t.add(const Duration(days: 1));
    }
    return t;
  }

  // Kejadian jam ini yang PALING RELEVAN buat status sekarang:
  // - Kalau kejadian pertamanya aja belum pernah lewat (masih di masa depan),
  //   ya itu yang dipakai (jadi otomatis "akan datang", bukan "terlewat").
  // - Kalau udah pernah lewat minimal sekali, cari kejadian di siklus
  //   24-jam-an terakhir yang paling dekat/pas dengan sekarang.
  DateTime? _relevantOccurrence(String jam) {
    final first = _firstOccurrenceOf(jam);
    if (first == null) return null;

    final now = DateTime.now();
    if (first.isAfter(now)) return first;

    const cycle = Duration(hours: 24);
    final diff = now.difference(first);
    final cyclesPassed = diff.inHours ~/ 24;
    return first.add(cycle * cyclesPassed);
  }

  // Kejadian jam ini berikutnya yang >= [reference]. Dipakai buat
  // jadwalBerikutnya supaya bisa milih yang paling dekat, gak asal ambil
  // urutan pertama di list yang > jam sekarang.
  DateTime? _nextOccurrenceFrom(String jam, DateTime reference) {
    final first = _firstOccurrenceOf(jam);
    if (first == null) return null;
    if (!first.isBefore(reference)) return first;

    const cycle = Duration(hours: 24);
    final diff = reference.difference(first);
    final cyclesPassed = diff.inHours ~/ 24;
    var occ = first.add(cycle * cyclesPassed);
    while (occ.isBefore(reference)) {
      occ = occ.add(cycle);
    }
    return occ;
  }

  // Fallback lama (dipakai kalau createdAt null / data lama).
  DateTime? _jadwalKeDateTime(String jam) {
    final parts = jam.split(':');
    if (parts.length != 2) return null;
    final now = DateTime.now();
    final jamInt = int.tryParse(parts[0]) ?? 0;
    final menitInt = int.tryParse(parts[1]) ?? 0;
    return DateTime(now.year, now.month, now.day, jamInt, menitInt);
  }

  // Cari apakah ada log "sudah minum" yang cocok untuk jadwal ini.
  // Satu log dianggap "milik" jadwal ini kalau jaraknya (dalam menit) tidak
  // lebih dari setengah interval dosis. Misal interval 8 jam -> toleransi
  // 4 jam ke kanan/kiri, supaya tiap log cuma "nempel" ke jadwal terdekatnya.
  bool _sudahDiminumUntuk(DateTime jadwalDt) {
    final batasMenit = (intervalJam * 60) / 2;

    for (final iso in logMinum) {
      final logDt = DateTime.tryParse(iso);
      if (logDt == null) continue;

      // Hanya bandingkan log di tanggal yang sama dengan jadwal yang dicek.
      final sameDay = logDt.year == jadwalDt.year &&
          logDt.month == jadwalDt.month &&
          logDt.day == jadwalDt.day;
      if (!sameDay) continue;

      final selisih = logDt.difference(jadwalDt).inMinutes.abs();
      if (selisih <= batasMenit) return true;
    }
    return false;
  }
}