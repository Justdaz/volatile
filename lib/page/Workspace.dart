import 'package:flutter/material.dart';
import 'package:vasvault/models/workspace_model.dart';
import 'package:vasvault/services/workspace_service.dart';
import 'package:vasvault/page/Create_workspace_page.dart';
import 'package:vasvault/theme/app_colors.dart';
import 'package:vasvault/page/Workspace_detail_page.dart';
import 'package:vasvault/utils/session_meneger.dart';

class WorkspacePage extends StatefulWidget {
  const WorkspacePage({super.key});

  @override
  State<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends State<WorkspacePage> {
  final WorkspaceService _service = WorkspaceService();
  final SessionManager _sessionManager = SessionManager();
  late Future<List<Workspace>> _workspacesFuture;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _refreshList();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final userId = await _sessionManager.getUserId();
    if (mounted) {
      setState(() {
        _currentUserId = userId;
      });
    }
  }

  void _refreshList() {
    setState(() {
      _workspacesFuture = _service.getWorkspaces();
    });
  }

  bool _isOwner(Workspace workspace) {
    return _currentUserId != null && workspace.ownerId == _currentUserId;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'Workspace Saya',
          style: TextStyle(
            color: isDark ? AppColors.darkText : AppColors.lightText,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'workspace_fab',
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateWorkspacePage(),
            ),
          );
          if (result == true) {
            _refreshList();
          }
        },
        backgroundColor: AppColors.primary,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: FutureBuilder<List<Workspace>>(
        future: _workspacesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: AppColors.error, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Gagal memuat data',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_open,
                    size: 64,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada workspace',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  Text(
                    'Tap tombol + untuk membuat baru',
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ],
              ),
            );
          }

          final workspaces = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.95,
            ),
            itemCount: workspaces.length,
            itemBuilder: (context, index) {
              final ws = workspaces[index];
              final isOwner = _isOwner(ws);

              return _WorkspaceCard(
                workspace: ws,
                isOwner: isOwner,
                isDark: isDark,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WorkspaceDetailPage(workspace: ws),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _WorkspaceCard extends StatelessWidget {
  final Workspace workspace;
  final bool isOwner;
  final bool isDark;
  final VoidCallback onTap;

  const _WorkspaceCard({
    required this.workspace,
    required this.isOwner,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final folderColor = isOwner
        ? AppColors.ownedFolder
        : AppColors.sharedFolder;
    final badgeText = isOwner ? 'Milik Saya' : 'Dibagikan';
    final badgeColor = isOwner
        ? AppColors.ownedFolder.withOpacity(0.15)
        : AppColors.sharedFolder.withOpacity(0.15);
    final badgeTextColor = isOwner
        ? AppColors.ownedFolder
        : AppColors.sharedFolder;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Stack(
          children: [
            if (!isOwner)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.sharedFolder.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.group,
                    size: 16,
                    color: AppColors.sharedFolder,
                  ),
                ),
              ),

            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: folderColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.folder_rounded,
                        size: 48,
                        color: folderColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      workspace.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkText
                            : AppColors.lightText,
                      ),
                    ),
                    if (workspace.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        workspace.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: badgeTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
