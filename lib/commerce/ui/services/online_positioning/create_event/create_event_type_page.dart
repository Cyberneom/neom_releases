import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';

import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/ui/widgets/core_widgets.dart';
import 'package:neom_commons/core/ui/widgets/header_intro.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/enums/app_in_use.dart';
import 'package:neom_commons/core/utils/enums/event_type.dart';
import '../event_controller.dart';

class CreateEventTypePage extends StatelessWidget {
  const CreateEventTypePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<EventController>(
        id: AppPageIdConstants.event,
        init: EventController(),
        builder: (_) => Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBarChild(color: Colors.transparent),
          body: Container(
            decoration: AppTheme.appBoxDecoration,
            child: Center(
              child: _.isLoading ? const CircularProgressIndicator()
                  : Column(
                children: <Widget>[
                AppTheme.heightSpace50,
                HeaderIntro(subtitle: AppTranslationConstants.createEventType.tr),
                const SizedBox(height: 80),
                Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      AppTheme.heightSpace10,
                       buildActionChip(
                         appEnum: EventType.rehearsal,
                         controllerFunction: _.setEventType,
                         isActive: AppFlavour.appInUse == AppInUse.gigmeout
                       ),
                      AppTheme.heightSpace10,
                      buildActionChip(
                          appEnum: EventType.jamming,
                          controllerFunction: _.setEventType,
                      ),
                      AppTheme.heightSpace10,
                      buildActionChip(
                          appEnum: AppFlavour.appInUse == AppInUse.gigmeout ? EventType.gig : EventType.analysisCircle,
                          controllerFunction: _.setEventType,
                          isActive: AppFlavour.appInUse == AppInUse.gigmeout
                      ),
                      AppTheme.heightSpace10,
                      AppFlavour.appInUse == AppInUse.gigmeout ? Column(
                        children: [ buildActionChip(
                          appEnum: EventType.festival,
                          controllerFunction: _.setEventType,
                          isActive: false
                        ),
                          AppTheme.heightSpace10,
                        ],) : Container(),
                      // buildActionChip(appEnum: EventType.clinic, controllerFunction: _.setEventType, isActive: false),
                      // AppTheme.heightSpace10,
                      // buildActionChip(appEnum: EventType.colloquium, controllerFunction: _.setEventType, isActive: false),
                      // AppTheme.heightSpace10,
                    ]
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
