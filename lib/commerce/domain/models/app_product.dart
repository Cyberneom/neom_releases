import 'package:enum_to_string/enum_to_string.dart';
import 'package:neom_commons/core/domain/model/price.dart';
import 'package:neom_commons/core/domain/model/review.dart';
import '../../utils/enums/product_type.dart';

class AppProduct {

  String id;
  String name;
  String description;
  ProductType type;
  Price? regularPrice = Price();
  Price? salePrice = Price();
  int qty;
  String imgUrl;
  bool isAvailable;  
  int numberOfSales;
  
  double reviewStars =  10.0;
  List<String> reviewIds;
  Review? lastReview;

  int createdTime;
  int updatedTime;

  AppProduct({
    this.id = "",
    this.name = "",
    this.description = "",
    this.type = ProductType.service,
    this.regularPrice,
    this.salePrice,
    this.qty = 0,
    this.imgUrl = "",
    this.isAvailable = true,    
    this.numberOfSales = 0,
    this.reviewStars = 10.0,
    this.lastReview,
    this.reviewIds = const [],
    this.createdTime = 0,
    this.updatedTime = 0
  });

  Map<String, dynamic> toJSON() {
    return <String, dynamic>{
      'id': id,
      'name': name,      
      'description': description,
      'type': type.name,
      'regularPrice': regularPrice?.toJSON() ?? Price().toJSON(),
      'salePrice': salePrice?.toJSON() ?? Price().toJSON(),
      'qty': qty,
      'imgUrl': imgUrl,
      'isAvailable': isAvailable,      
      'numberOfSales': numberOfSales,      
      'reviewStars': reviewStars,
      'lastReview': lastReview?.toJSON() ?? Review().toJSON(),
      'reviewIds': reviewIds,
      'createdTime': DateTime.now().millisecondsSinceEpoch,
      'updatedTime': DateTime.now().millisecondsSinceEpoch,
    };
  }

  AppProduct.fromJSON(data) :
    id = data["id"] ?? "",
    name = data["name"] ?? "",
    description = data["description"] ?? "",
    type = EnumToString.fromString(ProductType.values, data["type"] ?? ProductType.service.name) ?? ProductType.service,
    regularPrice = Price.fromJSON(data["regularPrice"] ?? {}),
    salePrice = Price.fromJSON(data["salePrice"] ?? {}),
    qty = data["qty"] ?? 0,
    imgUrl = data["imgUrl"] ?? "",
    isAvailable = data["isAvailable"] ?? true,    
    numberOfSales = data["numberOfSales"] ?? 0,
    reviewStars = data["reviewStars"] ?? 10,
    lastReview = Review.fromJSON(data["lastReview"] ?? {}),
    reviewIds = data["reviewIds"]?.cast<String>() ?? [],
    createdTime = data["createdTime"] ?? 0,
    updatedTime = data["updatedTime"] ?? 0;

  AppProduct.clone(AppProduct product) :
        id = product.id,
        name = product.name,
        description = product.description,
        type =  product.type,
        regularPrice = product.regularPrice,
        salePrice = product.salePrice,
        qty = product.qty,
        imgUrl = product.imgUrl,
        isAvailable = product.isAvailable,
        numberOfSales = product.numberOfSales,
        reviewStars = product.reviewStars,
        lastReview = product.lastReview,
        reviewIds = product.reviewIds,
        createdTime = product.createdTime,
        updatedTime = product.updatedTime;

}
