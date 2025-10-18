import 'package:flutter/material.dart';

class ProgramTypeBadge extends StatelessWidget {
  final String? programType;
  final double? price;
  final bool? userHasAccess;
  final bool hideForMonthlyProgram;
  final bool showMonthlyBadge;

  const ProgramTypeBadge({
    Key? key,
    this.programType,
    this.price,
    this.userHasAccess,
    this.hideForMonthlyProgram = false,
    this.showMonthlyBadge = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print("🎯 DEBUG ProgramTypeBadge:");
    print("   - programType: $programType");
    print("   - userHasAccess: $userHasAccess (type: ${userHasAccess.runtimeType})");
    print("   - price: $price");
    print("   - hideForMonthlyProgram: $hideForMonthlyProgram");

    // 1. Cacher badge pour programmes du mois dans leur section dédiée
    if (hideForMonthlyProgram) {
      print("   📅 Section programme du mois → AUCUN BADGE");
      return const SizedBox.shrink();
    }

    // 2. Afficher badge "Programme du mois" si demandé
    if (showMonthlyBadge) {
      print("   ⭐ Affichage badge PROGRAMME DU MOIS");
      return _buildMonthlyBadge();
    }

    // 3. Programmes gratuits ou avec accès → PAS DE BADGE
    if (userHasAccess == true || programType == 'free') {
      print("   ✅ Accès ou gratuit → AUCUN BADGE");
      return const SizedBox.shrink();
    }

    switch (programType) {
      case 'premium':
        print("   ⭐ Affichage badge PREMIUM");
        return _buildBadge(
          text: 'PREMIUM',
          color: Colors.orange,
          icon: Icons.star,
        );
      case 'paid':
        print("   🛒 Affichage icône panier (programme payant)");
        return _buildBadge(
          text: '', // Pas de texte, juste l'icône
          color: Colors.blue,
          icon: Icons.shopping_cart,
          iconOnly: true, // Nouvelle propriété
          solidBackground: true, // Fond plein bleu
        );
      default:
        print("   ❓ Type non reconnu, aucun badge");
        return const SizedBox.shrink();
    }
  }

  Widget _buildBadge({
    required String text,
    required Color color,
    required IconData icon,
    bool iconOnly = false,
    bool solidBackground = false,
  }) {
    return Container(
      padding: iconOnly
        ? const EdgeInsets.all(8)
        : const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: solidBackground ? color : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(iconOnly ? 20 : 12),
        border: solidBackground ? null : Border.all(color: color, width: 1),
      ),
      child: iconOnly
        ? Icon(
            icon,
            size: 16,
            color: solidBackground ? Colors.white : color,
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                text,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildMonthlyBadge() {
    const goldColor = Color(0xFFFFD700);
    const darkGoldColor = Color(0xFFB8860B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [goldColor, darkGoldColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: goldColor.withOpacity(0.4),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            'Programme du mois',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}