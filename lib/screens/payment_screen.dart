import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_braintree/flutter_braintree.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../extensions/LiveStream.dart';
import '../extensions/animatedList/animated_list_view.dart';
import '../extensions/app_button.dart';
import '../extensions/decorations.dart';
import '../extensions/extension_util/int_extensions.dart';
import '../extensions/extension_util/string_extensions.dart';
import '../extensions/extension_util/widget_extensions.dart';
import '../extensions/loader_widget.dart';
import '../extensions/system_utils.dart';
import '../extensions/text_styles.dart';
import '../extensions/widgets.dart';
import '../main.dart';
import '../models/payment_list_model.dart';
import '../models/subscribe_response.dart';
import '../models/subscription_payment_intent.dart';
import '../models/subscription_response.dart';
import '../network/rest_api.dart';
import '../screens/no_data_screen.dart';
import '../utils/app_colors.dart';
import '../utils/app_common.dart';
import '../utils/app_config.dart';
import '../utils/app_constants.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';


class PaymentScreen extends StatefulWidget {
  static String tag = '/payment_screen';
  final SubscriptionModel? mSubscriptionModel;

  PaymentScreen({this.mSubscriptionModel});

  @override
  PaymentScreenState createState() => PaymentScreenState();
}

class PaymentScreenState extends State<PaymentScreen> {
  List<PaymentModel> paymentList = [];
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  static const String _kProductIdAndroid = 'myfitnessapp_abonnement';
  static const String _kProductIdIOS = 'myfitnessapp_abonnement';

  String? selectedPaymentType,
      stripPaymentKey,
      stripPaymentPublishKey,
      payStackPublicKey,
      payPalTokenizationKey,
      flutterWavePublicKey,
      flutterWaveSecretKey,
      flutterWaveEncryptionKey,
      payTabsProfileId,
      payTabsServerKey,
      payTabsClientKey,
      myFatoorahToken,
      paytmMerchantId,
      orangeMoneyPublicKey,
      paytmMerchantKey;

  String? razorKey;

  bool isPaytmTestType = true;
  bool isFatrooahTestType = true;
  bool loading = false;


