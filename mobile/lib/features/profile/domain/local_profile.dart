const maxEmergencyContacts = 10;
const maxProfileDisplayNameLength = 200;
const maxEmergencyContactNameLength = 200;
const maxEmergencyContactLabelLength = 100;
const maxEmergencyContactIdLength = 100;

final class EmergencyContact {
  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.label,
    required this.selectedForSos,
  });

  final String id;
  final String name;
  final String phoneNumber;
  final String label;
  final bool selectedForSos;

  EmergencyContact copyWith({
    String? name,
    String? phoneNumber,
    String? label,
    bool? selectedForSos,
  }) => EmergencyContact(
    id: id,
    name: name ?? this.name,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    label: label ?? this.label,
    selectedForSos: selectedForSos ?? this.selectedForSos,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmergencyContact &&
          id == other.id &&
          name == other.name &&
          phoneNumber == other.phoneNumber &&
          label == other.label &&
          selectedForSos == other.selectedForSos;

  @override
  int get hashCode => Object.hash(id, name, phoneNumber, label, selectedForSos);
}

final class LocalProfile {
  LocalProfile({
    required this.displayName,
    required List<EmergencyContact> contacts,
  }) : contacts = List.unmodifiable(contacts);

  factory LocalProfile.empty() =>
      LocalProfile(displayName: '', contacts: const []);

  final String displayName;
  final List<EmergencyContact> contacts;

  LocalProfile copyWith({
    String? displayName,
    List<EmergencyContact>? contacts,
  }) => LocalProfile(
    displayName: displayName ?? this.displayName,
    contacts: contacts ?? this.contacts,
  );

  EmergencyContact? contactById(String id) {
    for (final contact in contacts) {
      if (contact.id == id) return contact;
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalProfile &&
          displayName == other.displayName &&
          _listEquals(contacts, other.contacts);

  @override
  int get hashCode => Object.hash(displayName, Object.hashAll(contacts));
}

bool _listEquals(List<Object?> left, List<Object?> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
