import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';

class PaymentService {
  late final CFPaymentGatewayService _pgService;
  
  // Callbacks
  Function()? onSuccess;
  Function(String)? onError;

  PaymentService() {
    _pgService = CFPaymentGatewayService();
    // Cashfree SDK callback
    _pgService.setCallback(_handlePaymentVerify, _handlePaymentError);
  }

  void dispose() {
    // No specific dispose required for Cashfree
  }

  int _currentPlanDays = 0;

  // Opens the cashfree checkout
  Future<void> openCheckout({
    required int amountInRupees,
    required String name,
    required String description,
    required int planDays,
    String? email,
  }) async {
    _currentPlanDays = planDays;
    
    try {
      // 1. Call Firebase Function to create order and get session_id
      final result = await FirebaseFunctions.instance.httpsCallable('createCashfreeOrder').call({
        'amount': amountInRupees,
        'email': email ?? 'supportmessbuddy@gmail.com',
        'customer_id': 'user_${DateTime.now().millisecondsSinceEpoch}', 
      });

      final String sessionId = result.data['payment_session_id'];
      final String orderId = result.data['order_id'];

      // 2. Launch Cashfree SDK
      var session = CFSessionBuilder()
          .setEnvironment(kDebugMode ? CFEnvironment.SANDBOX : CFEnvironment.PRODUCTION) 
          .setPaymentSessionId(sessionId)
          .setOrderId(orderId)
          .build();

      var webCheckout = CFWebCheckoutPaymentBuilder()
          .setSession(session)
          .build();

      _pgService.doPayment(webCheckout);
      
    } catch (e) {
      onError?.call("Error launching payment gateway: $e");
    }
  }

  // SDK calls this when user completes payment
  void _handlePaymentVerify(String orderId) async {
    try {
       // 3. Verify status on server
       await FirebaseFunctions.instance.httpsCallable('redeemPremiumWithCash').call({
         'planDays': _currentPlanDays,
         'orderId': orderId,
       });
       onSuccess?.call();
    } catch (e) {
       onError?.call("Failed to update premium status: $e");
    }
  }

  // SDK calls this on error/cancellation
  void _handlePaymentError(CFErrorResponse errorResponse, String orderId) {
    final message = errorResponse.getMessage() ?? "Payment Failed or Cancelled";
    if (kDebugMode) {
      print("PAYMENT ERROR: $message for Order: $orderId");
    }
    onError?.call(message);
  }
}
