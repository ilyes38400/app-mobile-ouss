import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import '../components/nutrition_sub_menu.dart';
import '../extensions/common.dart';
import '../extensions/extension_util/context_extensions.dart';
import '../extensions/extension_util/int_extensions.dart';
import '../extensions/extension_util/string_extensions.dart';
import '../extensions/loader_widget.dart';
import '../extensions/widgets.dart';
import '../main.dart';
import '../screens/favourite_screen.dart';
import '../../components/featured_diet_component.dart';
import '../../extensions/extension_util/widget_extensions.dart';
import '../../screens/view_all_diet.dart';
import '../components/diet_category_component.dart';
import '../extensions/app_text_field.dart';
import '../extensions/decorations.dart';
import '../extensions/horizontal_list.dart';
import '../extensions/text_styles.dart';
import '../models/category_diet_response.dart';
import '../models/diet_response.dart';
import '../network/rest_api.dart';
import '../utils/app_colors.dart';
import '../utils/app_common.dart';
import '../utils/app_images.dart';
import 'no_data_screen.dart';
import 'view_diet_category_screen.dart';
import 'package:mighty_fitness/screens/nutrition_analysis_page.dart';
import '../models/nutrition_element_response.dart';
import '../network/rest_api.dart';
import '../components/nutrition_sub_menu.dart';

class DietScreen extends StatefulWidget {
  @override
  _DietScreenState createState() => _DietScreenState();
}

class _DietScreenState extends State<DietScreen> {
  List<CategoryDietModel>? mDietCategoryList = [];
  List<DietModel>? mFeaturedDietList = [];
  List<DietModel>? mOtherDietList = [];
  List<DietModel>? mDietList = [];
  List<NutritionElement> mNutritionElements = [];
  bool isLoadingNutrition = false;

  TextEditingController mSearch = TextEditingController();
  String? mSearchValue = "";

  bool _showClearButton = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() {
    getDietData();
    _loadNutritionElements();   // ← nouveau
    mSearch.addListener(() {
      setState(() {
        _showClearButton = mSearch.text.isNotEmpty;
      });
    });
  }

  Future<void> _loadNutritionElements() async {
    setState(() => isLoadingNutrition = true);
    try {
      final res = await getNutritionElementsApi();
      mNutritionElements = res.data;
    } catch (e) {
      mNutritionElements = [];
    }
    setState(() => isLoadingNutrition = false);
  }

  Future<void> getDietData() async {
    setState(() => isLoading = true);
    try {
      final catRes = await getDietCategoryApi();
      mDietCategoryList = catRes.data;
      final featRes = await getDietApi("yes", false);
      mFeaturedDietList = featRes.data;
      final otherRes = await getDietApi("no", false);
      mOtherDietList = otherRes.data;
    } catch (e) {}
    setState(() => isLoading = false);
  }

  Future<void> getDietDataAPI() async {
    setState(() => isLoading = true);
    try {
      final res = await getSearchDietApi(mSearch: mSearchValue);
      mDietList = res.data;
    } catch (e) {
      mDietList = [];
    }
    setState(() => isLoading = false);
  }

