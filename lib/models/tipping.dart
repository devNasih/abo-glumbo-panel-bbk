import 'package:cloud_firestore/cloud_firestore.dart';

class TippingModel {
  String? agentId;
  String? agentName;
  String? agentPhone;
  double? cashtip;
  DateTime? lastUpdated;
  double? cardtip;
  String? walletId;
  bool? payoutRequested;
  double? payoutAmount;

  TippingModel({
    this.agentId,
    this.agentName,
    this.agentPhone,
    this.cashtip,
    this.lastUpdated,
    this.cardtip,
    this.walletId,
    this.payoutAmount,
    this.payoutRequested,
  });

  TippingModel.fromJson(Map<String, dynamic> json) {
    agentId = json['agentId'];
    agentName = json['agentName'];
    agentPhone = json['agentPhone'];
    cashtip = json['cashtip']?.toDouble();
    final timestamp = json['lastUpdated'];
    if (timestamp is Timestamp) {
      lastUpdated = timestamp.toDate();
    } else if (timestamp is String) {
      lastUpdated = DateTime.tryParse(timestamp);
    }
    cardtip = json['cardtip']?.toDouble();
    walletId = json['walletId'];
    payoutRequested = json['payoutRequested'] ?? false;
    payoutAmount = json['payoutAmount']?.toDouble();
  }

  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'agentName': agentName,
      'agentPhone': agentPhone,
      'cashtip': cashtip,
      'lastUpdated': lastUpdated?.toIso8601String(),
      'cardtip': cardtip,
      'walletId': walletId,
      'payoutRequested': payoutRequested,
      'payoutAmount': payoutAmount,
    };
  }

  TippingModel.fromSnapshot(DocumentSnapshot snapshot) {
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    agentId = data['agentId'];
    agentName = data['agentName'];
    agentPhone = data['agentPhone'];
    cashtip = data['cashtip']?.toDouble();
    final timestamp = data['lastUpdated'];
    if (timestamp is Timestamp) {
      lastUpdated = timestamp.toDate();
    } else if (timestamp is String) {
      lastUpdated = DateTime.tryParse(timestamp);
    }
    cardtip = data['cardtip']?.toDouble();
    walletId = data['walletId'];
    payoutRequested = data['payoutRequested'] ?? false;
    payoutAmount = data['payoutAmount']?.toDouble();
  }
  TippingModel.fromDocumentSnapshot(DocumentSnapshot snapshot)
    : this.fromSnapshot(snapshot);

  factory TippingModel.fromMap(Map<String, dynamic> map) => TippingModel(
    agentId: map['agentId'],
    agentName: map['agentName'],
    agentPhone: map['agentPhone'],
    cashtip: map['cashtip']?.toDouble(),
    lastUpdated: map['lastUpdated']?.toDate(),
    cardtip: map['cardtip']?.toDouble(),
    walletId: map['walletId'],
    payoutRequested: map['payoutRequested'] ?? false,
    payoutAmount: map['payoutAmount']?.toDouble(),
  );

  Map<String, dynamic> toMap() => {
    'agentId': agentId,
    'agentName': agentName,
    'agentPhone': agentPhone,
    'cashtip': cashtip,
    'lastUpdated': lastUpdated,
    'cardtip': cardtip,
    'walletId': walletId,
    'payoutRequested': payoutRequested ?? false,
    'payoutAmount': payoutAmount,
  };
}

class AllTipsModel {
  DateTime? createdAt;
  DateTime? updatedAt;
  String? paymentMethod;
  String? agentId;
  String? id;
  double? totalTipAmount;
  List<Map<String, dynamic>>? proofs;

  AllTipsModel({
    this.agentId,
    this.id,
    this.proofs,
    this.totalTipAmount,
    this.createdAt,
    this.updatedAt,
    this.paymentMethod,
  });

  factory AllTipsModel.fromJson(Map<String, dynamic> json) {
    return AllTipsModel(
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is Timestamp
                ? (json['createdAt'] as Timestamp).toDate()
                : json['createdAt'] as DateTime)
          : null,
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] is Timestamp
                ? (json['updatedAt'] as Timestamp).toDate()
                : json['updatedAt'] as DateTime)
          : null,
      agentId: json['agentId'] as String?,
      id: json['id'] as String?,
      totalTipAmount: json['totalTipAmount'] != null
          ? (json['totalTipAmount'] is double
                ? json['totalTipAmount'] as double
                : (json['totalTipAmount'] as num).toDouble())
          : null,
      proofs: json['proofs'] != null
          ? List<Map<String, dynamic>>.from(json['proofs'])
          : null,
      paymentMethod: json['paymentMethod'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'id': id,
      'totalTipAmount': totalTipAmount,
      'proofs': proofs,
      'paymentMethod': paymentMethod,
    };
  }
}
