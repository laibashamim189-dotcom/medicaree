import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class CloudinaryService {
  // Cloud Name: s9cayswl
  // Upload Preset: medicare_preset
  static const String cloudName = "s9coyswl";
  static const String uploadPreset = "medicare_preset";

  static Future<String?> uploadImage(File imageFile) async {
    // Exact URL for unsigned upload
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    try {
      final request = http.MultipartRequest('POST', url);
      
      // Fields MUST be added exactly like this for unsigned upload
      request.fields['upload_preset'] = uploadPreset;
      
      // Add file with a specific field name 'file'
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
      ));

      debugPrint("Cloudinary: Uploading to $url using preset $uploadPreset");

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = utf8.decode(responseData);
      
      debugPrint("Cloudinary Raw Response: $responseString");

      final jsonMap = jsonDecode(responseString);

      if (response.statusCode == 200) {
        return jsonMap['secure_url'];
      } else {
        // Handle "Upload Unknown API key" or other Cloudinary errors
        String errorMsg = jsonMap['error'] != null ? jsonMap['error']['message'] : "Error ${response.statusCode}";
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint("Cloudinary Service Exception: $e");
      rethrow;
    }
  }
}