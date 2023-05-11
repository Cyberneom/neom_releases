import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';

import 'package:neom_commons/core/domain/model/item_list.dart';
import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/ui/widgets/header_intro.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import '../event_controller.dart';

class CreateEventItemlistsPage extends StatelessWidget {
  const CreateEventItemlistsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GetBuilder<EventController>(
      id: AppPageIdConstants.event,
      builder: (_) => Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBarChild(color: Colors.transparent),
        backgroundColor: AppColor.main50,
        body: Container(
            decoration: AppTheme.boxDecoration,
            height: AppTheme.fullHeight(context),
            child: Column(
              children: [
              AppTheme.heightSpace50,
              HeaderIntro(subtitle: AppTranslationConstants.createEventItemlists.tr),
              AppTheme.heightSpace20,
              _.isLoading ? const Center(child: CircularProgressIndicator())
              : Expanded(
                child: Obx(()=> ListView.builder(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  itemCount: _.itemlists.values.length,
                  itemBuilder: (context, index) {
                    Itemlist itemlist = _.itemlists.values.elementAt(index);
                    return (itemlist.appItems?.isEmpty ?? true) ? Container()
                    : GestureDetector(
                      child: ListTile(
                        leading: SizedBox(
                          width: 50,
                          child: CachedNetworkImage(imageUrl: itemlist.imgUrl.isNotEmpty
                              ? itemlist.imgUrl
                              : (itemlist.appItems!.first.albumImgUrl.isNotEmpty
                              ? itemlist.appItems!.first.albumImgUrl
                              : AppFlavour.getNoImageUrl()
                            )
                          )
                        ),
                        title: Text(itemlist.name.length > AppConstants.maxItemlistNameLength
                          ? "${itemlist.name.substring(0,AppConstants.maxItemlistNameLength)}..."
                          : itemlist.name
                        ),
                        subtitle: Text(itemlist.description),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            (itemlist.appItems?.isNotEmpty ?? false)
                              ? ActionChip(
                                backgroundColor: AppColor.main50,
                                avatar: CircleAvatar(
                                  backgroundColor: AppColor.white80,
                                  child: Text(itemlist.appItems!.length.toString()),
                                ),
                                label: Icon(AppFlavour.getAppItemIcon(),
                                    color: AppColor.white80
                                ),
                                onPressed: () {
                                },
                              ) : Container()
                          ]
                        ),
                      ),
                      onTap: () async {
                        _.setSelectedItemlist(itemlist);
                      },
                    );
                  },
                ),),
              ),],
            ),
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0, 0.35, 1],
              colors: [
                theme.scaffoldBackgroundColor.withOpacity(0),
                theme.scaffoldBackgroundColor,
                theme.scaffoldBackgroundColor,
              ],
            ),
          ),
          child: Container(
            color: AppColor.main50,
            padding: const EdgeInsets.fromLTRB(50, 10, 50, 10),
            child: ElevatedButton.icon(
              style: ButtonStyle(
                  backgroundColor: MaterialStateProperty
                      .all<Color>(AppColor.bondiBlue75)
              ),
              icon: const Icon(CupertinoIcons.search_circle_fill),
              label: Text(AppTranslationConstants.selectSpecificItems.tr),
              onPressed: () => _.gotoTotalItems(),
            ),
          ),
        ),
      ),
    );
  }

}
