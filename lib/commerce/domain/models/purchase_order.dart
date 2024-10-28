import 'package:enum_to_string/enum_to_string.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
// ignore: implementation_imports
import 'package:in_app_purchase_android/src/types/google_play_purchase_details.dart';
// ignore: implementation_imports
import 'package:in_app_purchase_storekit/src/types/app_store_purchase_details.dart';
import 'package:neom_commons/core/domain/model/subscription_plan.dart';
import 'app_product.dart';

class PurchaseOrder {

  String id;
  String description;
  String url;
  /// SaleType saleType;
  int createdTime;
  String customerEmail;
  String couponId;
  ///DEPRECATED List<String>? paymentIds;
  List<String>? invoiceIds;
  AppProduct? product;
  SubscriptionPlan? subscriptionPlan;

  ///DEPRECATED
  /// Booking? booking;
  /// Event? event;
  /// AppReleaseItem? releaseItem;

  GooglePlayPurchaseDetails? googlePlayPurchaseDetails;
  AppStorePurchaseDetails? appStorePurchaseDetails;

  PurchaseOrder({
    this.id = "",
    this.description = "",
    this.url = '',
    /// this.saleType = SaleType.notDefined,
    this.createdTime = 0,
    this.customerEmail = '',
    this.couponId = '',
    /// this.paymentIds,
    this.invoiceIds,
    this.product,
    this.subscriptionPlan,
    /// this.booking,
    /// this.releaseItem,
    /// this.event,
    this.googlePlayPurchaseDetails,
    this.appStorePurchaseDetails
  });

  Map<String, dynamic> toJSON() {
    return <String, dynamic>{
      'id': id,
      'description': description,
      'url': url,
      /// 'saleType': saleType.name,
      'createdTime': createdTime,
      'customerEmail': customerEmail,
      'couponId': couponId,
      'invoiceIds': invoiceIds,
      'product': product?.toJSON(),
      'subscriptionPlan': subscriptionPlan?.toJSON(),
      /// 'booking': booking?.toJSON(),
      /// 'releaseItem': releaseItem?.toJSON(),
      /// 'event': event?.toJSON(),
      'googlePlayPurchaseDetails': googlePlayPurchaseDetails != null ? googlePlayPurchaseDetailsJSON(googlePlayPurchaseDetails) : {},
      'appStorePurchaseDetails': appStorePurchaseDetails != null ? appStorePurchaseDetailsJSON(appStorePurchaseDetails) : {},
    };
  }

  PurchaseOrder.fromJSON(data) :
    id = data["id"] ?? "",
    description = data["description"] ?? "",
    url = data["url"] ?? "",
    /// saleType = EnumToString.fromString(SaleType.values, data["saleType"]) ?? SaleType.product,
    createdTime = data["createdTime"] ?? 0,
    customerEmail = data["customerEmail"] ?? "",
    couponId = data["couponId"] ?? "",
    /// paymentIds = data["paymentIds"]?.cast<String>() ?? [],
    invoiceIds = data["invoiceIds"]?.cast<String>() ?? [],
    product = AppProduct.fromJSON(data["product"] ?? {}),
    subscriptionPlan = SubscriptionPlan.fromJSON(data["subscriptionPlan"] ?? {}),
    /// booking = Booking.fromJSON(data["booking"] ?? {}),
    /// event = Event.fromJSON(data["event"] ?? {}),
    /// releaseItem = AppReleaseItem.fromJSON(data["releaseItem"] ?? {}),
    googlePlayPurchaseDetails = googlePlayPurchaseDetailsFromJSON(data["googlePlayPurchaseDetails"] ?? {}),
    appStorePurchaseDetails = appStorePurchaseDetailsFromJSON(data["appStorePurchaseDetails"] ?? {});

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
