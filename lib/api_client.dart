import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000',
);

Uri resolvePhotoUri(String photoUrl) {
  final photoUri = Uri.parse(photoUrl);
  if (photoUri.hasScheme) return photoUri;

  final baseUri = Uri.parse(apiBaseUrl);
  final basePath = baseUri.path.replaceFirst(RegExp(r'/+$'), '');
  final relativePath = photoUrl.replaceFirst(RegExp(r'^/+'), '');
  return baseUri.replace(path: '$basePath/$relativePath');
}

enum DirectoryKind { family, students }

extension DirectoryKindInfo on DirectoryKind {
  String get endpoint => this == DirectoryKind.family ? 'family' : 'students';
  String get title => this == DirectoryKind.family ? 'Ma famille' : 'Étudiants';
  String get singular => this == DirectoryKind.family ? 'membre' : 'étudiant';
}

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class UserProfile {
  const UserProfile({required this.name, required this.email});

  final String name;
  final String email;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    name: json['name'] as String? ?? '',
    email: json['email'] as String? ?? '',
  );
}

class PersonRecord {
  const PersonRecord({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.relation = '',
    this.schoolClass = '',
    this.address = '',
    this.phone = '',
    this.birthday = '',
    this.photoUrl,
  });

  final int id;
  final String firstName;
  final String lastName;
  final String relation;
  final String schoolClass;
  final String address;
  final String phone;
  final String birthday;
  final String? photoUrl;

  String get fullName => '$firstName $lastName'.trim();

  factory PersonRecord.fromJson(Map<String, dynamic> json) => PersonRecord(
    id: int.parse(json['id'].toString()),
    firstName: json['first_name'] as String? ?? '',
    lastName: json['last_name'] as String? ?? '',
    relation: json['relationship'] as String? ?? '',
    schoolClass: json['school_class'] as String? ?? '',
    address: json['address'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    birthday: json['birthday'] as String? ?? '',
    photoUrl: json['photo_url'] as String?,
  );
}

class ApiClient {
  ApiClient({http.Client? client})
    : _client = client ?? http.Client(),
      _baseUrl = apiBaseUrl.replaceFirst(RegExp(r'/+$'), '');

  final http.Client _client;
  final String _baseUrl;
  String? _token;

  Uri _uri(String path) => Uri.parse('$_baseUrl/$path');

  Map<String, String> get _headers => {
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Future<UserProfile> authenticate({
    required String name,
    required String email,
    required String password,
    required bool register,
  }) async {
    final response = await _client
        .post(
          _uri(register ? 'auth/register' : 'auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            if (register) 'name': name,
            'email': email,
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 15));
    final data = _decodeResponse(response);
    _token = data['token'] as String?;
    if (_token == null || data['user'] is! Map<String, dynamic>) {
      throw const ApiException('Réponse de connexion invalide.');
    }
    return UserProfile.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<List<PersonRecord>> loadPeople(DirectoryKind kind) async {
    final response = await _client
        .get(_uri(kind.endpoint), headers: _headers)
        .timeout(const Duration(seconds: 15));
    final data = _decodeResponse(response)['items'];
    if (data is! List) {
      throw const ApiException('La réponse du serveur est invalide.');
    }
    return data
        .map((item) => PersonRecord.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> savePerson({
    required DirectoryKind kind,
    required Map<String, String> fields,
    int? id,
    XFile? photo,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      _uri('${kind.endpoint}${id == null ? '' : '/$id'}'),
    )..headers.addAll(_headers);
    request.fields.addAll(fields);
    if (photo != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'photo',
          await photo.readAsBytes(),
          filename: photo.name,
        ),
      );
    }
    final streamedResponse = await _client
        .send(request)
        .timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamedResponse);
    _decodeResponse(response);
  }

  Future<void> deletePerson(DirectoryKind kind, int id) async {
    final response = await _client
        .delete(_uri('${kind.endpoint}/$id'), headers: _headers)
        .timeout(const Duration(seconds: 15));
    _decodeResponse(response);
  }

  Future<void> signOut() async {
    final token = _token;
    if (token == null) return;
    try {
      final response = await _client
          .post(_uri('auth/logout'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      _decodeResponse(response);
    } finally {
      _token = null;
    }
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    Map<String, dynamic> body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException();
      }
      body = decoded;
    } on FormatException {
      throw ApiException(
        'Réponse serveur illisible (HTTP ${response.statusCode}).',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        body['error'] as String? ??
            'Erreur du serveur (${response.statusCode}).',
      );
    }
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    if (data == null) return <String, dynamic>{};
    throw const ApiException('La réponse du serveur est invalide.');
  }
}
