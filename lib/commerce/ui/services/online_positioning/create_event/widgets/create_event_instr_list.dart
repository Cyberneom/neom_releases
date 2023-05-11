import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:neom_commons/core/domain/model/instrument.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import '../../event_controller.dart';

class CreateEventInstrList extends StatelessWidget{
  const CreateEventInstrList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<EventController>(
      id: AppPageIdConstants.event,
      builder: (_) => ListView.separated(
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (__, index) {
          Instrument instrument = _.instrumentController.instruments.values.elementAt(index);

          int instrumentCounter = 0;

          for (var instr in _.requiredInstruments) {
            if(instrument == instr) {
              instrumentCounter++;
            }
          }

          return ListTile(
            onTap: () => _.addInstrument(index),
            title: Text(instrument.name.tr),
            trailing: SizedBox(
              width: AppTheme.fullWidth(context)/3,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _.requiredInstruments.contains(instrument) ?
                    Row(
                        children: [
                          IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: ()=>{
                                _.removeInstrument(index)
                              }
                          ),
                          Text(instrumentCounter.toString()),
                          IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: ()=>{
                                _.addInstrument(index)
                              }
                          )
                        ])
                        : const Icon(Icons.multitrack_audio_sharp, color: Colors.grey)
                  ]),
            ),
            tileColor: _.requiredInstruments.contains(instrument) ? AppColor.getMain() : Colors.transparent,
          );
        },
        itemCount: _.instrumentController.instruments.length,
      ),
    );
  }
}
