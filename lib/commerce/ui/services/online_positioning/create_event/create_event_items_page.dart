import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/ui/widgets/header_intro.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/constants/message_translation_constants.dart';
import '../event_controller.dart';
import 'widgets/create_event_item_list.dart';

class CreateEventItemsPage extends StatelessWidget {
  const CreateEventItemsPage({Key? key}) : super(key: key);

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
                HeaderIntro(subtitle: AppTranslationConstants.createEventItems.tr),
                const Expanded(child: CreateEventItemList(),),
                ]
              ),
            ),
      floatingActionButton: _.requiredItems.isNotEmpty ? FloatingActionButton(
        elevation: AppTheme.elevationFAB,
        tooltip: AppTranslationConstants.next.tr,
        onPressed: ()=>{
          _.requiredItems.isEmpty
              ? AppUtilities.showAlert(context, MessageTranslationConstants.itemDetails.tr, MessageTranslationConstants.createEventItemsMsg.tr)
              : _.addItemsToEvent()
        },
        child: const Icon(Icons.navigate_next),
      ) : Container(),
    ),);
  }
}
