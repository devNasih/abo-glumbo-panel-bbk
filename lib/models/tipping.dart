import 'package:cloud_firestore/cloud_firestore.dart';

class TippingModel {
  String? agentId;
  String? agentName;
  String? agentPhone;
  double? lastTipAmount;
  DateTime? lastUpdated;
  double? totalTip;
  String? walletId;
  bool? payoutRequested;

  TippingModel({
    this.agentId,
    this.agentName,
    this.agentPhone,
    this.lastTipAmount,
    this.lastUpdated,
    this.totalTip,
    this.walletId,
    this.payoutRequested,
  });

  TippingModel.fromJson(Map<String, dynamic> json) {
    agentId = json['agentId'];
    agentName = json['agentName'];
    agentPhone = json['agentPhone'];
    lastTipAmount = json['lastTipAmount']?.toDouble();
    final timestamp = json['lastUpdated'];
    if (timestamp is Timestamp) {
      lastUpdated = timestamp.toDate();
    } else if (timestamp is String) {
      lastUpdated = DateTime.tryParse(timestamp);
    }
    totalTip = json['totalTip']?.toDouble();
    walletId = json['walletId'];
    payoutRequested = json['payoutRequested'] ?? false;
  }

  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'agentName': agentName,
      'agentPhone': agentPhone,
      'lastTipAmount': lastTipAmount,
      'lastUpdated': lastUpdated?.toIso8601String(),
      'totalTip': totalTip,
      'walletId': walletId,
      'payoutRequested': payoutRequested,
    };
  }

  TippingModel.fromSnapshot(DocumentSnapshot snapshot) {
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    agentId = data['agentId'];
    agentName = data['agentName'];
    agentPhone = data['agentPhone'];
    lastTipAmount = data['lastTipAmount']?.toDouble();
    final timestamp = data['lastUpdated'];
    if (timestamp is Timestamp) {
      lastUpdated = timestamp.toDate();
    } else if (timestamp is String) {
      lastUpdated = DateTime.tryParse(timestamp);
    }
    totalTip = data['totalTip']?.toDouble();
    walletId = data['walletId'];
    payoutRequested = data['payoutRequested'] ?? false;
  }

  factory TippingModel.fromMap(Map<String, dynamic> map) => TippingModel(
    agentId: map['agentId'],
    agentName: map['agentName'],
    agentPhone: map['agentPhone'],
    lastTipAmount: map['lastTipAmount']?.toDouble(),
    lastUpdated: map['lastUpdated']?.toDate(),
    totalTip: map['totalTip']?.toDouble(),
    walletId: map['walletId'],
    payoutRequested: map['payoutRequested'] ?? false,
  );

  Map<String, dynamic> toMap() => {
    'agentId': agentId,
    'agentName': agentName,
    'agentPhone': agentPhone,
    'lastTipAmount': lastTipAmount,
    'lastUpdated': lastUpdated,
    'totalTip': totalTip,
    'walletId': walletId,
    'payoutRequested': payoutRequested ?? false,
  };
}

class AllTipsModel {
  DateTime? createdAt;
  DateTime? updatedAt;
  String? agentId;
  String? id;
  double? totalTipAmount;
  List<Map<String, dynamic>>? proofs;

  AllTipsModel({this.agentId, this.id, this.proofs, this.totalTipAmount});

  AllTipsModel.fromJson(Map<String, dynamic> json) {
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    agentId = json['agentId'];
    id = json['id'];
    totalTipAmount = json['totalTipAmount'];
    proofs = json['proofs'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};

    data['agentId'] = agentId;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['id'] = id;
    data['totalTipAmount'] = totalTipAmount;
    data['proofs'] = proofs;
    return data;
  }
}
