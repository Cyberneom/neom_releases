import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/domain/model/woo/woo_product.dart';
import 'package:neom_commons/core/domain/model/woo/woo_product_attribute.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/enums/woo/woo_product_status.dart';
import '../../utils/constants/woo_constants.dart';

class WooProductsApi {

  static Future<List<WooProduct>> getProducts({int perPage = 25, int page = 1,
    WooProductStatus status = WooProductStatus.publish, String categoryId = ''}) async {
    AppUtilities.startStopwatch(reference: 'getProducts');

    String url = '${AppFlavour.getWooUrl()}/products?page=$page&per_page=$perPage&status=${status.name}';
    if(categoryId.isNotEmpty) url = '$url&category=$categoryId';

    String credentials = base64Encode(utf8.encode('${AppFlavour.getWooClientKey()}:${AppFlavour.getWooClientSecret()}'));
    List<WooProduct> products = [];

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Basic $credentials'
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        for(var item in data.asMap().values) {
          WooProduct product = WooProduct.fromJSON(item);
          AppUtilities.logger.t('Product ${product.id} with name ${product.name}');
          products.add(product);
        }

        // List<Product> products = data.map((item) => Product.fromJson(item)).toList();
        AppUtilities.logger.d('${products.length} Products retrieved');
      } else {
        AppUtilities.logger.w(response.body.toString());
        jsonDecode(response.body);
        throw Exception('Error al cargar productos');
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    AppUtilities.stopStopwatch();
    return products;
  }

  static Future<void> createProduct(WooProduct product) async {

    String url = '${AppFlavour.getWooUrl()}/products';
    String credentials = base64Encode(utf8.encode('${AppFlavour.getWooClientKey()}:${AppFlavour.getWooClientSecret()}'));

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Basic $credentials',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(product.toJSON()),
    );

    if (response.statusCode == 201) {
      AppUtilities.logger.i('Producto creado correctamente');
    } else {
      AppUtilities.logger.i('Error al crear el producto: ${response.body}');
    }
  }

  static Future<void> addAttributesToProduct(String productId, List<WooProductAttribute> attributes, {bool isNew = false}) async {

    String url = '${AppFlavour.getWooUrl()}/products';
    String credentials = base64Encode(utf8.encode('${AppFlavour.getWooClientKey()}:${AppFlavour.getWooClientSecret()}'));
    int position = 0;
    try {
      List<WooProductAttribute> totalAttributes = [];
      if(!isNew) {
        WooProduct? currentProduct = await getProductAttributes(productId);
        if(currentProduct?.attributes?.isNotEmpty ?? false) {
          for(var attribute in attributes) {
            if(currentProduct!.attributes!. containsKey(attribute.name)) {
              currentProduct.attributes![attribute.name] = attribute;
              attribute.position = position;
              totalAttributes.add(attribute);
              position++;
            }
          }
          totalAttributes.addAll(currentProduct!.attributes!.values);
          for(var attribute in totalAttributes) {
            attributes.removeWhere((atr) => atr.name == attribute.name);
          }

          position = currentProduct.attributes?.length ?? 0;
        }

      }

      for(var attribute in attributes) {
        attribute.position = position;
        totalAttributes.add(attribute);
        position++;
      }
      final response = await http.put(
        Uri.parse('$url/$productId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic $credentials',
        },
        body: jsonEncode({
          WooConstants.attributes: totalAttributes.map((attribute) => attribute.toJSON()).toList(),
        }),
      );

      if (response.statusCode == 200) {
        AppUtilities.logger.i('Atributos agregados exitosamente');
      } else {
        AppUtilities.logger.i('Error al agregar atributos: ${response.statusCode}');
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
  }

  static Future<WooProduct?> getProductAttributes(String productId) async {

    String url = '${AppFlavour.getWooUrl()}/products';
    String credentials = base64Encode(utf8.encode('${AppFlavour.getWooClientKey()}:${AppFlavour.getWooClientSecret()}'));

    WooProduct? product;
    try {
      final response = await http.get(
        Uri.parse('$url/$productId'),
        headers: {
          'Authorization': 'Basic $credentials',
        },
      );

      if (response.statusCode == 200) {
        product = WooProduct.fromJSON(jsonDecode(response.body));
      } else {
        AppUtilities.logger.i('Error al obtener atributos: ${response.statusCode}');
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return product;
  }

  // Verificar si la variación existe
  static Future<String> getVariationId(int productId, String itemId, {optionId = ''}) async {

    String url = '${AppFlavour.getWooUrl()}/products';
    String credentials = base64Encode(utf8.encode('${AppFlavour.getWooClientKey()}:${AppFlavour.getWooClientSecret()}'));

    final response = await http.get(
      Uri.parse('$url/$productId/variations?search=$itemId'),
      headers: {
        'Authorization': 'Basic $credentials',
      },
    );

    if (response.statusCode == 200) {
      List variations = json.decode(response.body);
      if (variations.isNotEmpty) {
        return variations.first['id'].toString();
      }
    }
    return '';
  }

  // Crear una nueva variación si no existe
  static Future<String> createVariation(int productId, String itemId, List<String> options) async {

    String url = '${AppFlavour.getWooUrl()}/products';
    String credentials = base64Encode(utf8.encode('${AppFlavour.getWooClientKey()}:${AppFlavour.getWooClientSecret()}'));

    final response = await http.post(
      Uri.parse('$url/$productId/variations'),
      headers: {
        'Authorization': 'Basic $credentials',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'attributes': [
          {
            'name': 'Item ID',
            'option': itemId,
          },
        ],
        'regular_price': '0.00', // Establece el precio si es necesario
      }),
    );

    if (response.statusCode == 201) {
      final variation = json.decode(response.body);
      return variation['id'].toString();
    }
    return '';
  }

}
