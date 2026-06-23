import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../network/dio_client.dart';

class ImageUploadService {
  static final ImagePicker _picker = ImagePicker();

  /// Kullanıcıya galeri veya kamera seçeneği sunarak resim seçtirir
  static Future<File?> pickImage(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeriden Seç'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Kamerayla Çek'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return null;

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80, // Sıkıştırma yaparak boyutu düşür
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (e) {
      debugPrint('Resim seçme hatası: $e');
    }
    
    return null;
  }

  /// Seçilen resmi sunucuya yükler ve yeni fotoğrafın URL'sini döner
  static Future<String?> uploadProfilePhoto(File file, String endpoint) async {
    try {
      final dio = DioClient().dio;
      
      String fileName = file.path.split('/').last;
      
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
      });

      final response = await dio.post(
        endpoint,
        data: formData,
        options: Options(
          headers: {
            "Content-Type": "multipart/form-data",
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        // Endpoint'e göre dönen URL'nin field ismi değişebilir (profilePhoto veya logoUrl)
        if (response.data['data']['profilePhoto'] != null) {
            return response.data['data']['profilePhoto'];
        } else if (response.data['data']['logoUrl'] != null) {
            return response.data['data']['logoUrl'];
        }
      }
      return null;
    } on DioException catch (e) {
      debugPrint('Fotoğraf yükleme hatası: ${e.response?.data}');
      rethrow;
    } catch (e) {
      debugPrint('Beklenmeyen hata: $e');
      rethrow;
    }
  }
}
