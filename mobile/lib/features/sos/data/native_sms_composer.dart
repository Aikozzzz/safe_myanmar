import 'package:url_launcher/url_launcher.dart';

typedef SmsUriLauncher = Future<bool> Function(Uri uri);

abstract interface class NativeSmsComposer {
  Future<bool> open({required List<String> recipients, required String body});
}

final class UrlLauncherNativeSmsComposer implements NativeSmsComposer {
  UrlLauncherNativeSmsComposer([SmsUriLauncher? launcher])
    : _launcher =
          launcher ??
          ((uri) => launchUrl(uri, mode: LaunchMode.externalApplication));

  final SmsUriLauncher _launcher;

  static Uri buildUri({
    required List<String> recipients,
    required String body,
  }) => Uri(
    scheme: 'sms',
    path: recipients.join(','),
    queryParameters: {'body': body},
  );

  @override
  Future<bool> open({
    required List<String> recipients,
    required String body,
  }) async {
    if (recipients.isEmpty) return false;
    try {
      return await _launcher(buildUri(recipients: recipients, body: body));
    } on Object {
      return false;
    }
  }
}
