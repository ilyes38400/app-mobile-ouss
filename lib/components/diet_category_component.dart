import 'dart:ui';
import 'package:flutter/material.dart';
import '../main.dart';
import '../extensions/extension_util/context_extensions.dart';
import '../extensions/extension_util/int_extensions.dart';
import '../extensions/extension_util/string_extensions.dart';
import '../utils/app_common.dart';
import '../../extensions/extension_util/widget_extensions.dart';
import '../../extensions/text_styles.dart';
import '../extensions/decorations.dart';
import '../models/category_diet_response.dart';
import '../screens/view_all_diet.dart';
import '../utils/app_colors.dart';

class DietCategoryComponent extends StatefulWidget {
  final CategoryDietModel? mCategoryDietModel;
  final bool isGrid;
  final Function? onCall;

  DietCategoryComponent({
    this.mCategoryDietModel,
    this.isGrid = false,
    this.onCall,
  });

  @override
  _DietCategoryComponentState createState() => _DietCategoryComponentState();
}

class _DietCategoryComponentState extends State<DietCategoryComponent> {
  @override
  Widget build(BuildContext context) {
    double cardWidth = widget.isGrid ? (context.width() - 48) / 2 : context.width() * 0.44;

    return Container(
      width: cardWidth,
      height: 180,
      margin: EdgeInsets.only(top: 8, right: widget.isGrid ? 0 : 10, bottom: 8),
      decoration: boxDecorationWithRoundedCorners(
        borderRadius: radius(12),
        backgroundColor: appStore.isDarkMode ? context.cardColor : cardBackground,
      ),
      child: Stack(
        children: [
          // Image principale
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              widget.mCategoryDietModel!.categorydietImage!.validate(),
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          // Effet flou + titre
          Align(
            alignment: Alignment.bottomCenter,
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  height: 40,
                  width: double.infinity,
                  color: Colors.black.withOpacity(0.3),
                  alignment: Alignment.center,
                  child: Text(
                    widget.mCategoryDietModel!.title!.validate(),
                    style: boldTextStyle(color: Colors.white, size: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).onTap(() {
      ViewAllDiet(
        isCategory: true,
        mCategoryId: widget.mCategoryDietModel!.id,
        mTitle: widget.mCategoryDietModel!.title,
      ).launch(context);
    });
  }
}
