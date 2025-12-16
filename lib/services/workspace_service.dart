import 'dart:io';
import 'package:dio/dio.dart';

import '../models/workspace_member_model.dart';
import '../models/workspace_model.dart';
import '../constants/app_constant.dart';
import '../utils/session_meneger.dart';
import 'package:flutter/material.dart';
import 'package:vasvault/models/workspace_file_model.dart';
import 'package:vasvault/models/auth_response.dart';

class WorkspaceService {
  final String baseUrl = '${AppConstants.baseUrl}/api/v1';
  final SessionManager _session = SessionManager();

  late final Dio _dio;
  bool _isRefreshing = false;

  WorkspaceService() {
    _dio = Dio();
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);

    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 && !_isRefreshing) {
            _isRefreshing = true;

            try {
              final newTokens = await _refreshToken();

              if (newTokens != null) {
                await _session.saveSession(
                  newTokens.accessToken,
                  newTokens.refreshToken,
                  await _session.getId(),
                );

                final opts = error.requestOptions;
                opts.headers['Authorization'] =
                    'Bearer ${newTokens.accessToken}';

                final response = await _dio.fetch(opts);
                _isRefreshing = false;
                return handler.resolve(response);
              }
            } catch (e) {
              _isRefreshing = false;
              await _session.removeAccessToken();
            }

            _isRefreshing = false;
          }

          return handler.next(error);
        },
      ),
    );
  }

  Future<AuthResponseModel?> _refreshToken() async {
    try {
      String refreshToken = await _session.getRefreshToken();
      if (refreshToken.isEmpty) return null;

      final response = await Dio().post(
        '${AppConstants.baseUrl}/api/v1/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': AppConstants.tokenKey,
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        return AuthResponseModel.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('Refresh token error: $e');
      return null;
    }
  }

  Future<List<Workspace>> getWorkspaces({String query = ''}) async {
    final session = SessionManager();
    final String? token = await session.getAccessToken();

    if (token == null) {
      throw Exception('Token tidak ditemukan, silakan login ulang.');
    }

    print("TOKEN SAYA: $token");

    try {
      final response = await _dio.get(
        '/workspaces',
        queryParameters: query.isNotEmpty ? {'search': query} : null,

        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
            'x-api-key': AppConstants.tokenKey,
          },
        ),
      );

      final List result = response.data['data'] ?? [];

      return result.map((e) => Workspace.fromJson(e)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan');
    }
  }

  Future<bool> createWorkspace(String name, String description) async {
    final session = SessionManager();
    final String? token = await session.getAccessToken();

    if (token == null) {
      debugPrint('Gagal buat workspace: Token null');
      return false;
    }

    try {
      await _dio.post(
        '/workspaces',
        data: {'name': name, 'description': description},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
            'x-api-key': AppConstants.tokenKey,
          },
        ),
      );

      return true;
    } catch (e) {
      debugPrint('Gagal buat workspace: $e');
      return false;
    }
  }

  Future<Workspace> getWorkspaceDetail(int id) async {
    final session = SessionManager();
    final String? token = await session.getAccessToken();

    if (token == null) {
      throw Exception('Token tidak ditemukan, silakan login ulang.');
    }

    try {
      final response = await _dio.get(
        '/workspaces/$id',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'x-api-key': AppConstants.tokenKey,
          },
        ),
      );
      print(response.data);
      return Workspace.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<List<WorkspaceFile>> getWorkspaceFiles(int workspaceId) async {
    final session = SessionManager();
    final String? token = await session.getAccessToken();

    try {
      final response = await _dio.get(
        '/workspaces/$workspaceId/files',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'x-api-key': AppConstants.tokenKey,
          },
        ),
      );

      if (response.data['data'] != null) {
        final List result = response.data['data'];
        debugPrint('DATA SERVER: $result');
        return result.map((e) => WorkspaceFile.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Gagal ambil file workspace: $e');
      return [];
    }
  }

  Future<void> updateWorkspace(int id, String name, String description) async {
    try {
      await _dio.put(
        '/workspaces/$id',
        data: {'name': name, 'description': description},
      );
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<void> deleteWorkspace(int id) async {
    try {
      await _dio.delete('/workspaces/$id');
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<bool> uploadFile(int workspaceId, File file) async {
    final session = SessionManager();
    final String? token = await session.getAccessToken();

    if (token == null) return false;

    try {
      String fileName = file.path.split('/').last;

      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
        'workspace_id': workspaceId,
      });

      await _dio.post(
        '/files',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'x-api-key': AppConstants.tokenKey,
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      return true;
    } on DioException catch (e) {
      debugPrint('--- ERROR UPLOAD ---');
      debugPrint('URL: ${e.requestOptions.path}');
      debugPrint('Status: ${e.response?.statusCode}');
      debugPrint('Response: ${e.response?.data}');
      return false;
    } catch (e) {
      debugPrint('Error upload: $e');
      return false;
    }
  }

  Future<bool> deleteFile(int fileId) async {
    final session = SessionManager();
    final String? token = await session.getAccessToken();

    try {
      await _dio.delete(
        '/files/$fileId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'x-api-key': AppConstants.tokenKey,
          },
        ),
      );
      return true;
    } catch (e) {
      debugPrint('Gagal hapus file: $e');
      return false;
    }
  }

  Future<bool> addMember(int workspaceId, String email) async {
    final session = SessionManager();
    final String? token = await session.getAccessToken();

    if (token == null) return false;

    try {
      await _dio.post(
        '/workspaces/$workspaceId/members',
        data: {'email': email, 'role': 'viewer'},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'x-api-key': AppConstants.tokenKey,
          },
        ),
      );
      return true;
    } on DioException catch (e) {
      debugPrint('Error add member: ${e.response?.data}');

      return false;
    } catch (e) {
      debugPrint('Error add member: $e');
      return false;
    }
  }

Future<List<WorkspaceMember>> getWorkspaceMembers(int workspaceId) async {
  final session = SessionManager();
  final String? token = await session.getAccessToken();

  if (token == null) return [];

  try {
    final response = await _dio.get(
      '/workspaces/$workspaceId',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'x-api-key': AppConstants.tokenKey,
        },
      ),
    );

    final List members = response.data['data']['members'] ?? [];

    return members
        .map((e) => WorkspaceMember.fromJson(e))
        .toList();
  } catch (e) {
    debugPrint('Gagal ambil list member: $e');
    return [];
  }
}


  Future<bool> updateMemberRole(
    int workspaceId,
    int userId,
    String newRole,
  ) async {
    final session = SessionManager();
    final String? token = await session.getAccessToken();

    if (token == null) return false;

    try {
      await _dio.put(
        '/workspaces/$workspaceId/members/$userId',
        data: {'role': newRole},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'x-api-key': AppConstants.tokenKey,
          },
        ),
      );
      return true;
    } catch (e) {
      debugPrint('Gagal update role: $e');
      return false;
    }
  }

  Future<void> removeMember(int workspaceId, int userId) async {
    try {
      await _dio.delete('/workspaces/$workspaceId/members/$userId');
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  String _handleError(DioException e) {
    if (e.response != null) {
      return e.response?.data['error'] ?? 'Terjadi kesalahan pada server';
    } else {
      return 'Koneksi bermasalah: ${e.message}';
    }
  }
}
