class DoctorModel {
  final String id;
  final String name;
  final String specialty;
  final String providerType;
  final double rating;
  final int reviewCount;
  final String experience;
  final double consultationFee;
  final bool isAvailable;
  final bool isSignedUp;
  final String? imageUrl;
  final String? about;
  final String? location;
  final String? contactPhone;
  final String? contactWhatsApp;
  final WorkingHours workingHours;
  final List<String> languages;
  final List<String> services;
  final List<String> careModes;
  final List<ReviewModel> reviews;

  DoctorModel({
    required this.id,
    required this.name,
    required this.specialty,
    this.providerType = 'DOCTOR',
    required this.rating,
    required this.reviewCount,
    required this.experience,
    required this.consultationFee,
    this.isAvailable = true,
    this.isSignedUp = false,
    this.imageUrl,
    this.about,
    this.location,
    this.contactPhone,
    this.contactWhatsApp,
    WorkingHours? workingHours,
    this.languages = const ['English'],
    this.services = const [],
    this.careModes = const ['Clinic Visit'],
    this.reviews = const [],
  }) : workingHours = workingHours ?? WorkingHours();

  bool get isTherapist =>
      specialty.toLowerCase().contains('therapy') ||
      specialty.toLowerCase().contains('physio') ||
      services.any(
        (service) =>
            service.toLowerCase().contains('therapy') ||
            service.toLowerCase().contains('physio') ||
            service.toLowerCase().contains('kine'),
      );

  bool get isNurse =>
      specialty.toLowerCase().contains('nursing') ||
      services.any((service) => service.toLowerCase().contains('nursing'));

  bool get isDoctorProvider => !isNurse && !isTherapist;

  bool get isHomeCareProvider => !isDoctorProvider;

  bool get usesDirectContactOnly => isDoctorProvider && !isSignedUp;

  bool get canBookThroughApp => !usesDirectContactOnly;

  bool get canContactDirectly =>
      (contactPhone != null && contactPhone!.isNotEmpty) ||
      (contactWhatsApp != null && contactWhatsApp!.isNotEmpty);

  String get professionLabel {
    if (isDoctorProvider) return 'Doctor';
    if (isNurse) return 'Home Nurse';
    if (isTherapist) return 'Therapist';
    return 'Care Specialist';
  }

  String get serviceCategoryLabel {
    if (isDoctorProvider) return 'Medical Consultation';
    if (isNurse) return 'Nursing Care';
    if (isTherapist) return 'Therapy Service';
    return 'Care Service';
  }

  String get primaryActionLabel {
    if (usesDirectContactOnly) return 'Contact Doctor';
    if (isDoctorProvider) return 'Book Appointment';
    return 'Book Care Service';
  }

  factory DoctorModel.fromApi(Map<String, dynamic> json) {
    final workingHoursJson = Map<String, dynamic>.from(
      (json['workingHours'] as Map?) ?? const <String, dynamic>{},
    );
    final reviewsJson = (json['reviews'] as List?)?.cast<dynamic>() ?? const [];
    String? readImageUrl() {
      String? pick(dynamic value) {
        final text = value?.toString().trim();
        if (text == null || text.isEmpty) return null;
        return text;
      }

      final proProfile = json['proProfile'] is Map
          ? Map<String, dynamic>.from(json['proProfile'] as Map)
          : const <String, dynamic>{};
      final profile = json['profile'] is Map
          ? Map<String, dynamic>.from(json['profile'] as Map)
          : const <String, dynamic>{};

      return pick(json['imageUrl']) ??
          pick(json['profileImageUrl']) ??
          pick(json['profileAvatarUrl']) ??
          pick(json['avatarUrl']) ??
          pick(profile['imageUrl']) ??
          pick(profile['avatarUrl']) ??
          pick(proProfile['imageUrl']) ??
          pick(proProfile['avatarUrl']);
    }

    return DoctorModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Doctor',
      specialty: json['specialty']?.toString() ?? '',
      providerType: json['providerType']?.toString() ?? 'DOCTOR',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      experience: json['experience']?.toString() ?? 'Experience unavailable',
      consultationFee: (json['consultationFee'] as num?)?.toDouble() ?? 0,
      isAvailable: json['isAvailable'] as bool? ?? true,
      isSignedUp: json['isSignedUp'] as bool? ?? false,
      imageUrl: readImageUrl(),
      about: json['about']?.toString(),
      location: json['location']?.toString(),
      contactPhone: json['contactPhone']?.toString(),
      contactWhatsApp: json['contactWhatsApp']?.toString(),
      workingHours: WorkingHours.fromApi(workingHoursJson),
      languages:
          (json['languages'] as List?)
              ?.map((item) => item.toString())
              .toList() ??
          const ['English'],
      services:
          (json['services'] as List?)
              ?.map((item) => item.toString())
              .toList() ??
          const [],
      careModes:
          (json['careModes'] as List?)
              ?.map((item) => item.toString())
              .toList() ??
          const ['Clinic Visit'],
      reviews: reviewsJson
          .map(
            (review) =>
                ReviewModel.fromApi(Map<String, dynamic>.from(review as Map)),
          )
          .toList(),
    );
  }

}

class WorkingHours {
  final String monday;
  final String tuesday;
  final String wednesday;
  final String thursday;
  final String friday;
  final String saturday;
  final String sunday;

  WorkingHours({
    this.monday = '09:00 AM - 05:00 PM',
    this.tuesday = '09:00 AM - 05:00 PM',
    this.wednesday = '09:00 AM - 05:00 PM',
    this.thursday = '09:00 AM - 05:00 PM',
    this.friday = '09:00 AM - 05:00 PM',
    this.saturday = '10:00 AM - 02:00 PM',
    this.sunday = 'Closed',
  });

  factory WorkingHours.fromApi(Map<String, dynamic> json) {
    final weekdaysFallback = json['weekdays']?.toString() ?? '09:00 AM - 05:00 PM';
    return WorkingHours(
      monday: json['monday']?.toString() ?? weekdaysFallback,
      tuesday: json['tuesday']?.toString() ?? weekdaysFallback,
      wednesday: json['wednesday']?.toString() ?? weekdaysFallback,
      thursday: json['thursday']?.toString() ?? weekdaysFallback,
      friday: json['friday']?.toString() ?? weekdaysFallback,
      saturday: json['saturday']?.toString() ?? '10:00 AM - 02:00 PM',
      sunday: json['sunday']?.toString() ?? 'Closed',
    );
  }
}

class ReviewModel {
  final String name;
  final int rating;
  final String comment;
  final String date;
  final String? avatarUrl;

  ReviewModel({
    required this.name,
    required this.rating,
    required this.comment,
    required this.date,
    this.avatarUrl,
  });

  factory ReviewModel.fromApi(Map<String, dynamic> json) {
    return ReviewModel(
      name: json['name']?.toString() ?? 'Patient',
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      comment: json['comment']?.toString() ?? '',
      date: json['date']?.toString() ?? 'Recently',
      avatarUrl: json['avatarUrl']?.toString(),
    );
  }
}

class AppointmentModel {
  final String id;
  final DoctorModel doctor;
  final DateTime dateTime;
  final String type; // 'video', 'chat', 'in_person'
  final String status; // 'upcoming', 'completed', 'cancelled'
  final String? notes;

  AppointmentModel({
    required this.id,
    required this.doctor,
    required this.dateTime,
    required this.type,
    required this.status,
    this.notes,
  });
}
