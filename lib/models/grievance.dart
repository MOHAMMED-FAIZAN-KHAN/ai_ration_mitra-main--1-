enum GrievanceStatus { pending, inProgress, resolved, rejected }

enum GrievanceCategory { technical, ration, aadhaar, fps, payment, other }

class Grievance {
  final String id;
  final String userId;
  final String userName;
  final String userType; // 'citizen' or 'fps'
  final GrievanceCategory category;
  final String title;
  final String description;
  final String? attachmentUrl;
  final GrievanceStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<GrievanceRemark> remarks;

  Grievance({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userType,
    required this.category,
    required this.title,
    required this.description,
    this.attachmentUrl,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    required this.remarks,
  });

  factory Grievance.fromJson(Map<String, dynamic> json) {
    try {
      return Grievance(
        id: json['id'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        userName: json['userName'] as String? ?? 'Unknown',
        userType: json['userType'] as String? ?? 'citizen',
        category: _parseGrievanceCategory(json['category']),
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        attachmentUrl: json['attachmentUrl'] as String?,
        status: _parseGrievanceStatus(json['status']),
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
        remarks: (json['remarks'] as List<dynamic>?)
                ?.map(
                    (r) => GrievanceRemark.fromJson(r as Map<String, dynamic>))
                .toList() ??
            [],
      );
    } catch (e) {
      throw Exception('Failed to parse Grievance: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userType': userType,
      'category': category.toString().split('.').last,
      'title': title,
      'description': description,
      'attachmentUrl': attachmentUrl,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'remarks': remarks.map((r) => r.toJson()).toList(),
    };
  }

  static GrievanceStatus _parseGrievanceStatus(dynamic status) {
    if (status is String) {
      switch (status) {
        case 'pending':
          return GrievanceStatus.pending;
        case 'inProgress':
          return GrievanceStatus.inProgress;
        case 'resolved':
          return GrievanceStatus.resolved;
        case 'rejected':
          return GrievanceStatus.rejected;
      }
    }
    return GrievanceStatus.pending;
  }

  static GrievanceCategory _parseGrievanceCategory(dynamic category) {
    if (category is String) {
      switch (category) {
        case 'technical':
          return GrievanceCategory.technical;
        case 'ration':
          return GrievanceCategory.ration;
        case 'aadhaar':
          return GrievanceCategory.aadhaar;
        case 'fps':
          return GrievanceCategory.fps;
        case 'payment':
          return GrievanceCategory.payment;
        case 'other':
          return GrievanceCategory.other;
      }
    }
    return GrievanceCategory.other;
  }
}

class GrievanceRemark {
  final String id;
  final String userId;
  final String userName;
  final String userType; // 'admin' or 'user'
  final String remark;
  final DateTime createdAt;

  GrievanceRemark({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userType,
    required this.remark,
    required this.createdAt,
  });

  factory GrievanceRemark.fromJson(Map<String, dynamic> json) {
    try {
      return GrievanceRemark(
        id: json['id'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        userName: json['userName'] as String? ?? 'Unknown',
        userType: json['userType'] as String? ?? 'user',
        remark: json['remark'] as String? ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to parse GrievanceRemark: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userType': userType,
      'remark': remark,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
