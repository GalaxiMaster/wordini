import 'package:encrypt/encrypt.dart' as encrypts;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wordini/env/env.dart';

class EncryptionService {
  // Private constructor for the singleton pattern
  EncryptionService._internal();

  // The single, static instance of the class
  static final EncryptionService _instance = EncryptionService._internal();

  // Getter to access the single instance
  static EncryptionService get instance => _instance;

  // Class properties
  late final encrypts.Encrypter _encrypter;
  final _iv = encrypts.IV.allZerosOfLength(16);
  final _storage = const FlutterSecureStorage();

  /// Initializes the encryption service by loading the key from environment variables.
  Future<void> initialize() async {
    final keyString = Env.encryptionKey;
    final key = encrypts.Key.fromUtf8(keyString);
    _encrypter = encrypts.Encrypter(encrypts.AES(key));
  }

  /// Encrypts a given plaintext string.
  String encrypt(String plainText) {
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  /// Decrypts a given Base64 encrypted string.
  String decrypt(String encryptedText) {
    final encrypted = encrypts.Encrypted.fromBase64(encryptedText);
    final decrypted = _encrypter.decrypt(encrypted, iv: _iv);
    return decrypted;
  }

  /// Writes a key-value pair to secure storage.
  Future<void> writeToSecureStorage({required String key, required String value}) async {
    await _storage.write(key: key, value: value);
  }

  /// Reads a value from secure storage for a given key.
  /// Returns null if the key is not found.
  Future<String?> readFromSecureStorage({required String key}) async {
    return await _storage.read(key: key);
  }

  /// Deletes a specific key-value pair from secure storage.
  Future<void> deleteFromSecureStorage({required String key}) async {
    await _storage.delete(key: key);
  }

  /// Deletes all data from secure storage.
  Future<void> clearAllSecureStorage() async {
    await _storage.deleteAll();
  }
}