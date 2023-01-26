import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:neom_commons/core/data/firestore/constants/app_firestore_collection_constants.dart';
import 'package:neom_commons/core/data/firestore/constants/app_firestore_constants.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import '../../domain/models/app_product.dart';
import '../../domain/repository/product_repository.dart';
import '../../utils/enums/product_type.dart';

class ProductFirestore implements ProductRepository {

  var logger = AppUtilities.logger;
  final productReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.products);

  @override
  Future<List<AppProduct>> retrieveProductsByType({required ProductType type}) async {
    logger.d("Retrieving Products by type ${type.name}");
    List<AppProduct> products = [];

    try {

      QuerySnapshot querySnapshot = await productReference
          .where(AppFirestoreConstants.type, isEqualTo: type.name)
          .where(AppFirestoreConstants.isAvailable, isEqualTo: true)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        logger.d("Snapshot is not empty");
        for (var productSnapshot in querySnapshot.docs) {
          AppProduct product = AppProduct.fromJSON(productSnapshot.data());
          product.id = productSnapshot.id;
          logger.d(product.toString());
          products.add(product);
        }
        logger.d("${products.length} products found");
      }
    } catch (e) {
      logger.e(e.toString());
    }
    return products;
  }


  @override
  Future<String> insert(AppProduct product) async {
    logger.d("Inserting product ${product.name}");
    String productId = "";

    try {

      if(product.id.isNotEmpty) {
        await productReference.doc(product.id).set(product.toJSON());
        productId = product.id;
      } else {
        DocumentReference documentReference = await productReference
            .add(product.toJSON());
        productId = documentReference.id;
        product.id = productId;
        
      }
      logger.d("Product ${product.name} added with id ${product.id}");
    } catch (e) {
      logger.e(e.toString());
    }

    return productId;

  }


  @override
  Future<bool> remove(AppProduct product) async {
    logger.d("Removing product ${product.id}");

    try {
      await productReference.doc(product.id).delete();
      logger.d("Product ${product.id} removed");
      return true;

    } catch (e) {
      logger.e(e.toString());      
    }
    return false;
  }


}
