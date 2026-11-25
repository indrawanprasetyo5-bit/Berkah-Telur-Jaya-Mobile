enum UserRole { kasir, owner }

class UserSession {
  const UserSession({
    required this.id,
    required this.name,
    required this.role,
    this.isDemo = true,
  });

  final String id;
  final String name;
  final UserRole role;
  final bool isDemo;

  String get roleLabel => role == UserRole.owner ? 'Owner' : 'Kasir';
}
