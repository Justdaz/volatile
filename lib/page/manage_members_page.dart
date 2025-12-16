import 'package:flutter/material.dart';
import 'package:vasvault/models/workspace_member_model.dart';
import 'package:vasvault/services/workspace_service.dart';
import 'package:vasvault/utils/session_meneger.dart';

const List<String> _availableRoles = [
  'owner',
  'admin',
  'editor',
  'viewer',
];

class ManageMembersPage extends StatefulWidget {
  final int workspaceId;

  final String currentUserRole;

  const ManageMembersPage({
    super.key,
    required this.workspaceId,
    required this.currentUserRole,
  });

  @override
  State<ManageMembersPage> createState() => _ManageMembersPageState();
}

class _ManageMembersPageState extends State<ManageMembersPage> {
  List<WorkspaceMember> _members = [];
  bool _isLoading = true;
  String? _errorMessage;

  final SessionManager _sessionManager = SessionManager();

  bool get _canEditRoles => widget.currentUserRole == 'owner' || widget.currentUserRole == 'admin';

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final members = await WorkspaceService().getWorkspaceMembers(widget.workspaceId);
      setState(() {
        _members = members;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat anggota: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  Future<void> _updateRole(int userId, String newRole) async {

    if (!_canEditRoles) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda tidak memiliki izin untuk mengubah peran.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Memperbarui peran ke $newRole...')),
    );

    final success = await WorkspaceService().updateMemberRole(
      widget.workspaceId,
      userId,
      newRole,
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Peran berhasil diperbarui!')),
      );

      _fetchMembers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memperbarui peran.')),
      );

      _fetchMembers();
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Anggota'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : RefreshIndicator(
        onRefresh: _fetchMembers,
        child: FutureBuilder<int?>(
          future: _sessionManager.getUserId(),
          builder: (context, snapshot) {
            // ID pengguna yang sedang login
            final currentUserId = snapshot.data;
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            return ListView.builder(
              itemCount: _members.length,
              itemBuilder: (context, index) {
                final member = _members[index];

                final isOwnerInList = member.role == 'owner';

                final isCurrentUser = member.id == currentUserId;

                final isEditable = _canEditRoles && !isOwnerInList && !isCurrentUser;

            return ListTile(
              leading: const Icon(Icons.person),
              title: Text(member.email),
              subtitle: Text('Role: ${member.role}'),
              trailing: SizedBox(
                width: 130,
                child: DropdownButtonFormField<String>(
                  value: member.role,

                  items: _availableRoles.map((String role) {
                    return DropdownMenuItem<String>(
                      value: role,

                      enabled: !isOwnerInList,
                      child: Text(role),
                    );
                  }).toList(),
                  onChanged: isEditable
                      ? (String? newRole) {
                    if (newRole != null && newRole != member.role) {
                      _updateRole(member.id, newRole);
                    }
                  }
                      : null,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            );
              },
            );
          },
        ),
      ),
    );
  }
}