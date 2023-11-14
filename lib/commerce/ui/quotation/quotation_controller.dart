import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:neom_commons/core/domain/model/app_phyisical_item.dart';
import 'package:neom_commons/core/utils/enums/app_item_size.dart';
import 'package:neom_commons/neom_commons.dart';

import '../../domain/use_cases/quotation_service.dart';
import '../../utils/constants/app_commerce_constants.dart';

class QuotationController extends GetxController implements QuotationService {

  var logger = AppUtilities.logger;
  final loginController = Get.find<LoginController>();
  final userController = Get.find<UserController>();

  final RxBool isLoading = true.obs;
  final RxBool isPhysical = true.obs;
  final RxBool processARequired = true.obs;
  final RxBool processBRequired = true.obs;
  final RxBool coverDesignRequired = true.obs;
  final Rx<Country> phoneCountry = countries[0].obs;

  AppPhysicalItem itemToQuote = AppPhysicalItem();
  int itemQty = 0;
  int processACost = 0;
  int processBCost = 0;
  int coverDesignCost = 0;
  double pricePerUnit = 0;
  double totalCost = 0;

  TextEditingController itemQtyController = TextEditingController();
  TextEditingController itemDurationController = TextEditingController();
  TextEditingController controllerPhone = TextEditingController();

  String phoneNumber = '';

  @override
  void onInit() async {
    super.onInit();
    itemDurationController.text = AppCommerceConstants.minDuration.toString();
    itemToQuote.duration = (AppCommerceConstants.minDuration*AppCommerceConstants.durationConvertionPerSize).ceil();
    itemQtyController.text = AppCommerceConstants.minQty.toString();
    itemQty = AppCommerceConstants.minQty;
    updateQuotation();
    logger.d("Settings Controller Init");

    for (var country in countries) {
      if(Get.locale!.countryCode == country.code){
        phoneCountry.value = country; //Mexico
      }
    }

    isLoading.value = false;
  }

  @override
  void setAppItemSize(String selectedSize){
    logger.d("Setting new locale");
    try {
      itemToQuote.size = EnumToString.fromString(AppItemSize.values, selectedSize)
          ?? AppItemSize.a4;

      setAppItemDuration();
    } catch (e) {
      logger.toString();
    }

    update([AppPageIdConstants.quotation]);
  }

  @override
  void setAppItemDuration() {
    logger.d("");

    int newDuration = int.parse(itemDurationController.text.trim());

    if(itemToQuote.size == AppItemSize.a4) {
      newDuration = (newDuration*AppCommerceConstants.durationConvertionPerSize).round();
    }

    if(newDuration >= AppCommerceConstants.minDuration){
      itemToQuote.duration = newDuration;
    } else {
      // itemToQuote.duration = AppCommerceConstants.minQty;
      // AppUtilities.showSnackBar("Mínimo de páginas requerido",
      //     "El mínimo de páginas recomendado para iniciar un proceso de publicación es de $itemQty");
    }
    updateQuotation();
    update([AppPageIdConstants.quotation]);
  }

  @override
  void setAppItemQty() {
    logger.d("");

    int newItemQty = int.parse(itemQtyController.text.trim());

    if(newItemQty > AppCommerceConstants.minQty){
      itemQty = newItemQty;
    } else {
      // itemQty = AppCommerceConstants.minQty;
      // AppUtilities.showSnackBar("Mínimo de libros requerido", "El mínimo de libros a imprimir es de $itemQty");
    }
    updateQuotation();
    update([AppPageIdConstants.quotation]);
  }

  @override
  void setIsPhysical() async {
    logger.d("");
    isPhysical.value = !isPhysical.value;
    updateQuotation();
    update([AppPageIdConstants.quotation]);
  }

  @override
  void setProcessARequired() async {
    logger.d("");
    processARequired.value = !processARequired.value;
    updateQuotation();
    update([AppPageIdConstants.quotation]);
  }

  @override
  void setProcessBRequired() async {
    logger.d("");
    processBRequired.value = !processBRequired.value;
    updateQuotation();
    update([AppPageIdConstants.quotation]);
  }

