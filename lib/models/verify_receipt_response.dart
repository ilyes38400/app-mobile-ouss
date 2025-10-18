class VerifyReceiptResponse {
  bool? status;
  String? message;

  VerifyReceiptResponse({this.status, this.message});

  factory VerifyReceiptResponse.fromJson(Map<String, dynamic> json) {
    return VerifyReceiptResponse(
      status: json['status'],
      message: json['message'],
    );
  }
}
