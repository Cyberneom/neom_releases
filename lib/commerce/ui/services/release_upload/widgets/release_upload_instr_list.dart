import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:neom_commons/core/domain/model/instrument.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import '../release_upload_controller.dart';

class ReleaseUploadInstrList extends StatelessWidget{
  const ReleaseUploadInstrList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ReleaseUploadController>(
      id: AppPageIdConstants.releaseUpload,
      builder: (_) => ListView.separated(
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (__, index) {
          Instrument instrument = _.instrumentController.instruments.values.elementAt(index);
          return ListTile(
            onTap: () => _.instrumentsUsed.contains(instrument.name) ? _.removeInstrument(index) : _.addInstrument(index),
            title: Center(child: Text(instrument.name.tr.capitalizeFirst, style: const TextStyle(fontSize: AppTheme.chipsFontSize)),),
            tileColor: _.instrumentsUsed.contains(instrument.name) ? AppColor.getMain() : Colors.transparent,
          );
        },
        itemCount: _.instrumentController.instruments.length-1,
      ),
    );
  }
}
