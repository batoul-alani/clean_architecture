import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';


abstract class NetworkService<T> {
  Future<T> get(String url,
      {dynamic data, Map<String, dynamic>? queryParameters});

  Future<T> post(String url, dynamic body,
      [Map<String, dynamic>? queryParameters]);

  Future<T> put(String url, {dynamic data, dynamic queryParameters});
}

class DioNetworkService implements NetworkService<Response> {
  Dio get _dio {
    var dio = Dio(BaseOptions(
        baseUrl: AppConstants.baseUrl,
        receiveTimeout: const Duration(seconds: AppConstants.dioTimeout),
        connectTimeout: const Duration(seconds: AppConstants.dioTimeout),
        sendTimeout: const Duration(seconds: AppConstants.dioTimeout),
        headers: {'Accept': 'application/json'}));

    dio.interceptors.addAll({DioAppInterceptors()});
    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
      ));
    }
    return dio;
  }

  @override
  Future<Response> get(String url,
          {dynamic data, Map<String, dynamic>? queryParameters}) =>
      _dio.get(url, data: data, queryParameters: queryParameters);

  @override
  Future<Response> post(String url, dynamic body,
          [Map<String, dynamic>? queryParameters]) =>
      _dio.post(url, data: body, queryParameters: queryParameters);

  @override
  Future<Response> put(String url, {data, queryParameters}) =>
      _dio.put(url, data: data, queryParameters: queryParameters);
}

class DioAppInterceptors extends Interceptor {
  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = "";

    if (token != null) {
      options.headers['Authorization'] = 'token $token';
    }

    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response != null) {
      debugPrint(err.response!.statusCode.toString());
      debugPrint(err.response!.data.toString());
    }
    if (err.response?.statusCode == 403 || err.response?.statusCode == 401) {
      forceLogout(navigator.currentContext!);
    }

    final String? message = err.response?.data['message'];
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw DeadlineExceededException(err.requestOptions, message);
      case DioExceptionType.badResponse:
        switch (err.response?.statusCode) {
          case 400:
            throw BadRequestException(err.requestOptions, message);
          case 401:
            throw UnauthorizedException(err.requestOptions, message);
          case 403:
            throw AccessForbiddenException(err.requestOptions, message);
          case 404:
            throw NotFoundException(err.requestOptions, message);
          case 409:
            throw ConflictException(err.requestOptions, message);
          case 417:
            throw BadResponseException(err.requestOptions, message);
          case 422:
            throw UnprocessableEntityException(err.requestOptions, message);
          case 500:
            throw InternalServerErrorException(err.requestOptions, message);
        }
        break;
      case DioExceptionType.cancel:
        break;
      case DioExceptionType.unknown:
        throw NoInternetConnectionException(err.requestOptions, message);
      case DioExceptionType.badCertificate:
        throw BadCertificateException(err.requestOptions, message);
      case DioExceptionType.connectionError:
        throw ConnectionErrorException(err.requestOptions, message);
      // case DioExceptionType.badResponse:
      //   throw BadResponseException(err.requestOptions, message);
    }
    return handler.next(err);
  }
}

class ApiException extends DioException {
  ApiException(RequestOptions requestOptions, [this.customMessage])
      : super(requestOptions: requestOptions, error: customMessage);

  final String? customMessage;

  String get defaultErrorString => "Error Happened";

  @override
  String toString() {
    return customMessage ?? defaultErrorString;
  }
}

class BadRequestException extends ApiException {
  BadRequestException(super.requestOptions, [super.message]);

  @override
  String get defaultErrorString => "Bad Request";
}

class UnprocessableEntityException extends ApiException {
  UnprocessableEntityException(super.requestOptions, [super.message]);

  @override
  String get defaultErrorString => "UnProcessable Entity";
}

class InternalServerErrorException extends ApiException {
  InternalServerErrorException(super.requestOptions, [super.message]);

  @override
  String get defaultErrorString => "Some Thing Went Wrong, Try Again";
}

class ConflictException extends ApiException {
  ConflictException(super.requestOptions, [super.message]);

  @override
  String get defaultErrorString => "Conflict Connection";
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(super.requestOptions, [super.message]);

  @override
  String get defaultErrorString => "Unauthorized";
}

class NotFoundException extends ApiException {
  NotFoundException(super.requestOptions, [super.message]);

  @override
  String get defaultErrorString => "Not Found";
}

class NoInternetConnectionException extends ApiException {
  NoInternetConnectionException(super.requestOptions, [super.message]);

  @override
  String get defaultErrorString => "No Internet Connection";
}

class DeadlineExceededException extends ApiException {
  DeadlineExceededException(super.requestOptions, [super.message]);

  @override
  String get defaultErrorString => "Deadline Exceeded";
}

class AccessForbiddenException extends ApiException {
  AccessForbiddenException(super.requestOptions, [super.message]);

  @override
  String get defaultErrorString => "Access Forbidden";
}

class BadCertificateException extends ApiException {
  BadCertificateException(super.requestOptions, [super.message]);
  @override
  String get defaultErrorString => "Bad Certificate";
}

class ConnectionErrorException extends ApiException {
  ConnectionErrorException(super.requestOptions, [super.message]);
  @override
  String get defaultErrorString => "Connection Error";
}

class BadResponseException extends ApiException {
  BadResponseException(super.requestOptions, [super.message]);
  @override
  String get defaultErrorString => "Bad Response";
}
