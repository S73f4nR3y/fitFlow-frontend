class BookingModel {
  final String id;
  final String status;
  final double amount;
  final DateTime createdAt;
  final ScheduleModel? schedule;

  BookingModel({
    required this.id,
    required this.status,
    required this.amount,
    required this.createdAt,
    this.schedule,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] ?? '',
      status: json['status'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      schedule: json['schedule'] != null
          ? ScheduleModel.fromJson(json['schedule'])
          : null,
    );
  }

  bool get isConfirmed => status == 'confirmed';
  bool get isCancelled => status == 'cancelled';
}

class ScheduleModel {
  final String id;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String? location;
  final ClassModel? classEntity;

  ScheduleModel({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.location,
    this.classEntity,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['id'] ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      location: json['location'],
      classEntity: json['classEntity'] != null
          ? ClassModel.fromJson(json['classEntity'])
          : null,
    );
  }

  String get formattedDate => '${date.day}/${date.month}/${date.year}';
  String get formattedTime => '$startTime - $endTime';
}

class ClassModel {
  final String id;
  final String title;
  final String? description;
  final double price;
  final int durationMinutes;
  final int maxParticipants;
  final InstructorModel? instructor;

  ClassModel({
    required this.id,
    required this.title,
    this.description,
    required this.price,
    required this.durationMinutes,
    required this.maxParticipants,
    this.instructor,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      durationMinutes: json['durationMinutes'] ?? 30,
      maxParticipants: json['maxParticipants'] ?? 20,
      instructor: json['instructor'] != null
          ? InstructorModel.fromJson(json['instructor'])
          : null,
    );
  }

  String get formattedPrice => '\$$price';
  String get formattedDuration => '$durationMinutes min';
  String get formattedParticipants => '$maxParticipants';
}

class InstructorModel {
  final String id;
  final String displayName;
  final String? bio;
  final String? photoUrl;
  final String? avatarUrl;

  InstructorModel({
    required this.id,
    required this.displayName,
    this.bio,
    this.photoUrl,
    this.avatarUrl,
  });

  factory InstructorModel.fromJson(Map<String, dynamic> json) {
    return InstructorModel(
      id: json['id'] ?? '',
      displayName: json['displayName'] ?? '',
      bio: json['bio'],
      photoUrl: json['photoUrl'],
      avatarUrl: json['avatarUrl'] ?? json['user']?['avatarUrl'],
    );
  }

  String? get displayPhotoUrl {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return avatarUrl!.startsWith('http')
          ? avatarUrl
          : 'http://localhost:3000$avatarUrl';
    }
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return photoUrl!.startsWith('http')
          ? photoUrl
          : 'http://localhost:3000$photoUrl';
    }
    return null;
  }
}
