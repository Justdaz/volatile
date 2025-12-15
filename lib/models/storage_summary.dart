import 'package:vasvault/constants/app_constant.dart';

class LatestFile {
  final int id;
  final int userId;
  final int? folderId;
  final String fileName;
  final String filePath;
  final String mimeType;
  final int size;
  final DateTime createdAt;

  LatestFile({
    required this.id,
    required this.userId,
    this.folderId,
    required this.fileName,
    required this.filePath,
    required this.mimeType,
    required this.size,
    required this.createdAt,
  });

  factory LatestFile.fromJson(Map<String, dynamic> json) {
    return LatestFile(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      folderId: json['folder_id'] as int?,
      fileName: json['file_name'] as String,
      filePath: json['file_path'] as String,
      mimeType: json['mime_type'] as String,
      size: json['size'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'folder_id': folderId,
      'file_name': fileName,
      'file_path': filePath,
      'mime_type': mimeType,
      'size': size,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isImage => mimeType.startsWith('image/');
  bool get isPdf => mimeType.contains('pdf');
  String get thumbnailUrl =>
      '${AppConstants.baseUrl}/api/v1/files/$id/thumbnail';
  String get fileUrl => '${AppConstants.baseUrl}/api/v1/files/$id/download';
  String get displayName {
    final ext = fileName.contains('.') ? fileName.split('.').last : '';
    if (fileName.contains('-') && fileName.length > 36) {
      return ext.toUpperCase();
    }
    return fileName;
  }

  String get fileTypeLabel {
    if (mimeType.startsWith('image/')) return 'Image';
    if (mimeType.startsWith('video/')) return 'Video';
    if (mimeType.startsWith('audio/')) return 'Audio';
    if (mimeType.contains('pdf')) return 'PDF';
    if (mimeType.contains('word') || mimeType.contains('document'))
      return 'DOC';
    if (mimeType.contains('sheet') || mimeType.contains('excel')) return 'XLS';
    if (mimeType.contains('presentation') || mimeType.contains('powerpoint'))
      return 'PPT';
    if (mimeType.contains('zip') ||
        mimeType.contains('rar') ||
        mimeType.contains('tar'))
      return 'ZIP';
    return 'File';
  }
}

class StorageSummary {
  final int maxBytes;
  final int usedBytes;
  final int remainingBytes;
  final List<LatestFile> latestFiles;

  StorageSummary({
    required this.maxBytes,
    required this.usedBytes,
    required this.remainingBytes,
    this.latestFiles = const [],
  });

  factory StorageSummary.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;

    List<LatestFile> files = [];
    if (data['latest_files'] != null) {
      files = (data['latest_files'] as List)
          .map((f) => LatestFile.fromJson(f as Map<String, dynamic>))
          .toList();
    }

    return StorageSummary(
      maxBytes: data['max_bytes'] as int,
      usedBytes: data['used_bytes'] as int,
      remainingBytes: data['remaining_bytes'] as int,
      latestFiles: files,
    );
  }

  double get usagePercentage => maxBytes > 0 ? (usedBytes / maxBytes) * 100 : 0;

  String get formattedMaxBytes => formatBytes(maxBytes);
  String get formattedUsedBytes => formatBytes(usedBytes);
  String get formattedRemainingBytes => formatBytes(remainingBytes);

  static String formatBytes(int bytes) {
    if (bytes >= 1073741824) {
      return '${(bytes / 1073741824).toStringAsFixed(2)} GB';
    } else if (bytes >= 1048576) {
      return '${(bytes / 1048576).toStringAsFixed(2)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else {
      return '$bytes B';
    }
  }
}