  @override
  void dispose() {
    mSearch.dispose();
    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  Widget mHeading(String title, {Function? onCall}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: boldTextStyle(size: 18)).paddingSymmetric(horizontal: 16),
        IconButton(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onPressed: () => onCall?.call(),
          icon: Icon(Feather.chevron_right, color: primaryColor),
        ),
      ],
    );
  }

  Widget mDietSearchList(List<DietModel>? mList) {
    return ListView.builder(
      itemCount: mList?.length ?? 0,
      padding: EdgeInsets.symmetric(horizontal: 16),
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) =>
          FeaturedDietComponent(isList: true, mDietModel: mList![index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget(
        languages.lblDiet,
        context: context,
        showBack: false,
        titleSpacing: 16,
/*        actions: [
          Image.asset(ic_favorite, height: 25, width: 25, color: primaryColor)
              .onTap(() => FavouriteScreen(index: 1).launch(context))
              .paddingSymmetric(horizontal: 16),
        ],*/
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search field above photo card
                10.height,
                AppTextField(
                  controller: mSearch,
                  textFieldType: TextFieldType.OTHER,
                  decoration: defaultInputDecoration(
                      context, label: languages.lblSearch),
                  suffix: _showClearButton
                      ? IconButton(
                    onPressed: () {
                      mSearch.clear();
                      mSearchValue = '';
                      setState(() {});
                    },
                    icon: Icon(Icons.clear),
                  )
                      : mSuffixTextFieldIconWidget(ic_search),
                  onChanged: (v) {
                    mSearchValue = v;
                    getDietDataAPI();
                  },
                ).paddingSymmetric(horizontal: 16),
                SizedBox(height: 16),
                // Photo calorie card with original style
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                    child: ListTile(
                      leading:
                      Icon(Icons.camera_alt, size: 30, color: primaryColor),
                      title: Text(
                        'Scannez calories de mon plat',
                        style: boldTextStyle(),
                      ),
                      trailing:
                      Icon(Icons.arrow_forward_ios, size: 16, color: primaryColor),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NutritionAnalysisPage(),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // Content
                if (mSearchValue.isEmptyOrNull)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (mDietCategoryList!.isNotEmpty) ...[
                        mHeading(languages.lblDietCategories,
                            onCall: () => ViewDietCategoryScreen()
                                .launch(context)),
                        HorizontalList(
                          physics: BouncingScrollPhysics(),
                          itemCount: mDietCategoryList!.length,
                          padding: EdgeInsets.only(left: 16, right: 8),
                          itemBuilder: (context, i) =>
                              DietCategoryComponent(
                                  mCategoryDietModel:
                                  mDietCategoryList![i]),
                        ),
                        SizedBox(height: 8),
                      ],
                      if (mFeaturedDietList!.isNotEmpty) ...[
                        mHeading(languages.lblBestDietDiscoveries,
                            onCall: () => ViewAllDiet(
                                isFeatured: true,
                                mTitle:
                                languages.lblBestDietDiscoveries)
                                .launch(context)
                                .then((_) => getDietData())),
                        HorizontalList(
                          physics: BouncingScrollPhysics(),
                          itemCount: mFeaturedDietList!.length,
                          padding: EdgeInsets.only(
                              left: 16, right: 8, top: 4),
                          itemBuilder: (context, i) =>
                              FeaturedDietComponent(
                                  mDietModel:
                                  mFeaturedDietList![i]),
                        ),
                        SizedBox(height: 8),
                      ],
                      if (mOtherDietList!.isNotEmpty) ...[
                        mHeading(languages.lblDietaryOptions,
                            onCall: () => ViewAllDiet(
                                mTitle: languages.lblDietaryOptions)
                                .launch(context)
                                .then((_) => getDietData())),
                        mDietSearchList(mOtherDietList),
                      ],
                      SizedBox(height: 24),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text("Objectifs", style: boldTextStyle(size: 18)),
                      ),
                      // Si en cours de chargement, affichez un loader
                      if (isLoadingNutrition)
                        Center(child: CircularProgressIndicator()),
                      // Sinon, pour chaque élément récupéré, on crée un sous-menu
                      if (!isLoadingNutrition && mNutritionElements.isNotEmpty)
                        Column(
                          children: mNutritionElements.map((elem) {
                            return NutritionSubMenu(
                              title: elem.title,
                              slug: elem.slug,
                            );
                          }).toList(),
                        ),
                      // Si la liste est vide, message
                      if (!isLoadingNutrition && mNutritionElements.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text("Aucun objectif disponible."),
                        ),

                    ],
                  )
                else
                  Stack(
                    children: [
                      mDietSearchList(mDietList),
                      SizedBox(
                        height: context.height() * 0.6,
                        child: NoDataScreen(
                          mTitle: languages.lblResultNoFound,
                        )
                            .visible(mDietList!.isEmpty)
                            .center()
                            .visible(!isLoading),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (isLoading) Loader(),
        ],
      ),
    );
  }
}
