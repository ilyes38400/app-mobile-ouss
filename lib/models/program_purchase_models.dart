// Modèles pour la gestion des achats de programmes

class ProgramPurchaseRequest {
  final int userId;
  final int programId;
  final String programType; // 'workout' ou 'mental'
  final String platform; // 'apple' ou 'google'
  final String platformTransactionId;
  final String platformProductId;
  final double price;
  final String currency;

  ProgramPurchaseRequest({
    required this.userId,
    required this.programId,
    required this.programType,
    required this.platform,
    required this.platformTransactionId,
    required this.platformProductId,
    required this.price,
    required this.currency,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'program_id': programId,
      'program_type': programType,
      'platform': platform,
      'platform_transaction_id': platformTransactionId,
      'platform_product_id': platformProductId,
      'price': price,
      'currency': currency,
    };
  }
}

class ProgramPurchaseResponse {
  final bool status;
  final String message;
  final ProgramPurchaseData? data;

  ProgramPurchaseResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory ProgramPurchaseResponse.fromJson(Map<String, dynamic> json) {
    return ProgramPurchaseResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? ProgramPurchaseData.fromJson(json['data'])
          : null,
    );
  }
}

class ProgramPurchaseData {
  final int purchaseId;
  final String programTitle;
  final bool accessGranted;

  ProgramPurchaseData({
    required this.purchaseId,
    required this.programTitle,
    required this.accessGranted,
  });

  factory ProgramPurchaseData.fromJson(Map<String, dynamic> json) {
    return ProgramPurchaseData(
      purchaseId: json['purchase_id'] ?? 0,
      programTitle: json['program_title'] ?? '',
      accessGranted: json['access_granted'] ?? false,
    );
  }
}

class ProgramAccessCheckRequest {
  final int userId;
  final int programId;
  final String programType; // 'workout' ou 'mental'

  ProgramAccessCheckRequest({
    required this.userId,
    required this.programId,
    required this.programType,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'program_id': programId,
      'program_type': programType,
    };
  }
}

class ProgramAccessCheckResponse {
  final bool status;
  final ProgramAccessData data;

  ProgramAccessCheckResponse({
    required this.status,
    required this.data,
  });

  factory ProgramAccessCheckResponse.fromJson(Map<String, dynamic> json) {
    return ProgramAccessCheckResponse(
      status: json['status'] ?? false,
      data: ProgramAccessData.fromJson(json['data'] ?? {}),
    );
  }
}

class ProgramAccessData {
  final int programId;
  final String programType;
  final String programTitle;
  final String programAccessType;
  final double? price;
  final bool hasAccess;
  final String accessReason;
  final bool requiresPurchase;
  final bool requiresSubscription;

  ProgramAccessData({
    required this.programId,
    required this.programType,
    required this.programTitle,
    required this.programAccessType,
    this.price,
    required this.hasAccess,
    required this.accessReason,
    required this.requiresPurchase,
    required this.requiresSubscription,
  });

  factory ProgramAccessData.fromJson(Map<String, dynamic> json) {
    return ProgramAccessData(
      programId: json['program_id'] ?? 0,
      programType: json['program_type'] ?? '',
      programTitle: json['program_title'] ?? '',
      programAccessType: json['program_access_type'] ?? '',
      price: json['price'] != null ? double.tryParse(json['price'].toString()) : null,
      hasAccess: json['has_access'] ?? false,
      accessReason: json['access_reason'] ?? '',
      requiresPurchase: json['requires_purchase'] ?? false,
      requiresSubscription: json['requires_subscription'] ?? false,
    );
  }
}

class UserPurchasedProgram {
  final int id;
  final int programId;
  final String programType;
  final String programTitle;
  final String purchaseDate;
  final double price;
  final String currency;
  final String status;

  UserPurchasedProgram({
    required this.id,
    required this.programId,
    required this.programType,
    required this.programTitle,
    required this.purchaseDate,
    required this.price,
    required this.currency,
    required this.status,
  });

  factory UserPurchasedProgram.fromJson(Map<String, dynamic> json) {
    return UserPurchasedProgram(
      id: json['id'] ?? 0,
      programId: json['program_id'] ?? 0,
      programType: json['program_type'] ?? '',
      programTitle: json['program_title'] ?? '',
      purchaseDate: json['purchase_date'] ?? '',
      price: json['price'] != null ? double.tryParse(json['price'].toString()) ?? 0.0 : 0.0,
      currency: json['currency'] ?? '',
      status: json['status'] ?? '',
    );
  }
}

class UserPurchasedProgramsResponse {
  final bool status;
  final List<UserPurchasedProgram> data;

  UserPurchasedProgramsResponse({
    required this.status,
    required this.data,
  });

  factory UserPurchasedProgramsResponse.fromJson(Map<String, dynamic> json) {
    var dataList = json['data'] as List? ?? [];
    List<UserPurchasedProgram> programs = dataList
        .map((item) => UserPurchasedProgram.fromJson(item))
        .toList();

    return UserPurchasedProgramsResponse(
      status: json['status'] ?? false,
      data: programs,
    );
  }
}