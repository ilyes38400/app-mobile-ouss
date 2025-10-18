import 'dart:developer';

class SubscriptionPaymentIntentResponse {
  String? purchaseId;
  String? productId;
  String? transactionDate;
  String? platform;
  String? userId;

  SubscriptionPaymentIntentResponse({
    this.purchaseId,
    this.productId,
    this.transactionDate,
    this.platform,
    this.userId,
  });

  SubscriptionPaymentIntentResponse.fromJson(Map<String, dynamic> json) {
    log('Parsing JSON: $json');
    purchaseId = json['purchase_id'];
    productId = json['product_id'];
    transactionDate = json['transaction_date'];
    platform = json['platform'];
    userId = json['user_id'];
    log('Parsed purchaseId: $purchaseId, productId: $productId, transactionDate: $transactionDate, platform: $platform, userId: $userId');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'purchase_id': purchaseId,
      'product_id': productId,
      'transaction_date': transactionDate,
      'platform': platform,
      'user_id': userId,
    };
    log('Converted to JSON: $data');
    return data;
  }
}
