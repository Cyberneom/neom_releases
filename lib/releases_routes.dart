import 'package:get/get.dart';
import 'package:neom_core/core/utils/constants/app_route_constants.dart';
import 'releases/ui/release_upload_page.dart';
import 'releases/ui/widgets/release_upload_band_or_solo_page.dart';
import 'releases/ui/widgets/release_upload_genres_page.dart';
import 'releases/ui/widgets/release_upload_info_page.dart';
import 'releases/ui/widgets/release_upload_instr_page.dart';
import 'releases/ui/widgets/release_upload_itemlist_name_desc_page.dart';
import 'releases/ui/widgets/release_upload_name_desc_page.dart';
import 'releases/ui/widgets/release_upload_summary_page.dart';
import 'releases/ui/widgets/release_upload_type_page.dart';


class ReleasesRoutes {

  static final List<GetPage<dynamic>> routes = [
    GetPage(
      name: AppRouteConstants.releaseUpload,
      page: () => const ReleaseUploadPage(),
      transition: Transition.leftToRight,
    ),
    GetPage(
      name: AppRouteConstants.releaseUploadType,
      page: () => const ReleaseUploadType(),
      transition: Transition.zoom,
    ),
    GetPage(
      name: AppRouteConstants.releaseUploadBandOrSolo,
      page: () => const ReleaseUploadBandOrSoloPage(),
      transition: Transition.zoom,
    ),
    GetPage(
      name: AppRouteConstants.releaseUploadItemlistNameDesc,
      page: () => const ReleaseUploadItemlistNameDescPage(),
      transition: Transition.zoom,
    ),
    GetPage(
      name: AppRouteConstants.releaseUploadNameDesc,
      page: () => const ReleaseUploadNameDescPage(),
      transition: Transition.zoom,
    ),
    GetPage(
      name: AppRouteConstants.releaseUploadInstr,
      page: () => const ReleaseUploadInstrPage(),
      transition: Transition.zoom,
    ),
    GetPage(
      name: AppRouteConstants.releaseUploadGenres,
      page: () => const ReleaseUploadGenresPage(),
      transition: Transition.zoom,
    ),
    GetPage(
      name: AppRouteConstants.releaseUploadInfo,
      page: () => const ReleaseUploadInfoPage(),
      transition: Transition.zoom,
    ),
    GetPage(
      name: AppRouteConstants.releaseUploadSummary,
      page: () => const ReleaseUploadSummaryPage(),
      transition: Transition.zoom,
    ),
  ];

}
