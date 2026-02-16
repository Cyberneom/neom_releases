import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:sint/sint.dart';

import 'ui/release_upload_page.dart';
import 'ui/widgets/release_upload_band_or_solo_page.dart';
import 'ui/widgets/release_upload_genres_page.dart';
import 'ui/widgets/release_upload_info_page.dart';
import 'ui/widgets/release_upload_instr_page.dart';
import 'ui/widgets/release_upload_itemlist_name_desc_page.dart';
import 'ui/widgets/release_upload_name_desc_page.dart';
import 'ui/widgets/release_upload_summary_page.dart';
import 'ui/widgets/release_upload_type_page.dart';

class ReleaseRoutes {

  static final List<SintPage<dynamic>> routes = [
    SintPage(
      name: AppRouteConstants.releaseUpload,
      page: () => const ReleaseUploadPage(),
      transition: Transition.leftToRight,
    ),
    SintPage(
      name: AppRouteConstants.releaseUploadType,
      page: () => const ReleaseUploadType(),
      transition: Transition.zoom,
    ),
    SintPage(
      name: AppRouteConstants.releaseUploadBandOrSolo,
      page: () => const ReleaseUploadBandOrSoloPage(),
      transition: Transition.zoom,
    ),
    SintPage(
      name: AppRouteConstants.releaseUploadItemlistNameDesc,
      page: () => const ReleaseUploadItemlistNameDescPage(),
      transition: Transition.zoom,
    ),
    SintPage(
      name: AppRouteConstants.releaseUploadNameDesc,
      page: () => const ReleaseUploadNameDescPage(),
      transition: Transition.zoom,
    ),
    SintPage(
      name: AppRouteConstants.releaseUploadInstr,
      page: () => const ReleaseUploadInstrPage(),
      transition: Transition.zoom,
    ),
    SintPage(
      name: AppRouteConstants.releaseUploadGenres,
      page: () => const ReleaseUploadGenresPage(),
      transition: Transition.zoom,
    ),
    SintPage(
      name: AppRouteConstants.releaseUploadInfo,
      page: () => const ReleaseUploadInfoPage(),
      transition: Transition.zoom,
    ),
    SintPage(
      name: AppRouteConstants.releaseUploadSummary,
      page: () => const ReleaseUploadSummaryPage(),
      transition: Transition.zoom,
    ),
  ];

}
