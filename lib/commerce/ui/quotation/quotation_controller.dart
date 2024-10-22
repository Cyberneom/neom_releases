import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:neom_commons/core/domain/model/app_physical_item.dart';
import 'package:neom_commons/core/utils/constants/intl_countries_list.dart';
import 'package:neom_commons/core/utils/enums/app_item_size.dart';
import 'package:neom_commons/neom_commons.dart';

import '../../data/firestore/quotation_firestore.dart';
import '../../domain/models/app_quotation.dart';
import '../../domain/use_cases/quotation_service.dart';

class QuotationController extends GetxController implements QuotationService {
  
  final loginController = Get.find<LoginController>();
  final userController = Get.find<UserController>();

  bool isLoading = true;
  bool processARequired = false;
  bool processBRequired = false;
  bool coverDesignRequired = false;
  bool flapRequired = false;
  bool onlyPrinting = false;
  bool onlyDigital = false;

  final Rx<Country> phoneCountry = IntlPhoneConstants.availableCountries[0].obs;

  AppPhysicalItem itemToQuote = AppPhysicalItem();
  AppQuotation defaultQuotation = AppQuotation();
  double costPerDurationUnit = 0;
  int itemQty = 0;
  int processACost = 0;
  int processBCost = 0;
  int coverDesignCost = 0;
  double pricePerUnit = 0;
  double subtotalCost = 0;
  double taxCost = 0;
  double totalCost = 0;

  PaperType paperType = PaperType.uncoated90;
  CoverLamination coverLamination = CoverLamination.matte;

  TextEditingController itemQtyController = TextEditingController();
  TextEditingController itemDurationController = TextEditingController();
  TextEditingController controllerPhone = TextEditingController();

  String phoneNumber = '';
  String phoneCountryCode = '';

  @override
  void onInit() async {
    super.onInit();
    defaultQuotation = await QuotationFirestore().retrieve('default');
    itemToQuote.duration = defaultQuotation.minDuration*3; // 25*3 min for books
    itemDurationController.text = itemToQuote.duration.toString();
    itemQtyController.text = defaultQuotation.minQty.toString();
    itemQty = defaultQuotation.minQty;
    updateQuotation();
    AppUtilities.logger.d("Settings Controller Init");

    for (var country in IntlPhoneConstants.availableCountries) {
      if(Get.locale!.countryCode == country.code){
        phoneCountry.value = country; //Mexico
      }
    }

    if(userController.user.phoneNumber.isNotEmpty && userController.user.countryCode.isNotEmpty) {
      phoneNumber = userController.user.phoneNumber;
      phoneCountryCode = userController.user.countryCode;
    }

    isLoading = false;
  }

