/// Thrown when a bundled data file is malformed. The message is user-readable.
class DataFormatException implements Exception {
  DataFormatException(this.message);
  final String message;

  @override
  String toString() => message;
}

Map<String, dynamic> asMap(Object? value, String ctx) {
  if (value is Map<String, dynamic>) return value;
  throw DataFormatException('$ctx: expected an object');
}

List<dynamic> asList(Object? value, String ctx) {
  if (value is List<dynamic>) return value;
  throw DataFormatException('$ctx: expected a list');
}

String reqString(Map<String, dynamic> m, String key, String ctx) {
  final v = m[key];
  if (v is String && v.isNotEmpty) return v;
  throw DataFormatException('$ctx: missing or invalid text field "$key"');
}

String optString(Map<String, dynamic> m, String key, String def) {
  final v = m[key];
  return v is String ? v : def;
}

double reqDouble(Map<String, dynamic> m, String key, String ctx) {
  final v = m[key];
  if (v is num && v.isFinite) return v.toDouble();
  throw DataFormatException('$ctx: missing or invalid number "$key"');
}

double optDouble(Map<String, dynamic> m, String key, String ctx, double def) {
  if (!m.containsKey(key)) return def;
  return reqDouble(m, key, ctx);
}

int reqInt(Map<String, dynamic> m, String key, String ctx) {
  final v = m[key];
  if (v is num && v.isFinite && v == v.roundToDouble()) return v.toInt();
  throw DataFormatException('$ctx: missing or invalid whole number "$key"');
}

int optInt(Map<String, dynamic> m, String key, String ctx, int def) {
  if (!m.containsKey(key)) return def;
  return reqInt(m, key, ctx);
}

List<String> optStringList(Map<String, dynamic> m, String key, String ctx) {
  if (!m.containsKey(key)) return const [];
  final raw = asList(m[key], '$ctx.$key');
  return [
    for (final e in raw)
      if (e is String)
        e
      else
        throw DataFormatException('$ctx.$key: expected text entries'),
  ];
}

void check(bool ok, String ctx, String message) {
  if (!ok) throw DataFormatException('$ctx: $message');
}

int clampInt(int v, int lo, int hi) => v < lo ? lo : (v > hi ? hi : v);

double clampDouble(double v, double lo, double hi) =>
    v < lo ? lo : (v > hi ? hi : v);
