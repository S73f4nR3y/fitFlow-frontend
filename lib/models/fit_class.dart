class FitClass {
  final String id;
  final String instructorId;
  final String title;
  final String? description;
  final String type;
  final double price;
  final int durationMinutes;
  final int maxParticipants;
  final String? coverImageUrl;
  final bool isActive;

  FitClass({
    required this.id,
    required this.instructorId,
    required this.title,
    this.description,
    required this.type,
    required this.price,
    required this.durationMinutes,
    required this.maxParticipants,
    this.coverImageUrl,
    required this.isActive,
  });

  factory FitClass.fromJson(Map<String, dynamic> json) {
    return FitClass(
      id: json['id'] ?? '',
      instructorId: json['instructorId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      type: json['type'] ?? 'group',
      price: (json['price'] ?? 0).toDouble(),
      durationMinutes: json['durationMinutes'] ?? 30,
      maxParticipants: json['maxParticipants'] ?? 20,
      coverImageUrl: json['coverImageUrl'],
      isActive: json['isActive'] ?? true,
    );
  }
}

class ClassSchedule {
  final String id;
  final String classId;
  final DateTime date;
  final String startTime;
  final String endTime;
  final int currentParticipants;
  final String? location;
  final String? notes;

  ClassSchedule({
    required this.id,
    required this.classId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.currentParticipants,
    this.location,
    this.notes,
  });

  factory ClassSchedule.fromJson(Map<String, dynamic> json) {
    return ClassSchedule(
      id: json['id'] ?? '',
      classId: json['classId'] ?? '',
      date: DateTime.parse(json['date']),
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      currentParticipants: json['currentParticipants'] ?? 0,
      location: json['location'],
      notes: json['notes'],
    );
  }

  int get availableSpots => 0;
}
