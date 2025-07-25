import "dart:convert";
import "package:better_auth_flutter/better_auth_flutter.dart";
import "package:cookie_jar/cookie_jar.dart";
import "package:http/http.dart" as http;
import "package:path_provider/path_provider.dart";
import "dart:developer";

class Api {
  static final hc = http.Client();

  static late PersistCookieJar _cookieJar;

  static Future<void> init() async {
    try {
      final cacheDir = await getApplicationCacheDirectory();
      _cookieJar = PersistCookieJar(
        storage: FileStorage("${cacheDir.path}/.cookies/"),
      );
    } catch (e) {
      log("Failed to initialize cookie jar: ${e.toString()}", error: e);
    }
  }

  static Future<String?> getCookieHeader() async {
    final cookies = await _cookieJar.loadForRequest(BetterAuth.config.baseUrl);
    if (cookies.isEmpty) return null;
    return cookies.map((c) => "${c.name}=${c.value}").join("; ");
  }

  static Future<(dynamic, BetterAuthFailure?)> sendRequest(
    String path, {
    required MethodType method,
    String? host,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    int retry = 0,
    bool isAuthRoute = false,
  }) async {
    headers ??= {};

    headers.addAll({
      "Accept": "application/json",
      "Content-Type": "application/json",
    });

    final Uri uri = BetterAuth.config.resolveApiUrl(
      path: path,
      queryParameters: queryParameters,
    );

    final cookies = await getCookieHeader();
    if (cookies != null) {
      headers["Cookie"] = cookies;
    }

    final http.Response response;

    try {
      switch (method) {
        case MethodType.get:
          response = await hc
              .get(uri, headers: headers)
              .timeout(BetterAuth.config.timeLimit);
          break;
        case MethodType.post:
          response = await hc
              .post(uri, headers: headers, body: jsonEncode(body))
              .timeout(BetterAuth.config.timeLimit);
          break;
      }
    } catch (e) {
      return (null, BetterAuthFailure(code: BetterAuthError.unKnownError));
    }

    final setCookieHeader = response.headers["set-cookie"];
    if (setCookieHeader != null) {
      final cookiesList =
          setCookieHeader.split(",").map((cookieString) {
            return Cookie.fromSetCookieValue(cookieString.trim());
          }).toList();

      if (isAuthRoute) {
        await _cookieJar.saveFromResponse(
          BetterAuth.config.baseUrl,
          cookiesList,
        );
      }
    }

    switch (response.statusCode) {
      case 200:
        try {
          final data = jsonDecode(response.body);
          return (data, null);
        } catch (e) {
          return (
            null,
            BetterAuthFailure(
              code: BetterAuthError.unKnownError,
              message: "Failed to parse response body",
            ),
          );
        }

      default:
        try {
          final body = jsonDecode(response.body);

          if (body is! Map<String, dynamic> ||
              !body.containsKey("code") ||
              !body.containsKey("message")) {
            return (
              null,
              BetterAuthFailure(
                code: BetterAuthError.unKnownError,
                message: "Invalid response format",
              ),
            );
          }

          return (
            null,
            BetterAuthFailure(
              code: BetterAuthError.values.firstWhere(
                (element) => element.code == body["code"],
              ),
              message: body["message"],
            ),
          );
        } catch (e) {
          return (
            null,
            BetterAuthFailure(
              code: BetterAuthError.unKnownError,
              message: "Failed to parse response body",
            ),
          );
        }
    }
  }
}
