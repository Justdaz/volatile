import 'package:vasvault/constants/app_constant.dart';

class FileItem {
  final int id;
  final String fileName;
  final String filePath;
  final int size;
  final String mimeType;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? _thumbnailUrl;

  FileItem({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.size,
    required this.mimeType,
    required this.createdAt,
    this.updatedAt,
    String? thumbnailUrl,
  }) : _thumbnailUrl = thumbnailUrl;

  
  String? get thumbnailUrl {
    if (_thumbnailUrl != null) return _thumbnailUrl;
    if (mimeType.startsWith('image/')) {
      return '${AppConstants.baseUrl}/api/v1/files/$id/download';
    }
    
    return null;
  }

  factory FileItem.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.parse(json['created_at'] as String);
    return FileItem(
      id: json['id'] as int,
      fileName: json['file_name'] as String,
      filePath: json['file_path'] as String,
      size: json['size'] as int,
      mimeType: json['mime_type'] as String? ?? '',
      createdAt: createdAt,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      thumbnailUrl: json['thumbnail_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'file_name': fileName,
      'file_path': filePath,
      'size': size,
      'mime_type': mimeType,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  String get formattedSize {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}