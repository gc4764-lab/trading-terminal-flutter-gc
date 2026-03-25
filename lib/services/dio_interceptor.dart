// lib/services/dio_interceptor.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class AuthInterceptor extends Interceptor {
  final String Function() getToken;
  final Future<void> Function() onTokenExpired;
  
  AuthInterceptor({
    required this.getToken,
    required this.onTokenExpired,
  });
  
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = getToken();
    if (token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Token expired
      onTokenExpired();
    }
    handler.next(err);
  }
}

class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  
  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
  });
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final request = err.requestOptions;
    final shouldRetry = _shouldRetry(err);
    
    if (shouldRetry && request.extra['retry_count'] == null) {
      request.extra['retry_count'] = 0;
    }
    
    if (shouldRetry && request.extra['retry_count'] < maxRetries) {
      request.extra['retry_count'] = request.extra['retry_count'] + 1;
      
      // Exponential backoff
      await Future.delayed(Duration(seconds: request.extra['retry_count'] * 2));
      
      try {
        final response = await dio.fetch(request);
        handler.resolve(response);
      } catch (e) {
        handler.next(err);
      }
    } else {
      handler.next(err);
    }
  }
  
  bool _shouldRetry(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
           error.type == DioExceptionType.sendTimeout ||
           error.type == DioExceptionType.receiveTimeout ||
           (error.response?.statusCode ?? 0) >= 500;
  }
}