import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/ui/widgets/header_intro.dart';
import 'package:neom_commons/core/ui/widgets/header_widget.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/constants/intl_countries_list.dart';
import 'package:neom_commons/core/utils/enums/app_in_use.dart';
import 'package:neom_commons/core/utils/enums/app_item_size.dart';
import 'package:neom_commons/core/utils/enums/user_role.dart';

import 'quotation_controller.dart';

class QuotationPage extends StatelessWidget {

  const QuotationPage({super.key});


  @override
  Widget build(BuildContext context) {
    return GetBuilder<QuotationController>(
      init: QuotationController(),
      id: AppPageIdConstants.quotation,
      builder: (_) => Scaffold(
        appBar: AppBarChild(title: AppTranslationConstants.appItemQuotation.tr),
        body: Container(
          decoration: AppTheme.appBoxDecoration,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            children: <Widget>[
              HeaderWidget(AppTranslationConstants.appItemDuration.tr, secondHeader: true),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: AppTheme.fullWidth(context)/3,
                        child: TextFormField(
                          controller: _.itemDurationController,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r"^\d+\.?\d{0,2}")),
                            LengthLimitingTextInputFormatter(5),
                          ],
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                              filled: true,
                              hintText: AppTranslationConstants.specifyAppItemDuration.tr,
                              labelText: AppTranslationConstants.appItemDurationShort.tr,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              )),
                          onChanged: (text) {
                            if(text.isNotEmpty) _.setAppItemDuration();
                          },
                        ),
                      ),
                      DropdownButton<String>(
                        items: AppItemSize.values.map((AppItemSize size) {
                          return DropdownMenuItem<String>(
                            value: size.value,
                            child: SizedBox(
                              width: AppTheme.fullWidth(context)/3,
                              child: Text(size.value.toUpperCase().tr,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? chosenSize) {
                          _.setAppItemSize(chosenSize!);
                        },
                        value: _.itemToQuote.size.value,
                        elevation: 20,
                        dropdownColor: AppColor.getMain(),
                        underline: const SizedBox.shrink(),
                      ),
                    ],
                  )
              ),
              if(_.itemToQuote.size == AppItemSize.a4)
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                    AppTranslationConstants.appSizeWarningMsg.tr,
                    textAlign: TextAlign.justify,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w400),
                  )
                ),
              HeaderWidget(AppTranslationConstants.appItemQty.tr, secondHeader: true),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: AppTheme.fullWidth(context)/3,
                        child: TextFormField(
                          controller: _.itemQtyController,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r"^\d+\.?\d{0,2}")),
                            LengthLimitingTextInputFormatter(5),
                          ],
                          keyboardType: TextInputType.number,
                          enabled: _.isPhysical.value,
                          decoration: InputDecoration(
                              filled: true,
                              hintText: AppTranslationConstants.specifyAppItemQty.tr,
                              labelText: AppTranslationConstants.appItemQty.tr,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              )),
                          onChanged: (text) {
                            _.setAppItemQty() ;
                          },
                        ),
                      ),
                      SizedBox(
                        width: AppTheme.fullWidth(context)/2,
                        child: CheckboxListTile(
                          title: Text(AppTranslationConstants.appDigitalItem.tr),
                          value: !_.isPhysical.value,
                          onChanged: (bool? newValue) {
                            _.setIsPhysical();
                          },
                        ),
                      ),
                    ],
                  )
              ),
              HeaderWidget(AppTranslationConstants.processAAndB.tr, secondHeader: true),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CheckboxListTile(
                      title: Text(AppTranslationConstants.processA.tr),
                      value: _.processARequired.value,
                      onChanged: (value) => _.setProcessARequired(),
                    ),
                    CheckboxListTile(
                      title: Text(AppTranslationConstants.processB.tr),
                      value: _.processBRequired.value,
                      onChanged: (value) => _.setProcessBRequired(),
                    ),
                    CheckboxListTile(
                      title: Text(AppTranslationConstants.coverDesignRequired.tr),
                      value: _.coverDesignRequired.value,
                      onChanged: (value) => _.setCoverDesignRequired(),
                    ),
                  ],
                ),
              ),
              const Divider(),
              _.totalCost != 0 ? HeaderWidget(
                  AppTranslationConstants.total.tr, secondHeader: true)
                  : const SizedBox.shrink(),
              _.totalCost != 0 ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _.processARequired.value
                        ? buildQuotationInfo(
                        title: AppTranslationConstants.processA.tr,
                        subtitle: _.processACost.toString()
                    ) : const SizedBox.shrink(),
                    _.processBRequired.value
                        ? buildQuotationInfo(
                        title: AppTranslationConstants.processB.tr,
                        subtitle: _.processBCost.toString()
                    ) : const SizedBox.shrink(),
                    _.coverDesignRequired.value
                        ? buildQuotationInfo(
                        title: AppTranslationConstants.coverDesign.tr,
                        subtitle: _.coverDesignCost.toString(),
                    ) : const SizedBox.shrink(),
                    _.isPhysical.value
                        ? buildQuotationInfo(
                        title: "${AppTranslationConstants.pricePerUnit.tr} x ${_.itemQty}",
                        subtitle: _.pricePerUnit.toString()
                    ) : const SizedBox.shrink(),
                    const Divider(),
                    _.totalCost != 0
                        ? buildQuotationInfo(
                        title: AppTranslationConstants.totalToPay.tr,
                        subtitle: _.totalCost.toString()
                    ) : const SizedBox.shrink(),
                    _.totalCost != 0 ? Text(
                        "${AppTranslationConstants.quotationTotalMsg1.tr} ${_.itemToQuote.duration} ${AppTranslationConstants.quotationTotalMsg2.tr}",
                      textAlign: TextAlign.justify,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w400),
                    ) : const SizedBox.shrink(),
                    const Divider(),
                    AppFlavour.appInUse == AppInUse.e && _.userController.user!.userRole != UserRole.subscriber ?
                    Column(
                      children: [
                        buildPhoneField(quotationController: _),
                        AppTheme.heightSpace10
                      ],) : const SizedBox.shrink(),
                    Center(child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20,vertical: 20),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: AppColor.bondiBlue
                      ),
                      child: InkWell(
                        child: Text(_.userController.user!.userRole == UserRole.subscriber ?
                        AppTranslationConstants.contactUsViaWhatsapp.tr : "${AppTranslationConstants.send.tr} ${AppTranslationConstants.whatsappQuotation.tr}",
                          style: const TextStyle(color: Colors.white),),
                        onTap: () {
                          _.sendWhatsappQuotation();
                        },
                      ),
                    ),),
                    AppTheme.heightSpace10,
                    const HeaderIntro(showLogo: false),
                  ],
                ),
              ) : const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }

  ///DEPRECATED
  // Widget buildCheckBoxItem(bool checkedValue, {Function? action, String title = "",}) {
  //   return GestureDetector(
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //       children: <Widget>[
  //         Text(title, style: const TextStyle(fontSize: 15)),
  //         Checkbox(
  //           value: checkedValue,
  //           onChanged: (bool? newValue) => action != null ? action() : {},
  //         ),
  //       ],
  //     ),
  //     onTap: () => action != null ? action() : {},
  //   );
  // }

  Widget buildQuotationInfo({String title = "", String subtitle = ""}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(title, style: const TextStyle(fontSize: 18)),
          Text("\$$subtitle MXN", style: const TextStyle(fontSize: 18)),
        ],
      ),
    );
  }

  Widget buildPhoneField({required QuotationController quotationController}) {
    return Container(
        padding: const EdgeInsets.only(
          left: AppTheme.padding20,
          right: AppTheme.padding20,
          bottom: AppTheme.padding5,
        ),
        decoration: BoxDecoration(
          color: AppColor.bondiBlue25,
          borderRadius: BorderRadius.circular(40),
        ),
        child: IntlPhoneField(
          countries: IntlPhoneConstants.availableCountries,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: '${AppTranslationConstants.phoneNumber.tr} (${AppTranslationConstants.optional.tr})',
            alignLabelWithHint: true,
          ),
          pickerDialogStyle: PickerDialogStyle(
              backgroundColor: AppColor.getMain(),
              searchFieldInputDecoration: InputDecoration(
                labelText: AppTranslationConstants.searchByCountryName.tr,
              )
          ),
          initialCountryCode: IntlPhoneConstants.initialCountryCode,
          onChanged: (phone) {
            quotationController.controllerPhone.text = phone.number;
          },
          onCountryChanged: (country) {
            quotationController.phoneCountry.value = country;
          },
        )
    );
  }


}
