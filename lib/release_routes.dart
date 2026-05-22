import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:neom_core/ui/deferred_loader.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:sint/sint.dart';

import 'ui/release_upload_page.dart' deferred as release_upload;
import 'ui/web/release_upload_web_page.dart' deferred as release_upload_web;
import 'ui/widgets/release_upload_collective_or_solo_page.dart' deferred as release_col_solo;
import 'ui/widgets/release_upload_genres_page.dart' deferred as release_genres;
import 'ui/widgets/release_upload_info_page.dart' deferred as release_info;
import 'ui/widgets/release_upload_instr_page.dart' deferred as release_instr;
import 'ui/widgets/release_upload_itemlist_name_desc_page.dart' deferred as release_itemlist;
import 'ui/widgets/release_upload_name_desc_page.dart' deferred as release_name_desc;
import 'ui/widgets/release_upload_summary_page.dart' deferred as release_summary;
import 'ui/widgets/release_upload_type_page.dart' deferred as release_type;

class ReleaseRoutes {

  static final List<SintPage<dynamic>> routes = [
    SintPage(
      name: AppRouteConstants.releaseUpload,
      page: () => kIsWeb
          ? DeferredLoader(release_upload_web.loadLibrary, () => release_upload_web.ReleaseUploadWebPage())
          : DeferredLoader(release_upload.loadLibrary, () => release_upload.ReleaseUploadPage()),
      transition: Transition.leftToRight,
    ),
    SintPage(
      name: AppRouteConstants.releaseUploadType,
      page: () => DeferredLoader(release_type.loadLibrary, () => release_type.ReleaseUploadType()),
      transition: Transition.zoom,
    ),
    SintPage(
      name: AppRouteConstants.releaseUploadCollectiveOrSolo,
      page: () => DeferredLoader(release_col_solo.loadLibrary, () => release_col_solo.ReleaseUploadCollectiveOrSoloPage()),
      transition: Transition.zoom,
    ),
    SintPage(
      name: AppRouteConstants.releaseUploadItemlistNameDesc,
      page: () => DeferredLoader(release_itemlist.loadLibrary, () => release_itemlist.ReleaseUploadItemlistNameDescPage()),
      transition: Transition.zoom,
    ),
    SintPage(
      name: AppRouteConstants.releaseUploadNameDesc,
      page: () => DeferredLoader(release_name_desc.loadLibrary, () => release_name_desc.ReleaseUploadNameDescPage()),
      transition: Transition.zoom,
    ),
    SintPage(
      name: AppRouteConstants.releaseUploadInstr,
      page: () => DeferredLoader(release_instr.loadLibrary, () => release_instr.ReleaseUploadInstrPage()),
      transition: Transition.zoom,
    ),
    SintPage(
      name: AppRouteConstants.releaseUploadGenres,
      page: () => DeferredLoader(release_genres.loadLibrary, () => release_genres.ReleaseUploadGenresPage()),
      transition: Transition.zoom,
    ),
    SintPage(
      name: AppRouteConstants.releaseUploadInfo,
      page: () => DeferredLoader(release_info.loadLibrary, () => release_info.ReleaseUploadInfoPage()),
      transition: Transition.zoom,
    ),
    SintPage(
      name: AppRouteConstants.releaseUploadSummary,
      page: () => DeferredLoader(release_summary.loadLibrary, () => release_summary.ReleaseUploadSummaryPage()),
      transition: Transition.zoom,
    ),
  ];

}
