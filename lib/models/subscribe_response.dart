class SubscribeResponse {
  bool? status;
  String? message;

  SubscribeResponse({this.status, this.message});

  factory SubscribeResponse.fromJson(Map<String, dynamic> json) {
    return SubscribeResponse(
      status: json['status'],
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (status != null) data['status'] = status;
    if (message != null) data['message'] = message;
    return data;
  }
}
