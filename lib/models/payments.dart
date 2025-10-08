class Payments {
  final String? id;
  final String? date;
  final String? amount;
  final String? payerId;
  final String? jobId;
  final String? payeeId;
  final String? paymentType;
  final String? type;
  final String? status;

  Payments(
    this.payerId,
    this.jobId,
    this.payeeId,
    this.paymentType,
    this.type,
    this.status, {
    this.id,
    this.date,
    this.amount,
  });

  Payments.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      date = json['date'],
      amount = json['amount'],
      payerId = json['payerId'],
      jobId = json['jobId'],
      payeeId = json['payeeId'],
      paymentType = json['paymentType'],
      type = json['type'],
      status = json['status'];

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'amount': amount,
    'payerId': payerId,
    'jobId': jobId,
    'payeeId': payeeId,
    'paymentType': paymentType,
    'type': type,
    'status': status,
  };

  @override
  String toString() {
    return 'Payments{id: $id, date: $date, amount: $amount, payerId: $payerId, jobId: $jobId, payeeId: $payeeId, paymentType: $paymentType, type: $type, status: $status}';
  }

  Map<String, dynamic> toEditJson({required Payments previous}) {
    Map<String, dynamic> json = {
      'id': id,
      'date': date,
      'amount': amount,
      'payerId': payerId,
      'jobId': jobId,
      'payeeId': payeeId,
      'paymentType': paymentType,
      'type': type,
      'status': status,
    };

    return json;
  }
}
