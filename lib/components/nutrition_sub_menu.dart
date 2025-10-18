import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import '../screens/nutrition_detail_screen.dart';

class NutritionSubMenu extends StatelessWidget {
  final String title;
  final String slug;

  const NutritionSubMenu({
    Key? key,
    required this.title,
    required this.slug,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(Feather.flag, color: Theme.of(context).primaryColor),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
      trailing: Icon(Icons.chevron_right),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NutritionDetailScreen(slug: slug),
        ),
      ),
    );
  }
}
