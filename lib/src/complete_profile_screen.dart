import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _nameController = TextEditingController();
  String _userRole = 'Productor'; // Valor por defecto

  void _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _nameController.text.isNotEmpty) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'nombre': _nameController.text,
        'rol': _userRole,
        'email': user.email,
        'perfilCompleto': true,
        'fechaRegistro': FieldValue.serverTimestamp(),
      });
      // El AuthWrapper detectará el cambio automáticamente
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Completa tu Perfil')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre Completo'),
            ),
            const SizedBox(height: 20),
            DropdownButton<String>(
              value: _userRole,
              items: <String>['Productor', 'Comprador', 'Transportador']
                  .map((String value) =>
                      DropdownMenuItem(value: value, child: Text(value)))
                  .toList(),
              onChanged: (val) => setState(() => _userRole = val!),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _saveProfile,
              child: const Text('Guardar y Continuar'),
            )
          ],
        ),
      ),
    );
  }
}
