import 'package:flutter/foundation.dart';

import 'payment_service.dart';

enum PaymentMethod { waafi, card, applePay, paypal, cashOnDelivery }

class PaymentProvider extends ChangeNotifier {
  PaymentProvider({PaymentService paymentService = const PaymentService()})
    : _paymentService = paymentService;

  final PaymentService _paymentService;

  bool _isProcessing = false;
  String? _errorMessage;
  WaafiPaymentResult? _lastWaafiResult;

  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  WaafiPaymentResult? get lastWaafiResult => _lastWaafiResult;

  Future<WaafiPaymentResult> initiateWaafiPayment({
    required String orderId,
    required String userId,
    required double amount,
    required String mobileNumber,
    String? description,
  }) async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _paymentService.initiateWaafiPayment(
        orderId: orderId,
        userId: userId,
        amount: amount,
        mobileNumber: mobileNumber,
        description: description,
      );
      _lastWaafiResult = result;
      if (!result.success) {
        _errorMessage = result.message ?? 'WaafiPay payment failed.';
      }
      return result;
    } catch (error) {
      _errorMessage = error.toString();
      return WaafiPaymentResult(success: false, message: _errorMessage);
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  void reset() {
    _isProcessing = false;
    _errorMessage = null;
    _lastWaafiResult = null;
    notifyListeners();
  }
}
