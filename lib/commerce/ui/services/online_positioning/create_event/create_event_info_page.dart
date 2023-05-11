import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/ui/widgets/header_intro.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/enums/app_in_use.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import '../event_controller.dart';
import 'widgets/input_dropdown.dart';

class CreateEventInfoPage extends StatelessWidget {
  const CreateEventInfoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return GetBuilder<EventController>(
      id: AppPageIdConstants.event,
      builder: (_) {
         return Scaffold(
           extendBodyBehindAppBar: true,
           appBar: AppBarChild(color: Colors.transparent),
           body: SingleChildScrollView(
           child: Container(
             padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding10),
             decoration: AppTheme.appBoxDecoration,
             height: MediaQuery.of(context).size.height,
              child: Column(
                children: <Widget>[
                  AppTheme.heightSpace50,
                  HeaderIntro(subtitle: AppTranslationConstants.createEventPlace.tr),
                  AppTheme.heightSpace20,
                  // GestureDetector(
                  //   child: Row(
                  //     mainAxisAlignment: MainAxisAlignment.center,
                  //     children: <Widget>[
                  //       Checkbox(
                  //         value: _.isChecked,
                  //         onChanged: (bool? newValue) {
                  //           _.setCheckboxState();
                  //         },
                  //       ),
                  //       Text(AppTranslationConstants.dontHaveThisInfoYet.tr),
                  //     ],
                  //   ),
                  //   onTap: ()=>_.setCheckboxState(),
                  // ),
                  AppFlavour.appInUse == AppInUse.emxi ? GestureDetector(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Checkbox(
                          value: _.isOnlineEvent,
                          onChanged: (bool? newValue) {
                            _.setIsOnlineCheckboxState();
                          },
                        ),
                        Text(AppTranslationConstants.onlineEvent.tr),
                      ],
                    ),
                    onTap: ()=>_.setIsOnlineCheckboxState(),
                  ) :  Container(),
                  _.isChecked || _.isOnlineEvent ? Container() : Container(
                    padding: const EdgeInsets.all(10),
                    child: TextFormField(
                      controller: _.placeController,
                      onTap:() => _.getEventPlace(context) ,
                      decoration: InputDecoration(
                        filled: true,
                        labelText: AppTranslationConstants.specifyEventPlace.tr,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  _.isChecked ? Container() : Container(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          flex: 4,
                          child: InputDropdown(
                            labelText: AppTranslationConstants.date.tr,
                            valueText: _.eventDate == DateTime.now() ? ""
                                : DateFormat.yMMMd(AppTranslationConstants.esMx).format(_.eventDate),
                            valueStyle: Theme.of(context).textTheme.bodyLarge!,
                            onPressed: () async {
                              await showModalBottomSheet(
                                elevation: 20,
                                context: context,
                                builder: (BuildContext context) {
                                return SfDateRangePicker(
                                  onSelectionChanged: _.setEventDate,
                                  selectionColor: AppColor.bondiBlue75,
                                  todayHighlightColor: AppColor.white,
                                  minDate: DateTime.now(),
                                  maxDate: DateTime.now().add(const Duration(days: 120)),
                                  selectionMode: DateRangePickerSelectionMode.single,
                                  backgroundColor: AppColor.main50,
                                  enablePastDates: false,
                                  initialSelectedDate: DateTime.now(),
                                );
                              });
                            },
                          ),
                        ),
                        AppTheme.widthSpace10,
                        Expanded(
                          flex: 3,
                          child: InputDropdown(
                            labelText: AppTranslationConstants.time.tr,
                            valueText: _.eventTime.format(context),
                            valueStyle: Theme.of(context).textTheme.bodyLarge!,
                            onPressed: () async {
                              await _.setEventTime(context);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppTheme.heightSpace20,
                  Obx(()=>
                  _.isChecked || _.isOnlineEvent ? Container() : SizedBox(
                    width: 225,
                    height: 225,
                    child: GoogleMap(
                      mapType: MapType.normal,
                      initialCameraPosition: _.mapsController.getCameraPosition(_.profile.position!),
                      onMapCreated: (GoogleMapController controller) {
                        try {
                          _.mapsController.controller.complete(controller);
                        } catch (e) {
                          _.logger.i(e.toString());
                        }
                      },
                    ),
                  )),
                ],
              )
             ),
          ),
           floatingActionButton: _.validateInfo() || _.isChecked ? FloatingActionButton(
             tooltip: AppTranslationConstants.next.tr,
             elevation: AppTheme.elevationFAB,
             onPressed: ()=>{
               _.addInfoToEvent()
             },
             child: const Icon(Icons.navigate_next),
           ) : Container(),
         );
      }
    );
  }
}
