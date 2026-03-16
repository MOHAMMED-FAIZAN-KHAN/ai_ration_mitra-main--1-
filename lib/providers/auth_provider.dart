import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/firestore_service.dart';
import '../models/fps_operations.dart';

class AuthProvider extends ChangeNotifier {
  static const String fixedAdminId = '1234567890';
  static const String fixedAdminPassword = '12345678';

  AuthProvider({
    StorageService? storageService,
    AuthService? authService,
    FirestoreService? firestoreService,
    bool enableFirebase = true,
    String? initializationError,
  })  : _storage = storageService ?? StorageService(),
        _enableFirebase = enableFirebase,
        _initializationError = initializationError,
        _authService = enableFirebase ? (authService ?? AuthService()) : null,
        _firestoreService =
            enableFirebase ? (firestoreService ?? FirestoreService()) : null {
    _loadInitialSession();
  }

  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  final StorageService _storage;
  final AuthService? _authService;
  final FirestoreService? _firestoreService;
  final bool _enableFirebase;
  final String? _initializationError;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  bool get hasError => _error != null;
  bool get isInitialized => _isInitialized;

  Future<void> _loadInitialSession() async {
    try {
      _isLoading = true;
      notifyListeners();

      if (_enableFirebase && _authService != null) {
        final firebaseUser = _authService!.currentFirebaseUser;
        if (firebaseUser != null) {
          User? cloudUser;
          try {
            cloudUser = await _authService!.getUserProfileByUid(firebaseUser.uid);
          } catch (e) {
            if (!_isFirestoreAccessIssue(e)) {
              rethrow;
            }
          }
          if (cloudUser != null) {
            _currentUser = _hydrateWithFirebaseUser(cloudUser, firebaseUser);
          } else {
            _currentUser = _applyUserDefaults(
              _buildCitizenFromFirebaseUser(firebaseUser),
              identifier: firebaseUser.uid,
            );
            await _tryUpsertUserProfile(_currentUser!);
            await _ensureBeneficiaryRecord(_currentUser!, firebaseUser.uid);
          }
          await _storage.saveUser(_currentUser!);
        } else {
          await _loadStoredUserOnly();
        }
      } else {
        await _loadStoredUserOnly();
      }
      _error = null;
    } catch (e) {
      _error = 'Failed to load user data: $e';
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _loadStoredUserOnly() async {
    final storedUser = await _storage.getUser();
    if (storedUser != null && storedUser.type == UserType.citizen) {
      _currentUser = _applyUserDefaults(
        storedUser,
        identifier: storedUser.mobileNumber ?? storedUser.id,
      );
    } else {
      _currentUser = storedUser;
    }
  }

  Future<bool> signInWithGoogle({required UserType role}) async {
    if (!_enableFirebase) {
      _error = _firebaseInitMessage();
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final authService = _authService;
      if (authService == null) {
        _error = _firebaseInitMessage();
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final credential = await authService.signInWithGoogle();
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        _error = 'Google authentication did not return a user.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      User? matchedProfile;
      var firestoreAvailable = true;
      try {
        final storedProfile =
            await authService.getUserProfileByUid(firebaseUser.uid);
        final emailProfile = storedProfile == null &&
                firebaseUser.email != null &&
                firebaseUser.email!.trim().isNotEmpty
            ? await authService.getUserProfileByEmail(firebaseUser.email!)
            : null;
        matchedProfile = storedProfile ?? emailProfile;
      } catch (e) {
        if (_isFirestoreAccessIssue(e)) {
          firestoreAvailable = false;
        } else {
          rethrow;
        }
      }
      User resolvedUser;

      if (matchedProfile == null) {
        if (role != UserType.citizen && firestoreAvailable) {
          await authService.signOut();
          _error =
              'No ${_roleName(role)} account is linked with this Google account.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
        if (role != UserType.citizen && !firestoreAvailable) {
          await authService.signOut();
          _error =
              'Database is temporarily unavailable. Please try dealer/admin login again in a few minutes.';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        resolvedUser = _applyUserDefaults(
          _buildCitizenFromFirebaseUser(firebaseUser),
          identifier: firebaseUser.uid,
        );
      } else {
        if (matchedProfile.type != role) {
          await authService.signOut();
          _error =
              'This Google account is registered as ${_roleName(matchedProfile.type)}.';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        resolvedUser = _hydrateWithFirebaseUser(
          matchedProfile.copyWith(id: firebaseUser.uid),
          firebaseUser,
        );
        if (resolvedUser.type == UserType.citizen) {
          resolvedUser = _applyUserDefaults(
            resolvedUser,
            identifier: resolvedUser.mobileNumber ?? firebaseUser.uid,
          );
        }
      }

      _currentUser = resolvedUser;
      await _tryUpsertUserProfile(resolvedUser);
      await _ensureBeneficiaryRecord(resolvedUser, resolvedUser.uid ?? resolvedUser.id);
      await _storage.saveUser(resolvedUser);
      await _recordFirstLogin(resolvedUser, loginType: 'google');

      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
      return true;
    } on fb.FirebaseAuthException catch (e) {
      _error = _friendlyAuthError(
        code: e.code,
        fallback: e.message ?? 'Google sign-in failed.',
      );
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = _friendlyGenericError(
        e,
        fallback:
            'Google sign-in failed. Please check Firebase setup and internet.',
      );
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String identifier, String password, UserType type) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (identifier.trim().isEmpty) {
        _error = 'UID is required';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (password.trim().isEmpty) {
        _error = 'Password is required';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final normalizedIdentifier = identifier.trim();
      if (type == UserType.admin) {
        return _loginWithFixedAdmin(
          identifier: normalizedIdentifier,
          password: password.trim(),
        );
      }

      final authService = _authService;
      if (!_enableFirebase || authService == null) {
        _error = _firebaseInitMessage();
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (type == UserType.fpsDealer && _firestoreService != null) {
        try {
          final count = await _firestoreService!
              .dealerProfileCountByFpsId(normalizedIdentifier);
          if (count > 1) {
            _error =
                'Multiple dealer profiles share this FPS ID. Contact admin to resolve duplicates.';
            _isLoading = false;
            notifyListeners();
            return false;
          }
        } catch (e) {
          if (_isFirestoreAccessIssue(e)) {
            _error =
                'Unable to verify FPS ID uniqueness. Please try again in a moment.';
            _isLoading = false;
            notifyListeners();
            return false;
          }
          rethrow;
        }
      }

      User? matchedProfile;
      var firestoreAvailable = true;
      try {
        matchedProfile = await authService.findUserByIdentifier(
          identifier: normalizedIdentifier,
          userType: type,
        );
      } catch (e) {
        if (_isFirestoreAccessIssue(e)) {
          firestoreAvailable = false;
        } else {
          rethrow;
        }
      }
      if (matchedProfile == null && firestoreAvailable) {
        _error = 'Invalid UID or password';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final email = (matchedProfile?.email?.trim().toLowerCase().isNotEmpty ?? false)
          ? matchedProfile!.email!.trim().toLowerCase()
          : await _resolveLoginEmail(
              userType: type,
              identifier: normalizedIdentifier,
            );
      if (email.isEmpty) {
        _error = 'Account is not configured correctly. Please register again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final credential = await _signInWithEmailCandidates(
        authService: authService,
        password: password.trim(),
        primaryEmail: email,
        identifier: normalizedIdentifier,
        userType: type,
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        _error = 'Login failed.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      var resolvedUser = _hydrateWithFirebaseUser(
        (matchedProfile ?? _buildDefaultUser(
          identifier: normalizedIdentifier,
          userType: type,
        ))
            .copyWith(id: firebaseUser.uid, email: email),
        firebaseUser,
      );
      if (resolvedUser.type == UserType.citizen) {
        resolvedUser = _applyUserDefaults(
          resolvedUser,
          identifier: normalizedIdentifier,
        );
      }

      _currentUser = resolvedUser;
      await _tryUpsertUserProfile(resolvedUser);
      await _storage.saveUser(resolvedUser);
      await _recordFirstLogin(resolvedUser, loginType: 'login');
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
      return true;
    } on fb.FirebaseAuthException catch (e) {
      final code = e.code.toLowerCase();
      if (code == 'wrong-password' ||
          code == 'user-not-found' ||
          code == 'invalid-credential' ||
          code == 'invalid-email') {
        _error = 'Invalid UID or password';
      } else {
        _error = _friendlyAuthError(
          code: code,
          fallback: e.message ?? 'Login failed.',
        );
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = _friendlyGenericError(
        e,
        fallback: 'Login failed. Please try again.',
      );
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(User newUser, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (newUser.type == UserType.admin) {
        final adminId = newUser.uid?.trim() ?? '';
        if (adminId != fixedAdminId || password.trim() != fixedAdminPassword) {
          _error =
              'Admin registration is restricted. Use fixed Admin ID 1234567890 and password 12345678.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      if (newUser.name.trim().isEmpty) {
        _error = 'Name is required';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (newUser.mobileNumber?.isEmpty ?? true) {
        _error = 'Mobile number is required';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (password.trim().isEmpty || password.length < 6) {
        _error = 'Password must be at least 6 characters';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final authService = _authService;
      if (!_enableFirebase || authService == null) {
        _error = _firebaseInitMessage();
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final loginIdentifier = _loginIdentifierForUser(newUser);
      if (loginIdentifier == null || loginIdentifier.isEmpty) {
        _error = 'Invalid UID for selected user type';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (newUser.type == UserType.citizen &&
          _enableFirebase &&
          _firestoreService != null) {
        try {
          final uidCandidate = _beneficiaryUidForUser(newUser, loginIdentifier);
          final cardCandidate = _beneficiaryCardNumberForUser(newUser);
          final uidExists =
              await _firestoreService!.beneficiaryUidExists(uidCandidate);
          final cardExists =
              await _firestoreService!.beneficiaryCardExists(cardCandidate);
          if (uidExists || cardExists) {
            _error = 'A beneficiary with this UID already exists';
            _isLoading = false;
            notifyListeners();
            return false;
          }
        } catch (e) {
          if (_isFirestoreAccessIssue(e)) {
            _error =
                'Unable to verify UID uniqueness. Please try again in a moment.';
            _isLoading = false;
            notifyListeners();
            return false;
          }
          rethrow;
        }
      }
      if (newUser.type == UserType.fpsDealer &&
          _enableFirebase &&
          _firestoreService != null) {
        final fpsId = newUser.fpsId?.trim() ?? '';
        if (fpsId.isEmpty) {
          _error = 'FPS ID is required';
          _isLoading = false;
          notifyListeners();
          return false;
        }
        try {
          final exists = await _firestoreService!.dealerFpsIdExists(fpsId);
          if (exists) {
            _error = 'This FPS ID is already registered';
            _isLoading = false;
            notifyListeners();
            return false;
          }
        } catch (e) {
          if (_isFirestoreAccessIssue(e)) {
            _error =
                'Unable to verify FPS ID uniqueness. Please try again in a moment.';
            _isLoading = false;
            notifyListeners();
            return false;
          }
          rethrow;
        }
      }

      var firestoreAvailable = true;
      try {
        final existing = await authService.findUserByIdentifier(
          identifier: loginIdentifier,
          userType: newUser.type,
        );
        if (existing != null) {
          _error = 'This UID is already registered';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } catch (e) {
        if (_isFirestoreAccessIssue(e)) {
          firestoreAvailable = false;
        } else {
          rethrow;
        }
      }

      final authEmail = _resolveAuthEmail(newUser, loginIdentifier);
      final credential = await authService.createUserWithEmailAndPassword(
        email: authEmail,
        password: password.trim(),
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        _error = 'Registration failed.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      var userToStore = _hydrateWithFirebaseUser(
        newUser.copyWith(id: firebaseUser.uid, email: authEmail),
        firebaseUser,
      );
      if (userToStore.type == UserType.citizen) {
        userToStore = _applyUserDefaults(
          userToStore,
          identifier: loginIdentifier,
        );
      }

      _currentUser = userToStore;
      await _tryUpsertUserProfile(userToStore);
      await _ensureBeneficiaryRecord(userToStore, loginIdentifier);
      await _storage.saveUser(userToStore);
      await _recordFirstLogin(userToStore, loginType: 'registration');
      await _storage.saveAuthAlias(
        type: newUser.type,
        identifier: loginIdentifier,
        authEmail: authEmail,
      );
      _isLoading = false;
      _isInitialized = true;
      if (!firestoreAvailable) {
        _error = null;
      }
      notifyListeners();
      return true;
    } on fb.FirebaseAuthException catch (e) {
      final code = e.code.toLowerCase();
      if (code == 'email-already-in-use') {
        _error = 'Account already exists for this UID';
      } else if (code == 'weak-password') {
        _error = 'Password is too weak';
      } else {
        _error = _friendlyAuthError(
          code: code,
          fallback: e.message ?? 'Registration failed.',
        );
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = _friendlyGenericError(
        e,
        fallback: 'Registration failed. Please try again.',
      );
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      _isLoading = true;
      notifyListeners();

      if (_enableFirebase && _authService?.currentFirebaseUser != null) {
        await _authService!.signOut();
      }
      await _storage.clear();
      _currentUser = null;
      _error = null;
    } catch (e) {
      _error = 'Logout failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile(User updatedUser) async {
    try {
      if (_enableFirebase && _authService?.currentFirebaseUser != null) {
        final firebaseUser = _authService!.currentFirebaseUser!;
        _currentUser = _hydrateWithFirebaseUser(updatedUser, firebaseUser);
        await _tryUpsertUserProfile(_currentUser!);
      } else {
        _currentUser = updatedUser;
      }

      await _storage.saveUser(_currentUser!);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update profile: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeOtpAuth({
    required String identifier,
    required UserType userType,
    required bool isRegistration,
    User? registrationUser,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 350));

      if (_enableFirebase &&
          _authService != null &&
          _authService!.currentFirebaseUser == null) {
        await _authService!.signInAnonymously();
      }

      final baseUser = registrationUser ??
          (!isRegistration &&
                  _currentUser != null &&
                  _currentUser!.type == userType
              ? _currentUser!
              : _buildDefaultUser(
                  identifier: identifier,
                  userType: userType,
                ));

      _currentUser = _applyUserDefaults(baseUser, identifier: identifier);
      await _persistCurrentUser();
      if (_currentUser != null) {
        await _recordFirstLogin(
          _currentUser!,
          loginType: isRegistration ? 'registration' : 'otp',
        );
      }

      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'OTP verification failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _persistCurrentUser() async {
    if (_currentUser == null) {
      return;
    }

    if (_enableFirebase && _authService?.currentFirebaseUser != null) {
      final firebaseUser = _authService!.currentFirebaseUser!;
      _currentUser = _hydrateWithFirebaseUser(_currentUser!, firebaseUser);
      await _tryUpsertUserProfile(_currentUser!);
      await _ensureBeneficiaryRecord(_currentUser!, firebaseUser.uid);
    }

    await _storage.saveUser(_currentUser!);
  }

  Future<void> _recordFirstLogin(User user, {required String loginType}) async {
    if (!_enableFirebase || _firestoreService == null) {
      return;
    }
    if (user.type == UserType.admin) {
      return;
    }
    try {
      await _firestoreService!.createLoginRecordIfMissing(
        user: user,
        loginType: loginType,
      );
    } catch (e) {
      if (!_isFirestoreAccessIssue(e)) {
        debugPrint('Login record sync failed: $e');
      }
    }
  }

  User _buildDefaultUser({
    required String identifier,
    required UserType userType,
  }) {
    final nowId = DateTime.now().millisecondsSinceEpoch.toString();
    switch (userType) {
      case UserType.citizen:
        return User(
          id: nowId,
          type: userType,
          name: 'Rajesh Kumar',
          aadhaarNumber:
              identifier.length == 12 ? identifier : '456345894456',
          mobileNumber: identifier.length == 10 ? identifier : '9876543210',
          email: 'rajesh.kumar@example.com',
          uid: '4563 4589 4456',
          category: 'PHH (BPL)',
          assignedShop: 'Shyam Ration Store',
          address: 'Mumbai West',
        );
      case UserType.fpsDealer:
        return User(
          id: nowId,
          type: userType,
          name: 'Shyam Ration Store',
          mobileNumber: identifier,
          fpsId: identifier,
          email: 'dealer@example.com',
          address: 'Ward 11, Mumbai',
        );
      case UserType.admin:
        return User(
          id: nowId,
          type: userType,
          name: 'Admin User',
          mobileNumber: identifier,
          email: 'admin@example.com',
        );
    }
  }

  User _buildCitizenFromFirebaseUser(fb.User firebaseUser) {
    return User(
      id: firebaseUser.uid,
      type: UserType.citizen,
      name: firebaseUser.displayName?.trim().isNotEmpty == true
          ? firebaseUser.displayName!.trim()
          : 'Citizen User',
      mobileNumber: _normalizePhone(firebaseUser.phoneNumber),
      email: firebaseUser.email?.trim().toLowerCase(),
    );
  }

  String _beneficiaryUidForUser(User user, String identifier) {
    final rawUid = (user.uid ?? '').trim();
    if (rawUid.isNotEmpty) {
      return rawUid;
    }
    final aadhaarDigits =
        (user.aadhaarNumber ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (aadhaarDigits.length == 12) {
      return aadhaarDigits;
    }
    final digits = identifier.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isNotEmpty) {
      return digits;
    }
    return user.id;
  }

  String _beneficiaryCardNumberForUser(User user) {
    final uid = (user.uid ?? '').trim();
    if (uid.isNotEmpty) {
      return uid;
    }
    final aadhaar = (user.aadhaarNumber ?? '').trim();
    if (aadhaar.isNotEmpty) {
      return aadhaar;
    }
    final mobile = (user.mobileNumber ?? '').trim();
    if (mobile.isNotEmpty) {
      return mobile;
    }
    return user.id;
  }

  Future<void> _ensureBeneficiaryRecord(User user, String identifier) async {
    if (!_enableFirebase || user.type != UserType.citizen) {
      return;
    }
    final firestoreService = _firestoreService;
    if (firestoreService == null) {
      return;
    }
    try {
      final existing = await firestoreService.fetchBeneficiaryById(user.id);
      if (existing != null) {
        return;
      }
      final uidValue = _beneficiaryUidForUser(user, identifier);
      final cardNumber = _beneficiaryCardNumberForUser(user);
      final category = (user.category ?? '').trim().isNotEmpty
          ? user.category!.trim()
          : 'PHH (BPL)';
      final record = BeneficiaryRecord(
        id: user.id,
        uid: uidValue,
        name: user.name.trim().isNotEmpty ? user.name.trim() : 'Citizen User',
        cardNumber: cardNumber,
        category: category,
        familyMembers: 4,
        lastCollectionDate: null,
        nextEligibleDate: DateTime.now(),
        isActive: true,
        pendingItems: const ['Rice 3kg', 'Wheat 5kg', 'Sugar 1kg'],
      );
      await firestoreService.upsertBeneficiary(record);
    } catch (e) {
      if (!_isFirestoreAccessIssue(e)) {
        rethrow;
      }
    }
  }

  User _hydrateWithFirebaseUser(User user, fb.User firebaseUser) {
    final email = user.email?.trim().isNotEmpty == true
        ? user.email!.trim().toLowerCase()
        : firebaseUser.email?.trim().toLowerCase();

    final name = user.name.trim().isNotEmpty
        ? user.name.trim()
        : (firebaseUser.displayName?.trim().isNotEmpty == true
            ? firebaseUser.displayName!.trim()
            : 'User');

    final phone = user.mobileNumber?.trim().isNotEmpty == true
        ? user.mobileNumber!.trim()
        : _normalizePhone(firebaseUser.phoneNumber);

    return user.copyWith(
      id: firebaseUser.uid,
      name: name,
      email: email,
      mobileNumber: phone,
    );
  }

  String? _normalizePhone(String? rawPhone) {
    if (rawPhone == null || rawPhone.trim().isEmpty) {
      return null;
    }
    final digits = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 10) {
      return digits.substring(digits.length - 10);
    }
    return rawPhone.trim();
  }

  String _roleName(UserType type) {
    switch (type) {
      case UserType.citizen:
        return 'Citizen';
      case UserType.fpsDealer:
        return 'FPS Dealer';
      case UserType.admin:
        return 'Admin';
    }
  }

  String? _loginIdentifierForUser(User user) {
    switch (user.type) {
      case UserType.citizen:
        final aadhaar = user.aadhaarNumber?.trim() ?? '';
        final mobile = user.mobileNumber?.trim() ?? '';
        if (aadhaar.length == 12) {
          return aadhaar;
        }
        if (mobile.length == 10) {
          return mobile;
        }
        return null;
      case UserType.fpsDealer:
        final fpsId = user.fpsId?.trim() ?? '';
        return fpsId.isEmpty ? null : fpsId;
      case UserType.admin:
        final adminId = user.uid?.trim() ?? '';
        return adminId.isEmpty ? null : adminId;
    }
  }

  String _resolveAuthEmail(User user, String loginIdentifier) {
    if (user.type != UserType.citizen) {
      return _fallbackAuthEmail(type: user.type, identifier: loginIdentifier);
    }
    final explicitEmail = user.email?.trim().toLowerCase() ?? '';
    if (explicitEmail.isNotEmpty && explicitEmail.contains('@')) {
      return explicitEmail;
    }

    final safe = loginIdentifier
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
    final roleToken = user.type.toString().split('.').last;
    final fallbackLocal = safe.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : safe;
    return '$roleToken.$fallbackLocal@airation.local';
  }

  String _fallbackAuthEmail({
    required UserType type,
    required String identifier,
  }) {
    final safe = identifier
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (safe.isEmpty) {
      return '';
    }
    final roleToken = type.toString().split('.').last;
    return '$roleToken.$safe@airation.local';
  }

  Future<String> _resolveLoginEmail({
    required UserType userType,
    required String identifier,
  }) async {
    final alias = await _storage.getAuthAlias(type: userType, identifier: identifier);
    if (alias != null && alias.trim().isNotEmpty) {
      return alias.trim().toLowerCase();
    }
    return _fallbackAuthEmail(type: userType, identifier: identifier);
  }

  Future<fb.UserCredential> _signInWithEmailCandidates({
    required AuthService authService,
    required String password,
    required String primaryEmail,
    required String identifier,
    required UserType userType,
  }) async {
    final candidates = <String>[];
    void addCandidate(String? raw) {
      final email = (raw ?? '').trim().toLowerCase();
      if (email.isEmpty || candidates.contains(email)) {
        return;
      }
      candidates.add(email);
    }

    addCandidate(primaryEmail);
    addCandidate(await _storage.getAuthAlias(type: userType, identifier: identifier));
    addCandidate(_fallbackAuthEmail(type: userType, identifier: identifier));
    if (identifier.contains('@')) {
      addCandidate(identifier);
    }

    fb.FirebaseAuthException? lastAuthError;
    for (final email in candidates) {
      try {
        return await authService.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on fb.FirebaseAuthException catch (e) {
        lastAuthError = e;
        final code = e.code.toLowerCase();
        if (code == 'user-not-found' ||
            code == 'invalid-email' ||
            code == 'invalid-credential' ||
            code == 'wrong-password') {
          continue;
        }
        rethrow;
      }
    }

    if (lastAuthError != null) {
      throw lastAuthError;
    }
    throw fb.FirebaseAuthException(
      code: 'invalid-credential',
      message: 'Invalid UID or password',
    );
  }

  bool _isFirestoreUnavailable(Object error) {
    if (error is FirebaseException) {
      if (error.plugin == 'cloud_firestore' && error.code == 'unavailable') {
        return true;
      }
    }
    final text = error.toString().toLowerCase();
    return text.contains('cloud_firestore/unavailable') ||
        (text.contains('firestore') && text.contains('unavailable'));
  }

  bool _isFirestorePermissionDenied(Object error) {
    if (error is FirebaseException) {
      if (error.plugin == 'cloud_firestore' && error.code == 'permission-denied') {
        return true;
      }
    }
    final text = error.toString().toLowerCase();
    return text.contains('cloud_firestore/permission-denied') ||
        (text.contains('firestore') && text.contains('permission-denied'));
  }

  bool _isFirestoreAccessIssue(Object error) {
    return _isFirestoreUnavailable(error) || _isFirestorePermissionDenied(error);
  }

  Future<void> _tryUpsertUserProfile(User user) async {
    final authService = _authService;
    if (!_enableFirebase || authService == null) {
      return;
    }
    try {
      await authService.upsertUserProfile(user);
    } catch (e) {
      if (!_isFirestoreAccessIssue(e)) {
        rethrow;
      }
    }
  }

  String _friendlyAuthError({
    required String code,
    required String fallback,
  }) {
    switch (code.toLowerCase()) {
      case 'operation-not-allowed':
        return 'Email/Password sign-in is disabled in Firebase. Enable it in Firebase Console > Authentication > Sign-in method.';
      case 'network-request-failed':
        return 'Network issue while contacting Firebase. Check internet and retry.';
      case 'too-many-requests':
        return 'Too many attempts. Wait a minute and try again.';
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Invalid UID or password';
      default:
        return fallback;
    }
  }

  String _friendlyGenericError(Object error, {required String fallback}) {
    if (_isFirestoreUnavailable(error)) {
      return 'Database is temporarily unavailable. Please retry in a moment.';
    }
    if (_isFirestorePermissionDenied(error)) {
      return 'Database permission issue. Update Firestore rules for /users access.';
    }
    return fallback;
  }

  String _firebaseInitMessage() {
    final details = (_initializationError ?? '').trim();
    if (details.isNotEmpty) {
      return 'Firebase is not initialized. $details';
    }
    return 'Firebase is not initialized. If you are running on Chrome/Windows, configure Firebase Web app and firebase_options.dart.';
  }

  Future<bool> _loginWithFixedAdmin({
    required String identifier,
    required String password,
  }) async {
    if (identifier != fixedAdminId || password != fixedAdminPassword) {
      _error = 'Invalid UID or password';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    final adminUser = User(
      id: 'fixed-admin',
      type: UserType.admin,
      name: 'System Admin',
      mobileNumber: fixedAdminId,
      email: 'admin.fixed@airation.local',
      uid: fixedAdminId,
    );

    _currentUser = adminUser;
    await _storage.saveUser(adminUser);
    _error = null;
    _isLoading = false;
    _isInitialized = true;
    notifyListeners();
    return true;
  }

  User _applyUserDefaults(User user, {required String identifier}) {
    if (user.type != UserType.citizen) {
      return user;
    }

    String cleanDigits(String? value) =>
        (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    String spacedUidFromDigits(String digits) {
      if (digits.length >= 12) {
        return '${digits.substring(0, 4)} ${digits.substring(4, 8)} ${digits.substring(8, 12)}';
      }
      return '4563 4589 4456';
    }

    final aadhaarDigits = cleanDigits(user.aadhaarNumber).padRight(12, '0');
    final defaultAadhaar = aadhaarDigits.length >= 12
        ? aadhaarDigits.substring(0, 12)
        : '456345894456';
    final mobileDigits = cleanDigits(user.mobileNumber);
    final defaultMobile = mobileDigits.length >= 10
        ? mobileDigits.substring(mobileDigits.length - 10)
        : (identifier.length == 10 ? identifier : '9876543210');

    return user.copyWith(
      name: user.name.trim().isEmpty ? 'Rajesh Kumar' : user.name.trim(),
      aadhaarNumber: user.aadhaarNumber?.trim().isNotEmpty == true
          ? user.aadhaarNumber!.trim()
          : defaultAadhaar,
      mobileNumber: user.mobileNumber?.trim().isNotEmpty == true
          ? user.mobileNumber!.trim()
          : defaultMobile,
      uid: user.uid?.trim().isNotEmpty == true
          ? user.uid!.trim()
          : spacedUidFromDigits(defaultAadhaar),
      category: user.category?.trim().isNotEmpty == true
          ? user.category!.trim()
          : 'PHH (BPL)',
      assignedShop: user.assignedShop?.trim().isNotEmpty == true
          ? user.assignedShop!.trim()
          : 'Shyam Ration Store',
      address: user.address?.trim().isNotEmpty == true
          ? user.address!.trim()
          : 'Mumbai West',
      email: user.email?.trim().isNotEmpty == true
          ? user.email!.trim()
          : 'rajesh.kumar@example.com',
    );
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void resetAuth() {
    _currentUser = null;
    _isLoading = false;
    _error = null;
    _isInitialized = true;
    notifyListeners();
  }
}
