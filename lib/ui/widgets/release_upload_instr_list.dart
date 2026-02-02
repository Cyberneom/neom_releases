import 'package:flutter/material.dart';
import 'package:sint/sint.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_core/domain/model/instrument.dart';

import '../release_upload_controller.dart';

class ReleaseUploadInstrList extends StatelessWidget{
  const ReleaseUploadInstrList({super.key});

  @override
  Widget build(BuildContext context) {
    return SintBuilder<ReleaseUploadController>(
      id: AppPageIdConstants.releaseUpload,
      builder: (controller) => ListView.separated(
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (__, index) {
          Instrument instrument = controller.instrumentServiceImpl.instruments.values.elementAt(index);
          return ListTile(
            onTap: () => controller.instrumentsUsed.contains(instrument.name) ? controller.removeInstrument(index) : controller.addInstrument(index),
            title: Center(child: Text(instrument.name.tr.capitalizeFirst, style: const TextStyle(fontSize: AppTheme.chipsFontSize)),),
            tileColor: controller.instrumentsUsed.contains(instrument.name) ? AppColor.getMain() : Colors.transparent,
          );
        },
        itemCount: controller.instrumentServiceImpl.instruments.length-1,
      ),
    );
  }

}
