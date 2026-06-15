import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for picking and uploading images to Supabase Storage
class ImageUploadService {
  final SupabaseClient _client = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  String? get _userId => _client.auth.currentUser?.id;

  /// Pick an image from gallery
  Future<File?> pickImage({
    double maxWidth = 800,
    double maxHeight = 800,
    int quality = 85,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: quality,
      );

      if (pickedFile == null) return null;
      return File(pickedFile.path);
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Upload image to Supabase Storage and return public URL
  /// [bucket] - Storage bucket name (e.g., 'avatars', 'categories')
  /// [folder] - Optional folder within bucket (e.g., user ID)
  Future<String?> uploadImage({
    required File imageFile,
    required String bucket,
    String? folder,
    String? customFileName,
  }) async {
    if (_userId == null) {
      debugPrint('Error: User not authenticated');
      return null;
    }

    try {
      // Generate unique filename
      final extension = _getFileExtension(imageFile.path);
      final fileName = customFileName ??
          '${DateTime.now().millisecondsSinceEpoch}$extension';

      // Build storage path
      final storagePath = folder != null
          ? '$folder/$fileName'
          : fileName;

      // Read file bytes
      final bytes = await imageFile.readAsBytes();

      // Upload to Supabase Storage
      await _client.storage.from(bucket).uploadBinary(
        storagePath,
        bytes,
        fileOptions: FileOptions(
          contentType: _getContentType(extension),
          upsert: true,
        ),
      );

      // Get public URL
      final publicUrl = _client.storage.from(bucket).getPublicUrl(storagePath);

      debugPrint('Image uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  /// Pick and upload image in one step
  Future<String?> pickAndUploadImage({
    required String bucket,
    String? folder,
    double maxWidth = 800,
    double maxHeight = 800,
    int quality = 85,
  }) async {
    final file = await pickImage(
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      quality: quality,
    );

    if (file == null) return null;

    return uploadImage(
      imageFile: file,
      bucket: bucket,
      folder: folder,
    );
  }

  /// Upload profile photo
  Future<String?> uploadProfilePhoto() async {
    if (_userId == null) return null;

    return pickAndUploadImage(
      bucket: 'avatars',
      folder: _userId,
      maxWidth: 400,
      maxHeight: 400,
      quality: 90,
    );
  }

  /// Upload category image
  Future<String?> uploadCategoryImage() async {
    if (_userId == null) return null;

    return pickAndUploadImage(
      bucket: 'categories',
      folder: _userId,
      maxWidth: 200,
      maxHeight: 200,
      quality: 85,
    );
  }

  /// Delete image from storage
  Future<bool> deleteImage({
    required String bucket,
    required String filePath,
  }) async {
    try {
      await _client.storage.from(bucket).remove([filePath]);
      return true;
    } catch (e) {
      debugPrint('Error deleting image: $e');
      return false;
    }
  }

  String _getFileExtension(String filePath) {
    final lastDot = filePath.lastIndexOf('.');
    if (lastDot == -1 || lastDot == filePath.length - 1) {
      return '.jpg'; // Default extension
    }
    return filePath.substring(lastDot);
  }

  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
