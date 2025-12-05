import 'package:cloud_firestore/cloud_firestore.dart';

/// Unified Wallet Model that consolidates earnings, tips, and bonus
class UnifiedWalletModel {
  String? workerId;
  String? workerName;
  String? workerPhone;

  // Earnings breakdown
  double? totalEarnings; // Total card payments received
  double? cashEarnings; // Cash payments (info only, already in hand)
  double? paidEarnings; // Already paid out earnings
  double?
  availableEarnings; // Available for payout (totalEarnings - paidEarnings)

  // Tips breakdown
  double? totalTips; // Lifetime tips (card + cash)
  double? cardTips; // Available card tips for payout
  double? cashTips; // Cash tips (info only, not for payout)
  double? paidTips; // Already paid out tips

  // Bonus breakdown
  double? totalBonus; // Total bonus amount
  double? paidBonus; // Already paid out bonus
  double? availableBonus; // Available bonus for payout

  // Aggregated amounts
  double? totalAvailableBalance; // Sum of all available amounts
  double? lifetimeTotal; // Total of all earnings, tips, and bonus

  // Payout request status
  bool? payoutRequested;
  double? requestedAmount;
  Timestamp? lastPayoutRequestedAt;
  Timestamp? lastPayoutCompletedAt;
  Timestamp? lastUpdated;

  UnifiedWalletModel({
    this.workerId,
    this.workerName,
    this.workerPhone,
    this.totalEarnings,
    this.cashEarnings,
    this.paidEarnings,
    this.availableEarnings,
    this.totalTips,
    this.cardTips,
    this.cashTips,
    this.paidTips,
    this.totalBonus,
    this.paidBonus,
    this.availableBonus,
    this.totalAvailableBalance,
    this.lifetimeTotal,
    this.payoutRequested,
    this.requestedAmount,
    this.lastPayoutRequestedAt,
    this.lastPayoutCompletedAt,
    this.lastUpdated,
  });

