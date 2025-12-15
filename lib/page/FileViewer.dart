import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:vasvault/constants/app_constant.dart';
import 'package:vasvault/models/storage_summary.dart';
import 'package:vasvault/theme/app_colors.dart';
import 'package:vasvault/utils/session_meneger.dart';

class FileViewerPage extends StatefulWidget {
  final LatestFile file;

  const FileViewerPage({super.key, required this.file});

  @override
  State<FileViewerPage> createState() => _FileViewerPageState();
}

class _FileViewerPageState extends State<FileViewerPage> {
  String? _accessToken;
  bool _isLoading = true;
  bool _isDownloading = false;
  double _downloadProgress = 0;
  String? _errorMessage;
  String? _localFilePath;

  @override
  void initState() {
    super.initState();
    _loadAccessToken();
  }

  Future<void> _loadAccessToken() async {
    try {
      final session = SessionManager();
      final token = await session.getAccessToken();
      setState(() {
        _accessToken = token;
        _isLoading = false;
      });

      if (widget.file.isPdf || _isDocument(widget.file.mimeType)) {
        await _downloadFile();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat file';
        _isLoading = false;
      });
    }
  }

  bool _isDocument(String mimeType) {
    return mimeType.contains('word') ||
        mimeType.contains('document') ||
        mimeType.contains('presentation') ||
        mimeType.contains('powerpoint') ||
        mimeType.contains('sheet') ||
        mimeType.contains('excel');
  }

  Future<void> _downloadFile() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
    });

    try {
      final request = http.Request('GET', Uri.parse(widget.file.fileUrl));
      request.headers['Authorization'] = 'Bearer $_accessToken';
      request.headers['x-api-key'] = AppConstants.tokenKey;

      final response = await http.Client().send(request);

      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/${widget.file.fileName}';
        final file = File(filePath);

        final totalBytes = response.contentLength ?? 0;
        int receivedBytes = 0;
        final List<int> bytes = [];

        await for (final chunk in response.stream) {
          bytes.addAll(chunk);
          receivedBytes += chunk.length;
          if (totalBytes > 0) {
            setState(() {
              _downloadProgress = receivedBytes / totalBytes;
            });
          }
        }

        await file.writeAsBytes(bytes);
        setState(() {
          _localFilePath = filePath;
          _isDownloading = false;
        });
      } else {
        throw Exception('Download failed: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal mengunduh file';
        _isDownloading = false;
      });
    }
  }

  Future<void> _openWithExternalApp() async {
    if (_localFilePath != null) {
      final result = await OpenFilex.open(_localFilePath!);
      if (result.type != ResultType.done) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tidak dapat membuka file: ${result.message}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.file.fileTypeLabel,
          style: TextStyle(
            color: isDark ? AppColors.darkText : AppColors.lightText,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_localFilePath != null && !widget.file.isImage)
            IconButton(
              icon: Icon(
                Icons.open_in_new,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
              onPressed: _openWithExternalApp,
              tooltip: 'Buka dengan aplikasi lain',
            ),
        ],
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_isDownloading) {
      return _buildDownloadingUI(isDark);
    }

    if (_errorMessage != null) {
      return _buildErrorUI(isDark);
    }

    if (widget.file.isImage) {
      return _buildImageViewer(isDark);
    } else if (widget.file.isPdf && _localFilePath != null) {
      return _buildPdfViewer();
    } else if (_isDocument(widget.file.mimeType)) {
      return _buildDocumentViewer(isDark);
    } else {
      return _buildUnsupportedFile(isDark);
    }
  }

  Widget _buildDownloadingUI(bool isDark) {
    final percentage = (_downloadProgress * 100).toInt();
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: _downloadProgress > 0 ? _downloadProgress : null,
                  strokeWidth: 6,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  color: AppColors.primary,
                ),
                if (_downloadProgress > 0)
                  Text(
                    '$percentage%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Mengunduh file...',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorUI(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: TextStyle(
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _errorMessage = null;
                _isLoading = true;
              });
              _loadAccessToken();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text(
              'Coba Lagi',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageViewer(bool isDark) {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: Center(
        child: Image.network(
          widget.file.fileUrl,
          headers: {
            'Authorization': 'Bearer $_accessToken',
            'x-api-key': AppConstants.tokenKey,
          },
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
                color: AppColors.primary,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image_outlined,
                    size: 64,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Gagal memuat gambar',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPdfViewer() {
    return SfPdfViewer.file(
      File(_localFilePath!),
      canShowScrollHead: true,
      canShowScrollStatus: true,
    );
  }

  Widget _buildDocumentViewer(bool isDark) {
    IconData icon;
    Color color;
    String typeLabel;

    if (widget.file.mimeType.contains('presentation') ||
        widget.file.mimeType.contains('powerpoint')) {
      icon = Icons.slideshow_outlined;
      color = Colors.orange;
      typeLabel = 'PowerPoint';
    } else if (widget.file.mimeType.contains('word') ||
        widget.file.mimeType.contains('document')) {
      icon = Icons.description_outlined;
      color = Colors.blue;
      typeLabel = 'Word Document';
    } else if (widget.file.mimeType.contains('sheet') ||
        widget.file.mimeType.contains('excel')) {
      icon = Icons.table_chart_outlined;
      color = Colors.green;
      typeLabel = 'Excel Spreadsheet';
    } else {
      icon = Icons.insert_drive_file_outlined;
      color = AppColors.primary;
      typeLabel = 'Document';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: color),
          const SizedBox(height: 24),
          Text(
            typeLabel,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              widget.file.fileName,
              style: TextStyle(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            StorageSummary.formatBytes(widget.file.size),
            style: TextStyle(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _openWithExternalApp,
            icon: const Icon(Icons.open_in_new, color: Colors.white),
            label: const Text(
              'Buka dengan Aplikasi Lain',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnsupportedFile(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_drive_file_outlined,
            size: 80,
            color: AppColors.primary,
          ),
          const SizedBox(height: 24),
          Text(
            widget.file.fileTypeLabel,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            StorageSummary.formatBytes(widget.file.size),
            style: TextStyle(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Preview tidak tersedia',
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
