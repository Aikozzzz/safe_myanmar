import 'package:flutter/services.dart';

enum NativeSmsSendStatus {
  sent,
  partial,
  unknown,
  permissionDenied,
  unavailable,
  failed,
}

final class SmsSim {
  const SmsSim({
    required this.subscriptionId,
    required this.slotIndex,
    required this.label,
  });

  final int subscriptionId;
  final int slotIndex;
  final String label;

  String get displayLabel => 'SIM ${slotIndex + 1} - $label';
}

final class NativeSmsSendResult {
  const NativeSmsSendResult(
    this.status, {
    this.attemptId,
    this.confirmedParts = 0,
    this.totalParts = 0,
  });

  final NativeSmsSendStatus status;
  final String? attemptId;
  final int confirmedParts;
  final int totalParts;

  bool get acceptedByDevice =>
      status == NativeSmsSendStatus.sent ||
      status == NativeSmsSendStatus.partial;
}

abstract interface class NativeSmsSender {
  Future<List<SmsSim>> listSims();

  Future<bool> requestPermission();

  Future<NativeSmsSendResult> send({
    required List<String> recipients,
    required String body,
    required int subscriptionId,
  });
}

final class MethodChannelNativeSmsSender implements NativeSmsSender {
  MethodChannelNativeSmsSender([
    this._channel = const MethodChannel(channelName),
  ]);

  static const channelName = 'org.safemyanmar.mobile/sms';
  final MethodChannel _channel;

  @override
  Future<List<SmsSim>> listSims() async {
    try {
      final permitted =
          await _channel.invokeMethod<bool>('requestSimPermission') ?? false;
      if (!permitted) return const [];
      final response = await _channel.invokeMapMethod<Object?, Object?>(
        'getSimCards',
      );
      final rawSims = response?['sims'];
      if (response?['status'] != 'available' || rawSims is! List) {
        return const [];
      }
      return rawSims
          .whereType<Map>()
          .map((raw) {
            final subscriptionId = raw['subscription_id'];
            final slotIndex = raw['slot_index'];
            final label = raw['label'];
            if (subscriptionId is! int ||
                slotIndex is! int ||
                label is! String) {
              throw const FormatException();
            }
            return SmsSim(
              subscriptionId: subscriptionId,
              slotIndex: slotIndex,
              label: label,
            );
          })
          .toList(growable: false);
    } on MissingPluginException {
      return const [];
    } on PlatformException {
      return const [];
    } on FormatException {
      return const [];
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      return await _channel.invokeMethod<bool>('requestPermission') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<NativeSmsSendResult> send({
    required List<String> recipients,
    required String body,
    required int subscriptionId,
  }) async {
    try {
      final response = await _channel.invokeMapMethod<Object?, Object?>(
        'send',
        {
          'recipients': recipients,
          'body': body,
          'subscription_id': subscriptionId,
        },
      );
      final confirmedParts = response?['confirmed_parts'];
      final totalParts = response?['total_parts'];
      return NativeSmsSendResult(
        switch (response?['status']) {
          'sent' => NativeSmsSendStatus.sent,
          'partial' => NativeSmsSendStatus.partial,
          'unknown' => NativeSmsSendStatus.unknown,
          'permission_denied' => NativeSmsSendStatus.permissionDenied,
          'unavailable' => NativeSmsSendStatus.unavailable,
          _ => NativeSmsSendStatus.failed,
        },
        attemptId: response?['attempt_id'] as String?,
        confirmedParts: confirmedParts is int ? confirmedParts : 0,
        totalParts: totalParts is int ? totalParts : 0,
      );
    } on MissingPluginException {
      return const NativeSmsSendResult(NativeSmsSendStatus.unavailable);
    } on PlatformException catch (error) {
      return NativeSmsSendResult(
        error.code == 'permission_denied'
            ? NativeSmsSendStatus.permissionDenied
            : NativeSmsSendStatus.failed,
      );
    } on Object {
      return const NativeSmsSendResult(NativeSmsSendStatus.failed);
    }
  }
}
