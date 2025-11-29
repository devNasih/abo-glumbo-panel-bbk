import 'package:cloud_firestore/cloud_firestore.dart';

class TippingModel {
  String? agentId;
  String? agentName;
  String? agentPhone;
  double? cashtip;
  Timestamp? lastUpdated;
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
      lastUpdated = timestamp;
    } else if (timestamp is String) {
      lastUpdated = Timestamp.fromDate(DateTime.parse(timestamp));
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
      'lastUpdated': lastUpdated,
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
      lastUpdated = timestamp;
    } else if (timestamp is String) {
      lastUpdated = Timestamp.fromDate(DateTime.parse(timestamp));
    }
    cardtip = data['cardtip']?.toDouble();
    walletId = data['walletId'];
    payoutRequested = data['payoutRequested'] ?? false;
    payoutAmount = data['payoutAmount']?.toDouble();
  }

  TippingModel.fromDocumentSnapshot(DocumentSnapshot snapshot)
    : this.fromSnapshot(snapshot);

  factory TippingModel.fromMap(Map<String, dynamic> map) {
    final timestamp = map['lastUpdated'];
    Timestamp? lastUpdatedTimestamp;
    if (timestamp is Timestamp) {
      lastUpdatedTimestamp = timestamp;
    } else if (timestamp is String) {
      lastUpdatedTimestamp = Timestamp.fromDate(DateTime.parse(timestamp));
    }

    return TippingModel(
      agentId: map['agentId'],
      agentName: map['agentName'],
      agentPhone: map['agentPhone'],
      cashtip: map['cashtip']?.toDouble(),
      lastUpdated: lastUpdatedTimestamp,
      cardtip: map['cardtip']?.toDouble(),
      walletId: map['walletId'],
      payoutRequested: map['payoutRequested'] ?? false,
      payoutAmount: map['payoutAmount']?.toDouble(),
    );
  }

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
  Timestamp? createdAt;
  Timestamp? updatedAt;
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
    // Handle createdAt - can be Timestamp or String
    Timestamp? createdAtTimestamp;
    final createdAtValue = json['createdAt'];
    if (createdAtValue != null) {
      if (createdAtValue is Timestamp) {
        createdAtTimestamp = createdAtValue;
      } else if (createdAtValue is String) {
        createdAtTimestamp = Timestamp.fromDate(DateTime.parse(createdAtValue));
      }
    }

    // Handle updatedAt - can be Timestamp or String
    Timestamp? updatedAtTimestamp;
    final updatedAtValue = json['updatedAt'];
    if (updatedAtValue != null) {
      if (updatedAtValue is Timestamp) {
        updatedAtTimestamp = updatedAtValue;
      } else if (updatedAtValue is String) {
        updatedAtTimestamp = Timestamp.fromDate(DateTime.parse(updatedAtValue));
      }
    }

    // Handle totalTipAmount - Firebase stores it as 'Amount' (capital A)
    double? tipAmount;
    if (json['Amount'] != null) {
      // Firebase uses 'Amount' field
      tipAmount = json['Amount'] is double
          ? json['Amount'] as double
          : (json['Amount'] as num).toDouble();
    } else if (json['totalTipAmount'] != null) {
      // Fallback to 'totalTipAmount' field
      tipAmount = json['totalTipAmount'] is double
          ? json['totalTipAmount'] as double
          : (json['totalTipAmount'] as num).toDouble();
    }

    return AllTipsModel(
      createdAt: createdAtTimestamp,
      updatedAt: updatedAtTimestamp,
      agentId: json['agentId'] as String?,
      id: json['id'] as String?,
      totalTipAmount: tipAmount,
      proofs: json['proofs'] != null
          ? List<Map<String, dynamic>>.from(json['proofs'])
          : null,
      paymentMethod: json['paymentMethod'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'id': id,
      'Amount': totalTipAmount, // Use 'Amount' to match Firebase field name
      'proofs': proofs,
      'paymentMethod': paymentMethod,
    };
  }
}
