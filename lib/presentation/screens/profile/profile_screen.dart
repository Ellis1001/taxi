import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    final session = supabase.auth.currentSession;
    final user = session?.user;

    if (user == null) {
      // Not logged in
      return Scaffold(
        appBar: AppBar(title: const Text('Perfil')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No has iniciado sesión.'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/login');
                },
                child: const Text('Iniciar sesión'),
              ),
            ],
          ),
        ),
      );
    }

    // If logged in, show profile info
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: CircleAvatar(
                radius: 40,
                child: Icon(Icons.person, size: 48),
              ),
            ),
            const SizedBox(height: 24),
            Text('Nombre: ${user.userMetadata?['full_name'] ?? 'No especificado'}',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Text('Correo: ${user.email ?? 'No especificado'}',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Text('ID de usuario: ${user.id}',
                style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  // Show dialog to edit profile
                  final nameController = TextEditingController(text: user.userMetadata?['full_name'] ?? '');
                  final emailController = TextEditingController(text: user.email ?? '');
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Editar perfil'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: nameController,
                              decoration: const InputDecoration(
                                labelText: 'Nombre',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(16)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: emailController,
                              decoration: const InputDecoration(
                                labelText: 'Correo electrónico',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(16)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              final newName = nameController.text.trim();
                              final newEmail = emailController.text.trim();
                              try {
                                // Update user metadata (name)
                                await supabase.auth.updateUser(
                                  UserAttributes(
                                    email: newEmail != user.email ? newEmail : null,
                                    data: {'full_name': newName},
                                  ),
                                );
                                if (mounted) {
                                  Navigator.of(context).pop(true);
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error al actualizar: $e')),
                                  );
                                }
                              }
                            },
                            child: const Text('Guardar'),
                          ),
                        ],
                      );
                    },
                  );
                  if (result == true && mounted) {
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Perfil actualizado')),
                    );
                  }
                },
                child: const Text('Editar perfil'),
              ),
            ),
            const Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  await supabase.auth.signOut();
                  if (mounted) {
                    setState(() {});
                  }
                },
                child: const Text('Cerrar sesión'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}