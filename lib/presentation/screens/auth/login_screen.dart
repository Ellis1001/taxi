import 'package:flutter/material.dart';
import 'package:taxibooking/data/datasources/remote/supabase_api.dart';
import 'package:taxibooking/presentation/screens/home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _loading = false;

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      final response = await SupabaseApi().signInWithPassword(
        _email,
        _password,
      );
      if (response.user != null) {
        // Navigate to HomeScreen after successful login
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Login failed')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        // Center the card vertically and horizontally
        child: SingleChildScrollView(
          // Allow scrolling if content overflows
          padding: const EdgeInsets.all(24),
          child: Card(
            // Wrap the form in a Card
            elevation: 8, // Increased elevation for more prominent shadow
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16), // More rounded corners
            ),
            child: Padding(
              padding: const EdgeInsets.all(
                24,
              ), // Increased padding inside the card
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Column takes minimum space
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .stretch, // Stretch children horizontally
                  children: [
                    // Title inside the card
                    Text(
                      'Bienvenido de nuevo',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24), // Spacing after title

                    TextFormField(
                      decoration: InputDecoration(
                        // Styled InputDecoration
                        labelText: 'Correo electrónico',
                        border: OutlineInputBorder(
                          // Outline border
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                        ), // Add icon
                      ),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (value) => _email = value,
                      validator:
                          (value) =>
                              value == null || value.isEmpty
                                  ? 'Ingrese su correo'
                                  : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: InputDecoration(
                        // Styled InputDecoration
                        labelText: 'Contraseña',
                        border: OutlineInputBorder(
                          // Outline border
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.lock_outline), // Add icon
                      ),
                      obscureText: true,
                      onChanged: (value) => _password = value,
                      validator:
                          (value) =>
                              value == null || value.isEmpty
                                  ? 'Ingrese su contraseña'
                                  : null,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed:
                          _loading
                              ? null
                              : () {
                                if (_formKey.currentState!.validate()) {
                                  _login();
                                }
                              },
                      style: ElevatedButton.styleFrom(
                        // Styled button
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child:
                          _loading
                              ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ), // White indicator on button
                                ),
                              )
                              : const Text('Iniciar sesión'),
                    ),
                    const SizedBox(height: 16), // Spacing between buttons
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacementNamed('/register');
                      },
                      style: TextButton.styleFrom(
                        // Styled text button
                      ),
                      child: const Text('¿No tienes cuenta? Regístrate'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
