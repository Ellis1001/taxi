import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExcursionTab extends StatefulWidget {
  const ExcursionTab({super.key});

  @override
  State<ExcursionTab> createState() => _ExcursionTabState();
}

class _ExcursionTabState extends State<ExcursionTab> {
  final _formKey = GlobalKey<FormState>();
  String? _ubicacion = 'Trinidad'; // Set default to Trinidad
  List<Map<String, dynamic>> _excursiones = [];
  List<String> _ubicacionesDisponibles = [];
  bool _loading = false;
  bool _loadingUbicaciones = true;

  @override
  void initState() {
    super.initState();
    _fetchUbicaciones();
    // Fetch excursions for Trinidad initially
    _buscarExcursiones();
  }

  Future<void> _fetchUbicaciones() async {
    setState(() {
      _loadingUbicaciones = true;
    });
    final response = await Supabase.instance.client
        .from('excursiones')
        .select('ubicacion');
    if (response != null) {
      final ubicaciones = (response as List)
          .map((e) => e['ubicacion'] as String)
          .toSet()
          .toList();
      setState(() {
        _ubicacionesDisponibles = ubicaciones;
        if (_ubicacionesDisponibles.isNotEmpty) {
          if (_ubicacion == null || !_ubicacionesDisponibles.contains(_ubicacion)) {
            _ubicacion = _ubicacionesDisponibles.first;
          }
        } else {
          _ubicacion = null;
        }
        _loadingUbicaciones = false;
      });
      if (_ubicacion != null) {
        _buscarExcursiones();
      }
    } else {
      setState(() {
        _ubicacionesDisponibles = [];
        _ubicacion = null;
        _loadingUbicaciones = false;
      });
    }
  }