  @override
  void initState() {
    super.initState();
    final Stream<List<PurchaseDetails>> purchaseUpdated = InAppPurchase.instance.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
      // Gérer l'erreur ici.
      print(error);
    });
    init();
  }

    @override
    void dispose() {
      _subscription.cancel();
      super.dispose();
    }

    void init() async {
      await paymentListApiCall();
      if (paymentList.any((element) => element.type == PAYMENT_TYPE_STRIPE)) {
        Stripe.publishableKey = stripPaymentPublishKey.validate();
        Stripe.merchantIdentifier = mStripeIdentifier;
        await Stripe.instance.applySettings().catchError((e) {
          log("${e.toString()}");
        });
      }

    }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        _showPendingUI();
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        _handleError(purchaseDetails.error!);
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {

        // On affiche le loader (MobX)
        appStore.setLoading(true);

        // Appel de la fonction fusionnée
        await _verifyAndCreateSubscription(purchaseDetails);

        // On masque le loader
        appStore.setLoading(false);
      }

      if (purchaseDetails.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(purchaseDetails);
      }
    }
  }


  Future<void> _verifyAndCreateSubscription(PurchaseDetails purchaseDetails) async {
    try {
      String? originalTransactionId;
      String? productId = purchaseDetails.productID;
      String? receiptData;

      if (Platform.isIOS && purchaseDetails is AppStorePurchaseDetails) {
        final skTransaction = purchaseDetails.skPaymentTransaction;
        originalTransactionId = skTransaction?.originalTransaction?.transactionIdentifier
            ?? skTransaction?.transactionIdentifier;
        receiptData = purchaseDetails.verificationData.serverVerificationData;
      } else if (Platform.isAndroid) {
        receiptData = purchaseDetails.verificationData.serverVerificationData; // purchaseToken pour Android
      }

      final Map<String, dynamic> requestBody = {
        'receipt_data': receiptData,
        'original_transaction_id': originalTransactionId, // Uniquement iOS
        'platform': Platform.isIOS ? 'ios' : 'android',
        'product_id': productId, // Nécessaire pour Android
      };

      try {
        print("Envoi de la requête avec requestBody: $requestBody");
        final response = await verifyAndCreateSubscriptionApi(requestBody);

        print("Réponse reçue du backend: $response");

        if (response != null && response.status == true) {
          userStore.setSubscribe(1);
          finish(context);
          finish(context);
        } else {
          print("Erreur du back: ${response?.message}");
        }
      } catch (e, stackTrace) {
        print("Erreur lors de l'appel API verifyAndCreateSubscriptionApi : $e");
        print("StackTrace : $stackTrace");
        return;
      }
    } catch (e, stackTrace) {
      print("Exception globale dans _verifyAndCreateSubscription : $e");
      print("StackTrace : $stackTrace");
    }
  }











  Future<void> buySubscription() async {
    final InAppPurchase _inAppPurchase = InAppPurchase.instance;

    // Déterminer l'ID de produit en fonction de la plateforme
    String productId;
    if (Platform.isAndroid) {
      productId = _kProductIdAndroid;
    } else if (Platform.isIOS) {
      productId = _kProductIdIOS;
    } else {
      print('Unsupported platform');
      return;
    }

    final Set<String> _kProductIds = {productId};

    // Vérifier si la boutique est disponible
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      print('Store not available');
      return;
    }

    // Charger les produits disponibles à la vente
    final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(_kProductIds);
    if (response.notFoundIDs.isNotEmpty) {
      print('Products not found: ${response.notFoundIDs}');
      return;
    }

    List<ProductDetails> products = response.productDetails;
    if (products.isEmpty) {
      print('No products found');
      return;
    }

    // Assumer qu'il y a un seul produit pour simplifier l'exemple
    final ProductDetails productDetails = products.first;

    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);

    // Initier le flux d'achat
    _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  // Fonctions de support (à implémenter) :
  void _showPendingUI() {
    print("Achat en attente");
  }

  void _handleError(IAPError error) {
    print("Erreur d'achat: $error");
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {

    // a changer faut verifier le receipt
    try {
      String? originalTransactionId;
      if (Platform.isIOS && purchaseDetails is AppStorePurchaseDetails) {
        final skTransaction = purchaseDetails.skPaymentTransaction;
        // Notez : originalTransaction est de type SKPaymentTransactionWrapper?
        // Pour obtenir l'identifiant, on accède à sa propriété transactionIdentifier.
        originalTransactionId = skTransaction?.originalTransaction?.transactionIdentifier
            ?? skTransaction?.transactionIdentifier;
      }
      print("Receipt Data: ${purchaseDetails.verificationData.serverVerificationData}");

      final Map<String, dynamic> requestBody = {
        'receipt_data': purchaseDetails.verificationData.serverVerificationData,
        //'platform': Platform.isIOS ? 'ios' : 'android',
        'original_transaction_id': originalTransactionId,
        'user_id': userStore.userId.toString(),
      };

      final response = await verifyAndCreateSubscriptionApi(requestBody);
      print('ici le repsonse status');
      print(response.status );
      return response.status == true;
    } catch (e) {
      print("Exception during receipt verification: $e");
      return false;
    }
  }



  Future<void> _deliverProduct(PurchaseDetails purchaseDetails) async {

    String? originalTransactionId;
    if (Platform.isIOS && purchaseDetails is AppStorePurchaseDetails) {
      final skTransaction = purchaseDetails.skPaymentTransaction;
      // Notez : originalTransaction est de type SKPaymentTransactionWrapper?
      // Pour obtenir l'identifiant, on accède à sa propriété transactionIdentifier.
      originalTransactionId = skTransaction?.originalTransaction?.transactionIdentifier
          ?? skTransaction?.transactionIdentifier;
    }

    Map<String, dynamic> requestBody = {
      'purchase_id': purchaseDetails.purchaseID,
      'product_id': purchaseDetails.productID,
      'transaction_date': purchaseDetails.transactionDate,
      'platform': 'ios',
      'original_transaction_id': originalTransactionId,
      'user_id': userStore.userId.toString(),  // ou récupérez l'ID utilisateur du backend si nécessaire
    };

    // Appel de l'API pour créer un Payment Intent
    SubscriptionPaymentIntentResponse response = await subscriptionPaymentIntentApi(requestBody);
    // Ajouter votre logique de livraison ici.

    userStore.setSubscribe(1);
    print('apres paiement');
    print(userStore.isSubscribe);

    print("Produit livré");
    await getUSerDetail(context, userStore.userId).whenComplete(() {
      setState(() {
       // appStore.setLoading(false);
        //LiveStream().emit(PAYMENT);
        finish(context);
        finish(context);
      });
    });
  }

  void _handleInvalidPurchase(PurchaseDetails purchaseDetails) {
    print("Achat invalide");
  }


  /// Get Payment Gateway Api Call
  Future<void> paymentListApiCall() async {
    appStore.setLoading(true);
    await getPaymentApi().then((value) {
      appStore.setLoading(false);
      paymentList.addAll(value.data!);
      if (paymentList.isNotEmpty) {
        paymentList.forEach((element) {
          if (element.type == PAYMENT_TYPE_STRIPE) {
            stripPaymentKey = element.isTest == 1 ? element.testValue!.secretKey : element.liveValue!.secretKey;
            stripPaymentPublishKey = element.isTest == 1 ? element.testValue!.publishableKey : element.liveValue!.publishableKey;
          } else if (element.type == PAYMENT_TYPE_PAYSTACK) {
            payStackPublicKey = element.isTest == 1 ? element.testValue!.publicKey : element.liveValue!.publicKey;
          } else if (element.type == PAYMENT_TYPE_RAZORPAY) {
            razorKey = element.isTest == 1 ? element.testValue!.keyId.validate() : element.liveValue!.keyId.validate();
          } else if (element.type == PAYMENT_TYPE_PAYPAL) {
            payPalTokenizationKey = element.isTest == 1 ? element.testValue!.tokenizationKey : element.liveValue!.tokenizationKey;
          } else if (element.type == PAYMENT_TYPE_FLUTTERWAVE) {
            flutterWavePublicKey = element.isTest == 1 ? element.testValue!.publicKey : element.liveValue!.publicKey;
            flutterWaveSecretKey = element.isTest == 1 ? element.testValue!.secretKey : element.liveValue!.secretKey;
            flutterWaveEncryptionKey = element.isTest == 1 ? element.testValue!.encryptionKey : element.liveValue!.encryptionKey;
          } else if (element.type == PAYMENT_TYPE_PAYTABS) {
            payTabsProfileId = element.isTest == 1 ? element.testValue!.profileId : element.liveValue!.profileId;
            payTabsClientKey = element.isTest == 1 ? element.testValue!.clientKey : element.liveValue!.clientKey;
            payTabsServerKey = element.isTest == 1 ? element.testValue!.serverKey : element.liveValue!.serverKey;
          } else if (element.type == PAYMENT_TYPE_MYFATOORAH) {
            if (element.isTest == 1) {
              isFatrooahTestType = true;
            } else {
              isFatrooahTestType = false;
            }
            myFatoorahToken = element.isTest == 1 ? element.testValue!.accessToken : element.liveValue!.accessToken;
          } else if (element.type == PAYMENT_TYPE_PAYTM) {
            if (element.isTest == 1) {
              isPaytmTestType = true;
            } else {
              isPaytmTestType = false;
            }
            paytmMerchantId = element.isTest == 1 ? element.testValue!.merchantId : element.liveValue!.merchantId;
            paytmMerchantKey = element.isTest == 1 ? element.testValue!.merchantKey : element.liveValue!.merchantKey;
          } else if (element.type == PAYMENT_TYPE_ORANGE_MONEY) {
            orangeMoneyPublicKey = element.isTest == 1 ? element.testValue!.publicKey : element.liveValue!.publicKey;
          }
        });
      }
      setState(() {});
    }).catchError((error) {
      appStore.setLoading(false);
      log('${error.toString()}');
    });
  }

    Future<void> subscribe(String paymentIntentId) async {
      try {
        // Construire le corps de la requête
        Map<String, dynamic> requestBody = {
          'payment_intent_id': paymentIntentId, // Ajouter le PaymentIntent ID lors de l'abonnement
        };

        // Appel de l'API pour créer l'abonnement
        SubscribeResponse response = await subscribeApi(requestBody);

        if (response.message != null) {
          log("Souscription créée avec succès");
        } else {
          throw Exception('Échec de la création de la souscription : ${response.message}');
        }
      } catch (e) {
        log("Erreur lors de la création de la souscription : $e");
      }
    }


  String _getReference() {
    String platform;
    if (Platform.isIOS) {
      platform = 'iOS';
    } else {
      platform = 'Android';
    }
    return 'ChargedFrom${platform}_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Paypal Payment
  void payPalPayment() async {
    appStore.setLoading(true);
    final request = BraintreePayPalRequest(amount: widget.mSubscriptionModel!.price.toString(), currencyCode: userStore.currencySymbol.toUpperCase(), displayName: userStore.username.validate());
    final result = await Braintree.requestPaypalNonce(
      payPalTokenizationKey!,
      request,
    );
    if (result != null) {
      appStore.setLoading(false);
      paymentConfirm();
    } else {
      appStore.setLoading(false);
    }
  }






  Future<void> paymentConfirm() async {
    appStore.setLoading(true);
    Map req = {"package_id": widget.mSubscriptionModel!.id, "payment_status": "paid", "payment_type": selectedPaymentType, "txn_id": "", "transaction_detail": ""};
    await subscribePackageApi(req).then((value) async {
      toast(value.message);
      await getUSerDetail(context, userStore.userId).whenComplete(() {
        setState(() {
          appStore.setLoading(false);
          LiveStream().emit(PAYMENT);
          finish(context);
          finish(context);
        });
      });
    }).catchError((e) {
      appStore.setLoading(false);
      print(e.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget(languages.lblPayments, context: context),
      body: Stack(
        children: [
          paymentList.isNotEmpty
              ? AnimatedListView(
                  shrinkWrap: true,
                  itemCount: paymentList.length,
                  padding: EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: boxDecorationWithRoundedCorners(border: Border.all(width: 0.5, color: selectedPaymentType == paymentList[index].type ? primaryColor.withOpacity(0.80) : GreyLightColor)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              cachedImage(paymentList[index].gatewayLogo!, width: 35, height: 35, fit: BoxFit.contain),
                              12.width,
                              Text(paymentList[index].title.validate().capitalizeFirstLetter(), style: primaryTextStyle(), maxLines: 2),
                            ],
                          ).expand(),
                          selectedPaymentType == paymentList[index].type
                              ? Container(
                                  padding: EdgeInsets.all(0),
                                  decoration: boxDecorationWithRoundedCorners(backgroundColor: primaryColor, borderRadius: radius(8)),
                                  child: Icon(Icons.check, color: Colors.white),
                                )
                              : SizedBox(),
                        ],
                      ),
                    ).onTap(() {
                      selectedPaymentType = paymentList[index].type;
                      setState(() {});
                    });
                  })
              : NoDataScreen().visible(!appStore.isLoading),
          Observer(
            builder: (context) {
              return Loader().center().visible(appStore.isLoading);
            },
          )
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(16),
        child: Visibility(
          visible: paymentList.isNotEmpty,
          child: AppButton(
            text: languages.lblPay,
            color: primaryColor,
            onTap: () {
              if (selectedPaymentType == PAYMENT_TYPE_STRIPE) {
                buySubscription();
              }  else if (selectedPaymentType == PAYMENT_TYPE_PAYPAL) {
                payPalPayment();
              }
            },
          ),
        ),
      ),
    );
  }
}
