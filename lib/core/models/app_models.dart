export 'note_model.dart';
export 'calendar_models.dart';

class ContactItem {
  final String id;
  final String photoUrl;
  final String name;
  final String company;
  final String designation;
  final String phone;
  final String email;
  final String department;
  final String location;
  final String notes;
  bool isFavorite;
  bool isBlocked;

  ContactItem({
    required this.id,
    required this.photoUrl,
    required this.name,
    required this.company,
    required this.designation,
    required this.phone,
    required this.email,
    required this.department,
    required this.location,
    required this.notes,
    this.isFavorite = false,
    this.isBlocked = false,
  });
}

