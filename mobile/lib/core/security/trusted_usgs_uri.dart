Uri? parseTrustedUsgsUri(String value) {
  final uri = Uri.tryParse(value);
  if (uri == null || uri.scheme != 'https') return null;

  final host = uri.host.toLowerCase();
  if (host != 'earthquake.usgs.gov' && !host.endsWith('.earthquake.usgs.gov')) {
    return null;
  }
  return uri;
}
