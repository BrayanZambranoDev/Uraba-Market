import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';

/// Modelo de datos para un usuario de la plataforma.
class UserModel {
  final String uid;
  final String email;
  final String nombre;
  final String displayName;
  final String rol;
  final bool perfilCompleto;
  final String? photoURL;
  final DateTime? fechaRegistro;

  const UserModel({
    required this.uid,
    required this.email,
    required this.nombre,
    required this.displayName,
    required this.rol,
    required this.perfilCompleto,
    this.photoURL,
    this.fechaRegistro,
  });

  factory UserModel.fromMap(String uid, Map<String, dynamic> data) {
    return UserModel(
      uid: uid,
      email: data['email'] as String? ?? '',
      nombre: data['nombre'] as String? ?? data['displayName'] as String? ?? 'Usuario',
      displayName: data['displayName'] as String? ?? '',
      rol: data['rol'] as String? ?? AppConstants.rolComprador,
      perfilCompleto: data['perfilCompleto'] as bool? ?? false,
      photoURL: data['photoURL'] as String?,
      fechaRegistro: (data['fechaRegistro'] as Timestamp?)?.toDate(),
    );
  }

  factory UserModel.fromDoc(DocumentSnapshot doc) {
    return UserModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  bool get esComerciante => rol == AppConstants.rolComerciante;
  bool get esComprador => rol == AppConstants.rolComprador;

  /// Inicial del nombre para el avatar.
  String get inicial =>
      nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
}
