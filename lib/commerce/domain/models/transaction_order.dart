import 'package:enum_to_string/enum_to_string.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
// ignore: implementation_imports
import 'package:in_app_purchase_android/src/types/google_play_purchase_details.dart';
// ignore: implementation_imports
import 'package:in_app_purchase_storekit/src/types/app_store_purchase_details.dart';
import 'package:neom_commons/core/domain/model/subscription_plan.dart';
import 'package:neom_commons/core/utils/enums/profile_type.dart';
import '../../utils/enums/transaction_type.dart';
import 'app_product.dart';

class TransactionOrder {

  String id;
  String description;
  String url;
  int createdTime;
  String customerEmail;
  ProfileType customerType;
  String couponId;
  List<String>? invoiceIds;
  AppProduct? product;
  SubscriptionPlan? subscriptionPlan;

  GooglePlayPurchaseDetails? googlePlayPurchaseDetails;
  AppStorePurchaseDetails? appStorePurchaseDetails;

  TransactionType transactionType;

  TransactionOrder({
    this.id = "",
    this.description = "",
    this.url = '',
    this.createdTime = 0,
    this.customerEmail = '',
    this.customerType = ProfileType.general,
    this.couponId = '',
    this.invoiceIds,
    this.product,
    this.subscriptionPlan,
    this.googlePlayPurchaseDetails,
    this.appStorePurchaseDetails,
    this.transactionType = TransactionType.purchase,
  });

  Map<String, dynamic> toJSON() {
    return <String, dynamic>{
      'id': id,
      'description': description,
      'url': url,
      'createdTime': createdTime,
      'customerEmail': customerEmail,
      'customerType': customerType.name,
      'couponId': couponId,
      'invoiceIds': invoiceIds,
      'product': product?.toJSON(),
      'subscriptionPlan': subscriptionPlan?.toJSON(),
      'googlePlayPurchaseDetails': googlePlayPurchaseDetails != null ? googlePlayPurchaseDetailsJSON(googlePlayPurchaseDetails) : {},
      'appStorePurchaseDetails': appStorePurchaseDetails != null ? appStorePurchaseDetailsJSON(appStorePurchaseDetails) : {},
      'transactionType': transactionType.name,
    };
  }

  TransactionOrder.fromJSON(data) :
    id = data["id"] ?? "",
    description = data["description"] ?? "",
    url = data["url"] ?? "",
    createdTime = data["createdTime"] ?? 0,
    customerEmail = data["customerEmail"] ?? "",
    customerType = EnumToString.fromString(ProfileType.values, data["type"] ?? ProfileType.general.value) ?? ProfileType.general,
    couponId = data["couponId"] ?? "",
    invoiceIds = data["invoiceIds"]?.cast<String>() ?? [],
    product = AppProduct.fromJSON(data["product"] ?? {}),
    subscriptionPlan = SubscriptionPlan.fromJSON(data["subscriptionPlan"] ?? {}),
    googlePlayPurchaseDetails = googlePlayPurchaseDetailsFromJSON(data["googlePlayPurchaseDetails"] ?? {}),
    appStorePurchaseDetails = appStorePurchaseDetailsFromJSON(data["appStorePurchaseDetails"] ?? {}),
    transactionType = EnumToString.fromString(TransactionType.values, data["transactionType"] ?? TransactionType.purchase.name) ?? TransactionType.purchase;

  static Map googlePlayPurchaseDetailsJSON(GooglePlayPurchaseDetails? purchaseDetails) {
    return {
      'purchaseId': purchaseDetails?.purchaseID ?? "",
      'productId': purchaseDetails?.productID ?? "",
      'transactionDate': purchaseDetails?.transactionDate ?? "",
      'status': purchaseDetails?.status.name ?? PurchaseStatus.error.name,
      'verificationData': {
        'localVerificationData': purchaseDetails?.verificationData.localVerificationData ?? "",
        'serverVerificationData': purchaseDetails?.verificationData.serverVerificationData ?? "",
        'source': purchaseDetails?.verificationData.source ?? "",
      }
    };
  }

  static Map appStorePurchaseDetailsJSON(AppStorePurchaseDetails? purchaseDetails) {
    return {
      'purchaseId': purchaseDetails?.purchaseID ?? "",
      'productId': purchaseDetails?.productID ?? "",
      'transactionDate': purchaseDetails?.transactionDate ?? "",
      'status': purchaseDetails?.status.name ?? PurchaseStatus.error.name,
      'verificationData': {
        'localVerificationData': purchaseDetails?.verificationData.localVerificationData ?? "",
        'serverVerificationData': purchaseDetails?.verificationData.serverVerificationData ?? "",
        'source': purchaseDetails?.verificationData.source ?? "",
      }
    };
  }

  static GooglePlayPurchaseDetails? googlePlayPurchaseDetailsFromJSON(data) {
    return GooglePlayPurchaseDetails(
      purchaseID: data["purchaseId"] ?? "",
      productID: data["productId"] ?? "",
      transactionDate: data["transactionDate"] ?? "",
      status: EnumToString.fromString(PurchaseStatus.values, data["status"] ?? PurchaseStatus.error.name)
          ?? PurchaseStatus.error,
      verificationData: PurchaseVerificationData(
        localVerificationData: data["verificationData"]?["localVerificationData"] ?? "",
        serverVerificationData: data["verificationData"]?["serverVerificationData"] ?? "",
        source: data["verificationData"]?["source"] ?? "",
      ),
      billingClientPurchase: PurchaseWrapper(
        orderId: data["billingClientPurchase"]?["orderId"] ?? "",
        packageName: data["billingClientPurchase"]?["packageName"] ?? "",
        purchaseTime: data["billingClientPurchase"]?["purchaseTime"] ?? 0,
        purchaseToken: data["billingClientPurchase"]?["purchaseToken"] ?? "",
        signature: data["billingClientPurchase"]?["signature"] ?? "",
        products: data["billingClientPurchase"]?["products"]?.cast<String>() ?? [],
        isAutoRenewing: data["billingClientPurchase"]?["isAutoRenewing"] ?? false,
        originalJson: data["billingClientPurchase"]?["originalJson"] ?? "",
        developerPayload: data["billingClientPurchase"]?["developerPayload"] ?? "",
        isAcknowledged: data["billingClientPurchase"]?["isAcknowledged"] ?? false,
        purchaseState: EnumToString.fromString(PurchaseStateWrapper.values, (data["billingClientPurchase"]?["purchaseState"]
            ?? PurchaseStateWrapper.unspecified_state.name)) ?? PurchaseStateWrapper.unspecified_state,
        obfuscatedAccountId: data["billingClientPurchase"]?["obfuscatedAccountId"] ?? "",
        obfuscatedProfileId: data["billingClientPurchase"]?["obfuscatedProfileId"] ?? "",
      ),
    );
  }

  static AppStorePurchaseDetails? appStorePurchaseDetailsFromJSON(data) {
    return null;
  }

}
