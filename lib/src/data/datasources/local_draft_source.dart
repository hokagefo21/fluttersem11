import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/firebase_paths.dart';
import '../../../core/rest_client/data_exception.dart';
import '../../../models/contact_dto.dart';

abstract interface class LocalDraftSource {
  Future<ContactDto?> read();
  Future<void> write(ContactDto data);
  Future<void> clear();
}

class PreferencesDraftSource implements LocalDraftSource {
  final SharedPreferencesAsync prefs;
  PreferencesDraftSource(this.prefs);
  Future<T> _access<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } catch (_) {
      throw const LocalDataException();
    }
  }

  @override
  Future<ContactDto?> read() => _access(() async {
    final raw = await prefs.getString(draftKey);
    return raw == null
        ? null
        : ContactDto.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  });
  @override
  Future<void> write(ContactDto data) =>
      _access(() => prefs.setString(draftKey, jsonEncode(data.toJson())));
  @override
  Future<void> clear() => _access(() => prefs.remove(draftKey));
}
