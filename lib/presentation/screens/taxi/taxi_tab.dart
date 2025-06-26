import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:taxibooking/core/constants/app_colors.dart';

// Define a simple class to hold location data
class Ubicacion {
  final String nombre;
  final String codigo;
  final String tipo; // Add the 'tipo' field

  Ubicacion({required this.nombre, required this.codigo, required this.tipo}); // Update constructor

  // Factory constructor to create Ubicacion from Supabase row Map
  factory Ubicacion.fromJson(Map<String, dynamic> json) {
    return Ubicacion(
      nombre: json['nombre'] as String,
      codigo: json['codigo'] as String,
      tipo: json['tipo'] as String, // Parse the 'tipo' field
    );
  }

  // Override toString for potential display in Autocomplete suggestions
  @override
  String toString() {
    return '$nombre ($codigo)';
  }
}

// Async function to fetch locations from Supabase
Future<List<Ubicacion>> _fetchUbicaciones(String query) async {
  if (query.isEmpty) {
    return const [];
  }
  try {
    // Query the 'ubicaciones_cuba' table
    final response = await Supabase.instance.client
        .from('ubicaciones_cuba')
        .select('nombre, codigo, tipo') // Select 'tipo' as well
        // Filter by name or code, case-insensitive
        .or('nombre.ilike.%$query%,codigo.ilike.%$query%')
        .limit(10); // Limit the number of results

    if (response.isEmpty) {
      return const [];
    }

    // Map the list of maps to a list of Ubicacion objects
    return response.map((json) => Ubicacion.fromJson(json)).toList();
  } catch (e) {
    print('Error fetching ubicaciones: $e');
    return const []; // Return empty list on error
  }
}

// Helper function to determine icon based on location type
IconData _getIconForUbicacion(Ubicacion ubicacion) {
  final lowerTipo = ubicacion.tipo.toLowerCase(); // Use the 'tipo' field
  if (lowerTipo == 'aeropuerto') {
    return Icons.flight; // Airplane icon for airports
  } else if (lowerTipo == 'cayo') {
    return Icons.hotel; // Hotel icon for cayos
  } else {
    return Icons.location_city; // City icon for others (municipios, etc.)
  }
}


class TaxiTab extends StatefulWidget {
  const TaxiTab({super.key});

  @override
  State<TaxiTab> createState() => _TaxiTabState();
}

class _TaxiTabState extends State<TaxiTab> {
  final _formKey = GlobalKey<FormState>();
  String _taxiType = 'Colectivo'; // <-- Set initial value to 'Colectivo'
  // String _origen = ''; // Removed: Will store the selected location string (e.g., "Havana (HAV)")
  // String _destino = ''; // Removed: Will store the selected location string (e.g., "Varadero (VRA)")
  Ubicacion? _selectedOrigen; // New: Will store the selected Ubicacion object for Origen
  Ubicacion? _selectedDestino; // New: Will store the selected Ubicacion object for Destino
  int _personas = 1;
  DateTime? _fechaHora;

  double? _precio;
  bool _precioCalculado = false;
  bool _camposEditados = false;

  // Controllers for Autocomplete fields to manage text display
  final TextEditingController _origenController = TextEditingController();
  final TextEditingController _destinoController = TextEditingController();


  void _calcularPrecio() {
    // Simulación de cálculo de precio (puedes reemplazarlo con tu lógica real)
    setState(() {
      // Use the selected objects' names for the demo calculation
      final origenName = _selectedOrigen?.nombre ?? '';
      final destinoName = _selectedDestino?.nombre ?? '';

      _precio =
          (_taxiType == 'Privado' ? 30 : 15) +
          (_personas * 2) +
          ((origenName.length + destinoName.length) % 10); // Solo para demo
      _precioCalculado = true;
      _camposEditados = false;
    });
  }

  void _resetPrecio() {
    setState(() {
      _precio = null;
      _precioCalculado = false;
      _camposEditados = true;
    });
  }

