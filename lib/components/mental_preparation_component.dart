import 'package:flutter/material.dart';
import 'package:mighty_fitness/extensions/extension_util/context_extensions.dart';
import 'package:mighty_fitness/extensions/extension_util/string_extensions.dart';
import 'package:mighty_fitness/extensions/extension_util/widget_extensions.dart';
import 'package:mighty_fitness/extensions/decorations.dart';
import 'package:mighty_fitness/extensions/text_styles.dart';
import 'package:mighty_fitness/models/mental_preparation_response.dart';
import 'package:mighty_fitness/utils/app_colors.dart';
import 'package:mighty_fitness/components/program_type_badge.dart';
import 'package:mighty_fitness/components/program_access_button.dart';

import '../utils/app_common.dart';

class MentalPreparationComponent extends StatefulWidget {
  final MentalPreparation item;
  final VoidCallback? onTap;
  final VoidCallback? onAccessChanged;

  const MentalPreparationComponent({
    Key? key,
    required this.item,
    this.onTap,
    this.onAccessChanged,
  }) : super(key: key);

  @override
  _MentalPreparationComponentState createState() => _MentalPreparationComponentState();
}

class _MentalPreparationComponentState extends State<MentalPreparationComponent> {
  late MentalPreparation _item;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  @override
  Widget build(BuildContext context) {
    final width = context.width() * 0.72;
    const height = 180.0;

    return Stack(
      children: [
        // Image de fond
        cachedImage(
          _item.imageUrl ?? '',
          width: width,
          height: height,
          fit: BoxFit.cover,
        ).cornerRadiusWithClipRRect(16),

        // Overlay sombre
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(16),
          ),
        ),

        // Badge de type de programme
        Positioned(
          top: 12,
          left: 12,
          child: Builder(
            builder: (context) {
              print("🧠 DEBUG MentalPreparationComponent Badge:");
              print("   - title: ${_item.title}");
              print("   - programType: ${_item.programType}");
              print("   - userHasAccess: ${_item.userHasAccess}");
              print("   - price: ${_item.price}");

              return ProgramTypeBadge(
                programType: _item.programType,
                price: _item.price,
                userHasAccess: _item.userHasAccess,
              );
            }
          ),
        ),

        // Titre en bas à gauche
        Positioned(
          left: 16,
          bottom: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _item.title.capitalizeFirstLetter(),
                style: boldTextStyle(color: Colors.white),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    )
        .onTap(_handleTap)
        .paddingRight(12);
  }

  void _handleTap() {
    if (_item.userHasAccess == true || _item.programType == 'free') {
      // L'utilisateur a accès OU c'est un programme gratuit, navigation normale
      if (widget.onTap != null) {
        widget.onTap!();
      }
    } else {
      // L'utilisateur n'a pas accès, montrer le dialog
      _showAccessDialog();
    }
  }

  void _showAccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Accès requis'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Cette préparation mentale "${_item.title}" nécessite un accès spécial.'),
              SizedBox(height: 16),
              ProgramAccessButton(
                programId: _item.id,
                programType: 'mental', // Backend attend exactement 'mental'
                accessType: _item.programType,
                price: _item.price,
                userHasAccess: _item.userHasAccess,
                requiresPurchase: _item.requiresPurchase,
                requiresSubscription: _item.requiresSubscription,
                programTitle: _item.title,
                onAccessGranted: () {
                  Navigator.of(dialogContext).pop();
                  // Mettre à jour le modèle pour refléter l'accès
                  setState(() {
                    _item = MentalPreparation(
                      id: _item.id,
                      title: _item.title,
                      slug: _item.slug,
                      description: _item.description,
                      videoType: _item.videoType,
                      videoUrl: _item.videoUrl,
                      status: _item.status,
                      imageUrl: _item.imageUrl,
                      programType: _item.programType,
                      price: _item.price,
                      userHasAccess: true, // Mise à jour de l'accès
                      accessReason: 'purchased',
                      requiresPurchase: false,
                      requiresSubscription: false,
                    );
                  });
                  if (widget.onAccessChanged != null) {
                    widget.onAccessChanged!();
                  }
                  if (widget.onTap != null) {
                    widget.onTap!();
                  }
                },
                onAccessDenied: () {
                  Navigator.of(dialogContext).pop();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Annuler'),
            ),
          ],
        );
      },
    );
  }
}