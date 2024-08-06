
import 'package:neom_commons/core/domain/model/price.dart';
import 'package:neom_commons/core/utils/enums/app_currency.dart';
import 'package:neom_commons/core/utils/enums/product_type.dart';
import '../../domain/models/app_product.dart';

class AppCoinProductConstants {

  static List<AppProduct> appCoinProducts = [
    AppProduct(
      name: "App Coins Pack",
      description: "10 App Coins",
      type: ProductType.coins,
      regularPrice: Price(currency: AppCurrency.mxn, amount: 50),
      salePrice: Price(currency: AppCurrency.mxn, amount: 50),
      qty: 10,
      imgUrl: "https://firebasestorage.googleapis.com/v0/b/gig-me-out.appspot.com/o/AppStatics%2FProductAssets%2Fgigcoins_13.png?alt=media&token=7bcb4383-edf8-4efa-be7f-07e5b4d11ca6",
    ),
    AppProduct(
      name: "App Coins Pack",
      description: "20 App Coins",
      type: ProductType.coins,
      regularPrice: Price(currency: AppCurrency.mxn, amount: 100),
      salePrice: Price(currency: AppCurrency.mxn, amount: 90),
      qty: 20,
      imgUrl: "https://firebasestorage.googleapis.com/v0/b/gig-me-out.appspot.com/o/AppStatics%2FProductAssets%2Fgigcoins_13.png?alt=media&token=7bcb4383-edf8-4efa-be7f-07e5b4d11ca6",
    ),
    AppProduct(
      name: "App Coins Pack",
      description: "30 App Coins",
      type: ProductType.coins,
      regularPrice: Price(currency: AppCurrency.mxn, amount: 150),
      salePrice: Price(currency: AppCurrency.mxn, amount: 130),
      qty: 30,
      imgUrl: "https://firebasestorage.googleapis.com/v0/b/gig-me-out.appspot.com/o/AppStatics%2FProductAssets%2Fgigcoins_13.png?alt=media&token=7bcb4383-edf8-4efa-be7f-07e5b4d11ca6",
    ),
    AppProduct(
      name: "App Coins Pack",
      description: "50 App Coins",
      type: ProductType.coins,
      regularPrice: Price(currency: AppCurrency.mxn, amount: 250),
      salePrice: Price(currency: AppCurrency.mxn, amount: 220),
      qty: 50,
      imgUrl: "https://firebasestorage.googleapis.com/v0/b/gig-me-out.appspot.com/o/AppStatics%2FProductAssets%2Fgigcoins_13.png?alt=media&token=7bcb4383-edf8-4efa-be7f-07e5b4d11ca6",
    ),
    AppProduct(
      name: "App Coins Pack",
      description: "100 App Coins",
      type: ProductType.coins,
      regularPrice: Price(currency: AppCurrency.mxn, amount: 500),
      salePrice: Price(currency: AppCurrency.mxn, amount: 400),
      qty: 100,
      imgUrl: "https://firebasestorage.googleapis.com/v0/b/gig-me-out.appspot.com/o/AppStatics%2FProductAssets%2Fgigcoins_13.png?alt=media&token=7bcb4383-edf8-4efa-be7f-07e5b4d11ca6",
    ),
  ];

}
