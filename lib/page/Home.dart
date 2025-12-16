import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:vasvault/bloc/storage_bloc.dart';
import 'package:vasvault/bloc/storage_event.dart';
import 'package:vasvault/bloc/storage_state.dart';
import 'package:vasvault/constants/app_constant.dart';
import 'package:vasvault/models/storage_summary.dart';
import 'package:vasvault/page/FileViewer.dart';
import 'package:vasvault/theme/app_colors.dart';
import 'package:vasvault/utils/session_meneger.dart';
import 'package:vasvault/widgets/upload_bottom_sheet.dart';

class Home extends StatelessWidget {
  final StorageBloc storageBloc;

  const Home({super.key, required this.storageBloc});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final formattedDate = DateFormat('MMMM yyyy', 'id_ID').format(now);

    return BlocProvider.value(
      value: storageBloc,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              storageBloc.add(RefreshStorageSummary());
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VasVault',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  BlocBuilder<StorageBloc, StorageState>(
                    builder: (context, state) {
                      if (state is StorageLoading) {
                        return _buildLoadingCard();
                      } else if (state is StorageLoaded) {
                        return _buildStorageCard(state.storageSummary, isDark);
                      } else if (state is StorageError) {
                        return _buildErrorCard(state.message, isDark);
                      }
                      return _buildLoadingCard();
                    },
                  ),
                  const SizedBox(height: 24),
    
                  Text(
                    'Aksi Cepat',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildQuickActions(context, isDark),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'File Terakhir',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      TextButton(
                        onPressed: () {
                    
                        },
                        child: Text(
                          'Lihat Semua',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  BlocBuilder<StorageBloc, StorageState>(
                    builder: (context, state) {
                      if (state is StorageLoaded) {
                        final files = state.storageSummary.latestFiles;
                        if (files.isEmpty) {
                          return _buildEmptyFileCard(isDark);
                        }
                        return _buildLatestFilesGrid(files, isDark);
                      }
                      return _buildEmptyFileCard(isDark);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _buildErrorCard(String message, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 48),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              storageBloc.add(LoadStorageSummary());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageCard(StorageSummary storage, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Storage',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  storage.formattedMaxBytes,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Text(
            storage.formattedUsedBytes,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: storage.usagePercentage / 100,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Digunakan',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          storage.formattedUsedBytes,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tersisa',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          storage.formattedRemainingBytes,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isDark) {
    return Row(
      children: [
        _buildQuickActionButton(
          icon: Icons.cloud_upload_outlined,
          label: 'Upload',
          color: AppColors.primary,
          isDark: isDark,
          onTap: () {
            UploadBottomSheet.show(
              context,
              onUploadComplete: () {
                storageBloc.add(RefreshStorageSummary());
              },
            );
          },
        ),

        
        const SizedBox(width: 12),
        _buildQuickActionButton(
          icon: Icons.share_outlined,
          label: 'Shared',
          color: AppColors.warning,
          isDark: isDark,
          onTap: () {
            
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLatestFilesGrid(List<LatestFile> files, bool isDark) {
    final displayFiles = files.length > 6 ? files.sublist(0, 6) : files;
    final rows = (displayFiles.length / 3).ceil();
    final gridHeight = rows * 160.0 + (rows - 1) * 12.0;

    return SizedBox(
      height: gridHeight,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: displayFiles.length,
        itemBuilder: (context, index) {
          return _buildFileCard(context, displayFiles[index], isDark);
        },
      ),
    );
  }

  Widget _buildFileCard(BuildContext context, LatestFile file, bool isDark) {
    final formattedSize = StorageSummary.formatBytes(file.size);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => FileViewerPage(file: file)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thumbnail or icon
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
                child: file.isImage
                    ? _buildThumbnailImage(file, isDark)
                    : _buildFileTypeIcon(file, isDark),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.fileTypeLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formattedSize,
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
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailImage(LatestFile file, bool isDark) {
    return FutureBuilder<String>(
      future: _getAuthHeaders(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildFileTypeIcon(file, isDark);
        }
        return Image.network(
          file.thumbnailUrl,
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
            return _buildFileTypeIcon(file, isDark);
          },
        );
      },
    );
  }

  Future<String> _getAuthHeaders() async {
    final session = SessionManager();
    return await session.getAccessToken();
  }

  Widget _buildFileTypeIcon(LatestFile file, bool isDark) {
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
      color: color.withValues(alpha: 0.1),
      child: Center(child: Icon(icon, size: 40, color: color)),
    );
  }

  Widget _buildEmptyFileCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.cloud_upload_outlined,
            size: 48,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada file',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap + untuk menambah file pertama',
            style: TextStyle(
              fontSize: 12,
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
