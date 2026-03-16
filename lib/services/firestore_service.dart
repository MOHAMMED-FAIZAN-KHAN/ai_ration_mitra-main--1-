import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/grievance.dart';
import '../models/stock.dart';
import '../models/fps_operations.dart';
import '../models/user.dart';
import '../models/login_record.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // -------------------- Users --------------------
  Stream<List<User>> streamUsers({String? role}) {
    Query<Map<String, dynamic>> query =
        _firestore.collection('users').orderBy('name');
    if (role != null && role.trim().isNotEmpty) {
      query = query.where('type', isEqualTo: role.trim());
    }
    return query.snapshots().map(_mapUsers);
  }

  Future<void> upsertUser(User user) async {
    final data = user.toJson();
    await _firestore.collection('users').doc(user.id).set(
          data,
          SetOptions(merge: true),
        );
  }

  Future<bool> dealerFpsIdExists(String fpsId) async {
    final normalized = fpsId.trim();
    if (normalized.isEmpty) {
      return false;
    }
    final snapshot = await _firestore
        .collection('users')
        .where('type', isEqualTo: 'fpsDealer')
        .where('fpsId', isEqualTo: normalized)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<int> dealerProfileCountByFpsId(String fpsId) async {
    final normalized = fpsId.trim();
    if (normalized.isEmpty) {
      return 0;
    }
    final snapshot = await _firestore
        .collection('users')
        .where('type', isEqualTo: 'fpsDealer')
        .where('fpsId', isEqualTo: normalized)
        .limit(2)
        .get();
    return snapshot.docs.length;
  }

  // -------------------- Grievances --------------------
  Stream<List<Grievance>> streamGrievances({String? userId}) {
    Query<Map<String, dynamic>> query = _firestore.collection('grievances');
    if (userId != null && userId.trim().isNotEmpty) {
      query = query.where('userId', isEqualTo: userId.trim());
    } else {
      query = query.orderBy('createdAt', descending: true);
    }
    return query.snapshots().map(_mapGrievances);
  }

  Future<List<Grievance>> fetchGrievances({String? userId}) async {
    Query<Map<String, dynamic>> query = _firestore.collection('grievances');
    if (userId != null && userId.trim().isNotEmpty) {
      query = query.where('userId', isEqualTo: userId.trim());
    } else {
      query = query.orderBy('createdAt', descending: true);
    }
    final snapshot = await query.get();
    return _mapGrievanceDocs(snapshot.docs);
  }

  Future<String> createGrievance(Grievance grievance) async {
    final data = grievance.toJson();
    final ref = await _firestore.collection('grievances').add({
      ...data,
      'createdAt': grievance.createdAt.toIso8601String(),
      'updatedAt': grievance.updatedAt?.toIso8601String(),
    });
    await ref.set({'id': ref.id}, SetOptions(merge: true));
    return ref.id;
  }

  Future<void> updateGrievanceStatus({
    required String grievanceId,
    required GrievanceStatus status,
    required GrievanceRemark remark,
  }) async {
    await _firestore.collection('grievances').doc(grievanceId).update({
      'status': status.name,
      'updatedAt': DateTime.now().toIso8601String(),
      'remarks': FieldValue.arrayUnion([remark.toJson()]),
    });
  }

  // Dealer grievances (separate collection to keep existing UI)
  Stream<List<DealerGrievance>> streamDealerGrievances() {
    return _firestore
        .collection('dealer_grievances')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_mapDealerGrievances);
  }

  Future<String> createDealerGrievance(DealerGrievance grievance) async {
    final ref = await _firestore.collection('dealer_grievances').add({
      ...grievance.toJson(),
      'createdAt': grievance.createdAt.toIso8601String(),
    });
    await ref.set({'id': ref.id}, SetOptions(merge: true));
    return ref.id;
  }

  Future<void> updateDealerGrievanceStatus({
    required String grievanceId,
    required DealerGrievanceStatus status,
    String? adminRemark,
  }) async {
    final updates = <String, dynamic>{
      'status': status.name,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    if (adminRemark != null && adminRemark.trim().isNotEmpty) {
      updates['adminRemark'] = adminRemark.trim();
    }
    await _firestore.collection('dealer_grievances').doc(grievanceId).update(
          updates,
        );
  }

  // -------------------- Stock --------------------
  Stream<List<StockItem>> streamStockItems({String? fpsId}) {
    Query<Map<String, dynamic>> query =
        _firestore.collection('stock').orderBy('itemName');
    if (fpsId != null && fpsId.trim().isNotEmpty) {
      query = query.where('fpsId', isEqualTo: fpsId.trim());
    }
    return query.snapshots().map(_mapStockItems);
  }

  Future<void> upsertStockItem(StockItem item) async {
    await _firestore.collection('stock').doc(item.id).set(
          item.toJson(),
          SetOptions(merge: true),
        );
  }

  Stream<List<StockMovement>> streamStockMovements({
    String? fpsId,
    String? itemName,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('stock_movements')
        .orderBy('timestamp', descending: true);
    if (fpsId != null && fpsId.trim().isNotEmpty) {
      query = query.where('fpsId', isEqualTo: fpsId.trim());
    }
    if (itemName != null && itemName.trim().isNotEmpty) {
      query = query.where('itemName', isEqualTo: itemName.trim());
    }
    return query.snapshots().map(_mapStockMovements);
  }

  Future<void> createStockMovement(StockMovement movement) async {
    final ref = await _firestore.collection('stock_movements').add({
      ...movement.toJson(),
      'timestamp': movement.timestamp.toIso8601String(),
    });
    await ref.set({'id': ref.id}, SetOptions(merge: true));
  }

  // -------------------- Distribution --------------------
  Stream<List<DistributionLogEntry>> streamDistributionLogs({
    String? cardNumber,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('distribution')
        .orderBy('distributedAt', descending: true);
    if (cardNumber != null && cardNumber.trim().isNotEmpty) {
      query = query.where('cardNumber', isEqualTo: cardNumber.trim());
    }
    return query.snapshots().map(_mapDistributionLogs);
  }

  Future<void> createDistributionLog(DistributionLogEntry entry,
      {String? dealerId, String? userId}) async {
    final ref = await _firestore.collection('distribution').add({
      ...entry.toJson(),
      'dealerId': dealerId,
      'userId': userId,
      'distributedAt': entry.distributedAt.toIso8601String(),
    });
    await ref.set({'id': ref.id}, SetOptions(merge: true));
  }

  // -------------------- Requisitions --------------------
  Stream<List<StockRequisition>> streamRequisitions() {
    return _firestore
        .collection('requisitions')
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map(_mapRequisitions);
  }

  Future<String> createRequisition(StockRequisition requisition) async {
    final ref = await _firestore.collection('requisitions').add({
      ...requisition.toJson(),
      'requestedAt': requisition.requestedAt.toIso8601String(),
    });
    await ref.set({'id': ref.id}, SetOptions(merge: true));
    return ref.id;
  }

  Future<void> updateRequisitionStatus({
    required String id,
    required DealerRequisitionStatus status,
  }) async {
    await _firestore.collection('requisitions').doc(id).update({
      'status': status.name,
    });
  }

  // -------------------- Beneficiaries --------------------
  Stream<List<BeneficiaryRecord>> streamBeneficiaries() {
    return _firestore
        .collection('beneficiaries')
        .orderBy('name')
        .snapshots()
        .map(_mapBeneficiaries);
  }

  Future<BeneficiaryRecord?> fetchBeneficiaryById(String id) async {
    final snapshot = await _firestore.collection('beneficiaries').doc(id).get();
    if (!snapshot.exists) {
      return null;
    }
    final data = snapshot.data();
    if (data == null) {
      return null;
    }
    return BeneficiaryRecord.fromJson({
      ...data,
      'id': snapshot.id,
    });
  }

  Future<bool> beneficiaryUidExists(String uid) async {
    final normalized = uid.trim();
    if (normalized.isEmpty) {
      return false;
    }
    final snapshot = await _firestore
        .collection('beneficiaries')
        .where('uid', isEqualTo: normalized)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<bool> beneficiaryCardExists(String cardNumber) async {
    final normalized = cardNumber.trim();
    if (normalized.isEmpty) {
      return false;
    }
    final snapshot = await _firestore
        .collection('beneficiaries')
        .where('cardNumber', isEqualTo: normalized)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<void> upsertBeneficiary(BeneficiaryRecord record) async {
    await _firestore.collection('beneficiaries').doc(record.id).set(
          record.toJson(),
          SetOptions(merge: true),
        );
  }

  // -------------------- Login Records --------------------
  Stream<List<LoginRecord>> streamLoginRecords({String? userType}) {
    Query<Map<String, dynamic>> query =
        _firestore.collection('login_records').orderBy('createdAt', descending: true);
    if (userType != null && userType.trim().isNotEmpty) {
      query = query.where('userType', isEqualTo: userType.trim());
    }
    return query.snapshots().map(_mapLoginRecords);
  }

  Future<void> createLoginRecordIfMissing({
    required User user,
    required String loginType,
  }) async {
    final userType = user.type.toString().split('.').last;
    final docId = '${userType}_${user.id}';
    final docRef = _firestore.collection('login_records').doc(docId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (snapshot.exists) {
        return;
      }
      transaction.set(docRef, {
        'name': user.name.trim().isEmpty ? _defaultNameFor(userType) : user.name.trim(),
        'uid': _loginUidForUser(user),
        'email': user.email?.trim().isNotEmpty == true
            ? user.email!.trim().toLowerCase()
            : null,
        'loginType': loginType.trim().isEmpty ? 'login' : loginType.trim(),
        'userType': userType,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // -------------------- Mappers --------------------
  List<User> _mapUsers(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs
        .map((doc) => User.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  List<Grievance> _mapGrievances(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return _mapGrievanceDocs(snapshot.docs);
  }

  List<Grievance> _mapGrievanceDocs(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return docs
        .map((doc) => Grievance.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  List<DealerGrievance> _mapDealerGrievances(
      QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs
        .map((doc) => DealerGrievance.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  List<StockItem> _mapStockItems(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs
        .map((doc) => StockItem.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  List<StockMovement> _mapStockMovements(
      QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs
        .map((doc) => StockMovement.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  List<DistributionLogEntry> _mapDistributionLogs(
      QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs
        .map((doc) => DistributionLogEntry.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  List<StockRequisition> _mapRequisitions(
      QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs
        .map((doc) => StockRequisition.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  List<BeneficiaryRecord> _mapBeneficiaries(
      QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs
        .map((doc) => BeneficiaryRecord.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  List<LoginRecord> _mapLoginRecords(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs
        .map((doc) => LoginRecord.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  String _loginUidForUser(User user) {
    final trimmedUid = (user.uid ?? '').trim();
    if (trimmedUid.isNotEmpty) {
      return trimmedUid;
    }
    final fpsId = (user.fpsId ?? '').trim();
    if (fpsId.isNotEmpty) {
      return fpsId;
    }
    final aadhaar = (user.aadhaarNumber ?? '').trim();
    if (aadhaar.isNotEmpty) {
      return aadhaar;
    }
    return user.id;
  }

  String _defaultNameFor(String userType) {
    switch (userType) {
      case 'fpsDealer':
        return 'FPS Dealer';
      case 'citizen':
        return 'Citizen User';
      default:
        return 'User';
    }
  }
}
