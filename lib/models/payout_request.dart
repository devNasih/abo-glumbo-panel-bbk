import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PayoutRequestModel {
  String? id;
  String? userId;
  String? amount;
  String? status;
  Timestamp? createdAt;
  Timestamp? updatedAt;
  PayoutAccountModel? payoutAccount;

  PayoutRequestModel({
    this.id,
    this.userId,
    this.amount,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.payoutAccount,
  });

  PayoutRequestModel copyWith({
    String? id,
    String? userId,
    String? amount,
    String? status,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    PayoutAccountModel? payoutAccount,
  }) {
    return PayoutRequestModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      payoutAccount: payoutAccount ?? this.payoutAccount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'payoutAccount': payoutAccount?.toJson(),
    };
  }

  factory PayoutRequestModel.fromMap(Map<String, dynamic> map) {
    return PayoutRequestModel(
      id: map['id'],
      userId: map['userId'],
      amount: map['amount'],
      status: map['status'],
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
      payoutAccount: map['payoutAccount'] != null
          ? PayoutAccountModel.fromMap(map['payoutAccount'])
          : null,
    );
  }

  factory PayoutRequestModel.fromJson(Map<String, dynamic> json) {
    return PayoutRequestModel(
      id: json['id'],
      userId: json['userId'],
      amount: json['amount'],
      status: json['status'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      payoutAccount: json['payoutAccount'] != null
          ? PayoutAccountModel.fromJson(json['payoutAccount'])
          : null,
    );
  }
}
