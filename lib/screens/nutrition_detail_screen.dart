import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/nutrition_element_response.dart';
import '../network/rest_api.dart';

class NutritionDetailScreen extends StatefulWidget {
  final String slug;
  const NutritionDetailScreen({Key? key, required this.slug}) : super(key: key);

  @override
  _NutritionDetailScreenState createState() => _NutritionDetailScreenState();
}

class _NutritionDetailScreenState extends State<NutritionDetailScreen> {
  NutritionElement? element;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await getNutritionElementBySlugApi(slug: widget.slug);
      element = res.data.isNotEmpty ? res.data.first : null;
    } catch (e) {
      element = null;
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (element == null) {
      return Scaffold(body: Center(child: Text("Aucun contenu trouvé")));
    }

    return Scaffold(
      // On passe body à un CustomScrollView pour le SliverAppBar
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: Theme.of(context).primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                element!.title,
                style: TextStyle(fontSize: 16),
              ),
              background: element!.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                imageUrl: element!.imageUrl,
                fit: BoxFit.cover,
              )
                  : Container(color: Colors.grey.shade200),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Html(
                data: element!.description,
                style: {
                  "h2": Style(
                    color: Theme.of(context).primaryColor,
                    fontSize: FontSize.xLarge,
                    fontWeight: FontWeight.bold,
                  ),
                  "h3": Style(
                    color: Theme.of(context).primaryColorDark,
                    fontSize: FontSize.large,
                    fontWeight: FontWeight.bold,
                  ),
                  "p": Style(
                    fontSize: FontSize.medium,
                    lineHeight: LineHeight(1.5),
                  ),
                  "ul": Style(
                    padding: EdgeInsets.only(left: 20, bottom: 8),
                  ),
                  "li": Style(
                    margin: Margins.only(bottom: 10.0),
                  ),
                },
                // Permet de rendre les <img> du HTML via CachedNetworkImage
                customRenders: {
                  tagMatcher("img"): CustomRender.widget(
                    widget: (context, buildChildren) {
                      final src = context.tree.element?.attributes['src'] ?? '';
                      return Padding(
                        padding: EdgeInsets.all(16),
                        child: CachedNetworkImage(
                          imageUrl: src,
                          placeholder: (_, __) =>
                              Center(child: CircularProgressIndicator()),
                          errorWidget: (_, __, ___) => Icon(Icons.broken_image),
                        ),
                      );
                    },
                  ),
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
