class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final String? instructorStatus;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.instructorStatus,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'client',
      instructorStatus: json['instructorStatus'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  bool get isClient => role == 'client';
  bool get isInstructor => role == 'instructor';
  bool get isAdmin => role == 'admin';
  bool get isInstructorApproved =>
      isInstructor && instructorStatus == 'approved';
  bool get isInstructorPending => isInstructor && instructorStatus == 'pending';
}
