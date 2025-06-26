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
        appBar: AppBar(
          title: const Text('Perfil'),
          automaticallyImplyLeading: false, // <-- Add this here as well
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'No has iniciado sesión.',
                style: TextStyle(fontSize: 18, color: Colors.grey), // Added some style
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/login');
                },
                style: ElevatedButton.styleFrom( // Added button style
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: const TextStyle(fontSize: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Iniciar sesión'),
              ),
            ],
          ),
        ),
      );
    }

    // If logged in, show profile info
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        automaticallyImplyLeading: false, // <-- This hides the back button
      ),
      body: SingleChildScrollView( // Use SingleChildScrollView to prevent overflow
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center, // Center the column content
          children: [
            // Enhanced Profile Picture Area
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).primaryColor, // Use theme color for border
                  width: 3,
                ),
              ),
              child: const CircleAvatar(
                radius: 50, // Increased size
                backgroundColor: Colors.blueGrey, // Added a background color
                child: Icon(Icons.person, size: 60, color: Colors.white), // Increased icon size and color
              ),
            ),
            const SizedBox(height: 32), // Increased spacing

            // User Information Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20), // Increased padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Información del Usuario',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor, // Styled title
                      ),
                    ),
                    const Divider(height: 20, thickness: 1), // Add a divider
                    const SizedBox(height: 8),
                    _buildInfoRow('Nombre:', user.userMetadata?['full_name'] ?? 'No especificado'),
                    const SizedBox(height: 12),
                    _buildInfoRow('Correo:', user.email ?? 'No especificado'),
                    const SizedBox(height: 12),
                    _buildInfoRow('ID de usuario:', user.id, isUserId: true), // Helper for ID style
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32), // Increased spacing

            // Edit Profile Button
            ElevatedButton(
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
              style: ElevatedButton.styleFrom( // Styled button
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                textStyle: const TextStyle(fontSize: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Editar perfil'),
            ),

            const SizedBox(height: 24), // Spacing before logout button

            // Logout Button
            ElevatedButton(
              onPressed: () async {
                await supabase.auth.signOut();
                if (mounted) {
                  setState(() {});
                }
              },
              style: ElevatedButton.styleFrom( // Styled button
                backgroundColor: Colors.redAccent, // Red color for logout
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                textStyle: const TextStyle(fontSize: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Cerrar sesión'),
            ),
            // Removed Spacer as SingleChildScrollView handles space
          ],
        ),
      ),
    );
  }

  // Helper method to build info rows
  Widget _buildInfoRow(String label, String value, {bool isUserId = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Expanded( // Use Expanded to prevent overflow
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: isUserId ? Colors.grey[700] : Colors.black87, // Different color for ID
            ),
            overflow: TextOverflow.ellipsis, // Handle long text
          ),
        ),
      ],
    );
  }
}