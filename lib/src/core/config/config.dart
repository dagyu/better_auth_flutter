const kDefaultApiPrefixPath = "/api/auth";
const kDefaultTimeLimit = Duration(seconds: 2);

class BetterAuthConfig {
  final Uri apiBaseUrl;
  final Duration timeLimit;

  BetterAuthConfig({
    required Uri baseUrl,
    String apiPrefixPath = kDefaultApiPrefixPath,
    this.timeLimit = kDefaultTimeLimit,
  }) : apiBaseUrl = baseUrl.replace(path: apiPrefixPath);

  Uri get baseUrl => Uri(
    scheme: apiBaseUrl.scheme,
    host: apiBaseUrl.host,
    port: apiBaseUrl.port,
  );

  Uri resolveApiUrl({String? path, Map<String, dynamic>? queryParameters}) {
    return apiBaseUrl.replace(
      pathSegments: [...apiBaseUrl.pathSegments, if (path != null) path],
      queryParameters: queryParameters,
    );
  }
}
