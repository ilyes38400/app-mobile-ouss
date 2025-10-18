import 'package:flutter/material.dart';
import '../utils/app_images.dart';
import '../../extensions/colors.dart';
import '../../extensions/decorations.dart';
import '../../extensions/extension_util/context_extensions.dart';
import '../../extensions/extension_util/int_extensions.dart';
import '../../extensions/extension_util/string_extensions.dart';
import '../../extensions/extension_util/widget_extensions.dart';
import '../../utils/app_colors.dart';
import '../extensions/text_styles.dart';
import '../main.dart';
import '../models/workout_detail_response.dart';
import '../network/rest_api.dart';
import '../screens/subscribe_screen.dart';
import '../screens/workout_detail_screen.dart';
import '../utils/app_common.dart';
import 'program_type_badge.dart';
import 'program_access_button.dart';

class WorkoutComponent extends StatefulWidget {
  final WorkoutDetailModel? mWorkoutModel;
  final Function? onCall;
  final bool isView;
  final bool isMonthlyProgram;
  final bool isActuallyMonthlyProgram;

  WorkoutComponent({this.mWorkoutModel, this.onCall, this.isView = false, this.isMonthlyProgram = false, this.isActuallyMonthlyProgram = false});

  @override
  _WorkoutComponentState createState() => _WorkoutComponentState();
}

class _WorkoutComponentState extends State<WorkoutComponent> {
  Future<void> setWorkout(int? id) async {
    appStore.setLoading(true);
    Map req = {"workout_id": id};
    await setWorkoutFavApi(req).then((value) {
      toast(value.message);
      appStore.setLoading(false);
      if (widget.mWorkoutModel!.isFavourite == 1) {
        widget.mWorkoutModel!.isFavourite = 0;
      } else {
        widget.mWorkoutModel!.isFavourite = 1;
      }
      appStore.setLoading(false);
      widget.onCall!.call();
      setState(() {});
    }).catchError((e) {
      appStore.setLoading(false);
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    var width = widget.isView == true ? context.width() : context.width() * 0.72;
    var height = 230.0;
    
    // Couleurs dorées pour les programmes du mois
    const goldColor = Color(0xFFFFD700);
    const darkGoldColor = Color(0xFFB8860B);
    
    Widget imageWidget = cachedImage(widget.mWorkoutModel!.workoutImage.validate(), height: height, fit: BoxFit.cover, width: width).cornerRadiusWithClipRRect(16);
    
    // Si c'est un programme du mois, ajouter le contour doré
    if (widget.isMonthlyProgram) {
      imageWidget = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: goldColor, width: 3),
          boxShadow: [
            BoxShadow(
              color: goldColor.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 8,
              offset: Offset(0, 0),
            ),
          ],
        ),
        child: imageWidget,
      );
    }
    
    return Stack(
      children: [
        imageWidget,
        mBlackEffect(width, height, radiusValue: 16),
        Positioned(
          left: 16,
          top: 8,
          right: 12,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Badge avec logique d'accès améliorée
              ProgramTypeBadge(
                programType: widget.mWorkoutModel!.programType,
                price: widget.mWorkoutModel!.price,
                userHasAccess: widget.mWorkoutModel!.userHasAccess,
                hideForMonthlyProgram: widget.isMonthlyProgram,
                showMonthlyBadge: !widget.isMonthlyProgram && widget.isActuallyMonthlyProgram, // Afficher badge "programme du mois" seulement en dehors de la section dédiée ET si c'est vraiment un programme du mois
              ),
/*              Container(
                decoration: boxDecorationWithRoundedCorners(backgroundColor: Colors.white.withOpacity(0.5), boxShape: BoxShape.circle),
                padding: EdgeInsets.all(5),
                child: Image.asset(widget.mWorkoutModel!.isFavourite == 1 ? ic_favorite_fill : ic_favorite, color: widget.mWorkoutModel!.isFavourite == 1 ? primaryColor : white, width: 20, height: 20)
                    .center(),
              ).onTap(() {
                setState(() {});
                setWorkout(widget.mWorkoutModel!.id.validate());
              }),*/
            ],
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.mWorkoutModel!.title.capitalizeFirstLetter().validate(), style: boldTextStyle(color: white)),
              4.height,
              Row(
                children: [
                  Container(
                    margin: EdgeInsets.only(right: 6), 
                    height: 4, 
                    width: 4, 
                    decoration: boxDecorationWithRoundedCorners(
                      boxShape: BoxShape.circle, 
                      backgroundColor: widget.isMonthlyProgram ? goldColor : white,
                    ),
                  ),
                  Text('${widget.mWorkoutModel!.workoutTypeTitle.validate()}', style: secondaryTextStyle(color: white)),
                  8.width,
                  Container(
                    height: 14, 
                    width: 2, 
                    color: widget.isMonthlyProgram ? goldColor : primaryColor,
                  ),
                  8.width,
                  Text(widget.mWorkoutModel!.levelTitle.validate(), style: secondaryTextStyle(color: white)),
                  if (widget.isMonthlyProgram) ...[
                    Spacer(),
                    Icon(
                      Icons.star,
                      color: goldColor,
                      size: 16,
                    ),
                  ],
                ],
              ),
            ],
          ),
        )
      ],
    ).onTap(() {
      _handleWorkoutTap();
    }).paddingBottom(widget.isView == true ? 16 : 0);
  }

  void _handleWorkoutTap() {
    // Toujours permettre l'accès aux détails du workout
    // La logique de déblocage sera gérée dans WorkoutDetailScreen
    _navigateToWorkoutDetail();
  }

  void _navigateToWorkoutDetail() {
    WorkoutDetailScreen(
      id: widget.mWorkoutModel!.id,
      mWorkoutModel: widget.mWorkoutModel!,
    ).launch(context).then((value) {
      if (widget.onCall != null) {
        widget.onCall!();
      }
    });
  }

  void _showSubscriptionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Abonnement requis'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, size: 50, color: Colors.orange),
              SizedBox(height: 16),
              Text(
                'Ce programme "${widget.mWorkoutModel!.title}" est réservé aux membres premium.',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Abonnez-vous pour accéder à tous les programmes premium !',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SubscribeScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: Text('S\'abonner', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
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
              Text('Ce programme "${widget.mWorkoutModel!.title}" nécessite un accès spécial.'),
              SizedBox(height: 16),
              ProgramAccessButton(
                programId: widget.mWorkoutModel!.id!,
                programType: 'workout',
                accessType: widget.mWorkoutModel!.programType,
                price: widget.mWorkoutModel!.price,
                userHasAccess: widget.mWorkoutModel!.userHasAccess,
                requiresPurchase: widget.mWorkoutModel!.requiresPurchase,
                requiresSubscription: widget.mWorkoutModel!.requiresSubscription,
                programTitle: widget.mWorkoutModel!.title!,
                onAccessGranted: () {
                  Navigator.of(dialogContext).pop();
                  // Mettre à jour le modèle pour refléter l'accès
                  setState(() {
                    widget.mWorkoutModel!.userHasAccess = true;
                  });
                  _navigateToWorkoutDetail();
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
