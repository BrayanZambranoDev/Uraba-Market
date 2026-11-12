import '../constants/app_constants.dart';

/// Validadores centralizados reutilizables en todos los formularios.
/// Elimina la duplicación de lógica entre login_screen y register_screen.
class Validators {
  Validators._();

  static final RegExp _emailRegex =
      RegExp(r'^[\w\-\.\+]+@([\w\-]+\.)+[\w\-]{2,}$');

  /// Valida formato de correo electrónico.
  /// Retorna [null] si es válido, o un mensaje de error.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El correo es obligatorio';
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Ingresa un correo válido';
    }
    return null;
  }

  /// Valida que el correo tenga formato válido (retorna bool).
  static bool isValidEmail(String email) =>
      _emailRegex.hasMatch(email.trim());

  /// Valida contraseña: obligatoria y longitud mínima.
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria';
    }
    if (value.length < AppConstants.longitudMinimaPassword) {
      return 'Mínimo ${AppConstants.longitudMinimaPassword} caracteres';
    }
    return null;
  }

  /// Valida que la confirmación coincida con la contraseña original.
  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contraseña';
    }
    if (value != original) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  /// Valida nombre completo: obligatorio y longitud mínima.
  static String? nombre(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre es obligatorio';
    }
    if (value.trim().length < AppConstants.longitudMinimaNombre) {
      return 'Debe tener al menos ${AppConstants.longitudMinimaNombre} caracteres';
    }
    return null;
  }

  /// Valida precio: obligatorio, numérico y mayor a cero.
  static String? precio(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa el precio';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null) return 'Precio inválido';
    if (parsed <= 0) return 'El precio debe ser mayor a cero';
    return null;
  }

  /// Valida stock: obligatorio y numérico.
  static String? stock(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa el stock disponible';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null) return 'Stock inválido';
    if (parsed < 0) return 'El stock no puede ser negativo';
    return null;
  }

  /// Valida que un campo de texto no esté vacío.
  static String? required(String? value, {String fieldName = 'Este campo'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es obligatorio';
    }
    return null;
  }

  /// Valida longitud máxima de un mensaje de chat.
  static bool isMensajeValido(String texto) =>
      texto.trim().isNotEmpty &&
      texto.trim().length <= AppConstants.longitudMaximaMensaje;
}
