import 'package:get/get.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'ui/woo_webview_page.dart';

class WooRoutes {

  static final List<GetPage<dynamic>> routes = [
    GetPage(
        name: AppRouteConstants.wooWebView,
        page: () => const WooWebViewPage(),
        transition: Transition.zoom
    ),
  ];

}
