enum YangonEmergencyService { ambulance, fire, police, yangonGeneralHospital }

final class YangonEmergencyPhone {
  const YangonEmergencyPhone({
    required this.displayNumber,
    required this.dialNumber,
  });

  final String displayNumber;
  final String dialNumber;

  Uri get uri => Uri(scheme: 'tel', path: dialNumber);
}

final class YangonEmergencyContact {
  const YangonEmergencyContact({required this.service, required this.phones});

  final YangonEmergencyService service;
  final List<YangonEmergencyPhone> phones;
}

const yangonEmergencyContactSourceUrl =
    'https://www.yangondirectory.com/emergency.html';
final yangonEmergencyContactsCheckedAt = DateTime.utc(2026, 9, 5);

const yangonEmergencyContacts = <YangonEmergencyContact>[
  YangonEmergencyContact(
    service: YangonEmergencyService.ambulance,
    phones: [YangonEmergencyPhone(displayNumber: '192', dialNumber: '192')],
  ),
  YangonEmergencyContact(
    service: YangonEmergencyService.fire,
    phones: [YangonEmergencyPhone(displayNumber: '191', dialNumber: '191')],
  ),
  YangonEmergencyContact(
    service: YangonEmergencyService.police,
    phones: [YangonEmergencyPhone(displayNumber: '199', dialNumber: '199')],
  ),
  YangonEmergencyContact(
    service: YangonEmergencyService.yangonGeneralHospital,
    phones: [
      YangonEmergencyPhone(displayNumber: '01 256112', dialNumber: '01256112'),
      YangonEmergencyPhone(displayNumber: '01 265131', dialNumber: '01265131'),
    ],
  ),
];
