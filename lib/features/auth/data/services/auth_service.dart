import 'package:dio/dio.dart';

import '../models/auth_session.dart';
import '../models/auth_user.dart';

class AuthService {
  AuthService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://api.escuelajs.co/api/',
              headers: const {'Content-Type': 'application/json'},
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
            ),
          );

  final Dio _dio;

  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final loginResponse = await _dio.post<Object?>(
        'v1/auth/login',
        data: {'email': email.trim(), 'password': password},
      );
      final loginData = _asJsonObject(loginResponse.data);
      final accessToken = loginData['access_token'];
      final refreshToken = loginData['refresh_token'];

      if (accessToken is! String ||
          accessToken.isEmpty ||
          refreshToken is! String ||
          refreshToken.isEmpty) {
        throw const AuthException('The login response did not include tokens.');
      }

      final profileResponse = await _dio.get<Object?>(
        'v1/auth/profile',
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
      );
      final user = AuthUser.fromJson(_asJsonObject(profileResponse.data));

      return AuthSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        user: user,
      );
    } on DioException catch (error) {
      throw AuthException(_messageFor(error));
    } on FormatException catch (error) {
      throw AuthException(error.message);
    }
  }

  static Map<String, dynamic> _asJsonObject(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    throw const FormatException('The server returned an invalid response.');
  }

  static String _messageFor(DioException error) {
    final responseData = error.response?.data;
    if (responseData is Map) {
      final message = responseData['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
      if (message is List && message.isNotEmpty) {
        return message.join('\n');
      }
    }

    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout => 'The request timed out. Please try again.',
      DioExceptionType.connectionError =>
        'Unable to connect. Check your internet connection and try again.',
      _ => 'Unable to sign in. Please check your details and try again.',
    };
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
