// lib/presentation/widgets/user_selector_widget.dart
// Widget temporal para seleccionar usuario actual

import 'package:flutter/material.dart';
import '../../core/services/user_service.dart';
import '../../core/services/firebase_user_service.dart';

class UserSelectorWidget extends StatefulWidget {
  final VoidCallback? onUserChanged;
  
  const UserSelectorWidget({Key? key, this.onUserChanged}) : super(key: key);

  @override
  State<UserSelectorWidget> createState() => _UserSelectorWidgetState();
}

class _UserSelectorWidgetState extends State<UserSelectorWidget> {
  String? _currentUserName;
  String? _currentUserEmail;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final name = await UserService.getCurrentUserName();
    final email = await UserService.getCurrentUserEmail();
    
    setState(() {
      _currentUserName = name;
      _currentUserEmail = email;
    });
  }

  Future<void> _showUserSelector() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Cargar usuarios de Firebase
      final usersData = await FirebaseUserService.getAllUsers();
      
      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      // Mostrar diálogo de selección
      final selectedUser = await showDialog<Map<String, String>>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Seleccionar Usuario Actual'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: usersData.length,
              itemBuilder: (context, index) {
                final user = usersData[index];
                return ListTile(
                  title: Text(user['name']!),
                  subtitle: Text(user['email']!),
                  onTap: () => Navigator.of(context).pop(user),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      );

      if (selectedUser != null) {
        // Configurar nuevo usuario
        UserService.setCurrentUser(
          selectedUser['email']!,
          selectedUser['name']!,
        );
        
        setState(() {
          _currentUserName = selectedUser['name'];
          _currentUserEmail = selectedUser['email'];
        });

        widget.onUserChanged?.call();
      }

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando usuarios: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.person, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Usuario Actual:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _currentUserName ?? 'Cargando...',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_currentUserEmail != null)
                  Text(
                    _currentUserEmail!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          if (_isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            TextButton(
              onPressed: _showUserSelector,
              child: const Text('Cambiar'),
            ),
        ],
      ),
    );
  }
}