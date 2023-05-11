import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/ui/widgets/core_widgets.dart';
import 'package:neom_commons/core/ui/widgets/header_intro.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/enums/event_type.dart';
import 'package:neom_commons/core/utils/enums/usage_reason.dart';
import '../event_controller.dart';

class CreateEventReasonPage extends StatelessWidget {
  const CreateEventReasonPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<EventController>(
        id: AppPageIdConstants.event,
        builder: (_) => Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBarChild(color: Colors.transparent),
          body: Container(
            decoration: AppTheme.appBoxDecoration,
            child: _.isLoading ? const Center(child: CircularProgressIndicator())
          : Center(child: Column(
              children: <Widget>[
                AppTheme.heightSpace50,
                HeaderIntro(subtitle: AppTranslationConstants.createEventReason.tr),
                AppTheme.heightSpace100,
                Column(mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      AppTheme.heightSpace10,
                      buildActionChip(appEnum: UsageReason.fun, controllerFunction: _.setReason),
                      AppTheme.heightSpace10,
                      buildActionChip(appEnum: UsageReason.professional, controllerFunction: _.setReason),
                      AppTheme.heightSpace10,
                      _.event.type == EventType.rehearsal || _.event.type == EventType.jamming
                          ? buildActionChip(appEnum: UsageReason.composition, controllerFunction: _.setReason)
                       : Container(),
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
