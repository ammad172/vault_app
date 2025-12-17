import 'package:flutter/foundation.dart';
import '../models/vault_entry.dart';
import 'package:hive_flutter/hive_flutter.dart';

class VaultService {
  static const _boxName = 'vault_entries';
  static Box<Map>? _box;

  static Future<void> init(Uint8List encryptionKey) async {
    if (Hive.isBoxOpen(_boxName)) {
      _box = Hive.box<Map>(_boxName);
      return;
    }

    _box = await Hive.openBox<Map>(
      _boxName,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
  }

  static Box<Map> get box {
    final b = _box;
    if (b == null) {
      throw StateError('Vault box not initialized');
    }
    return b;
  }

  static ValueListenable<Box<Map>> listenable() {
    return box.listenable();
  }

  static List<VaultEntry> getEntriesSnapshot() {
    final b = box;
    final entries = <VaultEntry>[];
    for (final key in b.keys) {
      final value = b.get(key);
      if (value is Map) {
        entries.add(VaultEntry.fromMap(key.toString(), value));
      }
    }
    // Sort by updatedAt desc
    entries.sort((a, b_) => b_.updatedAt.compareTo(a.updatedAt));
    return entries;
  }

  static Future<void> saveEntry(VaultEntry entry) async {
    await box.put(entry.id, entry.toMap());
  }

  static VaultEntry? getEntry(String id) {
    final value = box.get(id);
    if (value is Map) {
      return VaultEntry.fromMap(id, value);
    }
    return null;
  }

  static Future<void> deleteEntry(String id) async {
    await box.delete(id);
  }
}