  @override
  void onReady() async {
    try {
      ///THIS IS USED TO GENERATE DEFAULT QUOTATION VALUES FOR DYNAMIC USE
      // AppQuotation defaultQuotation = AppQuotation(id: 'default', from: userController.user.id);  // Create a quotation with default values
      // String quotationId = await QuotationFirestore().insert(defaultQuotation);

    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    update([AppPageIdConstants.quotation]);
  }


  @override
  void setAppItemSize(String selectedSize) {
    AppUtilities.logger.t("Setting new itemSize");
    try {
      itemToQuote.size = EnumToString.fromString(AppItemSize.values, selectedSize)
          ?? AppItemSize.halfLetter;

      setAppItemDuration();
    } catch (e) {
      AppUtilities.logger.toString();
    }

    update([AppPageIdConstants.quotation]);
  }

  @override
  void setPaperType(String selectedType) {
    AppUtilities.logger.t("Setting new type");
    try {
      paperType = EnumToString.fromString(PaperType.values, selectedType)
          ?? PaperType.uncoated90;
      updateQuotation();
    } catch (e) {
      AppUtilities.logger.toString();
    }

    update([AppPageIdConstants.quotation]);
  }

  @override
  void setCoverLamination(String selectedLamination) {
    AppUtilities.logger.t("Setting new type");
    try {
      coverLamination = EnumToString.fromString(CoverLamination.values, selectedLamination)
          ?? CoverLamination.matte;
      updateQuotation();
    } catch (e) {
      AppUtilities.logger.toString();
    }

    update([AppPageIdConstants.quotation]);
  }

  @override
  void setAppItemDuration() {
    AppUtilities.logger.t("setAppItemDuration");


    if(itemDurationController.text.isNotEmpty) {
      int newDuration = int.parse(itemDurationController.text.trim());

      if(itemToQuote.size == AppItemSize.letter) {
        newDuration = (newDuration*defaultQuotation.durationConvertionPerSize).round();
      }

      if(newDuration >= defaultQuotation.minDuration){
        itemToQuote.duration = newDuration;
      } else {
        // itemToQuote.duration = defaultQuotation.minQty;
        // AppUtilities.showSnackBar("Mínimo de páginas requerido",
        //     "El mínimo de páginas recomendado para iniciar un proceso de publicación es de $itemQty");
      }
      updateQuotation();
    }

    update([AppPageIdConstants.quotation]);
  }

  @override
  void setAppItemQty() {
    AppUtilities.logger.t("setAppItemQty");

    if(itemQtyController.text.isNotEmpty) {
      int newItemQty = int.parse(itemQtyController.text.trim());
      if(newItemQty > defaultQuotation.minQty){
        itemQty = newItemQty;
      } else {
        itemQty = defaultQuotation.minQty;
        // AppUtilities.showSnackBar("Mínimo de libros requerido", "El mínimo de libros a imprimir es de $itemQty");
      }
      updateQuotation();
    }

    update([AppPageIdConstants.quotation]);
  }

  @override
  void setOnlyPrinting() async {
    AppUtilities.logger.t("setOnlyPrinting");
    onlyPrinting = !onlyPrinting;
    onlyDigital = false;
    if(onlyPrinting) {
      processARequired = false;
      processBRequired = false;
      coverDesignRequired = false;
    }
    updateQuotation();
    update([AppPageIdConstants.quotation]);
  }

  @override
  void setOnlyDigital() async {
    AppUtilities.logger.t("setOnlyDigital");
    onlyDigital = !onlyDigital;
    onlyPrinting = false;
    if(onlyDigital) {
      itemQty = 0;
    } else {
      setAppItemQty();
    }
    updateQuotation();
    update([AppPageIdConstants.quotation]);
  }


  @override
  void setProcessARequired() async {
    AppUtilities.logger.t("setProcessARequired");
    processARequired = !processARequired;
    updateQuotation();
    update([AppPageIdConstants.quotation]);
  }

  @override
  void setProcessBRequired() async {
    AppUtilities.logger.t("setProcessBRequired");
    processBRequired = !processBRequired;
    updateQuotation();
    update([AppPageIdConstants.quotation]);
  }

  @override
  void setCoverDesignRequired() async {
    AppUtilities.logger.t("setCoverDesignRequired");
    coverDesignRequired = !coverDesignRequired;
    updateQuotation();
    update([AppPageIdConstants.quotation]);
  }

  @override
  void setFlapRequired() async {
    AppUtilities.logger.t("setFlapRequired");
    flapRequired = !flapRequired;
    updateQuotation();
    update([AppPageIdConstants.quotation]);
  }

  @override
  void updateQuotation() {
    AppUtilities.logger.t("Updating Quotation");


    if(!onlyDigital) {
      if(itemQty <= defaultQuotation.minQty) {
        costPerDurationUnit = defaultQuotation.maxCostPerDurationUnit;
      } else if(itemQty >= defaultQuotation.midQty) {
        costPerDurationUnit = defaultQuotation.minCostPerDurationUnit;
      } else {
        double interpolation = (itemQty - defaultQuotation.minQty) / (defaultQuotation.midQty - defaultQuotation.minQty);
        costPerDurationUnit = defaultQuotation.maxCostPerDurationUnit - interpolation
            * (defaultQuotation.maxCostPerDurationUnit - defaultQuotation.minCostPerDurationUnit);
      }

      switch(itemToQuote.size) {
        case AppItemSize.quarterLetter:
          costPerDurationUnit = costPerDurationUnit * defaultQuotation.lowSizeRelation;
          break;
        case AppItemSize.letter:
          costPerDurationUnit = costPerDurationUnit * defaultQuotation.highSizeRelation;
          break;
        default:
          break;
      }

      switch(paperType) {
        case PaperType.bond75:
          costPerDurationUnit = costPerDurationUnit * defaultQuotation.lowQualityRelation;
          break;
        case PaperType.couche130:
          costPerDurationUnit = costPerDurationUnit * defaultQuotation.highQualityRelation;
          break;
        default:
          break;
      }

      pricePerUnit = (itemToQuote.duration * costPerDurationUnit) + (flapRequired ? defaultQuotation.costPerFlap : 0)
          + (defaultQuotation.prePrintCost/itemQty).roundToDouble();
    } else {
      pricePerUnit = 0;
    }

    AppUtilities.logger.i("Price per unit: $pricePerUnit");
    processACost = processARequired ? (itemToQuote.duration * defaultQuotation.processACost).round() : 0;
    AppUtilities.logger.i("Price per Process A: $processACost");
    processBCost = processBRequired ? (itemToQuote.duration * defaultQuotation.processBCost).round() : 0;
    AppUtilities.logger.i("Price per Process B: $processBCost");
    addRevenuePercentage();
    coverDesignCost = coverDesignRequired ? defaultQuotation.coverDesignCost : 0;
    AppUtilities.logger.i("Cover Design Cost: $coverDesignCost");
    subtotalCost = processACost + processBCost + coverDesignCost + (pricePerUnit*itemQty);
    taxCost = subtotalCost*defaultQuotation.tax;
    totalCost = subtotalCost+taxCost;
    AppUtilities.logger.i("Total Cost: $totalCost");
    update([AppPageIdConstants.quotation]);
  }

  @override
  void addRevenuePercentage() {
    pricePerUnit = (pricePerUnit * (1+defaultQuotation.revenuePercentage)).roundToDouble();
    processACost = (processACost * (1+defaultQuotation.revenuePercentage)).round();
    processBCost = (processBCost * (1+defaultQuotation.revenuePercentage)).round();
  }

  @override
  Future<void> sendWhatsappQuotation() async {
    AppUtilities.logger.d("Sending WhatsApp Quotation to phone");

    String message = "";
    String phone = "";
    String validateMsg = "";

    try {

      message = "${userController.user.userRole == UserRole.subscriber
          ? AppTranslationConstants.subscriberQuotationWhatsappMsg.tr : AppTranslationConstants.adminQuotationWhatsappMsg.tr}\n"
          "${itemToQuote.duration != 0 ? "\n${AppTranslationConstants.appItemDuration.tr}: ${itemToQuote.duration}" : ""}"
          "${(itemQty != 0 && !onlyDigital) ? "\n${AppTranslationConstants.appItemQty.tr}: $itemQty\n" : ""}"
          "\n${itemToQuote.size.name.tr}\n"
          "${AppTranslationConstants.paperType.tr.capitalize}: ${paperType.name.tr}\n"
          "${AppTranslationConstants.coverLamination.tr.capitalize}: ${coverLamination.name.tr}\n"
          "${flapRequired ? "${AppTranslationConstants.flapRequired.tr}\n" : ""}"
          "${pricePerUnit != 0 ? "\n${AppTranslationConstants.pricePerUnit.tr}: \$${pricePerUnit} MXN\n" : ""}"
          "${processACost != 0 ? "${AppTranslationConstants.processA.tr}: \$${processACost.toDouble()} MXN\n" : ""}"
          "${processBCost != 0 ? "${AppTranslationConstants.processB.tr}: \$${processBCost.toDouble()} MXN\n" : ""}"
          "${coverDesignCost != 0 ? "${AppTranslationConstants.coverDesign.tr}: \$${coverDesignCost.toDouble()} MXN\n" : ""}"
          "${totalCost != 0 ? "\n${AppTranslationConstants.subtotal.tr}: \$${subtotalCost.toString()} MXN\n" : ""}"
          "${taxCost != 0 ? "${AppTranslationConstants.taxes.tr}: \$${taxCost.toStringAsFixed(1)} MXN\n" : ""}"
          "${totalCost != 0 ? "${AppTranslationConstants.totalToPay.tr}: \$${totalCost.toString()} MXN\n\n" : ""}"
          "${AppTranslationConstants.thanksForYourAttention.tr}\n"
          "${userController.profile.name}";

      if(userController.user.userRole != UserRole.subscriber) {
        message = message + '\n\n${MessageTranslationConstants.shareAppMsg.tr}\n'
            '${AppFlavour.getLinksUrl()}\n';
      }

      if(userController.user.userRole == UserRole.subscriber) {
        phone = AppFlavour.getWhatsappBusinessNumber();
      } else if(phoneNumber.isEmpty && phoneCountryCode.isEmpty) {
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
          phoneCountryCode = phoneCountry.value.dialCode;
          phone =  phoneCountryCode + phoneNumber;
        }
      } else {
        phone =  phoneCountryCode + phoneNumber;
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
