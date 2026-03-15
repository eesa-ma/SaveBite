import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  CloudinaryService({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  static const String _uploadPreset = 'savebite_upload';
  static const String _uploadEndpoint =
      'https://api.cloudinary.com/v1_1/dwb7pjyit/image/upload';

  final ImagePicker _imagePicker;

  Future<File?> pickImageFromGallery() async {
    final pickedImage = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedImage == null) {
      return null;
    }

    return File(pickedImage.path);
  }

  Future<String> uploadImageToCloudinary(File imageFile) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(_uploadEndpoint),
    )..fields['upload_preset'] = _uploadPreset;

    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Cloudinary upload failed: $responseBody');
    }

    final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
    final secureUrl = decoded['secure_url'];
    if (secureUrl is! String || secureUrl.isEmpty) {
      throw Exception('Cloudinary response missing secure_url.');
    }

    return secureUrl;
  }
}