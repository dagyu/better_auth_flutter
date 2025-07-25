import "package:better_auth_flutter/src/core/api/api.dart";
import "package:better_auth_flutter/src/core/config/config.dart";
import "package:better_auth_flutter/src/core/local_storage/kv_store.dart";
import "package:better_auth_flutter/src/modules/better_auth_client.dart";

class BetterAuth {
  BetterAuth._();

  static final BetterAuth _instance = BetterAuth._();
  static BetterAuth get instance => _instance;
  static late BetterAuthConfig config;

  static bool _isInitialized = false;

  final BetterAuthClient _client = BetterAuthClient();
  BetterAuthClient get client {
    if (!_isInitialized) {
      throw Exception(
        "BetterAuth not initialized. Call BetterAuth.init() first.",
      );
    }
    return _client;
  }

  static Future<void> init({required Uri baseUrl}) async {
    if (_isInitialized) return;
    await KVStore.init();
    await Api.init();
    config = BetterAuthConfig(baseUrl: baseUrl);
    _isInitialized = true;
  }

  static Future<void> initWithConfig({required BetterAuthConfig config}) async {
    if (_isInitialized) return;
    await KVStore.init();
    await Api.init();
    BetterAuth.config = config;
    _isInitialized = true;
  }
}
