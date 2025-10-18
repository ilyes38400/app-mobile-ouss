import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:mighty_fitness/extensions/extension_util/widget_extensions.dart';
import 'package:mighty_fitness/extensions/extension_util/context_extensions.dart';
import 'package:mighty_fitness/extensions/loader_widget.dart';
import 'package:mighty_fitness/extensions/text_styles.dart';
import 'package:mighty_fitness/extensions/decorations.dart';
import 'package:mighty_fitness/network/rest_api.dart';
import 'package:mighty_fitness/utils/app_colors.dart';
import 'package:mighty_fitness/extensions/extension_util/string_extensions.dart';
import 'package:mighty_fitness/extensions/extension_util/int_extensions.dart';
import 'package:mighty_fitness/extensions/app_button.dart';
import 'package:mighty_fitness/utils/app_common.dart';
import 'package:mighty_fitness/utils/app_constants.dart';
import 'package:mighty_fitness/extensions/widgets.dart';
import 'package:mighty_fitness/main.dart';

class ProgramPaymentScreen extends StatefulWidget {
  final int programId;
  final String programTitle;
  final String programType;
  final double price;

  const ProgramPaymentScreen({
    Key? key,
    required this.programId,
    required this.programTitle,
    required this.programType,
    required this.price,
  }) : super(key: key);

  @override
  _ProgramPaymentScreenState createState() => _ProgramPaymentScreenState();
}

class _ProgramPaymentScreenState extends State<ProgramPaymentScreen> {
  bool _isProcessing = false;
  bool _isInitialized = false;
  String? _selectedPaymentMethod = 'stripe';
  String? stripPaymentPublishKey;

  @override
  void initState() {
    super.initState();
    print("🏃 DEBUG ProgramPaymentScreen initState:");
    print("   - programId: ${widget.programId}");
    print("   - programTitle: ${widget.programTitle}");
    print("   - programType: '${widget.programType}' (length: ${widget.programType.length})");
    print("   - price: ${widget.price}");
    _initializeStripe();
  }

