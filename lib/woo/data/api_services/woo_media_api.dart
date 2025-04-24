import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';


class WooMediaApi {


  static Future<String> uploadMediaToWordPress(File file, {String fileName = ''}) async {
    AppUtilities.logger.i("Uploading media file to WordPress");

    String url = '${AppFlavour.getSiteUrl()}/wp-json/wp/v2/media';
    String mediaUrl = '';

    try {
      // Crea una solicitud de subida multipart
      var request = http.MultipartRequest('POST', Uri.parse(url));

      // Añadir el archivo al cuerpo de la solicitud
      request.files.add(http.MultipartFile(
        'file',
        file.readAsBytes().asStream(),
        file.lengthSync(),
        filename: fileName.isNotEmpty ? fileName : file.path.split('/').last,
      ));

      // Añade las cabeceras necesarias
      String jwtToken = await getJwtToken();
      request.headers['Authorization'] = 'Bearer $jwtToken';
      request.headers['Content-Disposition'] = 'attachment; filename="${fileName.isNotEmpty ? fileName : file.path.split('/').last}"';

      // Envía la solicitud
      var response = await request.send();

      if (response.statusCode == 201) {
        // Obtiene la respuesta y decodifica
        var responseData = await response.stream.bytesToString();
        var jsonData = jsonDecode(responseData);
        mediaUrl = jsonData['source_url'];
        AppUtilities.logger.i('Media uploaded successfully: $mediaUrl');
      } else {
        AppUtilities.logger.e('Failed to upload media: ${response.statusCode}');
        AppUtilities.logger.e('Response: ${await response.stream.bytesToString()}');
      }
    } catch (e) {
      AppUtilities.logger.e('Error uploading media: $e');
    }

    return mediaUrl;
  }

  static Future<String> getJwtToken() async {
    String url = '${AppFlavour.getSiteUrl()}/wp-json/jwt-auth/v1/token';

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': 'emmanuel.montoyae@gmail.com',
        'password': '3mxi20l4!!',
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return responseData['token'];  // Retorna el token JWT
    } else {
      throw Exception('Failed to obtain JWT token. Status Code ${response.statusCode}');
    }
  }

}
