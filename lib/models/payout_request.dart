import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PayoutRequestModel {
  String? id;
  String? userId;
  String? amount;
  String? status;
  String? type;
  Timestamp? createdAt;
  Timestamp? updatedAt;
  Timestamp? approvedAt;
  PayoutAccountModel? payoutAccount;

  PayoutRequestModel({
    this.id,
    this.userId,
    this.amount,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.approvedAt,
    this.payoutAccount,
    this.type,
  });

  PayoutRequestModel copyWith({
    String? id,
    String? userId,
    String? amount,
    String? status,
    Timestamp? createdAt,
    Timestamp? approvedAt,
    Timestamp? updatedAt,
    PayoutAccountModel? payoutAccount,
    String? type,
  }) {
    return PayoutRequestModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      approvedAt: approvedAt ?? this.approvedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      payoutAccount: payoutAccount ?? this.payoutAccount,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'status': status,
      'createdAt': createdAt,
      'approvedAt': approvedAt,
      'updatedAt': updatedAt,
      'payoutAccount': payoutAccount?.toJson(),
      'type': type,
    };
  }

  factory PayoutRequestModel.fromMap(Map<String, dynamic> map) {
    return PayoutRequestModel(
      id: map['id'],
      userId: map['userId'],
      amount: map['amount'],
      status: map['status'],
      approvedAt: map['approvedAt'],
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
      payoutAccount: map['payoutAccount'] != null
          ? PayoutAccountModel.fromMap(map['payoutAccount'])
          : null,
      type: map['type'],
    );
  }

  factory PayoutRequestModel.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse timestamps
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

    return PayoutRequestModel(
      id: json['id'],
      userId: json['userId'],
      amount: json['amount'],
      status: json['status'],
      approvedAt: parseTimestamp(json['approvedAt']),
      createdAt: parseTimestamp(json['createdAt']),
      updatedAt: parseTimestamp(json['updatedAt']),
      payoutAccount: json['payoutAccount'] != null
          ? PayoutAccountModel.fromJson(json['payoutAccount'])
          : null,
      type: json['type'],
    );
  }
}
