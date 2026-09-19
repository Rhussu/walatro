import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walatro/models/table_score_model.dart';

/// Servicio de persistencia local para guardar y recuperar el estado
/// de la partida en el Anotador de Mesa usando SharedPreferences.
class TableScoreStorage {
  static const String _storageKey = 'walatro_table_score_state_v1';

  /// Carga el estado guardado o retorna un estado por defecto si no existe o hay error.
  static Future<TableScoreState> loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
        return TableScoreState.fromJson(decoded);
      }
    } catch (e) {
      debugPrint('Error al cargar estado de anotador: $e');
    }
    return TableScoreState.createDefault();
  }

  /// Guarda el estado actual de la partida.
  static Future<bool> saveState(TableScoreState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(state.toJson());
      return await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      debugPrint('Error al guardar estado de anotador: $e');
      return false;
    }
  }

  /// Borra la partida guardada para reiniciar.
  static Future<bool> clearState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_storageKey);
    } catch (e) {
      debugPrint('Error al reiniciar estado de anotador: $e');
      return false;
    }
  }
}
