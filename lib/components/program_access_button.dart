import 'package:flutter/material.dart';
import 'package:mighty_fitness/services/program_purchase_service.dart';
import '../screens/subscribe_screen.dart';
import '../screens/program_payment_screen.dart';

class ProgramAccessButton extends StatefulWidget {
  final int programId;
  final String programType; // 'workout' ou 'mental'
  final String? accessType; // 'free', 'premium', 'paid'
  final double? price;
  final bool? userHasAccess;
  final bool? requiresPurchase;
  final bool? requiresSubscription;
  final String programTitle;
  final VoidCallback? onAccessGranted;
  final VoidCallback? onAccessDenied;

  const ProgramAccessButton({
    Key? key,
    required this.programId,
    required this.programType,
    required this.programTitle,
    this.accessType,
    this.price,
    this.userHasAccess,
    this.requiresPurchase,
    this.requiresSubscription,
    this.onAccessGranted,
    this.onAccessDenied,
  }) : super(key: key);

  @override
  _ProgramAccessButtonState createState() => _ProgramAccessButtonState();
}

class _ProgramAccessButtonState extends State<ProgramAccessButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final buttonText = ProgramPurchaseService.getActionText(
      widget.accessType,
      widget.userHasAccess,
      widget.price,
    );

    final buttonColor = Color(ProgramPurchaseService.getButtonColor(
      widget.accessType,
      widget.userHasAccess,
    ));

    return Container(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleButtonPress,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _getIconForType(),
                  const SizedBox(width: 8),
                  Text(
                    buttonText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _getIconForType() {
    if (widget.userHasAccess == true) {
      return const Icon(Icons.play_arrow, size: 20);
    }

    switch (widget.accessType) {
      case 'free':
        return const Icon(Icons.play_arrow, size: 20);
      case 'premium':
        return const Icon(Icons.star, size: 20);
      case 'paid':
        return const Icon(Icons.shopping_cart, size: 20);
      default:
        return const Icon(Icons.lock, size: 20);
    }
  }

  void _handleButtonPress() async {
    print('🔘 ProgramAccessButton: Bouton pressé');
    print('🔘 AccessType: ${widget.accessType}');
    print('🔘 UserHasAccess: ${widget.userHasAccess}');
    print('🔘 Price: ${widget.price}');
    print('🔘 ProgramTitle: ${widget.programTitle}');

    if (widget.userHasAccess == true) {
      print('🔘 L\'utilisateur a déjà accès');
      widget.onAccessGranted?.call();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.accessType == 'free') {
        print('🔘 Programme gratuit');
        widget.onAccessGranted?.call();
      } else if (widget.accessType == 'premium') {
        print('🔘 Programme premium - redirection vers abonnement');
        _showSubscriptionDialog();
      } else if (widget.accessType == 'paid') {
        print('🔘 Programme payant - lancement de l\'achat');
        await _handlePurchase();
      } else {
        print('🔘 Type non reconnu, accès refusé');
        widget.onAccessDenied?.call();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSubscriptionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Abonnement requis'),
          content: Text(
            'Ce programme "${widget.programTitle}" nécessite un abonnement premium pour y accéder.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SubscribeScreen(),
                  ),
                );
              },
              child: Text('S\'abonner'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handlePurchase() async {
    print('💳 _handlePurchase: Début de l\'achat');
    print('💳 ProgramId: ${widget.programId}');
    print('💳 ProgramTitle: ${widget.programTitle}');
    print('💳 ProgramType: ${widget.programType}');
    print('💳 Price: ${widget.price}');

    try {
      print('💳 Navigation vers ProgramPaymentScreen...');
      // Naviguer vers l'écran de paiement dédié aux programmes
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProgramPaymentScreen(
            programId: widget.programId,
            programTitle: widget.programTitle,
            programType: widget.programType,
            price: widget.price ?? 0.0,
          ),
        ),
      );

      print('💳 Retour de ProgramPaymentScreen avec result: $result');

      // Si le paiement est réussi
      if (result == true) {
        print('💳 Paiement réussi, appel de onAccessGranted');
        widget.onAccessGranted?.call();
      } else {
        print('💳 Paiement échoué ou annulé');
      }
    } catch (e) {
      print('💳 Erreur dans _handlePurchase: $e');
      _showErrorDialog('Erreur lors de l\'achat: $e');
      widget.onAccessDenied?.call();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Achat réussi'),
            ],
          ),
          content: Text(
            'Vous avez maintenant accès au programme "${widget.programTitle}".',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
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
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('Erreur'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}