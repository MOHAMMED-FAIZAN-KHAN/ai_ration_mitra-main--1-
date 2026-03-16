import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user.dart';

class AuthService {
  AuthService({
    fb.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? fb.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final fb.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  Stream<fb.User?> authStateChanges() => _firebaseAuth.authStateChanges();

  fb.User? get currentFirebaseUser => _firebaseAuth.currentUser;

  Future<fb.UserCredential> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign-in was cancelled.');
      }

    final googleAuth = await googleUser.authentication;
    final credential = fb.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return _firebaseAuth.signInWithCredential(credential);
  }

  Future<fb.UserCredential> signInAnonymously() {
    return _firebaseAuth.signInAnonymously();
  }

  Future<fb.UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<fb.UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  Future<User?> getUserProfileByUid(String uid) async {
    final snapshot = await _firestore.collection('users').doc(uid).get();
    if (!snapshot.exists) {
      return null;
    }

    final data = snapshot.data();
    if (data == null) {
      return null;
    }

    return User.fromJson({
      ...data,
      'id': uid,
    });
  }

  Future<User?> findUserByIdentifier({
    required String identifier,
    required UserType userType,
  }) async {
    final normalized = identifier.trim();
    if (normalized.isEmpty) {
      return null;
    }

    QuerySnapshot<Map<String, dynamic>> snapshot;
    switch (userType) {
      case UserType.citizen:
        final isAadhaar = RegExp(r'^\d{12}$').hasMatch(normalized);
        snapshot = await _firestore
            .collection('users')
            .where('type', isEqualTo: 'citizen')
            .where(
              isAadhaar ? 'aadhaarNumber' : 'mobileNumber',
              isEqualTo: normalized,
            )
            .limit(1)
            .get();
        break;
      case UserType.fpsDealer:
        snapshot = await _firestore
            .collection('users')
            .where('type', isEqualTo: 'fpsDealer')
            .where('fpsId', isEqualTo: normalized)
            .limit(1)
            .get();
        break;
      case UserType.admin:
        snapshot = await _firestore
            .collection('users')
            .where('type', isEqualTo: 'admin')
            .where('uid', isEqualTo: normalized)
            .limit(1)
            .get();
        break;
    }

    if (snapshot.docs.isEmpty) {
      return null;
    }

    final doc = snapshot.docs.first;
    return User.fromJson({
      ...doc.data(),
      'id': doc.id,
    });
  }

  Future<User?> getUserProfileByEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      return null;
    }

    final snapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: normalizedEmail)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    final doc = snapshot.docs.first;
    return User.fromJson({
      ...doc.data(),
      'id': doc.id,
    });
  }

  Future<void> upsertUserProfile(User user) async {
    final normalizedEmail = user.email?.trim().toLowerCase();
    await _firestore.collection('users').doc(user.id).set(
          {
            ...user.toJson(),
            'email': normalizedEmail,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
  }
}
