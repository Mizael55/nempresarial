import 'package:supabase_flutter/supabase_flutter.dart';
import 'failures.dart';

/// Centralized Error Handler to convert backend and network exceptions into user-friendly messages
class ErrorHandler {
  ErrorHandler._();

  static Failure handle(dynamic error) {
    if (error is Failure) return error;

    if (error is PostgrestException) {
      final msg = error.message.trim();
      if (msg.isNotEmpty && !msg.startsWith('{')) {
        return AuthFailure(msg);
      }
    }

    if (error is AuthException) {
      return AuthFailure(error.message);
    }

    final errorString = error.toString().toLowerCase();

    // Supabase Auth Exceptions
    if (errorString.contains('invalid login credentials') ||
        errorString.contains('invalid_grant') ||
        errorString.contains('correo electrónico o contraseña incorrectos') ||
        errorString.contains('contraseña incorrectos')) {
      return const AuthFailure('Correo electrónico o contraseña incorrectos.');
    }
    if (errorString.contains('user already registered') ||
        errorString.contains('user_already_exists')) {
      return const AuthFailure('Ya existe una cuenta registrada con este correo.');
    }
    if (errorString.contains('password should be at least')) {
      return const ValidationFailure('La contraseña debe tener al menos 6 caracteres.');
    }
    if (errorString.contains('email not confirmed')) {
      return const AuthFailure('Por favor, confirma tu correo electrónico antes de ingresar.');
    }

    // Network / Socket
    if (errorString.contains('socketexception') ||
        errorString.contains('clientexception') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('network is unreachable')) {
      return const NetworkFailure('Sin conexión a internet. Los cambios se guardarán localmente.');
    }

    // PostgreSQL Constraints
    if (errorString.contains('duplicate key value') || errorString.contains('unique constraint')) {
      if (errorString.contains('sku')) {
        return const ValidationFailure('Ya existe un producto con este código SKU.');
      }
      if (errorString.contains('barcode')) {
        return const ValidationFailure('Ya existe un producto con este código de barras.');
      }
      return const ValidationFailure('Ya existe un registro con estos datos únicos.');
    }

    if (errorString.contains('foreign key constraint')) {
      return const ValidationFailure('No se puede eliminar porque tiene registros asociados.');
    }

    if (errorString.contains('row-level security') || errorString.contains('permission denied')) {
      return const PermissionFailure('No tienes autorización para completar esta operación.');
    }

    return UnexpectedFailure(
      'Ocurrió un error inesperado al procesar la solicitud. Por favor intenta de nuevo.',
    );
  }

  static String getUserFriendlyMessage(dynamic error) {
    return handle(error).message;
  }
}
