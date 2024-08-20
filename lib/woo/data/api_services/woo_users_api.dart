import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:neom_commons/core/domain/model/app_user.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';

class WooUsersApi {
  Future<void> createWooCommerceUser(AppUser user) async {
    final url = Uri.parse('https://tudominio.com/wp-json/wc/v3/customers');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Basic <tu_clave_api>',
    };
    final body = jsonEncode({
      'username': user.email,
      'email': user.email,
      'password': user.password,
      // ... otros campos personalizados
    });

    final response = await http.post(url, headers: headers, body: body);
    if (response.statusCode == 201) {
      AppUtilities.logger.i('Usuario creado exitosamente en WooCommerce');
    } else {
      AppUtilities.logger.e('Error al crear usuario: ${response.body}');
    }
  }

  // Future<void> crearCuentaWordPress(String nombre, String email, String password) async {
  //   final url = 'https://tu-sitio.com/wp-json/wc/v3/customers';
  //   final apiKey = 'tu_consumer_key';
  //   final apiSecret = 'tu_consumer_secret';
  //
  //   final response = await http.post(
  //     Uri.parse(url),
  //     headers: {
  //       'Authorization': 'Basic ' + base64Encode(utf8.encode('$apiKey:$apiSecret')),
  //       'Content-Type': 'application/json',
  //     },
  //     body: jsonEncode({
  //       'email': email,
  //       'first_name': nombre,
  //       'password': password,
  //       'username': email.split('@').first,
  //     }),
  //   );
  //
  //   if (response.statusCode == 201) {
  //     // Cuenta creada con éxito en WooCommerce
  //     print('Cuenta creada: ${response.body}');
  //   } else {
  //     // Manejo de errores
  //     print('Error: ${response.body}');
  //   }
  // }

}
