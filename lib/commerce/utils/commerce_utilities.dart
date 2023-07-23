// TODO Verify why is not retrieving products
// import 'package:http/http.dart' as http;
// import 'package:neom_commons/core/utils/app_utilities.dart';
//
// class CommerceUtilities {
//
//   Future<void> getWooCommerceProducts() async {
//
//     http.Response response;
//     String url = "https://api.medium.com/v1/me";
//     response = await http.get(
//       Uri.parse(url),
//       headers: {
//         'Authorization': 'Bearer 24881f0e58aea776fb789ed1dd6a61647d39b8d0d73e51d4be6398022b17524be',
//       },
//     );
//
//     String body = response.body;
//     AppUtilities.logger.i(body);
//
//     url = "https://api.medium.com/v1/users/16d811f8e6d5a377baf71ce7c45f2105a8402cf9b3ada02a3b364d21b2eb3dc67/publications";
//     response = await http.get(
//       Uri.parse(url),
//       headers: {
//         'Authorization': 'Bearer 24881f0e58aea776fb789ed1dd6a61647d39b8d0d73e51d4be6398022b17524be',
//       },
//     );
//     body = response.body;
//     AppUtilities.logger.i(body.toString());
//
//     url = "https://api.medium.com/v1/publications/613029aab3b5";
//     //url = "https://api.medium.com/v1/publications/613029aab3b5/contributors";
//
//     response = await http.get(
//       Uri.parse(url),
//       headers: {
//         'Authorization': 'Bearer 24881f0e58aea776fb789ed1dd6a61647d39b8d0d73e51d4be6398022b17524be',
//       },
//     );
//
//     body = response.body;
//     AppUtilities.logger.i(body.toString());
//
//     await WooSignal.instance.init(appKey: "app_a9d9e47ea6369b514e1070c4bf7a33");
//     String productName = "";
//     List<Product> products = await WooSignal.instance.getProducts();
//     if (products.isNotEmpty) {
//       productName = products[0].name ?? "";
//       AppUtilities.logger.i(productName);
//     } else {
//       AppUtilities.logger.i("Empty products wordpress");
//     }
//
//     AppUtilities.logger.i("");
//   }
//
// }