  @override
  void dispose() {
    // Dispose controllers when the widget is removed from the widget tree
    _origenController.dispose();
    _destinoController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Taxi type selection as two buttons
            Container(
              padding: EdgeInsets.all(5),
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  // Barra de selección animada
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    left: _taxiType == 'Colectivo' ? 0 : MediaQuery.of(context).size.width / 2 - 24,
                    child: Container(
                      width: MediaQuery.of(context).size.width / 2 - 24,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.lightBlue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  // Botoness
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _taxiType = 'Colectivo';
                              _resetPrecio();
                            });
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            foregroundColor: _taxiType == 'Colectivo' ? Colors.white : Colors.black,
                          ),
                          child: const Text('Colectivo'),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _taxiType = 'Privado';
                              _resetPrecio();
                            });
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            foregroundColor: _taxiType == 'Privado' ? Colors.white : Colors.black,
                          ),
                          child: const Text('Privado'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Autocomplete for Origen
            Autocomplete<Ubicacion>(
              optionsBuilder: (TextEditingValue textEditingValue) async {
                // Fetch options based on the current input
                return await _fetchUbicaciones(textEditingValue.text);
              },
              // How to display the option in the suggestion list
              // displayStringForOption: (Ubicacion option) => '${option.nombre} (${option.codigo})', // Removed
              // What happens when an option is selected
              onSelected: (Ubicacion selection) {
                setState(() {
                  // Store the selected Ubicacion object
                  _selectedOrigen = selection;
                  _resetPrecio(); // Recalculate price if needed
                });
                // Update the controller text when an option is selected
                _origenController.text = '${selection.nombre} (${selection.codigo})';
                print('Selected origen: ${_origenController.text}'); // For debugging
              },
              // How to build the actual text field
              fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                // Use the state's controller
                // _origenController.text = textEditingController.text; // Keep state controller in sync - Removed, controller is managed by Autocomplete
                return TextFormField(
                  controller: textEditingController, // Use the controller provided by Autocomplete
                  focusNode: focusNode,
                  decoration: InputDecoration( // Use InputDecoration instead of const InputDecoration
                    labelText: 'Origen',
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                    // Add prefix icon based on selected location
                    prefixIcon: _selectedOrigen != null && textEditingController.text == '${_selectedOrigen!.nombre} (${_selectedOrigen!.codigo})'
                        ? Icon(_getIconForUbicacion(_selectedOrigen!))
                        : null, // Show icon only if a location is selected and text matches
                  ),
                  onChanged: (value) {
                    // Update state as user types (important for _resetPrecio)
                    // This also handles cases where the user types without selecting
                    // If the text changes, clear the selected location
                    if (_selectedOrigen != null && value != '${_selectedOrigen!.nombre} (${_selectedOrigen!.codigo})') {
                       setState(() {
                         _selectedOrigen = null; // Clear selected location if text is edited
                         if (_precioCalculado) _resetPrecio();
                       });
                    } else if (_selectedOrigen == null) {
                       // If no location was selected, just reset price if needed
                       if (_precioCalculado) _resetPrecio();
                    }
                    // Note: _origen state variable is no longer used for storing the selected string
                  },
                  validator: (value) => value == null || value.isEmpty ? 'Ingrese el origen' : null,
                  onFieldSubmitted: (String value) {
                    // Optional: handle submission (e.g., if user presses Enter)
                    onFieldSubmitted(); // Call the Autocomplete's default handler
                  },
                );
              },
              // Custom builder for the options view
              optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<Ubicacion> onSelected, Iterable<Ubicacion> options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4.0,
                    // Add shape with rounded corners
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)), // Match input field radius
                    ),
                    child: SizedBox(
                      height: 100.0,
                      // Limit height of the suggestion list
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: options.length,
                        itemBuilder: (BuildContext context, int index) {
                          final Ubicacion option = options.elementAt(index);
                          return ListTile(
                             leading: Icon(_getIconForUbicacion(option)), // Use the updated function
                            title: Text('${option.nombre} (${option.codigo})'),
                            onTap: () {
                              onSelected(option); // Call the onSelected callback
                            },
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // Autocomplete for Destino
            Autocomplete<Ubicacion>(
              optionsBuilder: (TextEditingValue textEditingValue) async {
                return await _fetchUbicaciones(textEditingValue.text);
              },
              // displayStringForOption: (Ubicacion option) => '${option.nombre} (${option.codigo})', // Removed
              onSelected: (Ubicacion selection) {
                setState(() {
                  _selectedDestino = selection; // Store the selected Ubicacion object
                  _resetPrecio();
                });
                 // Update the controller text when an option is selected
                _destinoController.text = '${selection.nombre} (${selection.codigo})';
                print('Selected destino: ${_destinoController.text}'); // For debugging
              },
               fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                 // Use the state's controller
                 // _destinoController.text = textEditingController.text; // Keep state controller in sync - Removed
                return TextFormField(
                  controller: textEditingController, // Use the controller provided by Autocomplete
                  focusNode: focusNode,
                  decoration: InputDecoration( // Use InputDecoration instead of const InputDecoration
                    labelText: 'Destino',
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                     // Add prefix icon based on selected location
                    prefixIcon: _selectedDestino != null && textEditingController.text == '${_selectedDestino!.nombre} (${_selectedDestino!.codigo})'
                        ? Icon(_getIconForUbicacion(_selectedDestino!))
                        : null, // Show icon only if a location is selected and text matches
                  ),
                  onChanged: (value) {
                    // If the text changes, clear the selected location
                     if (_selectedDestino != null && value != '${_selectedDestino!.nombre} (${_selectedDestino!.codigo})') {
                       setState(() {
                         _selectedDestino = null; // Clear selected location if text is edited
                         if (_precioCalculado) _resetPrecio();
                       });
                    } else if (_selectedDestino == null) {
                       // If no location was selected, just reset price if needed
                       if (_precioCalculado) _resetPrecio();
                    }
                    // Note: _destino state variable is no longer used for storing the selected string
                  },
                  validator: (value) => value == null || value.isEmpty ? 'Ingrese el destino' : null,
                  onFieldSubmitted: (String value) {
                    onFieldSubmitted();
                  },
                );
              },
               // Custom builder for the options view
              optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<Ubicacion> onSelected, Iterable<Ubicacion> options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4.0,
                     // Add shape with rounded corners
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)), // Match input field radius
                    ),
                    child: SizedBox(
                      height: 200.0, // Limit height of the suggestion list
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: options.length,
                        itemBuilder: (BuildContext context, int index) {
                          final Ubicacion option = options.elementAt(index);
                          return ListTile(
                             leading: Icon(_getIconForUbicacion(option)), // Use the updated function
                            title: Text('${option.nombre} (${option.codigo})'),
                            onTap: () {
                              onSelected(option); // Call the onSelected callback
                            },
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<int>(
                    value: _personas,
                    decoration: const InputDecoration(
                      labelText: 'Personas',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                    ),
                    items: List.generate(
                      10,
                      (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('${index + 1}'),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _personas = value!;
                        _resetPrecio();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
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
                            _fechaHora = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                            _resetPrecio();
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
                          Icon(
                            Icons.calendar_today,
                            size: 20,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _fechaHora == null
                                  ? 'Seleccionar'
                                  : '${_fechaHora!.day}/${_fechaHora!.month}/${_fechaHora!.year} ${_fechaHora!.hour}:${_fechaHora!.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                color:
                                    _fechaHora == null
                                        ? Colors.grey
                                        : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Mostrar el precio si ya fue calculado
            if (_precioCalculado && _precio != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Precio estimado: \$${_precio!.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      !_precioCalculado ? AppColors.primary : Colors.green,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () async {
                  if (_formKey.currentState!.validate() && _fechaHora != null) {
                    if (!_precioCalculado) {
                      _calcularPrecio();
                    } else {
                      final contactFormKey = GlobalKey<FormState>();
                      String direccion = '';
                      String nombreAlojamiento = '';
                      final direccionController = TextEditingController();
                      direccionController.text = '';
                      final nombreAlojamientoController =
                          TextEditingController(); // Add controller for accommodation name
                      nombreAlojamientoController.text = '';

                      await showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Datos de Recogida'),
                            content: Form(
                              key: contactFormKey,
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Como último paso para confirmar su reserva introduzca la dirección física y el nombre de la casa particular o hotel donde será recogido',
                                      style: TextStyle(fontSize: 14),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: direccionController,
                                      decoration: InputDecoration(
                                        labelText: 'Dirección física',
                                        border: const OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(16),
                                          ),
                                        ),
                                      ),
                                      onChanged: (value) => direccion = value,
                                      validator:
                                          (value) =>
                                              value == null || value.isEmpty
                                                  ? 'Ingrese su dirección'
                                                  : null,
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller:
                                          nombreAlojamientoController, // Use the new controller
                                      decoration: const InputDecoration(
                                        labelText:
                                            'Nombre de la casa particular o hotel',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(16),
                                          ),
                                        ),
                                      ),
                                      onChanged:
                                          (value) => nombreAlojamiento = value,
                                      validator:
                                          (value) =>
                                              value == null || value.isEmpty
                                                  ? 'Ingrese el nombre del alojamiento'
                                                  : null,
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
                                onPressed: () async {
                                  // Make this onPressed async
                                  if (contactFormKey.currentState!.validate()) {
                                    // Get current user ID
                                    final userId =
                                        Supabase
                                            .instance
                                            .client
                                            .auth
                                            .currentUser
                                            ?.id;

                                    if (userId == null) {
                                      // Handle case where user is not logged in
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Debe iniciar sesión para reservar',
                                            ),
                                          ),
                                        );
                                        Navigator.of(
                                          context,
                                        ).pop(); // Close dialog
                                        // Optionally navigate to login screen
                                        // Navigator.of(context).pushNamed('/login');
                                      }
                                      return; // Stop here if no user
                                    }

                                    // Prepare data for insertion
                                    final reservaData = {
                                      'user_id': userId,
                                      'taxi_type': _taxiType,
                                      // Use the name and code from the selected objects
                                      'origen': _selectedOrigen != null ? '${_selectedOrigen!.nombre} (${_selectedOrigen!.codigo})' : _origenController.text,
                                      'destino': _selectedDestino != null ? '${_selectedDestino!.nombre} (${_selectedDestino!.codigo})' : _destinoController.text,
                                      'personas': _personas,
                                      'fecha_hora':
                                          _fechaHora
                                              ?.toIso8601String(), // Store as ISO 8601 string
                                      'precio': _precio,
                                      'estado':
                                          'confirmado', // Set status to 'confirmado'
                                      'direccion_recogida':
                                          direccionController.text,
                                      'nombre_alojamiento':
                                          nombreAlojamientoController.text,
                                      'categoria':
                                          "Viaje Provincial",
                                      // 'created_at' will be set by the database default
                                    };

                                    try {
                                      // Insert data into the 'reserva' table
                                      await Supabase.instance.client
                                          .from('reservas') // <-- Check this table name
                                          .insert(reservaData);

                                      if (mounted) {
                                        Navigator.of(
                                          context,
                                        ).pop(); // Close dialog
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            backgroundColor:
                                                Colors
                                                    .green, // Indicate success
                                            content: Text(
                                              'Reserva de taxi confirmada!\n'
                                              'Origen: ${_selectedOrigen?.nombre ?? ''}, Destino: ${_selectedDestino?.nombre ?? ''}\n'
                                              
                                              'Precio: \$${_precio!.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            duration: const Duration(
                                              seconds: 4,
                                            ),
                                          ),
                                        );
                                        // Reset form fields after successful booking
                                        setState(() {
                                          // Reset selected objects
                                          _selectedOrigen = null;
                                          _selectedDestino = null;
                                          _personas = 1;
                                          _fechaHora = null;
                                          _precio = null;
                                          _precioCalculado = false;
                                          _camposEditados = false;
                                          // Clear the text controllers as well
                                          _origenController.clear();
                                          _destinoController.clear();
                                        });
                                      }
                                    } catch (e) {
                                      // Handle insertion errors
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            backgroundColor:
                                                Colors.red, // Indicate error
                                            content: Text(
                                              'Error al guardar la reserva: $e',
                                            ),
                                          ),
                                        );
                                      }
                                    } finally {
                                       // Dispose controllers after use
                                       direccionController.dispose();
                                       nombreAlojamientoController.dispose();
                                    }
                                  }
                                },
                                child: const Text('Enviar'),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  } else if (_fechaHora == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Seleccione fecha y hora')),
                    );
                  }
                },
                child: Text(
                  !_precioCalculado
                      ? 'Calcular Precio'
                      : (_camposEditados ? 'Recalcular' : 'Confirmar'),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// The _TaxiFormModal widget is currently defined but not used in the build method above.
// If you intend to use this widget, the Autocomplete logic would need to be
// implemented within its build method and state management handled accordingly.
// For now, the Autocomplete functionality is implemented directly in the _TaxiTabState build method.
// If this widget is not needed, you can remove it.
class _TaxiFormModal extends StatefulWidget {
  final String taxiType;
  final ValueChanged<String> onTaxiTypeChanged;
  final String origen;
  final ValueChanged<String> onOrigenChanged;
  final String destino;
  final ValueChanged<String> onDestinoChanged;
  final int personas;
  final ValueChanged<int> onPersonasChanged;
  final DateTime? fechaHora;
  final ValueChanged<DateTime?> onFechaHoraChanged;
  final double? precio;
  final bool precioCalculado;
  final bool camposEditados;
  final VoidCallback onCalcularPrecio;
  final VoidCallback onResetPrecio;
  final GlobalKey<FormState> formKey;

  const _TaxiFormModal({
    required this.taxiType,
    required this.onTaxiTypeChanged,
    required this.origen,
    required this.onOrigenChanged,
    required this.destino,
    required this.onDestinoChanged,
    required this.personas,
    required this.onPersonasChanged,
    required this.fechaHora,
    required this.onFechaHoraChanged,
    required this.precio,
    required this.precioCalculado,
    required this.camposEditados,
    required this.onCalcularPrecio,
    required this.onResetPrecio,
    required this.formKey,
    Key? key,
  }) : super(key: key);

  @override
  State<_TaxiFormModal> createState() => _TaxiFormModalState();
}

class _TaxiFormModalState extends State<_TaxiFormModal> {
  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Taxi type selection
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          widget.taxiType == 'Colectivo'
                              ? const Color(0xFF002A8F)
                              : Colors.grey[200],
                      foregroundColor:
                          widget.taxiType == 'Colectivo'
                              ? Colors.white
                              : Colors.black,
                      elevation: widget.taxiType == 'Colectivo' ? 4 : 0,
                    ),
                    onPressed: () {
                      widget.onTaxiTypeChanged('Colectivo');
                    },
                    child: const Text('Colectivo'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          widget.taxiType == 'Privado'
                              ? const Color(0xFFFFD700)
                              : Colors.grey[200],
                      foregroundColor:
                          widget.taxiType == 'Privado'
                              ? Colors.white
                              : Colors.black,
                      elevation: widget.taxiType == 'Privado' ? 4 : 0,
                    ),
                    onPressed: () {
                      widget.onTaxiTypeChanged('Privado');
                    },
                    child: const Text('Privado'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // TODO: Implement Autocomplete here if this modal is used
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Origen',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
              initialValue: widget.origen,
              onChanged: widget.onOrigenChanged,
              validator:
                  (value) =>
                      value == null || value.isEmpty
                          ? 'Ingrese el origen'
                          : null,
            ),
            const SizedBox(height: 16),
            // TODO: Implement Autocomplete here if this modal is used
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Destino',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
              initialValue: widget.destino,
              onChanged: widget.onDestinoChanged,
              validator:
                  (value) =>
                      value == null || value.isEmpty
                          ? 'Ingrese el destino'
                          : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<int>(
                    value: widget.personas,
                    decoration: const InputDecoration(
                      labelText: 'Personas',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                    ),
                    items: List.generate(
                      10,
                      (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('${index + 1}'),
                      ),
                    ),
                    onChanged: (value) {
                      if (value != null) widget.onPersonasChanged(value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
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
                          widget.onFechaHoraChanged(
                            DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            ),
                          );
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
                          Icon(
                            Icons.calendar_today,
                            size: 20,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.fechaHora == null
                                  ? 'Seleccionar'
                                  : '${widget.fechaHora!.day}/${widget.fechaHora!.month}/${widget.fechaHora!.year} ${widget.fechaHora!.hour}:${widget.fechaHora!.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                color:
                                    widget.fechaHora == null
                                        ? Colors.grey
                                        : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (widget.precioCalculado && widget.precio != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Precio estimado: \$${widget.precio!.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      !widget.precioCalculado
                          ? Colors.deepPurple
                          : Colors.green,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  if (widget.formKey.currentState!.validate() &&
                      widget.fechaHora != null) {
                    if (!widget.precioCalculado) {
                      widget.onCalcularPrecio();
                    } else {
                      Navigator.of(context).pop();
                      // You can trigger the next step here (e.g., show contact info dialog)
                    }
                  } else if (widget.fechaHora == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Seleccione fecha y hora')),
                    );
                  }
                },
                child: Text(
                  !widget.precioCalculado
                      ? 'Calcular Precio'
                      : (widget.camposEditados ? 'Recalcular' : 'Confirmar'),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }}