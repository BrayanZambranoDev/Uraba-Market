import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

class CloudinaryService {
  static const String _cloudName = 'de3xjwduc';
  static const String _uploadPreset = 'urabamarket';

  // ── Comprimir imagen antes de subir ──────────────────────────────────────
  /// Reduce a máximo 1080px de ancho y calidad JPEG 82%.
  /// Solo actúa si la imagen supera 200 KB para no degradar imágenes pequeñas.
  static Uint8List _compress(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;

    img.Image processed = decoded;
    if (decoded.width > 1080) {
      final ratio = 1080 / decoded.width;
      processed = img.copyResize(
        decoded,
        width: 1080,
        height: (decoded.height * ratio).round(),
        interpolation: img.Interpolation.linear,
      );
    }

    return Uint8List.fromList(img.encodeJpg(processed, quality: 82));
  }

  // ── Subir audio ───────────────────────────────────────────────────────────
  /// [bytes]: bytes del archivo de audio
  /// [folder]: carpeta en Cloudinary ('chats_audio')
  static Future<String> uploadAudio(
    Uint8List bytes, {
    required String folder,
  }) async {
    final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/video/upload');

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder'] = folder
      ..fields['resource_type'] = 'video'
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: '${folder}_${DateTime.now().millisecondsSinceEpoch}.m4a',
      ));

    final streamed = await request.send().timeout(
          const Duration(seconds: 60),
          onTimeout: () =>
              throw Exception('Tiempo de espera agotado al subir audio.'),
        );
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode == 200) {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['secure_url'] as String;
    } else {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final msg = json['error']?['message'] ?? 'Error desconocido';
      throw Exception('Cloudinary audio: $msg');
    }
  }

  // ── Subir imagen ──────────────────────────────────────────────────────────
  /// [bytes]: bytes de la imagen (XFile.readAsBytes())
  /// [folder]: carpeta en Cloudinary ('perfiles', 'productos', 'publicaciones')
  static Future<String> uploadImage(
    Uint8List bytes, {
    required String folder,
  }) async {
    // Comprimir si la imagen pesa más de 200 KB
    final toUpload =
        bytes.lengthInBytes > 200 * 1024 ? _compress(bytes) : bytes;

    final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload');

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder'] = folder
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        toUpload,
        filename: '${folder}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ));

    final streamed = await request.send().timeout(
          const Duration(seconds: 60),
          onTimeout: () =>
              throw Exception('Tiempo de espera agotado al subir imagen.'),
        );
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode == 200) {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['secure_url'] as String;
    } else {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final msg = json['error']?['message'] ?? 'Error desconocido';
      throw Exception('Cloudinary: $msg');
    }
  }
}
