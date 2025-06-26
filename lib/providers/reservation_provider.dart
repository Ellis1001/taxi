import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async'; // Import for StreamSubscription

class ReservationProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _provinciales = [];
  List<Map<String, dynamic>> _excursiones = [];
  bool _loading = false;
  String _errorMessage = '';

  StreamSubscription? _provincialesSubscription;
  StreamSubscription? _excursionesSubscription;
  StreamSubscription? _authStateSubscription; // Add auth state subscription

  List<Map<String, dynamic>> get provinciales => _provinciales;
  List<Map<String, dynamic>> get excursiones => _excursiones;
  bool get isLoading => _loading;
  String get errorMessage => _errorMessage;

  // Constructor to set up auth state listener
  ReservationProvider() {
    _setupAuthStateListener();
  }

  void _setupAuthStateListener() {
    _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange
        .listen((data) {
          final AuthChangeEvent event = data.event;
          final Session? session = data.session;

          print('Auth state changed: $event'); // Debug print

          if (event == AuthChangeEvent.signedIn) {
            // User signed in, fetch reservations and start streams
            print('User signed in, fetching reservations...'); // Debug print
            fetchReservations();
          } else if (event == AuthChangeEvent.signedOut) {
            // User signed out, clear data and stop streams
            print('User signed out, clearing data...'); // Debug print
            _provinciales = [];
            _excursiones = [];
            _loading = false;
            _errorMessage = '';
            _stopListeningToChanges(); // Stop streams
            notifyListeners(); // Notify listeners that data is cleared
          }
          // Handle other events like AuthChangeEvent.tokenRefreshed if needed
        });
  }

  Future<void> fetchReservations() async {
    _loading = true;
    _errorMessage = '';
    notifyListeners();

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _loading = false;
      _errorMessage = 'Usuario no autenticado.';
      notifyListeners();
      _stopListeningToChanges(); // Stop any active listeners if user logs out
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('reservas')
          .select()
          .eq('user_id', user.id)
          .order('fecha_hora', ascending: false);

      final response2 = await Supabase.instance.client
          .from('reservas_excursiones')
          .select()
          .eq('user_id', user.id)
          .order('fecha_hora', ascending: false);

      _provinciales = response.toList();

      _excursiones = response2.toList();
      _loading = false;
      notifyListeners();
      _startListeningToChanges(); // Start listening for real-time updates after initial fetch
    } catch (e) {
      print('Error fetching reservations: $e');
      _errorMessage = 'Error al cargar reservas: ${e.toString()}';
      _loading = false;
      notifyListeners();
      _stopListeningToChanges(); // Stop listeners on error too
    }
  }

  void _startListeningToChanges() {
    _stopListeningToChanges(); // Cancel any existing subscriptions first

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // Listen to 'reservas' table (Provincial)
    _provincialesSubscription = Supabase.instance.client
    .from('reservas')
    .stream(primaryKey: ['id'])
    .eq('user_id', user.id)
    .order('fecha_hora', ascending: false)
    .listen((data) {
        try {
            // Conversión explícita
            _provinciales = List<Map<String, dynamic>>.from(data);
            notifyListeners();
        } catch (e) {
            print('Error en conversión provincial: $e');
            _errorMessage = 'Error en datos provinciales: $e';
            notifyListeners();
        }
    });

// Para excursiones
_excursionesSubscription = Supabase.instance.client
    .from('reservas_excursiones')
    .stream(primaryKey: ['id'])
    .eq('user_id', user.id)
    .order('fecha_hora', ascending: false)
    .listen((data) {
        try {
            // Conversión explícita
            _excursiones = List<Map<String, dynamic>>.from(data);
            notifyListeners();
        } catch (e) {
            print('Error en conversión excursiones: $e');
            _errorMessage = 'Error en datos excursiones: $e';
            notifyListeners();
        }
    });
  }

  void _stopListeningToChanges() {
    _provincialesSubscription?.cancel();
    _provincialesSubscription = null;
    _excursionesSubscription?.cancel();
    _excursionesSubscription = null;
  }

  // Call this method when the provider is disposed by its owner
  void disposeListeners() {
    _stopListeningToChanges();
    _authStateSubscription?.cancel(); // Cancel auth state listener
    _authStateSubscription = null;
  }

  @override
  void dispose() {
    disposeListeners(); // Clean up listeners when the provider itself is disposed
    super.dispose();
  }

  // Método para añadir una nueva reserva (ejemplo conceptual)
  // Deberías llamar a este método desde la pantalla donde creas la reserva
  void addProvincialReservation(Map<String, dynamic> newReservation) {
    // This method might become less necessary if you rely solely on streams
    // for updates after inserting into Supabase.
    _provinciales.insert(
      0,
      newReservation,
    ); // Añade al inicio para que se vea primero
    notifyListeners();
  }

  void addExcursionReservation(Map<String, dynamic> newReservation) {
    // This method might become less necessary if you rely solely on streams
    // for updates after inserting into Supabase.
    _excursiones.insert(
      0,
      newReservation,
    ); // Añade al inicio para que se vea primero
    notifyListeners();
  }

  // Método para eliminar una reserva (opcional, podrías manejarlo aquí o en la UI)
  Future<void> deleteReservation(int id, String table) async {
    try {
      await Supabase.instance.client.from(table).delete().eq('id', id);
      await fetchReservations(); // This is no longer needed, stream will update
      // notifyListeners(); // Stream listener will call notifyListeners
      // Removed the notifyListeners() call here.
    } catch (e) {
      print('Error deleting reservation: $e');
      _errorMessage = 'Error al eliminar reserva: $e';
      // Keep notifyListeners() here to show error message in UI
      notifyListeners();
    }
    // Removed the notifyListeners() call that was outside the catch block
  }
}
