class UserProfileResponse {
  bool? status;       // "status": true/false (bool)
  int? isSubscribe;   // "is_subscribe": 0 ou 1 (int)


  UserProfileResponse({
    this.status,
    this.isSubscribe,

  });

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) {
    return UserProfileResponse(
      status: json['status'] as bool?,          // parse en bool?
      isSubscribe: json['is_subscribe'] as int?,// parse en int?
      // message: json['message'] as String?,
      // id: json['id'] as int?,
      // email: json['email'] as String?,
    );
  }
}
