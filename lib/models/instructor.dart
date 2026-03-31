class Instructor {
  final String id;
  final String userId;
  final String displayName;
  final String? bio;
  final String? photoUrl;
  final List<String>? specialties;
  final double rating;
  final int totalRatings;
  final bool isActive;

  Instructor({
    required this.id,
    required this.userId,
    required this.displayName,
    this.bio,
    this.photoUrl,
    this.specialties,
    required this.rating,
    required this.totalRatings,
    required this.isActive,
  });

  factory Instructor.fromJson(Map<String, dynamic> json) {
    return Instructor(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      displayName: json['displayName'] ?? '',
      bio: json['bio'],
      photoUrl: json['photoUrl'],
      specialties: json['specialties'] != null
          ? List<String>.from(json['specialties'])
          : null,
      rating: (json['rating'] ?? 0).toDouble(),
      totalRatings: json['totalRatings'] ?? 0,
      isActive: json['isActive'] ?? true,
    );
  }
}
