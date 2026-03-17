import 'dart:io';

import 'package:flutter/services.dart';

class CloudinaryService {
  Future<File?> pickImageFromGallery() async {
    // Placeholder implementation until image-picker wiring is added.
    throw MissingPluginException(
      'Image picker plugin is not configured for this build.',
    );
  }

  Future<String> uploadImageToCloudinary(File imageFile) async {
    // Placeholder implementation for upload flow.
    throw UnimplementedError(
      'Cloudinary upload is not configured yet.',
    );
  }
}