  Future<void> _buscarExcursiones() async {
    if (_ubicacion == null || _ubicacion!.isEmpty) return;
    setState(() {
      _loading = true;
      _excursiones = [];
    });
    try { // Added try block
      final response = await Supabase.instance.client
          .from('excursiones')
          .select()
          .eq('ubicacion', _ubicacion!.trim());
      setState(() {
        _excursiones = List<Map<String, dynamic>>.from(response);
        _loading = false;
      });
    } catch (e) { // Added catch block
      print('Error fetching excursions: $e');
      setState(() {
        _loading = false;
        _excursiones = []; // Clear excursions on error
      });
      // Optionally show a SnackBar to the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar excursiones: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _loadingUbicaciones
                ? const CircularProgressIndicator()
                : DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Provincia turística',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                    ),
                    value: _ubicacion,
                    items: _ubicacionesDisponibles
                        .map((provincia) => DropdownMenuItem(
                              value: provincia,
                              child: Text(provincia),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _ubicacion = value;
                      });
                      if (value != null && value.isNotEmpty) {
                        _buscarExcursiones();
                      }
                    },
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Seleccione una provincia' : null,
                  ),
            const SizedBox(height: 16),
            // Elimina o comenta el botón de buscar excursiones si ya no es necesario
            // ElevatedButton(
            //   onPressed: () {
            //     if (_formKey.currentState!.validate()) {
            //       _buscarExcursiones();
            //     }
            //   },
            //   child: const Text('Buscar excursiones'),
            // ),
            const SizedBox(height: 24),
            if (_loading)
              const CircularProgressIndicator()
            else if (_excursiones.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _excursiones.length,
                  itemBuilder: (context, index) {
                    final excursion = _excursiones[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (excursion['imagen_url'] != null)
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              child: Image.network(
                                excursion['imagen_url'],
                                height: 160,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  height: 160,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image, size: 60, color: Colors.grey),
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        excursion['titulo'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      // Show the description here
                                      if (excursion['descripcion'] != null && excursion['descripcion'].toString().isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 8),
                                          child: Text(
                                            excursion['descripcion'],
                                            style: const TextStyle(
                                              fontSize: 15,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                      Text(
                                        'Precio: \$${excursion['precio']}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.green,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                              ]),
                                  ),
                                
                                ElevatedButton(
                                  onPressed: () async {
                                    DateTime? selectedDateTime;
                                    int cantidadPersonas = 1;
                                    bool incluirGuia = false;
                                    final reservaFormKey = GlobalKey<FormState>();
                                
                                    // Add controllers for input fields
                                    final nombreHostalHotelController = TextEditingController(text: excursion['hostal_hotel'] ?? '');
                                    final direccionFisicaController = TextEditingController(text: excursion['direccion'] ?? '');
                                
                                    await showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: const Text('Detalles de la reserva'),
                                          content: Form(
                                            key: reservaFormKey,
                                            child: SingleChildScrollView(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  // Editable Hostal/Hotel name
                                                  TextFormField(
                                                    controller: nombreHostalHotelController,
                                                    decoration: const InputDecoration(
                                                      labelText: 'Nombre del Hostal/Hotel',
                                                      border: OutlineInputBorder(
                                                        borderRadius: BorderRadius.all(Radius.circular(16)),
                                                      ),
                                                    ),
                                                    validator: (value) =>
                                                        value == null || value.isEmpty ? 'Ingrese el nombre del Hostal/Hotel' : null,
                                                  ),
                                                  const SizedBox(height: 12),
                                                  // Editable address
                                                  TextFormField(
                                                    controller: direccionFisicaController,
                                                    decoration: const InputDecoration(
                                                      labelText: 'Dirección',
                                                      border: OutlineInputBorder(
                                                        borderRadius: BorderRadius.all(Radius.circular(16)),
                                                      ),
                                                    ),
                                                    validator: (value) =>
                                                        value == null || value.isEmpty ? 'Ingrese la dirección' : null,
                                                  ),
                                                  const SizedBox(height: 16),
                                                  // Fecha y hora picker
                                                  StatefulBuilder(
                                                    builder: (context, setState) {
                                                      return InkWell(
                                                        onTap: () async {
                                                          final date = await showDatePicker(
                                                            context: context,
                                                            initialDate: DateTime.now(),
                                                            firstDate: DateTime.now(),
                                                            lastDate: DateTime.now().add(const Duration(days: 365)),
                                                          );
                                                          if (date != null) {
                                                            final time = await showTimePicker(
                                                              context: context,
                                                              initialTime: TimeOfDay.now(),
                                                            );
                                                            if (time != null) {
                                                              setState(() {
                                                                selectedDateTime = DateTime(
                                                                  date.year,
                                                                  date.month,
                                                                  date.day,
                                                                  time.hour,
                                                                  time.minute,
                                                                );
                                                              });
                                                            }
                                                          }
                                                        },
                                                        child: InputDecorator(
                                                          decoration: const InputDecoration(
                                                            labelText: 'Fecha y hora',
                                                            border: OutlineInputBorder(
                                                              borderRadius: BorderRadius.all(Radius.circular(16)),
                                                            ),
                                                          ),
                                                          child: Row(
                                                            children: [
                                                              Icon(Icons.calendar_today, size: 20, color: Colors.grey[700]),
                                                              const SizedBox(width: 8),
                                                              Expanded(
                                                                child: Text(
                                                                  selectedDateTime == null
                                                                      ? 'Seleccionar'
                                                                      : '${selectedDateTime!.day}/${selectedDateTime!.month}/${selectedDateTime!.year} ${selectedDateTime!.hour}:${selectedDateTime!.minute.toString().padLeft(2, '0')}',
                                                                  style: TextStyle(
                                                                    color: selectedDateTime == null ? Colors.grey : Colors.black,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                  const SizedBox(height: 16),
                                                  // Cantidad de personas
                                                  TextFormField(
                                                    initialValue: '1',
                                                    decoration: const InputDecoration(
                                                      labelText: 'Cantidad de personas',
                                                      border: OutlineInputBorder(
                                                        borderRadius: BorderRadius.all(Radius.circular(16)),
                                                      ),
                                                    ),
                                                    keyboardType: TextInputType.number,
                                                    validator: (value) {
                                                      final n = int.tryParse(value ?? '');
                                                      if (n == null || n < 1) return 'Ingrese una cantidad válida';
                                                      return null;
                                                    },
                                                    onChanged: (value) {
                                                      final n = int.tryParse(value);
                                                      if (n != null && n > 0) cantidadPersonas = n;
                                                    },
                                                  ),
                                                  const SizedBox(height: 16),
                                                  // Checkbox para guía
                                                  StatefulBuilder(
                                                    builder: (context, setState) {
                                                      return CheckboxListTile(
                                                        title: const Text('Incluir guía (+12 USD)'),
                                                        value: incluirGuia,
                                                        onChanged: (value) {
                                                          setState(() {
                                                            incluirGuia = value ?? false;
                                                          });
                                                        },
                                                        controlAffinity: ListTileControlAffinity.leading,
                                                        contentPadding: EdgeInsets.zero,
                                                      );
                                                    },
                                                  ),
                                                  const SizedBox(height: 8),
                                                  // Show the message only if incluirGuia is true
                                                  if (incluirGuia)
                                                    const Text(
                                                      'Si selecciona guía, el precio de la excursión aumentará en 12 USD.',
                                                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                
                                                Navigator.of(context).pop();
                                              },
                                              child: const Text('Cancelar'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () async { // Made onPressed async
                                                if (reservaFormKey.currentState!.validate() && selectedDateTime != null) {
                                                  // Collect data
                                                  final user = Supabase.instance.client.auth.currentUser;
                                                  if (user == null) {
                                                    if (mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(content: Text('Usuario no autenticado')),
                                                      );
                                                    }
                                                    return; // Exit if user is not logged in
                                                  }

                                                  String direccionFisica = direccionFisicaController.text;
                                                  String nombreHostalHotel = nombreHostalHotelController.text;
                                                  String excursionTitulo = excursion['titulo'] ?? '';
                                                  double basePrecio = 0;
                                                  if (excursion['precio'] != null) {
                                                    basePrecio = double.tryParse(excursion['precio'].toString()) ?? 0;
                                                  }
                                                  double totalPrecio = incluirGuia ? basePrecio + 12 : basePrecio;
                                                  String? excursionId = excursion['id']?.toString(); // Get excursion ID

                                                  if (excursionId == null) {
                                                     if (mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(content: Text('Error: ID de excursión no encontrado')),
                                                      );
                                                    }
                                                    return;
                                                  }

                                                  try {
                                                    // Insert into reservas_excursiones table
                                                    await Supabase.instance.client
                                                        .from('reservas_excursiones')
                                                        .insert({
                                                          'user_id': user.id,
                                                          'excursiones_id': excursionId, // Use the excursion ID
                                                          'titulo': excursionTitulo,
                                                          'precio': totalPrecio,
                                                          'fecha_hora': selectedDateTime!.toIso8601String(), // Save as ISO 8601 string
                                                          'cantidad_personas': cantidadPersonas,
                                                          'incluir_guia': incluirGuia,
                                                          'hostal_hotel': nombreHostalHotel,
                                                          'direccion': direccionFisica,
                                                        });

                                                    // Close the dialog
                                                    Navigator.of(context).pop();

                                                    // Show success message
                                                    if (mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          backgroundColor: Colors.green,
                                                          content: Text(
                                                            '¡Reserva confirmada!\n'
                                                            'Excursión: $excursionTitulo\n'
                                                            'Precio: \$${totalPrecio.toStringAsFixed(2)}',
                                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                                          ),
                                                          duration: const Duration(seconds: 4),
                                                        ),
                                                      );
                                                    }

                                                  } catch (e) {
                                                    print('Error saving reservation: $e');
                                                     // Show error message
                                                    if (mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Text('Error al guardar la reserva: ${e.toString()}'),
                                                          backgroundColor: Colors.red,
                                                        ),
                                                      );
                                                    }
                                                  }

                                                } else if (selectedDateTime == null) {
                                                  if (mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text('Seleccione fecha y hora')),
                                                    );
                                                  }
                                                }
                                              },
                                              child: const Text('Confirmar'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  child: const Text('Reservar'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              )
            else if (_ubicacion != null && _ubicacion!.isNotEmpty && !_loading)
              const Text('No hay excursiones disponibles en esta área.'),
          ],
        ),
      ),
    );
  }
}