import 'package:flutter/material.dart';
import 'package:mighty_fitness/extensions/extension_util/widget_extensions.dart';
import 'package:mighty_fitness/extensions/loader_widget.dart';
import 'package:mighty_fitness/extensions/text_styles.dart';
import 'package:mighty_fitness/extensions/decorations.dart';
import 'package:mighty_fitness/models/program_purchase_models.dart';
import 'package:mighty_fitness/network/rest_api.dart';
import 'package:mighty_fitness/utils/app_colors.dart';
import 'package:mighty_fitness/extensions/extension_util/string_extensions.dart';
import 'package:mighty_fitness/extensions/extension_util/int_extensions.dart';

import '../extensions/shared_pref.dart';
import '../utils/app_common.dart';
import '../extensions/widgets.dart';
import '../main.dart';

class MyPurchasesScreen extends StatefulWidget {
  @override
  _MyPurchasesScreenState createState() => _MyPurchasesScreenState();
}

class _MyPurchasesScreenState extends State<MyPurchasesScreen> {
  late Future<UserPurchasedProgramsResponse> _futurePurchases;

  @override
  void initState() {
    super.initState();
    _loadPurchases();
  }

  void _loadPurchases() {
    final userId = userStore.userId;
    _futurePurchases = getUserPurchasedProgramsApi(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1C1C1E),
      appBar: appBarWidget(
        'Mes Achats',
        elevation: 0,
        context: context,
        color: Color(0xFF1C1C1E),
        textColor: Colors.white,
      ),
      body: SafeArea(
        child: FutureBuilder<UserPurchasedProgramsResponse>(
          future: _futurePurchases,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Loader().center();
            }

            if (snapshot.hasError) {
              return _buildErrorWidget();
            }

            final purchases = snapshot.data?.data ?? [];

            if (purchases.isEmpty) {
              return _buildEmptyWidget();
            }

            return RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _loadPurchases();
                });
              },
              child: ListView.separated(
                padding: EdgeInsets.all(16),
                itemCount: purchases.length,
                separatorBuilder: (_, __) => SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _buildPurchaseCard(purchases[index]);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPurchaseCard(UserPurchasedProgram purchase) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Colors.blueGrey[800]!,
              Colors.blueGrey[700]!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: purchase.programType == 'workout'
                        ? Colors.blue.withOpacity(0.2)
                        : Colors.purple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: purchase.programType == 'workout'
                          ? Colors.blue
                          : Colors.purple,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        purchase.programType == 'workout'
                            ? Icons.fitness_center
                            : Icons.psychology,
                        size: 14,
                        color: purchase.programType == 'workout'
                            ? Colors.blue
                            : Colors.purple,
                      ),
                      4.width,
                      Text(
                        purchase.programType == 'workout'
                            ? 'WORKOUT'
                            : 'MENTAL',
                        style: TextStyle(
                          color: purchase.programType == 'workout'
                              ? Colors.blue
                              : Colors.purple,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Spacer(),
                _buildStatusBadge(purchase.status),
              ],
            ),
            12.height,
            Text(
              purchase.programTitle.capitalizeFirstLetter(),
              style: boldTextStyle(color: Colors.white, size: 16),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            8.height,
            Row(
              children: [
                Icon(Icons.euro, color: Colors.green, size: 16),
                4.width,
                Text(
                  '${purchase.price.toStringAsFixed(2)} ${purchase.currency}',
                  style: boldTextStyle(color: Colors.green, size: 14),
                ),
                Spacer(),
                Icon(Icons.access_time, color: Colors.grey[400], size: 16),
                4.width,
                Text(
                  _formatDate(purchase.purchaseDate),
                  style: secondaryTextStyle(color: Colors.grey[400], size: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'active':
        color = Colors.green;
        text = 'ACTIF';
        icon = Icons.check_circle;
        break;
      case 'expired':
        color = Colors.red;
        text = 'EXPIRÉ';
        icon = Icons.cancel;
        break;
      case 'pending':
        color = Colors.orange;
        text = 'EN ATTENTE';
        icon = Icons.schedule;
        break;
      default:
        color = Colors.grey;
        text = status.toUpperCase();
        icon = Icons.help;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          4.width,
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

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey[600],
          ),
          16.height,
          Text(
            'Aucun achat',
            style: boldTextStyle(color: Colors.white, size: 20),
          ),
          8.height,
          Text(
            'Vous n\'avez encore acheté aucun programme.',
            style: secondaryTextStyle(color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
          24.height,
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Parcourir les programmes',
              style: boldTextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[400],
          ),
          16.height,
          Text(
            'Erreur de chargement',
            style: boldTextStyle(color: Colors.white, size: 20),
          ),
          8.height,
          Text(
            'Impossible de charger vos achats.',
            style: secondaryTextStyle(color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
          24.height,
          ElevatedButton(
            onPressed: () {
              setState(() {
                _loadPurchases();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Réessayer',
              style: boldTextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}