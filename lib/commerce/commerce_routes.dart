import 'package:get/get.dart';

import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'ui/orders/confirmation/order_confirmation_page.dart';
import 'ui/orders/order_details_page.dart';
import 'ui/payment/payment_gateway_page.dart';
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
  ];

}
