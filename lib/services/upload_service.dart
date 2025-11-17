import 'dart:io';
import 'package:http/http.dart' as http;

/// Service for uploading photos with metadata to the server
class UploadService {
  static const String uploadUrl =
      'https://flutter-sandbox.free.beeceptor.com/upload_photo/';

  /// Uploads a photo with comment and coordinates to the server
  /// Returns true if upload was successful, false otherwise
  Future<bool> uploadPhoto({
    required File imageFile,
    required String comment,
    required double latitude,
    required double longitude,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));

      // Add form fields
      request.fields['comment'] = comment;
      request.fields['latitude'] = latitude.toString();
      request.fields['longitude'] = longitude.toString();

      // Add photo file
      request.files.add(
        await http.MultipartFile.fromPath('photo', imageFile.path),
      );

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}
