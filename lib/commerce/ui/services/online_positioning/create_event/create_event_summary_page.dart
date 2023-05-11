import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/neom_commons.dart';
import '../event_controller.dart';
import 'widgets/create_event_summary_background.dart';
import 'widgets/create_event_summary_rubber_page.dart';


class CreateEventSummaryPage extends StatelessWidget {
  const CreateEventSummaryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<EventController>(
      id: AppPageIdConstants.event,
      builder: (_) => Scaffold(
      body: Container(
        height: AppTheme.fullHeight(context),
        decoration: AppTheme.appBoxDecoration,
        child: Stack(
        alignment: Alignment.center,
        children: const [
          CreateEventSummaryBackground(),
          CreateEventSummaryRubberPage(),
          CustomBackButton(),
        ],
      ),),
    ),
    );
  }

}
