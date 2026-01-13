import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  static const String cloudName = 'dua4n3gr9';
  static const String uploadPreset = 'flutter';
  static const String apiKey = '276347998746349';

  /// Upload XFile (works on Web and Mobile)
  static Future<String> uploadXFile(
    XFile file, {
    required String folder,
    required String fileName,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      return uploadFromBytes(bytes: bytes, fileName: fileName, folder: folder);
    } catch (e) {
      if (e.toString().contains('_Namespace')) {
        throw Exception(
          'Web Upload Error (Namespace): Please ensure you are using Web-compatible file picker.',
        );
      }
      rethrow;
    }
  }

  /// Upload image from bytes to Cloudinary
  static Future<String> uploadFromBytes({
    required Uint8List bytes,
    required String fileName,
    required String folder,
  }) async {
    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] = folder;
      request.fields['quality'] = 'auto:best';

      String finalName = fileName;
      if (!finalName.contains('.')) {
        finalName = '$finalName.jpg';
      }

      // Safe mime type lookup
      String mimeType = 'image/jpeg';
      try {
        mimeType =
            lookupMimeType(finalName, headerBytes: bytes) ?? 'image/jpeg';
      } catch (_) {
        // Fallback if lookup fails
      }

      final mimeParts = mimeType.split('/');

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: finalName,
          contentType: MediaType(mimeParts[0], mimeParts[1]),
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseBody) as Map<String, dynamic>;
        final secureUrl = jsonResponse['secure_url'];
        if (secureUrl != null && secureUrl is String) {
          return secureUrl;
        } else {
          throw Exception(
            'Invalid response from Cloudinary: missing secure_url',
          );
        }
      } else {
        throw Exception(
          'Cloudinary upload failed with status ${response.statusCode}: $responseBody',
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Cloudinary upload error: $e');
    }
  }

  /// Upload multiple images from bytes to Cloudinary
  /// Returns list of secure URLs of successfully uploaded images
  /// Continues uploading even if some fail (failed uploads are skipped)
  static Future<List<String>> uploadMultipleFromBytes({
    required List<Uint8List> bytesList,
    required List<String> fileNames,
    required String folder,
  }) async {
    final List<String> urls = [];
    for (int i = 0; i < bytesList.length; i++) {
      try {
        final url = await uploadFromBytes(
          bytes: bytesList[i],
          fileName: fileNames[i],
          folder: folder,
        );
        urls.add(url);
      } catch (e) {
        // Log error but continue with other uploads
        debugPrint('Failed to upload ${fileNames[i]}: $e');
      }
    }
    return urls;
  }
}
