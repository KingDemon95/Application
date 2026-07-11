import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // ─── REGISTER ────────────────────────────────────────────────
  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      await cred.user!.updateDisplayName(fullName.trim());

      await _db.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'fullName': fullName.trim(),
        'email': email.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (e) {
      throw _mapError(e);
    }
  }

  // ─── LOGIN ───────────────────────────────────────────────────
  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } on FirebaseAuthException catch (e) {
      throw _mapError(e);
    }
  }

  // ─── LOGIN WITH GOOGLE ───────────────────────────────────────
  Future<UserCredential?> loginWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn(
        clientId: kIsWeb
            ? '962529220510-db5rpeo4k4oqpb2odj9pepgctq88oc8a.apps.googleusercontent.com'
            : null,
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null; // user cancel

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await _auth.signInWithCredential(credential);

      // Simpan ke Firestore kalau user baru
      final isNewUser = userCred.additionalUserInfo?.isNewUser ?? false;
      if (isNewUser) {
        await _db.collection('users').doc(userCred.user!.uid).set({
          'uid': userCred.user!.uid,
          'fullName': userCred.user!.displayName ?? '',
          'email': userCred.user!.email ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return userCred;
    } on FirebaseAuthException catch (e) {
      throw _mapError(e);
    }
  }

  // ─── LOGOUT ──────────────────────────────────────────────────
  Future<void> logout() async => await _auth.signOut();

  // ─── RESET PASSWORD ──────────────────────────────────────────
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _mapError(e);
    }
  }

  // ─── GET USER DATA FROM FIRESTORE ────────────────────────────
  Future<Map<String, dynamic>?> getUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _db.collection('users').doc(user.uid).get();
    return doc.data();
  }

  // ─── ERROR MAPPER ────────────────────────────────────────────
  String _mapError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Email sudah terdaftar';
      case 'invalid-email':
        return 'Format email tidak valid';
      case 'weak-password':
        return 'Password minimal 6 karakter';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email atau password salah';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan, coba lagi nanti';
      case 'network-request-failed':
        return 'Periksa koneksi internet kamu';
      default:
        return e.message ?? 'Terjadi kesalahan';
    }
  }
}

