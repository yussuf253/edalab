import '../core/network/api_client.dart';

class WaafiPaymentResult {
  const WaafiPaymentResult({
    required this.success,
    this.referenceId,
    this.transactionId,
    this.paymentUrl,
    this.responseCode,
    this.message,
    this.raw,
  });

  final bool success;
  final String? referenceId;
  final String? transactionId;
  final String? paymentUrl;
  final String? responseCode;
  final String? message;
  final Map<String, dynamic>? raw;

  factory WaafiPaymentResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final params = data is Map ? data['params'] : null;
    return WaafiPaymentResult(
      success: json['success'] == true,
      referenceId: json['referenceId']?.toString(),
      transactionId:
          json['transactionId']?.toString() ??
          (params is Map ? params['transactionId']?.toString() : null),
      paymentUrl:
          json['paymentUrl']?.toString() ??
          (params is Map ? params['directPaymentLink']?.toString() : null),
      responseCode: json['responseCode']?.toString(),
      message:
          json['responseMessage']?.toString() ?? json['message']?.toString(),
      raw: json,
    );
  }
}

class PaymentService {
  const PaymentService();

  Future<WaafiPaymentResult> initiateWaafiPayment({
    required String orderId,
    required String userId,
    required double amount,
    String? description,
  }) async {
    final response = await ApiClient.post('/payments/waafipay/initiate', {
      'orderId': orderId,
      'userId': userId,
      'amount': amount,
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
    });

    if (response is Map) {
      return WaafiPaymentResult.fromJson(Map<String, dynamic>.from(response));
    }
    return const WaafiPaymentResult(
      success: false,
      message: 'Unexpected payment response.',
    );
  }
}
