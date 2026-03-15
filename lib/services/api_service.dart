import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;

  void setToken(String token) => _token = token;
  void clearToken() => _token = null;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<Map<String, dynamic>> get(String endpoint) async {
    final res = await http.get(
      Uri.parse('${AppConfig.baseUrl}/$endpoint'),
      headers: _headers,
    );
    return _handle(res);
  }

  Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('${AppConfig.baseUrl}/$endpoint'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  Future<Map<String, dynamic>> put(
      String endpoint, Map<String, dynamic> body) async {
    final res = await http.put(
      Uri.parse('${AppConfig.baseUrl}/$endpoint'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    final res = await http.delete(
      Uri.parse('${AppConfig.baseUrl}/$endpoint'),
      headers: _headers,
    );
    return _handle(res);
  }

  Future<Map<String, dynamic>> uploadProduct({
    required Map<String, String> fields,
    Uint8List? imageBytes,
    String? imageName,
    String method = 'POST',
    int? productId,
  }) async {
    final uri = productId != null
        ? Uri.parse('${AppConfig.baseUrl}/products/update.php?id=$productId')
        : Uri.parse('${AppConfig.baseUrl}/products/create.php');

    final request = http.MultipartRequest('POST', uri);
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }
    request.fields.addAll(fields);
    if (method == 'PUT') request.fields['_method'] = 'PUT';

    if (imageBytes != null && imageName != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: imageName,
      ));
    }

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return _handle(res);
  }

  Map<String, dynamic> _handle(http.Response res) {
    try {
      final data = jsonDecode(res.body);
      return data is Map<String, dynamic> ? data : {'data': data};
    } catch (_) {
      return {'success': false, 'message': 'Invalid server response'};
    }
  }
}
