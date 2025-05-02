import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class AppStarted extends AuthEvent {}

class LoggedIn extends AuthEvent {
  final String email;
  final String password;

  const LoggedIn({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class SignedUp extends AuthEvent {
   final String email;
   final String password;
   // Add other fields like name, phone if needed for signup
   // final String name; 

   const SignedUp({required this.email, required this.password /*, required this.name */});

   @override
   List<Object> get props => [email, password /*, name */];
}


class LoggedOut extends AuthEvent {}