  Future<void> _initializeStripe() async {
    try {
      // Récupérer la configuration de paiement comme dans PaymentScreen
      final paymentList = await getPaymentApi();

      // Trouver la configuration Stripe
      final stripeConfig = paymentList.data?.firstWhere(
        (element) => element.type == PAYMENT_TYPE_STRIPE,
        orElse: () => throw Exception('Configuration Stripe non trouvée'),
      );

      if (stripeConfig != null) {
        stripPaymentPublishKey = stripeConfig.isTest == 1
          ? stripeConfig.testValue?.publishableKey
          : stripeConfig.liveValue?.publishableKey;

        if (stripPaymentPublishKey != null) {
          Stripe.publishableKey = stripPaymentPublishKey!;
          Stripe.merchantIdentifier = 'IN'; // Ou ton merchant identifier
          await Stripe.instance.applySettings();

          setState(() {
            _isInitialized = true;
          });
        }
      }
    } catch (e) {
      print('Erreur initialisation Stripe: $e');
      _showErrorDialog('Erreur de configuration du paiement');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: appBarWidget('Acheter le programme', context: context),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      appBar: appBarWidget(
        'Acheter le programme',
        context: context,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informations du programme
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                    decoration: boxDecorationWithRoundedCorners(
                      backgroundColor: context.cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.fitness_center,
                              color: primaryColor,
                              size: 24,
                            ),
                            12.width,
                            Expanded(
                              child: Text(
                                widget.programTitle,
                                style: boldTextStyle(size: 18),
                              ),
                            ),
                          ],
                        ),
                        16.height,
                        Row(
                          children: [
                            Text(
                              'Type: ',
                              style: secondaryTextStyle(),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: boxDecorationWithRoundedCorners(
                                backgroundColor: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                widget.programType.capitalizeFirstLetter(),
                                style: primaryTextStyle(
                                  color: primaryColor,
                                  size: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        12.height,
                        Row(
                          children: [
                            Text(
                              'Prix: ',
                              style: secondaryTextStyle(),
                            ),
                            Text(
                              '${widget.price.toStringAsFixed(2)} €',
                              style: boldTextStyle(
                                color: primaryColor,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  24.height,

                  // Méthodes de paiement
                  Text(
                    'Méthode de paiement',
                    style: boldTextStyle(size: 16),
                  ),

                  16.height,

                  // Stripe (Carte bancaire)
                  Container(
                    decoration: boxDecorationWithRoundedCorners(
                      border: Border.all(
                        color: _selectedPaymentMethod == 'stripe'
                          ? primaryColor
                          : Colors.grey.withOpacity(0.3),
                        width: _selectedPaymentMethod == 'stripe' ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.credit_card,
                        color: primaryColor,
                      ),
                      title: Text(
                        'Carte bancaire',
                        style: primaryTextStyle(),
                      ),
                      subtitle: Text(
                        'Paiement sécurisé par Stripe',
                        style: secondaryTextStyle(size: 12),
                      ),
                      trailing: Radio<String>(
                        value: 'stripe',
                        groupValue: _selectedPaymentMethod,
                        onChanged: (value) {
                          setState(() {
                            _selectedPaymentMethod = value;
                          });
                        },
                        activeColor: primaryColor,
                      ),
                      onTap: () {
                        setState(() {
                          _selectedPaymentMethod = 'stripe';
                        });
                      },
                    ),
                  ),

                  24.height,

                  // Informations de sécurité
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: boxDecorationWithRoundedCorners(
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.security,
                          color: Colors.blue,
                          size: 20,
                        ),
                        12.width,
                        Expanded(
                          child: Text(
                            'Paiement 100% sécurisé. Vos données bancaires sont protégées par le cryptage SSL.',
                            style: secondaryTextStyle(size: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bouton de paiement
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.cardColor,
              border: Border(
                top: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: AppButton(
              text: _isProcessing
                ? 'Traitement...'
                : 'Payer ${widget.price.toStringAsFixed(2)} €',
              color: primaryColor,
              onTap: _isProcessing ? null : _handlePayment,
              width: double.infinity,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePayment() async {
    if (_selectedPaymentMethod != 'stripe') return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // 1. Créer un PaymentIntent via le backend
      final paymentIntentResponse = await _createProgramPaymentIntent();

      if (paymentIntentResponse['client_secret'] != null) {
        // 2. Lancer le processus de paiement Stripe
        final paymentSuccess = await _processStripePayment(
          paymentIntentResponse['client_secret'],
        );

        if (paymentSuccess) {
          // 3. Confirmer l'achat côté serveur
          final confirmationSuccess = await _confirmProgramPurchase(
            paymentIntentResponse['payment_intent_id'],
          );

          if (confirmationSuccess) {
            _showSuccessDialog();
          } else {
            _showErrorDialog('Erreur lors de la confirmation de l\'achat');
          }
        }
      } else {
        _showErrorDialog('Impossible de créer la demande de paiement');
      }
    } catch (e) {
      _showErrorDialog('Erreur lors du paiement: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>> _createProgramPaymentIntent() async {
    final Map<String, dynamic> requestBody = {
      'program_id': widget.programId,
      'program_type': widget.programType,
      'amount': (widget.price * 100).toInt(), // Convertir en centimes
      'currency': 'eur',
      'description': 'Achat du programme ${widget.programTitle}',
    };

    print("💳 DEBUG _createProgramPaymentIntent:");
    print("   - programId: ${widget.programId}");
    print("   - programType: ${widget.programType}");
    print("   - programTitle: ${widget.programTitle}");
    print("   - price: ${widget.price}");
    print("   - amount (centimes): ${(widget.price * 100).toInt()}");
    print("   - requestBody: $requestBody");

    try {
      final response = await createProgramPaymentIntentApi(requestBody);
      print("💳 DEBUG Response createProgramPaymentIntent: $response");
      return response;
    } catch (e) {
      print("❌ DEBUG Erreur createProgramPaymentIntent: $e");
      rethrow;
    }
  }

  Future<bool> _processStripePayment(String clientSecret) async {
    try {
      // Initialiser le PaymentSheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'My Fitness App',
          allowsDelayedPaymentMethods: true,
          style: appStore.isDarkMode ? ThemeMode.dark : ThemeMode.light,
        ),
      );

      // Présenter le PaymentSheet
      await Stripe.instance.presentPaymentSheet();

      return true;
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        // L'utilisateur a annulé
        return false;
      }
      throw Exception('Erreur Stripe: ${e.error.localizedMessage}');
    }
  }

  Future<bool> _confirmProgramPurchase(String paymentIntentId) async {
    final Map<String, dynamic> requestBody = {
      'program_id': widget.programId,
      'program_type': widget.programType,
      'payment_intent_id': paymentIntentId,
    };

    final response = await confirmProgramPurchaseApi(requestBody);
    return response['success'] == true;
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              12.width,
              Text('Achat réussi !'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Félicitations ! Vous avez maintenant accès au programme :'),
              8.height,
              Text(
                '"${widget.programTitle}"',
                style: boldTextStyle(color: primaryColor),
              ),
              16.height,
              Text(
                'Vous pouvez maintenant commencer votre entraînement !',
                style: secondaryTextStyle(),
              ),
            ],
          ),
          actions: [
            AppButton(
              text: 'Commencer',
              color: primaryColor,
              onTap: () {
                Navigator.of(context).pop(); // Fermer le dialog
                Navigator.of(context).pop(true); // Retourner à l'écran précédent avec succès
              },
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 28),
              12.width,
              Text('Erreur'),
            ],
          ),
          content: Text(message),
          actions: [
            AppButton(
              text: 'OK',
              color: Colors.grey,
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}