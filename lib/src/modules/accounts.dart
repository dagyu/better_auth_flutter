import "package:better_auth_flutter/better_auth_flutter.dart";
import "package:better_auth_flutter/src/core/api/data/models/account.dart";

class Accounts {
  static Future<(List<Account>?, Failure?)> listAccounts() async {
    try {
      final (result, error) = await Api.sendRequest(
        AppEndpoints.listAccounts,
        method: MethodType.get,
      );

      if (error != null) return (null, error);

      if (result is! List) throw Exception("Invalid response format");

      final List<Account> accounts =
          result
              .map(
                (account) => Account.fromMap(account as Map<String, dynamic>),
              )
              .toList();

      return (accounts, null);
    } catch (e) {
      return (
        null,
        Failure(code: BetterAuthError.unKnownError, message: e.toString()),
      );
    }
  }
}
