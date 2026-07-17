import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/pengingat_model.dart';

class PengingatService {
  final _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference get _col =>
      _db.collection('users').doc(_uid).collection('pengingat');

  // ─── Ambil satu pengingat by ID ──────────────────────────────────────────
  Future<PengingatModel?> getPengingat(String pengingatId) async {
    final doc = await _col.doc(pengingatId).get();
    if (!doc.exists) return null;
    return PengingatModel.fromMap(
        doc.id, doc.data() as Map<String, dynamic>);
  }

  // ─── Stream semua pengingat aktif ────────────────────────────────────────
  Stream<List<PengingatModel>> streamPengingatAktif() {
    return _col
        .where('isAktif', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) =>
                PengingatModel.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList());
  }

  // ─── Catat sudah minum + hitung hari ke berapa ───────────────────────────
  Future<void> sudahMinum(String pengingatId) async {
    final now = DateTime.now();
    final doc = await _col.doc(pengingatId).get();
    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final hariKe = createdAt != null
        ? DateTime.now().difference(createdAt).inDays + 1
        : (data['hariPenggunaan'] ?? 0) as int;

    await _col.doc(pengingatId).update({
      'terakhirDiminum': FieldValue.serverTimestamp(),
      'hariPenggunaan': hariKe,
      'logMinum': FieldValue.arrayUnion([now.toIso8601String()]),
    });
  }

  // ─── Hentikan pengingat (non-aktifkan) ───────────────────────────────────
  Future<void> hentikanPengingat(String pengingatId) async {
    await _col.doc(pengingatId).update({
      'isAktif': false,
      'dihentikanPada': FieldValue.serverTimestamp(),
    });
  }

  // ─── Generate baseId dari pengingatId untuk notifikasi ───────────────────
  // Pakai djb2 hash manual (bukan String.hashCode bawaan Dart), karena
  // hashCode bawaan pakai random seed yang beda tiap sesi app —
  // jadi ID yang dihasilkan waktu jadwalkan notifikasi bisa gak sama lagi
  // waktu mau dibatalkan di sesi lain. djb2 di bawah ini deterministic:
  // input yang sama selalu menghasilkan angka yang sama, kapan pun dipanggil.
  static int generateBaseId(String pengingatId) {
    int hash = 5381;
    for (final c in pengingatId.codeUnits) {
      hash = ((hash << 5) + hash + c) & 0x7FFFFFFF; // & 0x7FFFFFFF jaga tetap positif & 31-bit
    }
    return hash % 100000;
  }
}