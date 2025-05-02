import 'package:flutter/material.dart';
import 'package:taxibooking/data/datasources/remote/supabase_api.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _email = '';
  String _password = '';
  String _name = '';
  bool _loading = false;
  String _selectedCountryCode = '+53'; // Default to Cuba

  // Full list of country codes and flags (sample shown, expand as needed)
  final List<Map<String, String>> _countryCodes = [
    {'code': '+1', 'flag': '🇺🇸'},
    {'code': '+7', 'flag': '🇷🇺'},
    {'code': '+20', 'flag': '🇪🇬'},
    {'code': '+27', 'flag': '🇿🇦'},
    {'code': '+30', 'flag': '🇬🇷'},
    {'code': '+31', 'flag': '🇳🇱'},
    {'code': '+32', 'flag': '🇧🇪'},
    {'code': '+33', 'flag': '🇫🇷'},
    {'code': '+34', 'flag': '🇪🇸'},
    {'code': '+36', 'flag': '🇭🇺'},
    {'code': '+39', 'flag': '🇮🇹'},
    {'code': '+40', 'flag': '🇷🇴'},
    {'code': '+41', 'flag': '🇨🇭'},
    {'code': '+43', 'flag': '🇦🇹'},
    {'code': '+44', 'flag': '🇬🇧'},
    {'code': '+45', 'flag': '🇩🇰'},
    {'code': '+46', 'flag': '🇸🇪'},
    {'code': '+47', 'flag': '🇳🇴'},
    {'code': '+48', 'flag': '🇵🇱'},
    {'code': '+49', 'flag': '🇩🇪'},
    {'code': '+51', 'flag': '🇵🇪'},
    {'code': '+52', 'flag': '🇲🇽'},
    {'code': '+53', 'flag': '🇨🇺'},
    {'code': '+54', 'flag': '🇦🇷'},
    {'code': '+55', 'flag': '🇧🇷'},
    {'code': '+56', 'flag': '🇨🇱'},
    {'code': '+57', 'flag': '🇨🇴'},
    {'code': '+58', 'flag': '🇻🇪'},
    {'code': '+60', 'flag': '🇲🇾'},
    {'code': '+61', 'flag': '🇦🇺'},
    {'code': '+62', 'flag': '🇮🇩'},
    {'code': '+63', 'flag': '🇵🇭'},
    {'code': '+64', 'flag': '🇳🇿'},
    {'code': '+65', 'flag': '🇸🇬'},
    {'code': '+66', 'flag': '🇹🇭'},
    {'code': '+81', 'flag': '🇯🇵'},
    {'code': '+82', 'flag': '🇰🇷'},
    {'code': '+84', 'flag': '🇻🇳'},
    {'code': '+86', 'flag': '🇨🇳'},
    {'code': '+90', 'flag': '🇹🇷'},
    {'code': '+91', 'flag': '🇮🇳'},
    {'code': '+92', 'flag': '🇵🇰'},
    {'code': '+93', 'flag': '🇦🇫'},
    {'code': '+94', 'flag': '🇱🇰'},
    {'code': '+95', 'flag': '🇲🇲'},
    {'code': '+98', 'flag': '🇮🇷'},
    // ... add all countries here ...
  ];

  Future<void> _register() async {
    setState(() => _loading = true);
    try {
      final fullPhoneNumber = '$_selectedCountryCode${_phoneController.text}';
      final response = await SupabaseApi().signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        data: {
          'full_name': _name,
          'phone': fullPhoneNumber, // Save phone with prefix
        },
      );
      if (response.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro exitoso. Revisa tu correo para confirmar tu cuenta.')),
        );
        Navigator.of(context).pushReplacementNamed('/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.session?.toString() ?? 'Error desconocido al registrar')),
        
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _loading = false);
    }
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nombre'),
                onChanged: (value) => _name = value,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Ingrese su nombre' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) => _email = value,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Ingrese su correo' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _selectedCountryCode,
                      decoration: const InputDecoration(
                        labelText: 'Código',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      items: _countryCodes
                          .map((country) => DropdownMenuItem(
                                value: country['code'],
                                child: Text('${country['flag']} ${country['code']}'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCountryCode = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 5,
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  if (!RegExp(r'[A-Z]').hasMatch(value)) {
                    return 'Password must contain at least one uppercase letter';
                  }
                  if (!RegExp(r'[a-z]').hasMatch(value)) {
                    return 'Password must contain at least one lowercase letter';
                  }
                  if (!RegExp(r'\d').hasMatch(value)) {
                    return 'Password must contain at least one number';
                  }
                  if (!RegExp(r'[!@#\$&*~._-]').hasMatch(value)) {
                    return 'Password must contain at least one special character';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm Password'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading
                    ? null
                    : () {
                        if (_formKey.currentState!.validate()) {
                          _register();
                        }
                      },
                child: _loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Registrarse'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                child: const Text('¿Ya tienes cuenta? Inicia sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}