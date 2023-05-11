import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';

import 'package:neom_commons/core/domain/model/app_item.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import '../../event_controller.dart';

class CreateEventItemList extends StatelessWidget{
  const CreateEventItemList({Key? key}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return GetBuilder<EventController>(
        id: AppPageIdConstants.event,
        builder: (_) => ListView.builder(
          itemCount: _.totalBandItems.isEmpty ? _.totalItems.length : _.totalBandItems.length,
          itemBuilder: (__, index) {
            AppItem appItem = AppItem();
            if(_.totalBandItems.isEmpty) {
              appItem = _.totalItems.values.elementAt(index);
            } else {
              appItem = _.totalBandItems.values.elementAt(index);
            }

            return ListTile(
              onTap: () => _.requiredItems.containsKey(appItem.id) ? _.removeAppItem(appItem)
                : _.addAppItem(appItem),
              title: Text(appItem.name.length > AppConstants.maxAppItemNameLength
                  ? "${appItem.name.substring(0,AppConstants.maxAppItemNameLength)}...": appItem.name),
              subtitle: Text(appItem.artist.length > AppConstants.maxArtistNameLength ?
                    "${appItem.artist.substring(0,AppConstants.maxArtistNameLength)}..."
                  : appItem.artist),
              trailing: Icon(Icons.multitrack_audio_sharp,
                color: _.requiredItems.containsKey(appItem.id) ? Colors.deepPurple : Colors.grey),
              tileColor: _.requiredItems.containsKey(appItem.id) ? AppColor.getMain() : Colors.transparent,
              leading: CachedNetworkImage(
                imageUrl: appItem.albumImgUrl.isNotEmpty ? appItem.albumImgUrl
                  : AppFlavour.getNoImageUrl(),
                width: 50,height: 50,),
          );
        },
      ),
    );
  }
}
