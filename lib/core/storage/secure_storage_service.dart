import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;
  final Map<String, String> _fallbackMemory = {};

  SecureStorageService([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              mOptions: MacOsOptions(
                accessibility: KeychainAccessibility.first_unlock,
                useDataProtectionKeyChain: false,
              ),
            );

  Future<void> write(String key, String value) async {
    _fallbackMemory[key] = value;
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {
      // Graceful fallback to memory on sandboxed desktop environments
    }
  }

  Future<String?> read(String key) async {
    try {
      final val = await _storage.read(key: key);
      if (val != null) return val;
    } catch (_) {
      // Fallback
    }
    return _fallbackMemory[key];
  }

  Future<void> delete(String key) async {
    _fallbackMemory.remove(key);
    try {
      await _storage.delete(key: key);
    } catch (_) {}
  }

  Future<void> deleteAll() async {
    _fallbackMemory.clear();
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }
}

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});