  factory UnifiedWalletModel.fromJson(Map<String, dynamic> json) {
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

    return UnifiedWalletModel(
      workerId: json['workerId'] as String?,
      workerName: json['workerName'] as String?,
      workerPhone: json['workerPhone'] as String?,
      totalEarnings: (json['totalEarnings'] as num?)?.toDouble(),
      cashEarnings: (json['cashEarnings'] as num?)?.toDouble(),
      paidEarnings: (json['paidEarnings'] as num?)?.toDouble(),
      availableEarnings: (json['availableEarnings'] as num?)?.toDouble(),
      totalTips: (json['totalTips'] as num?)?.toDouble(),
      cardTips: (json['cardTips'] as num?)?.toDouble(),
      cashTips: (json['cashTips'] as num?)?.toDouble(),
      paidTips: (json['paidTips'] as num?)?.toDouble(),
      totalBonus: (json['totalBonus'] as num?)?.toDouble(),
      paidBonus: (json['paidBonus'] as num?)?.toDouble(),
      availableBonus: (json['availableBonus'] as num?)?.toDouble(),
      totalAvailableBalance: (json['totalAvailableBalance'] as num?)
          ?.toDouble(),
      lifetimeTotal: (json['lifetimeTotal'] as num?)?.toDouble(),
      payoutRequested: json['payoutRequested'] as bool?,
      requestedAmount: (json['requestedAmount'] as num?)?.toDouble(),
      lastPayoutRequestedAt: parseTimestamp(json['lastPayoutRequestedAt']),
      lastPayoutCompletedAt: parseTimestamp(json['lastPayoutCompletedAt']),
      lastUpdated: parseTimestamp(json['lastUpdated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'workerId': workerId,
      'workerName': workerName,
      'workerPhone': workerPhone,
      'totalEarnings': totalEarnings ?? 0.0,
      'cashEarnings': cashEarnings ?? 0.0,
      'paidEarnings': paidEarnings ?? 0.0,
      'availableEarnings': availableEarnings ?? 0.0,
      'totalTips': totalTips ?? 0.0,
      'cardTips': cardTips ?? 0.0,
      'cashTips': cashTips ?? 0.0,
      'paidTips': paidTips ?? 0.0,
      'totalBonus': totalBonus ?? 0.0,
      'paidBonus': paidBonus ?? 0.0,
      'availableBonus': availableBonus ?? 0.0,
      'totalAvailableBalance': totalAvailableBalance ?? 0.0,
      'lifetimeTotal': lifetimeTotal ?? 0.0,
      'payoutRequested': payoutRequested ?? false,
      'requestedAmount': requestedAmount ?? 0.0,
      'lastPayoutRequestedAt': lastPayoutRequestedAt,
      'lastPayoutCompletedAt': lastPayoutCompletedAt,
      'lastUpdated': lastUpdated ?? Timestamp.now(),
    };
  }

  factory UnifiedWalletModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>?;
    if (data == null) return UnifiedWalletModel();
    return UnifiedWalletModel.fromJson(data);
  }

  UnifiedWalletModel copyWith({
    String? workerId,
    String? workerName,
    String? workerPhone,
    double? totalEarnings,
    double? cashEarnings,
    double? paidEarnings,
    double? availableEarnings,
    double? totalTips,
    double? cardTips,
    double? cashTips,
    double? paidTips,
    double? totalBonus,
    double? paidBonus,
    double? availableBonus,
    double? totalAvailableBalance,
    double? lifetimeTotal,
    bool? payoutRequested,
    double? requestedAmount,
    Timestamp? lastPayoutRequestedAt,
    Timestamp? lastPayoutCompletedAt,
    Timestamp? lastUpdated,
  }) {
    return UnifiedWalletModel(
      workerId: workerId ?? this.workerId,
      workerName: workerName ?? this.workerName,
      workerPhone: workerPhone ?? this.workerPhone,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      cashEarnings: cashEarnings ?? this.cashEarnings,
      paidEarnings: paidEarnings ?? this.paidEarnings,
      availableEarnings: availableEarnings ?? this.availableEarnings,
      totalTips: totalTips ?? this.totalTips,
      cardTips: cardTips ?? this.cardTips,
      cashTips: cashTips ?? this.cashTips,
      paidTips: paidTips ?? this.paidTips,
      totalBonus: totalBonus ?? this.totalBonus,
      paidBonus: paidBonus ?? this.paidBonus,
      availableBonus: availableBonus ?? this.availableBonus,
      totalAvailableBalance:
          totalAvailableBalance ?? this.totalAvailableBalance,
      lifetimeTotal: lifetimeTotal ?? this.lifetimeTotal,
      payoutRequested: payoutRequested ?? this.payoutRequested,
      requestedAmount: requestedAmount ?? this.requestedAmount,
      lastPayoutRequestedAt:
          lastPayoutRequestedAt ?? this.lastPayoutRequestedAt,
      lastPayoutCompletedAt:
          lastPayoutCompletedAt ?? this.lastPayoutCompletedAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Unified Payout Request Model
class UnifiedPayoutRequestModel {
  String? id;
  String? workerId;
  String? workerName;

  // Breakdown of requested amounts
  double? earningsAmount;
  double? tipsAmount;
  double? bonusAmount;
  double? totalAmount;

  // Payout account details
  Map<String, dynamic>? payoutAccount;

  // Status and timestamps
  String? status; // 'P' = Pending, 'A' = Approved/Completed, 'R' = Rejected
  Timestamp? createdAt;
  Timestamp? approvedAt;
  Timestamp? rejectedAt;
  Timestamp? updatedAt;

  // Payment proof (for admin)
  String? paymentProofUrl;
  String? transactionId;
  String? rejectionReason;

  UnifiedPayoutRequestModel({
    this.id,
    this.workerId,
    this.workerName,
    this.earningsAmount,
    this.tipsAmount,
    this.bonusAmount,
    this.totalAmount,
    this.payoutAccount,
    this.status,
    this.createdAt,
    this.approvedAt,
    this.rejectedAt,
    this.updatedAt,
    this.paymentProofUrl,
    this.transactionId,
    this.rejectionReason,
  });

  factory UnifiedPayoutRequestModel.fromJson(Map<String, dynamic> json) {
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

    return UnifiedPayoutRequestModel(
      id: json['id'] as String?,
      workerId: json['workerId'] as String?,
      workerName: json['workerName'] as String?,
      earningsAmount: (json['earningsAmount'] as num?)?.toDouble(),
      tipsAmount: (json['tipsAmount'] as num?)?.toDouble(),
      bonusAmount: (json['bonusAmount'] as num?)?.toDouble(),
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
      payoutAccount: json['payoutAccount'] as Map<String, dynamic>?,
      status: json['status'] as String?,
      createdAt: parseTimestamp(json['createdAt']),
      approvedAt: parseTimestamp(json['approvedAt']),
      rejectedAt: parseTimestamp(json['rejectedAt']),
      updatedAt: parseTimestamp(json['updatedAt']),
      paymentProofUrl: json['paymentProofUrl'] as String?,
      transactionId: json['transactionId'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workerId': workerId,
      'workerName': workerName,
      'earningsAmount': earningsAmount ?? 0.0,
      'tipsAmount': tipsAmount ?? 0.0,
      'bonusAmount': bonusAmount ?? 0.0,
      'totalAmount': totalAmount ?? 0.0,
      'payoutAccount': payoutAccount,
      'status': status ?? 'P',
      'createdAt': createdAt ?? Timestamp.now(),
      'approvedAt': approvedAt,
      'rejectedAt': rejectedAt,
      'updatedAt': updatedAt ?? Timestamp.now(),
      'paymentProofUrl': paymentProofUrl,
      'transactionId': transactionId,
      'rejectionReason': rejectionReason,
    };
  }

  factory UnifiedPayoutRequestModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>?;
    if (data == null) return UnifiedPayoutRequestModel();
    // Merge the document ID into the data
    final dataWithId = {...data, 'id': snapshot.id};
    return UnifiedPayoutRequestModel.fromJson(dataWithId);
  }

  UnifiedPayoutRequestModel copyWith({
    String? id,
    String? workerId,
    String? workerName,
    double? earningsAmount,
    double? tipsAmount,
    double? bonusAmount,
    double? totalAmount,
    Map<String, dynamic>? payoutAccount,
    String? status,
    Timestamp? createdAt,
    Timestamp? approvedAt,
    Timestamp? rejectedAt,
    Timestamp? updatedAt,
    String? paymentProofUrl,
    String? transactionId,
    String? rejectionReason,
  }) {
    return UnifiedPayoutRequestModel(
      id: id ?? this.id,
      workerId: workerId ?? this.workerId,
      workerName: workerName ?? this.workerName,
      earningsAmount: earningsAmount ?? this.earningsAmount,
      tipsAmount: tipsAmount ?? this.tipsAmount,
      bonusAmount: bonusAmount ?? this.bonusAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      payoutAccount: payoutAccount ?? this.payoutAccount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paymentProofUrl: paymentProofUrl ?? this.paymentProofUrl,
      transactionId: transactionId ?? this.transactionId,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}

/// Payout History Model for tracking completed payouts
class PayoutHistoryModel {
  String? id;
  String? workerId;
  String? workerName;

  double? earningsAmount;
  double? tipsAmount;
  double? bonusAmount;
  double? totalAmount;

  Timestamp? completedAt;
  String? transactionId;
  String? paymentProofUrl;
  Map<String, dynamic>? payoutAccount;

  PayoutHistoryModel({
    this.id,
    this.workerId,
    this.workerName,
    this.earningsAmount,
    this.tipsAmount,
    this.bonusAmount,
    this.totalAmount,
    this.completedAt,
    this.transactionId,
    this.paymentProofUrl,
    this.payoutAccount,
  });

  factory PayoutHistoryModel.fromJson(Map<String, dynamic> json) {
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

    return PayoutHistoryModel(
      id: json['id'] as String?,
      workerId: json['workerId'] as String?,
      workerName: json['workerName'] as String?,
      earningsAmount: (json['earningsAmount'] as num?)?.toDouble(),
      tipsAmount: (json['tipsAmount'] as num?)?.toDouble(),
      bonusAmount: (json['bonusAmount'] as num?)?.toDouble(),
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
      completedAt: parseTimestamp(json['completedAt']),
      transactionId: json['transactionId'] as String?,
      paymentProofUrl: json['paymentProofUrl'] as String?,
      payoutAccount: json['payoutAccount'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workerId': workerId,
      'workerName': workerName,
      'earningsAmount': earningsAmount ?? 0.0,
      'tipsAmount': tipsAmount ?? 0.0,
      'bonusAmount': bonusAmount ?? 0.0,
      'totalAmount': totalAmount ?? 0.0,
      'completedAt': completedAt ?? Timestamp.now(),
      'transactionId': transactionId,
      'paymentProofUrl': paymentProofUrl,
      'payoutAccount': payoutAccount,
    };
  }

  factory PayoutHistoryModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>?;
    if (data == null) return PayoutHistoryModel();
    // Merge the document ID into the data
    final dataWithId = {...data, 'id': snapshot.id};
    return PayoutHistoryModel.fromJson(dataWithId);
  }
}
