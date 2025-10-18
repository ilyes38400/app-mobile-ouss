import 'package:flutter/material.dart';
import 'package:mighty_fitness/extensions/extension_util/double_extensions.dart';
import '../../extensions/loader_widget.dart';
import '../../extensions/extension_util/context_extensions.dart';
import '../../extensions/extension_util/int_extensions.dart';
import '../../extensions/extension_util/string_extensions.dart';
import '../../extensions/extension_util/widget_extensions.dart';
import '../../main.dart';
import '../../screens/dashboard_screen.dart';
import '../extensions/app_button.dart';
import '../extensions/app_text_field.dart';
import '../extensions/common.dart';
import '../extensions/constants.dart';
import '../extensions/decorations.dart';
import '../extensions/shared_pref.dart';
import '../extensions/text_styles.dart';
import '../models/register_request.dart';
import '../network/rest_api.dart';
import '../utils/app_colors.dart';
import '../utils/app_common.dart';
import '../utils/app_constants.dart';

class SignUpStep4Component extends StatefulWidget {
  @override
  _SignUpStep4ComponentState createState() => _SignUpStep4ComponentState();
}

class _SignUpStep4ComponentState extends State<SignUpStep4Component> {
  GlobalKey<FormState> mFormKey = GlobalKey<FormState>();

  TextEditingController mWeightCont = TextEditingController();
  TextEditingController mHeightCont = TextEditingController();
  TextEditingController mIdealWeightCont = TextEditingController();


  FocusNode mWeightFocus = FocusNode();
  FocusNode mHeightFocus = FocusNode();
  FocusNode mIdealFocus = FocusNode();


  @override
  void initState() {
    super.initState();
    init();
  }

  init() async {
    //
    mWeightCont.text = userStore.weight.validate();
    mHeightCont.text = userStore.height.validate();
    mIdealWeightCont.text = userStore.idealWeight.validate();


    appStore.setLoading(false);
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }


  Future<void> saveData() async {
    hideKeyboard(context);
    UserProfile userProfile = UserProfile();
    userProfile.age = userStore.age.toInt();
    userProfile.heightUnit = userStore.heightUnit.validate();
    userProfile.height = userStore.height.validate();
    userProfile.weight = userStore.weight.validate();
    userProfile.weightUnit = userStore.weightUnit.validate();
    userProfile.idealWeight = userStore.idealWeight.validate();
    Map<String, dynamic> req;
    if (getBoolAsync(IS_OTP) != true) {
      req = {
        'first_name': userStore.fName.validate(),
        'last_name': userStore.lName.validate(),
        'username': userStore.email.validate(),
        'email': userStore.email.validate(),
        'password': userStore.password.validate(),
        'user_type': LoginUser,
        'status': statusActive,
        'phone_number': userStore.phoneNo.validate(),
        'gender': userStore.gender.validate(),
        'user_profile': userProfile,
        "player_id": getStringAsync(PLAYER_ID).validate(),
      };
    } else {
      req = {
        'first_name': userStore.fName.validate(),
        'last_name': userStore.lName.validate(),
        'username': userStore.phoneNo.validate(),
        'email': userStore.email.validate(),
        'password': userStore.password.validate(),
        'user_type': LoginUser,
        'status': statusActive,
        'phone_number': userStore.phoneNo.validate(),
        'gender': userStore.gender.validate(),
        'user_profile': userProfile,
        "player_id": getStringAsync(PLAYER_ID).validate(),
        "login_type": LoginTypeOTP,
      };
    }

    appStore.setLoading(true);
    await registerApi(req).then((value) async {
      appStore.setLoading(false);
      userStore.setLogin(true);
      userStore.setToken(value.data!.apiToken.validate());
      getUSerDetail(context, value.data!.id).then((value) {
        DashboardScreen().launch(context, isNewTask: true);
      }).catchError((e) {
        print("error=>" + e.toString());
      });
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString());
    });
    setState(() {});
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Form(
            key: mFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(languages.lblLetUsKnowBetter, style: boldTextStyle(size: 22)),
                24.height,
                Text(languages.lblWeight, style: secondaryTextStyle(color: textPrimaryColorGlobal)),
                4.height,
                AppTextField(
                  controller: mWeightCont,
                  textFieldType: TextFieldType.NUMBER,
                  isValidationRequired: true,
                  focus: mWeightFocus,
                  decoration: defaultInputDecoration(
                    context,
                    label: languages.lblEnterWeight,
                  ).copyWith(
                    suffix: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Text('kg', style: boldTextStyle()),
                    ),
                  ),
                ),                16.height,
                Text(languages.lblHeight, style: secondaryTextStyle(color: textPrimaryColorGlobal)),
                4.height,
                AppTextField(
                  controller: mHeightCont,
                  textFieldType: TextFieldType.NUMBER,
                  isValidationRequired: true,
                  focus: mHeightFocus,
                  decoration: defaultInputDecoration(
                    context,
                    label: languages.lblEnterHeight,
                  ).copyWith(
                    suffix: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Text('cm', style: boldTextStyle()),
                    ),
                  ),
                ),
                16.height,

                Text('Poids cible (objectif)', style: secondaryTextStyle(color: textPrimaryColorGlobal)),
                4.height,
                AppTextField(
                  controller: mIdealWeightCont,
                  textFieldType: TextFieldType.NUMBER,
                  isValidationRequired: true,
                  focus: mIdealFocus,
                  decoration: defaultInputDecoration(
                    context,
                    label: 'Entrez votre poids cible',
                  ).copyWith(
                    suffix: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Text('kg', style: boldTextStyle()),
                    ),
                  ),
                ),
                24.height,
                AppButton(
                  text: languages.lblDone,
                  width: context.width(),
                  color: primaryColor,
                  onTap: () {
                    // NE LÂCHE PAS tant que le Form n'est pas valide
                    if (mFormKey.currentState!.validate()) {
                      // Tout est rempli : on peut enregistrer et passer à l'étape suivante
                      userStore.setWeight(mWeightCont.text.validate());
                      userStore.setHeight(mHeightCont.text.validate());
                      userStore.setIdealWeight(mIdealWeightCont.text.validate());
                      appStore.signUpIndex++;
                      setState(() {});
                    }
                  },
                ),              ],
            ).paddingSymmetric(horizontal: 16),
          ),
        ),
        Loader().visible(appStore.isLoading)
      ],
    );
  }
}
