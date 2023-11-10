import 'package:get/get.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';

import 'ui/orders/confirmation/order_confirmation_page.dart';
import 'ui/orders/order_details_page.dart';
import 'ui/payment/payment_gateway_page.dart';
import 'ui/quotation/quotation_page.dart';
import 'ui/services/commerce_services_page.dart';
import 'ui/services/release_upload/release_upload_page.dart';
import 'ui/services/release_upload/widgets/release_upload_band_or_solo_page.dart';
import 'ui/services/release_upload/widgets/release_upload_genres_page.dart';
import 'ui/services/release_upload/widgets/release_upload_info_page.dart';
import 'ui/services/release_upload/widgets/release_upload_instr_page.dart';
import 'ui/services/release_upload/widgets/release_upload_itemlist_name_desc_page.dart';
import 'ui/services/release_upload/widgets/release_upload_name_desc_page.dart';
import 'ui/services/release_upload/widgets/release_upload_summary_page.dart';
import 'ui/services/release_upload/widgets/release_upload_type_page.dart';
import 'ui/wallet_history_page.dart';

class CommerceRoutes {

  static final List<GetPage<dynamic>> routes = [
    GetPage(
      name: AppRouteConstants.wallet,
      page: () => const WalletHistoryPage(),
      transition: Transition.leftToRight,
    ),
    GetPage(
      name: AppRouteConstants.orderDetails,
      page: () => const OrderDetailsPage(),
      transition: Transition.zoom,
    ),
    GetPage(
      name: AppRouteConstants.orderConfirmation,
      page: () => const OrderConfirmationPage(),
      transition: Transition.zoom,
    ),
    GetPage(
      name: AppRouteConstants.paymentGateway,
      page: () => const PaymentGatewayPage(),
      transition: Transition.zoom,
    ),
    GetPage(
      name: AppRouteConstants.services,
      page: () => const CommerceServicesPage(),
      transition: Transition.zoom,
    ),
    GetPage(
      name: AppRouteConstants.quotation,
      page: () => const QuotationPage(),
      transition: Transition.zoom,
    ),
    GetPage(
      name: AppRouteConstants.releaseUpload,
      page: () => const ReleaseUploadPage(),
      transition: Transition.zoom,
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
