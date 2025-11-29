import 'package:cloud_firestore/cloud_firestore.dart';

class WarrantyModel {
  String? id;
  String? assignedTechnicianId;
  String warrantyStatusCode;
  bool? claimrequested;
  List<RejectedTechnicianModel>? rejectedTechnicians;
  Timestamp? createdAt;
  Timestamp? updatedAt;
  Timestamp? requestedOn;
  Timestamp? completedAt;
  Timestamp? acceptedAt;
  Timestamp? rejectedAt;
  Timestamp? expiredOn;

  WarrantyModel({
    this.id,
    this.assignedTechnicianId,
    this.warrantyStatusCode = 'A',
    this.claimrequested,
    this.rejectedTechnicians = const [],
    this.createdAt,
    this.updatedAt,
    this.requestedOn,
    this.completedAt,
    this.acceptedAt,
    this.rejectedAt,
    this.expiredOn,
  });

  factory WarrantyModel.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert timestamp fields
    Timestamp? parseTimestamp(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value;
      if (value is String) {
        try {
          return Timestamp.fromDate(DateTime.parse(value));
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    return WarrantyModel(
      id: json['id'],
      assignedTechnicianId: json['assignedTechnicianId'],
      warrantyStatusCode: json['warrantyStatusCode']?.toString() ?? 'A',
      claimrequested: json['claimrequested'] as bool?,
      createdAt: parseTimestamp(json['createdAt']),
      updatedAt: parseTimestamp(json['updatedAt']),
      requestedOn: parseTimestamp(json['requestedOn']),
      completedAt: parseTimestamp(json['completedAt']),
      acceptedAt:
          parseTimestamp(json['acceptedAt']) ??
          parseTimestamp(json['acceptedOn']),
      rejectedAt: parseTimestamp(json['rejectedAt']),
      expiredOn: parseTimestamp(json['expiredOn']),
      rejectedTechnicians: (json['rejectedTechnicians'] is List)
          ? (json['rejectedTechnicians'] as List)
                .map(
                  (e) => RejectedTechnicianModel.fromJson(
                    e as Map<String, dynamic>,
                  ),
                )
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assignedTechnicianId': assignedTechnicianId,
      'warrantyStatusCode': warrantyStatusCode,
      'claimrequested': claimrequested,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'requestedOn': requestedOn,
      'completedAt': completedAt,
      'acceptedAt': acceptedAt,
      'rejectedAt': rejectedAt,
      'expiredOn': expiredOn,
      'rejectedTechnicians': rejectedTechnicians
          ?.map((e) => e.toJson())
          .toList(),
    };
  }

  static WarrantyModel fromDocumentSnapshot(QueryDocumentSnapshot doc) {
    return WarrantyModel.fromJson(doc.data() as Map<String, dynamic>);
  }

  @override
  String toString() {
    return 'WarrantyModel(id: $id, status: $warrantyStatusCode, '
        'assignedTo: $assignedTechnicianId, '
        'requestedOn: $requestedOn, acceptedAt: $acceptedAt, '
        'completedAt: $completedAt, rejectedAt: $rejectedAt)';
  }
}

class RejectedTechnicianModel {
  String? uid;
  String? name;
  String? phone;
  String? reason;
  Timestamp? rejectedAt;

  RejectedTechnicianModel({
    this.uid,
    this.name,
    this.phone,
    this.reason,
    this.rejectedAt,
  });

  factory RejectedTechnicianModel.fromJson(Map<String, dynamic> json) {
    // Safely parse timestamp
    Timestamp? rejectedAtTimestamp;
    final rejectedAtValue = json['rejectedAt'];
    if (rejectedAtValue != null) {
      if (rejectedAtValue is Timestamp) {
        rejectedAtTimestamp = rejectedAtValue;
      } else if (rejectedAtValue is String) {
        try {
          rejectedAtTimestamp = Timestamp.fromDate(
            DateTime.parse(rejectedAtValue),
          );
        } catch (e) {
          rejectedAtTimestamp = null;
        }
      }
    }

    return RejectedTechnicianModel(
      uid: json['uid'],
      name: json['name'],
      phone: json['phone'],
      reason: json['reason'],
      rejectedAt: rejectedAtTimestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'reason': reason,
      'rejectedAt': rejectedAt,
    };
  }
}
