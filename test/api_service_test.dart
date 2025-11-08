import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:new_kare_1/services/api_service.dart';

import 'dart:typed_data';

class _FakeAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final path = options.path;
    if (path.endsWith('/signup')) {
      return ResponseBody.fromString('{"ok":true,"id":"123"}', 200, headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});
    }
    if (path.endsWith('/login')) {
      return ResponseBody.fromString('{"access_token":"tok123"}', 200, headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});
    }
    return ResponseBody.fromString('{"error":"not found"}', 404, headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});
  }
}

void main() {
  group('ApiService', () {
    late Dio dio;
    late ApiService api;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'http://192.168.29.59:8000'));
      dio.httpClientAdapter = _FakeAdapter();
      api = ApiService(dio: dio);
    });

    test('signup returns data on success', () async {
      final res = await api.signup(
        name: 'Test',
        email: 'a@klu.ac.in',
        password: 'Pass1234',
        department: 'Computer Science',
        phoneNumber: '+918675671807',
      );
      expect(res['ok'], true);
      expect(res['id'], '123');
    });

    test('login returns token', () async {
      final res = await api.login(email: 'a@klu.ac.in', password: 'Pass1234');
      expect(res['access_token'], 'tok123');
    });
  });
}
