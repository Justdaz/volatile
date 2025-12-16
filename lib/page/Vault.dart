import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vasvault/bloc/vault_bloc.dart';
import 'package:vasvault/bloc/vault_event.dart';
import 'package:vasvault/bloc/vault_state.dart';
import 'package:vasvault/constants/app_constant.dart';
import 'package:vasvault/models/file_item.dart';
import 'package:vasvault/models/storage_summary.dart';
import 'package:vasvault/page/FileViewer.dart';
import 'package:vasvault/theme/app_colors.dart';
import 'package:vasvault/utils/session_meneger.dart';

class Vault extends StatefulWidget {
  const Vault({super.key});

  @override
  State<Vault> createState() => _VaultState();
}

class _VaultState extends State<Vault> {
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    context.read<VaultBloc>().add(LoadVaultFiles());
  }

  LatestFile _toLatestFile(FileItem file) {
    return LatestFile(
      id: file.id,
      userId: 0,
      fileName: file.fileName,
      filePath: file.filePath,
      mimeType: file.mimeType,
      size: file.size,
      createdAt: file.createdAt,
    );
  }

  Future<String> _getAuthToken() async {
    final session = SessionManager();
    return await session.getAccessToken();
  }

  void _openFileViewer(FileItem file) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FileViewerPage(file: _toLatestFile(file)),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Vault'),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
            tooltip: _isGridView
                ? 'Switch to list view'
                : 'Switch to grid view',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<VaultBloc>().add(RefreshVaultFiles());
            },
          ),
        ],
      ),
      body: BlocBuilder<VaultBloc, VaultState>(
        builder: (context, state) {
          if (state is VaultLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is VaultError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${state.message}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<VaultBloc>().add(LoadVaultFiles());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (state is VaultLoaded) {
            if (state.files.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.folder_open, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No files uploaded yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload your first file to get started',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                context.read<VaultBloc>().add(RefreshVaultFiles());
                await Future.delayed(const Duration(seconds: 1));
              },
              child: _isGridView
                  ? _buildGridView(state.files, isDark)
                  : _buildListView(state.files, isDark),
            );
          }
          return const Center(child: Text('Welcome to your Vault'));
        },
      ),
    );
  }

  Widget _buildGridView(List<FileItem> files, bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return _buildGridCard(file, isDark);
      },
    );
  }

  Widget _buildListView(List<FileItem> files, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return _buildFileCard(file, isDark);
      },
    );
  }

  Widget _buildGridCard(FileItem file, bool isDark) {
    final isImage = file.mimeType.startsWith('image/');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: InkWell(
        onTap: () => _openFileViewer(file),
        onLongPress: () => _showFileOptions(file),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: _getFileColor(file.mimeType).withOpacity(0.1),
                ),
                child: isImage
                    ? _buildThumbnailImage(file, isDark)
                    : _buildThumbnailIcon(file, isDark),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          file.fileName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkText
                                : AppColors.lightText,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          file.formattedSize,
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        size: 16,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                      padding: EdgeInsets.zero,
                      iconSize: 16,
                      onSelected: (value) {
                        switch (value) {
                          case 'preview':
                            _openFileViewer(file);
                            break;
                          case 'download':
                            _downloadFile(file);
                            break;
                          case 'rename':
                            _showRenameDialog(file);
                            break;
                          case 'delete':
                            _confirmDelete(file);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'preview',
                          child: Row(
                            children: [
                              Icon(Icons.visibility_outlined, size: 20),
                              SizedBox(width: 12),
                              Text('Preview'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'download',
                          child: Row(
                            children: [
                              Icon(Icons.download_outlined, size: 20),
                              SizedBox(width: 12),
                              Text('Download'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'rename',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 20),
                              SizedBox(width: 12),
                              Text('Rename'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outlined,
                                size: 20,
                                color: Colors.red,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailImage(FileItem file, bool isDark) {
    return FutureBuilder<String>(
      future: _getAuthToken(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildThumbnailIcon(file, isDark);
        }
        return Image.network(
          file.thumbnailUrl!,
          fit: BoxFit.cover,
          headers: {
            'Authorization': 'Bearer ${snapshot.data}',
            'x-api-key': AppConstants.tokenKey,
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: isDark
                  ? AppColors.darkBackground
                  : AppColors.lightBackground,
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildThumbnailIcon(file, isDark);
          },
        );
      },
    );
  }

  Widget _buildThumbnailIcon(FileItem file, bool isDark) {
    IconData icon;
    Color color;

    if (file.mimeType.startsWith('image/')) {
      icon = Icons.image_outlined;
      color = AppColors.success;
    } else if (file.mimeType.startsWith('video/')) {
      icon = Icons.video_file_outlined;
      color = AppColors.error;
    } else if (file.mimeType.startsWith('audio/')) {
      icon = Icons.audio_file_outlined;
      color = AppColors.warning;
    } else if (file.mimeType.contains('pdf')) {
      icon = Icons.picture_as_pdf_outlined;
      color = AppColors.error;
    } else if (file.mimeType.contains('presentation') ||
        file.mimeType.contains('powerpoint')) {
      icon = Icons.slideshow_outlined;
      color = Colors.orange;
    } else if (file.mimeType.contains('word') ||
        file.mimeType.contains('document')) {
      icon = Icons.description_outlined;
      color = Colors.blue;
    } else if (file.mimeType.contains('sheet') ||
        file.mimeType.contains('excel')) {
      icon = Icons.table_chart_outlined;
      color = Colors.green;
    } else {
      icon = Icons.insert_drive_file_outlined;
      color = AppColors.primary;
    }

    return Container(
      color: color.withOpacity(0.1),
      child: Center(child: Icon(icon, size: 40, color: color)),
    );
  }

  Widget _buildFileCard(FileItem file, bool isDark) {
    final isImage = file.mimeType.startsWith('image/');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: InkWell(
        onTap: () => _openFileViewer(file),
        onLongPress: () => _showFileOptions(file),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: isImage
                      ? _buildListThumbnailImage(file, isDark)
                      : _buildListThumbnailIcon(file, isDark),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.fileName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkText
                            : AppColors.lightText,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${file.formattedSize} • ${_formatDate(file.createdAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListThumbnailImage(FileItem file, bool isDark) {
    return FutureBuilder<String>(
      future: _getAuthToken(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildListThumbnailIcon(file, isDark);
        }
        return Image.network(
          file.thumbnailUrl!,
          fit: BoxFit.cover,
          headers: {
            'Authorization': 'Bearer ${snapshot.data}',
            'x-api-key': AppConstants.tokenKey,
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: _getFileColor(file.mimeType).withOpacity(0.1),
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildListThumbnailIcon(file, isDark);
          },
        );
      },
    );
  }

  Widget _buildListThumbnailIcon(FileItem file, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: _getFileColor(file.mimeType).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(
          _getFileIcon(file.mimeType),
          color: _getFileColor(file.mimeType),
          size: 24,
        ),
      ),
    );
  }

  IconData _getFileIcon(String mimeType) {
    if (mimeType.startsWith('image/')) {
      return Icons.image;
    } else if (mimeType.startsWith('video/')) {
      return Icons.video_file;
    } else if (mimeType.startsWith('audio/')) {
      return Icons.audio_file;
    } else if (mimeType.contains('pdf')) {
      return Icons.picture_as_pdf;
    } else if (mimeType.contains('document') ||
        mimeType.contains('word') ||
        mimeType.contains('text')) {
      return Icons.description;
    } else if (mimeType.contains('spreadsheet') || mimeType.contains('excel')) {
      return Icons.table_chart;
    } else if (mimeType.contains('zip') ||
        mimeType.contains('rar') ||
        mimeType.contains('compressed')) {
      return Icons.folder_zip;
    }
    return Icons.insert_drive_file;
  }

  Color _getFileColor(String mimeType) {
    if (mimeType.startsWith('image/')) {
      return Colors.blue;
    } else if (mimeType.startsWith('video/')) {
      return Colors.purple;
    } else if (mimeType.startsWith('audio/')) {
      return Colors.orange;
    } else if (mimeType.contains('pdf')) {
      return Colors.red;
    } else if (mimeType.contains('document') ||
        mimeType.contains('word') ||
        mimeType.contains('text')) {
      return Colors.indigo;
    } else if (mimeType.contains('spreadsheet') || mimeType.contains('excel')) {
      return Colors.green;
    } else if (mimeType.contains('zip') ||
        mimeType.contains('rar') ||
        mimeType.contains('compressed')) {
      return Colors.amber;
    }
    return Colors.grey;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}mo ago';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _downloadFile(FileItem file) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DownloadProgressDialog(
        file: file,
        onComplete: (filePath) {
          Navigator.pop(context);
          if (filePath != null) {
            _showDownloadCompleteDialog(file.fileName, filePath);
          }
        },
        getAuthToken: _getAuthToken,
      ),
    );
  }

  void _showDownloadCompleteDialog(String fileName, String filePath) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Download Complete'),
            ],
          ),
          content: Text('$fileName has been downloaded successfully.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                OpenFilex.open(filePath);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text(
                'Open File',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showRenameDialog(FileItem file) {
    final TextEditingController controller = TextEditingController(
      text: file.fileName,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename File'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'New file name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newName = controller.text.trim();
                if (newName.isNotEmpty && newName != file.fileName) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Renamed to $newName'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text(
                'Rename',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showFileOptions(FileItem file) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.fileName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      file.formattedSize,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.visibility_outlined),
                title: const Text('Preview'),
                onTap: () {
                  Navigator.pop(context);
                  _openFileViewer(file);
                },
              ),
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Download'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Download feature coming soon'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Share feature coming soon')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Details'),
                onTap: () {
                  Navigator.pop(context);
                  _showFileDetails(file);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(file);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showFileDetails(FileItem file) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('File Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Name', file.fileName),
              _detailRow('Size', file.formattedSize),
              _detailRow('Type', file.mimeType),
              _detailRow('Uploaded', _formatFullDate(file.createdAt)),
              if (file.updatedAt != null)
                _detailRow('Modified', _formatFullDate(file.updatedAt!)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.grey[700])),
          ),
        ],
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _confirmDelete(FileItem file) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete File'),
          content: Text('Are you sure you want to delete "${file.fileName}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Delete feature coming soon')),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

class _DownloadProgressDialog extends StatefulWidget {
  final FileItem file;
  final Function(String?) onComplete;
  final Future<String> Function() getAuthToken;

  const _DownloadProgressDialog({
    required this.file,
    required this.onComplete,
    required this.getAuthToken,
  });

  @override
  State<_DownloadProgressDialog> createState() =>
      _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<_DownloadProgressDialog> {
  double _progress = 0;
  String _status = 'Preparing download...';
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    try {
      final token = await widget.getAuthToken();
      final fileUrl =
          '${AppConstants.baseUrl}/api/v1/files/${widget.file.id}/download';

      setState(() {
        _status = 'Connecting...';
      });

      final request = http.Request('GET', Uri.parse(fileUrl));
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['x-api-key'] = AppConstants.tokenKey;

      final response = await http.Client().send(request);

      if (response.statusCode == 200) {
        final directory = await getExternalStorageDirectory();
        final downloadPath =
            '${directory?.path ?? '/storage/emulated/0/Download'}/${widget.file.fileName}';
        final file = File(downloadPath);

        final totalBytes = response.contentLength ?? 0;
        int receivedBytes = 0;
        final List<int> bytes = [];

        setState(() {
          _status = 'Downloading...';
        });

        await for (final chunk in response.stream) {
          bytes.addAll(chunk);
          receivedBytes += chunk.length;
          if (totalBytes > 0) {
            setState(() {
              _progress = receivedBytes / totalBytes;
            });
          }
        }

        await file.writeAsBytes(bytes);

        setState(() {
          _status = 'Complete!';
          _progress = 1.0;
        });

        await Future.delayed(const Duration(milliseconds: 500));
        widget.onComplete(downloadPath);
      } else {
        throw Exception('Download failed: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isError = true;
        _status = 'Download failed: ${e.toString()}';
      });
      await Future.delayed(const Duration(seconds: 2));
      widget.onComplete(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (_progress * 100).toInt();

    return AlertDialog(
      title: Text(_isError ? 'Download Failed' : 'Downloading'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_isError) ...[
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _progress > 0 ? _progress : null,
                    strokeWidth: 6,
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    color: AppColors.primary,
                  ),
                  if (_progress > 0)
                    Text(
                      '$percentage%',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
          ],
          Text(
            _status,
            textAlign: TextAlign.center,
            style: TextStyle(color: _isError ? Colors.red : null),
          ),
          if (!_isError) ...[
            const SizedBox(height: 8),
            Text(
              widget.file.fileName,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
