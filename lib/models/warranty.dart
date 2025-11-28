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
    return WarrantyModel(
      id: json['id'],
      assignedTechnicianId: json['assignedTechnicianId'],
      warrantyStatusCode: json['warrantyStatusCode']?.toString() ?? 'A',
      claimrequested: json['claimrequested'] as bool?,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp)
          : json['createdAt'] as Timestamp,
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp)
          : json['updatedAt'] as Timestamp,
      requestedOn: json['requestedOn'] is Timestamp
          ? (json['requestedOn'] as Timestamp)
          : json['requestedOn'] as Timestamp,
      completedAt: json['completedAt'] is Timestamp
          ? (json['completedAt'] as Timestamp)
          : json['completedAt'] as Timestamp,
      acceptedAt: json['acceptedAt'] is Timestamp
          ? (json['acceptedAt'] as Timestamp)
          : (json['acceptedAt'] as Timestamp?) ??
                (json['acceptedOn'] is Timestamp
                    ? (json['acceptedOn'] as Timestamp)
                    : json['acceptedOn'] as Timestamp?),
      rejectedAt: json['rejectedAt'] is Timestamp
          ? (json['rejectedAt'] as Timestamp)
          : json['rejectedAt'] as Timestamp?,
      expiredOn: json['expiredOn'] is Timestamp
          ? (json['expiredOn'] as Timestamp)
          : json['expiredOn'] as Timestamp?,
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
    return RejectedTechnicianModel(
      uid: json['uid'],
      name: json['name'],
      phone: json['phone'],
      reason: json['reason'],
      rejectedAt: (json['rejectedAt'] is Timestamp)
          ? (json['rejectedAt'] as Timestamp)
          : (json['rejectedAt'] as Timestamp),
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
