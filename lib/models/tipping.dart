import 'package:cloud_firestore/cloud_firestore.dart';

class TippingModel {
  String? agentId;
  String? agentName;
  String? agentPhone;
  double? lastTipAmount;
  DateTime? lastUpdated;
  double? totalTip;
  String? walletId;

  TippingModel({
    this.agentId,
    this.agentName,
    this.agentPhone,
    this.lastTipAmount,
    this.lastUpdated,
    this.totalTip,
    this.walletId,
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
    };
  }
}
