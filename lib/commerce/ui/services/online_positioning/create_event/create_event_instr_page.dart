import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/ui/widgets/header_intro.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/constants/message_translation_constants.dart';
import 'package:neom_commons/core/utils/enums/app_in_use.dart';
import 'package:neom_commons/core/utils/enums/profile_type.dart';
import 'package:neom_commons/core/utils/enums/vocal_type.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

import '../event_controller.dart';
import 'widgets/create_event_instr_list.dart';

class CreateEventInstrPage extends StatelessWidget {
  const CreateEventInstrPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<EventController>(
      id: AppPageIdConstants.event,
      builder: (_) => Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBarChild(color: Colors.transparent),
        body: Container(
          decoration: AppTheme.appBoxDecoration,
          child: Column(
              children: <Widget>[
                AppTheme.heightSpace50,
                HeaderIntro(subtitle: AppTranslationConstants.createEventInstr.tr),
                const Expanded(child: CreateEventInstrList(),),
              ]
          ),
        ),
      floatingActionButton: _.requiredInstruments.isNotEmpty ? FloatingActionButton(
          tooltip: AppTranslationConstants.next.tr,
          elevation: AppTheme.elevationFAB,
          child: const Icon(Icons.navigate_next),
          onPressed: () {
            if(_.requiredInstruments.isEmpty) {
              Get.snackbar(
                  MessageTranslationConstants.introInstrumentSelection.tr,
                  MessageTranslationConstants.introInstrumentMsg.tr,
                  snackPosition: SnackPosition.bottom);
            } else if (_.profile.type == ProfileType.instrumentist && (_.profile.instruments?.isNotEmpty ?? false)) {
              Set<String> participantInstruments = {};
              for (var requiredInstrument in _.requiredInstruments) {
                if(!participantInstruments.contains(requiredInstrument.name)) {
                  for (var instrumentName in _.profile.instruments!.keys) {
                    if(requiredInstrument.name == instrumentName) {
                      participantInstruments.add(instrumentName);
                    }
                  }
                }
              }
              participantInstruments.add(AppTranslationConstants.none);

              if(_.selectedInstrument.name.isEmpty) {
                _.setInstrumentToFulfill();
              }

              Alert(
                  context: context,
                  style: AlertStyle(
                    backgroundColor: AppColor.main50,
                    titleStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  title: AppTranslationConstants.playingRole.tr,
                  content: Column(
                    children: <Widget>[
                      participantInstruments.isNotEmpty ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${
                              AppFlavour.appInUse == AppInUse.gigmeout
                                  ? AppTranslationConstants.instrument.tr
                                  : AppTranslationConstants.participation.tr.capitalizeFirst!}:'),
                          Obx(()=>
                              DropdownButton<String>(
                                items: participantInstruments.map((String instrumentName) {
                                  return DropdownMenuItem<String>(
                                    value: instrumentName,
                                    child: Text(instrumentName.tr.capitalizeFirst!),
                                  );
                                }).toList(),
                                onChanged: (String? instrumentToFulfill) {
                                  _.setInstrumentToFulfill(selectedInstr: instrumentToFulfill ?? "");
                                },
                                value: _.selectedInstrument.name.isNotEmpty
                                    ? _.selectedInstrument.name : AppTranslationConstants.none,
                                alignment: Alignment.center,
                                icon: const Icon(Icons.arrow_downward),
                                iconSize: 20,
                                elevation: 16,
                                dropdownColor: AppColor.main75,
                              ),
                          ),
                        ],
                      ) : const SizedBox(),
                      (_.profile.instruments!.containsKey(AppTranslationConstants.vocal)
                          || _.profile.instruments!.containsKey(AppTranslationConstants.vocal.tr)
                          || AppFlavour.appInUse == AppInUse.emxi
                      ) ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${
                          AppFlavour.appInUse == AppInUse.gigmeout
                              ? AppTranslationConstants.vocalType.tr
                              : AppTranslationConstants.moderator.tr
                          }:'),
                          Obx(()=>
                              DropdownButton<String>(
                                items: VocalType.values.map((VocalType vocalType) {
                                  return DropdownMenuItem<String>(
                                    value: vocalType.name,
                                    child: Text(vocalType.name.toLowerCase().tr),
                                  );
                                }).toList(),
                                onChanged: (String? vocalType) {
                                  _.setVocalTypeToFulfill(vocalType ?? "");
                                },
                                value: _.selectedVocalType.name.isNotEmpty
                                    ? _.selectedVocalType.name
                                    : VocalType.main.name,
                                alignment: Alignment.center,
                                icon: const Icon(Icons.arrow_downward),
                                iconSize: 20,
                                elevation: 16,
                                dropdownColor: AppColor.main75,
                              ),
                          ),
                        ],) : Container()
                    ],
                  ),
                  buttons: [
                    DialogButton(
                      color: AppColor.bondiBlue75,
                      onPressed: () => {
                        _.createInstrumentFulfillment()
                      },
                      child: Text(AppTranslationConstants.select.tr,
                        style: const TextStyle(fontSize: 15),
                      ),
                    )
                  ]
              ).show();
            } else {
              _.createInstrumentFulfillment();
            }
          },
        ) : Container(),
      ),
    );
  }
}
