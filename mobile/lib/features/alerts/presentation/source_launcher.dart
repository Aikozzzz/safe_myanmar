import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

typedef SourceLauncher = Future<bool> Function(Uri uri);

final sourceLauncherProvider = Provider<SourceLauncher>(
  (_) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);
