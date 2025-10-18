// lib/screens/mental_preparation_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mighty_fitness/extensions/extension_util/context_extensions.dart';
import 'package:mighty_fitness/extensions/extension_util/int_extensions.dart';
import 'package:mighty_fitness/extensions/extension_util/string_extensions.dart';
import 'package:mighty_fitness/extensions/extension_util/widget_extensions.dart';
import 'package:mighty_fitness/extensions/loader_widget.dart';
import 'package:mighty_fitness/extensions/text_styles.dart';
import 'package:mighty_fitness/extensions/decorations.dart';
import 'package:mighty_fitness/models/mental_preparation_response.dart';
import 'package:mighty_fitness/network/rest_api.dart';
import 'package:mighty_fitness/utils/app_common.dart';
import 'package:mighty_fitness/utils/app_colors.dart';
import 'package:mighty_fitness/components/program_type_badge.dart';

import '../main.dart';
import 'mental_preparation_detail_screen.dart';

class MentalPreparationListScreen extends StatefulWidget {
  @override
  _MentalPreparationListScreenState createState() =>
      _MentalPreparationListScreenState();
}

class _MentalPreparationListScreenState
    extends State<MentalPreparationListScreen> {
  late Future<MentalPreparationResponse> _futureMentalList;

  @override
  void initState() {
    super.initState();
    // Utiliser la nouvelle API avec contrôle d'accès
    _futureMentalList = getMentalPreparationsWithAccessApi();
  }

  void _refreshData() {
    setState(() {
      _futureMentalList = getMentalPreparationsWithAccessApi();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1C1C1E),
      body: SafeArea(
        child: FutureBuilder<MentalPreparationResponse>(
          future: _futureMentalList,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Loader().center();
            }
            final list = snapshot.data?.data ?? [];
            if (list.isEmpty) {
              return Center(
                child: Text(
                  "Aucun programme mental disponible", style: boldTextStyle(size: 20, color: Colors.white)),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                16.height,
                // Titre principal (inchangé)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    "Préparation Mentale", style: boldTextStyle(size: 20, color: Colors.white)),
                ),
                40.height,
                // Sous-titre avec trait dessous
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Les programmes", style: boldTextStyle(size: 20, color: Colors.white)),
                      4.height,
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
                16.height,
                // Liste verticale de cards
                Expanded(
                  child: ListView.separated(
                    physics: BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (ctx, idx) {
                      final mp = list[idx];
                      final cardHeight = 185.0;
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: InkWell(
                          onTap: () {
                            // Toujours permettre l'accès aux détails comme pour les workouts
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MentalPreparationDetailScreen(
                                  id: mp.id,
                                  mMentalPreparationModel: mp,
                                ),
                              ),
                            ).then((_) {
                              // Recharger la liste au retour pour mettre à jour les statuts d'accès
                              _refreshData();
                            });
                          },
                          child: Stack(
                            children: [
                              // Image de fond
                              cachedImage(
                                mp.imageUrl.validate(),
                                width: double.infinity,
                                height: cardHeight,
                                fit: BoxFit.cover,
                              ),
                              // Overlay sombre
                              mBlackEffect(
                                  context.width() - 32, cardHeight,
                                  radiusValue: 0),
                              // Badge pour le type de programme (en haut à droite)
                              Positioned(
                                top: 12,
                                right: 12,
                                child: ProgramTypeBadge(
                                  programType: mp.programType,
                                  price: mp.price,
                                  userHasAccess: mp.userHasAccess,
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
                                      mp.title.capitalizeFirstLetter(),
                                      style: boldTextStyle(
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
