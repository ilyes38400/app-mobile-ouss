import 'package:flutter/services.dart';
import 'package:mighty_fitness/models/program_purchase_models.dart';
import 'package:mighty_fitness/network/rest_api.dart';
import '../extensions/shared_pref.dart';
import '../main.dart';

class ProgramPurchaseService {
  static const MethodChannel _channel = MethodChannel('program_purchase');

  /// Vérifier l'accès utilisateur à un programme
  static Future<ProgramAccessData> checkAccess({
    required int programId,
    required String programType, // 'workout' ou 'mental'
  }) async {
    try {
      final userId = userStore.userId;
      final request = ProgramAccessCheckRequest(
        userId: userId,
        programId: programId,
        programType: programType,
      );

      final response = await checkProgramAccessApi(request);
      if (response.status) {
        return response.data;
      } else {
        throw Exception('Erreur lors de la vérification d\'accès');
      }
    } catch (e) {
      throw Exception('Erreur de vérification d\'accès: $e');
    }
  }

  /// Obtenir les programmes achetés par l'utilisateur
  static Future<List<UserPurchasedProgram>> getUserPurchases() async {
    try {
      final userId = userStore.userId;
      final response = await getUserPurchasedProgramsApi(userId);

      if (response.status) {
        return response.data;
      } else {
        return [];
      }
    } catch (e) {
      print('Erreur lors de la récupération des achats: $e');
      return [];
    }
  }

  /// Lancer le processus d'achat in-app
  static Future<bool> startPurchase({
    required int programId,
    required String programType,
    required String productId,
    required double price,
  }) async {
    try {
      // 1. Initier l'achat via la plateforme (Apple/Google)
      final purchaseResult = await _initiatePlatformPurchase(productId);

      if (purchaseResult['success'] == true) {
        // 2. Confirmer l'achat côté serveur
        final success = await _confirmPurchaseOnServer(
          programId: programId,
          programType: programType,
          transactionId: purchaseResult['transactionId'],
          productId: productId,
          price: price,
        );

        return success;
      }

      return false;
    } catch (e) {
      print('Erreur lors de l\'achat: $e');
      return false;
    }
  }

  /// Initie l'achat via la plateforme (Apple Store/Google Play)
  static Future<Map<String, dynamic>> _initiatePlatformPurchase(String productId) async {
    try {
      final result = await _channel.invokeMethod('startPurchase', {
        'productId': productId,
      });

      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      print('Erreur plateforme d\'achat: ${e.message}');
      return {'success': false, 'error': e.message};
    }
  }

  /// Confirme l'achat côté serveur
  static Future<bool> _confirmPurchaseOnServer({
    required int programId,
    required String programType,
    required String transactionId,
    required String productId,
    required double price,
  }) async {
    try {
      final userId = userStore.userId;
      final request = ProgramPurchaseRequest(
        userId: userId,
        programId: programId,
        programType: programType,
        platform: _getCurrentPlatform(),
        platformTransactionId: transactionId,
        platformProductId: productId,
        price: price,
        currency: 'EUR',
      );

      final response = await purchaseProgramApi(request);
      return response.status && (response.data?.accessGranted ?? false);
    } catch (e) {
      print('Erreur confirmation serveur: $e');
      return false;
    }
  }

  /// Détermine la plateforme actuelle
  static String _getCurrentPlatform() {
    // Pour Flutter, on peut détecter la plateforme
    try {
      if (const bool.fromEnvironment('dart.library.io')) {
        // Plateforme mobile
        return 'apple'; // Par défaut, on peut améliorer la détection
      }
      return 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }

  /// Vérifier si un programme nécessite un achat
  static bool requiresPurchase(String? programType, bool? userHasAccess, bool? requiresPurchase) {
    return programType == 'paid' &&
           (userHasAccess == false || userHasAccess == null) &&
           (requiresPurchase == true);
  }

  /// Vérifier si un programme nécessite un abonnement
  static bool requiresSubscription(String? programType, bool? userHasAccess, bool? requiresSubscription) {
    return programType == 'premium' &&
           (userHasAccess == false || userHasAccess == null) &&
           (requiresSubscription == true);
  }

  /// Obtenir le texte d'action selon le type de programme
  static String getActionText(String? programType, bool? userHasAccess, double? price) {
    if (userHasAccess == true) {
      return 'Accéder';
    }

    switch (programType) {
      case 'free':
        return 'Gratuit';
      case 'premium':
        return 'Abonnement requis';
      case 'paid':
        return price != null ? '${price.toStringAsFixed(2)} €' : 'Acheter';
      default:
        return 'Accéder';
    }
  }

  /// Obtenir la couleur du bouton selon le statut
  static int getButtonColor(String? programType, bool? userHasAccess) {
    if (userHasAccess == true) {
      return 0xFF4CAF50; // Vert
    }

    switch (programType) {
      case 'free':
        return 0xFF4CAF50; // Vert
      case 'premium':
        return 0xFFFF9800; // Orange
      case 'paid':
        return 0xFF2196F3; // Bleu
      default:
        return 0xFF9E9E9E; // Gris
    }
  }
}