  @override
  void setCoverDesignRequired() async {
    logger.d("");
    coverDesignRequired.value = !coverDesignRequired.value;
    updateQuotation();
    update([AppPageIdConstants.quotation]);
  }

  @override
  void updateQuotation() {
    pricePerUnit = isPhysical.value ? (itemToQuote.duration * AppCommerceConstants.costPerDurationUnit).roundToDouble() : 0;
    processACost = processARequired.value ? (itemToQuote.duration * AppCommerceConstants.processACost).round() : 0;
    processBCost = processBRequired.value ? (itemToQuote.duration * AppCommerceConstants.processBCost).round() : 0;
    addRevenuePercentage();
    coverDesignCost = coverDesignRequired.value ? AppCommerceConstants.coverDesignCost : 0;
    totalCost = processACost + processBCost + coverDesignCost + (pricePerUnit*itemQty);
    update([AppPageIdConstants.quotation]);
  }

  @override
  void addRevenuePercentage() {
    pricePerUnit = (pricePerUnit * (1+AppCommerceConstants.revenuePercentage)).roundToDouble();
    processACost = (processACost * (1+AppCommerceConstants.revenuePercentage)).round();
    processBCost = (processBCost * (1+AppCommerceConstants.revenuePercentage)).round();
  }

  @override
  Future<void> sendWhatsappQuotation() async {

    String message = "";
    String phone = "";
    String validateMsg = "";

    try {

      message = "${userController.user!.userRole == UserRole.subscriber
          ? AppTranslationConstants.subscriberQuotationWhatsappMsg.tr : AppTranslationConstants.adminQuotationWhatsappMsg.tr}\n"
          "${itemToQuote.duration != 0 ? "\n${AppTranslationConstants.appItemDuration.tr}: ${itemToQuote.duration}" : ""}"
          "${(itemQty != 0 && isPhysical.value) ? "\n${AppTranslationConstants.appItemQty.tr}: $itemQty\n" : ""}"
          "${processACost != 0 ? "\n${AppTranslationConstants.processA.tr}: \$$processACost MXN" : ""}"
          "${processBCost != 0 ? "\n${AppTranslationConstants.processB.tr}: \$$processBCost MXN" : ""}"
          "${coverDesignCost != 0 ? "\n${AppTranslationConstants.coverDesign.tr}: \$$coverDesignCost MXN" : ""}"
          "${pricePerUnit != 0 ? "\n${AppTranslationConstants.pricePerUnit.tr}: \$$pricePerUnit MXN\n" : ""}"
          "${totalCost != 0 ? "\n${AppTranslationConstants.totalToPay.tr}: \$${totalCost.toString()} MXN\n\n" : ""}"
          "${AppTranslationConstants.thanksForYourAttention.tr}\n"
          "${userController.profile.name}";

      if(userController.user!.userRole == UserRole.subscriber) {
        phone = AppFlavour.getWhatsappBusinessNumber();
      } else {
        if (controllerPhone.text.isEmpty &&
            (controllerPhone.text.length < phoneCountry.value.minLength
                || controllerPhone.text.length > phoneCountry.value.maxLength)
        ) {
          validateMsg = MessageTranslationConstants.pleaseEnterPhone;
          phoneNumber = "";
        } else if (phoneCountry.value.code.isEmpty) {
          validateMsg = MessageTranslationConstants.pleaseEnterCountryCode;
          phoneNumber = "";
        } else {
          phoneNumber = controllerPhone.text;
          phone = phoneCountry.value.dialCode + phoneNumber;
        }
      }


      if(phone.isNotEmpty) {
        AppUtilities.logger.i("Sending WhatsApp Quotation to $phone");
        CoreUtilities.launchWhatsappURL(phone, message);
      } else {
        AppUtilities.showSnackBar(title: AppTranslationConstants.whatsappQuotation, message: validateMsg);
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    update([AppPageIdConstants.quotation]);
  }

}
