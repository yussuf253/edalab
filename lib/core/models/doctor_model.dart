class DoctorModel {
  final String id;
  final String name;
  final String specialty;
  final double rating;
  final int reviewCount;
  final String experience;
  final double consultationFee;
  final bool isAvailable;
  final String? imageUrl;
  final String? about;
  final String? location;
  final WorkingHours workingHours;
  final List<String> languages;
  final List<String> services;
  final List<ReviewModel> reviews;

  DoctorModel({
    required this.id,
    required this.name,
    required this.specialty,
    required this.rating,
    required this.reviewCount,
    required this.experience,
    required this.consultationFee,
    this.isAvailable = true,
    this.imageUrl,
    this.about,
    this.location,
    WorkingHours? workingHours,
    this.languages = const ['English'],
    this.services = const [],
    this.reviews = const [],
  }) : workingHours = workingHours ?? WorkingHours();

  factory DoctorModel.fromApi(Map<String, dynamic> json) {
    final workingHoursJson = Map<String, dynamic>.from(
      (json['workingHours'] as Map?) ?? const <String, dynamic>{},
    );
    final reviewsJson = (json['reviews'] as List?)?.cast<dynamic>() ?? const [];

    return DoctorModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Doctor',
      specialty: json['specialty']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      experience: json['experience']?.toString() ?? 'Experience unavailable',
      consultationFee: (json['consultationFee'] as num?)?.toDouble() ?? 0,
      isAvailable: json['isAvailable'] as bool? ?? true,
      imageUrl: json['imageUrl']?.toString(),
      about: json['about']?.toString(),
      location: json['location']?.toString(),
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
      reviews: reviewsJson
          .map(
            (review) =>
                ReviewModel.fromApi(Map<String, dynamic>.from(review as Map)),
          )
          .toList(),
    );
  }

  static List<DoctorModel> sampleDoctors = [
    DoctorModel(
      id: 'd1',
      name: 'Dr. Sarah Johnson',
      specialty: 'Cardiologist',
      rating: 4.9,
      reviewCount: 1200,
      experience: '15 years',
      consultationFee: 50.0,
      isAvailable: true,
      about:
          'Dr. Sarah Johnson is a board-certified cardiologist with over 15 years of experience specializing in preventive cardiology, heart failure management, and cardiac rehabilitation.',
      location: 'City Medical Center, 123 Health Street',
      languages: ['English', 'Spanish'],
      services: [
        'Heart Checkup',
        'ECG',
        'Echocardiogram',
        'Stress Test',
        'Cardiac Rehab',
      ],
      reviews: [
        ReviewModel(
          name: 'Maria G.',
          rating: 5,
          comment: 'Dr. Johnson is incredibly thorough and caring.',
          date: '2 weeks ago',
        ),
        ReviewModel(
          name: 'Robert K.',
          rating: 5,
          comment: 'Best cardiologist I\'ve ever been to. Highly recommend!',
          date: '1 month ago',
        ),
        ReviewModel(
          name: 'Lisa T.',
          rating: 4,
          comment: 'Very knowledgeable and takes time with patients.',
          date: '2 months ago',
        ),
      ],
    ),
    DoctorModel(
      id: 'd2',
      name: 'Dr. Michael Chen',
      specialty: 'Dermatologist',
      rating: 4.8,
      reviewCount: 890,
      experience: '10 years',
      consultationFee: 45.0,
      isAvailable: true,
      about:
          'Dr. Michael Chen specializes in medical and cosmetic dermatology with expertise in skin cancer treatment and advanced skincare.',
      location: 'Skin Health Clinic, 456 Beauty Ave',
    ),
    DoctorModel(
      id: 'd3',
      name: 'Dr. Emily Williams',
      specialty: 'Pediatrician',
      rating: 4.7,
      reviewCount: 1500,
      experience: '12 years',
      consultationFee: 40.0,
      isAvailable: false,
      about:
          'Dr. Emily Williams is a compassionate pediatrician providing comprehensive care for children from birth to adolescence.',
      location: 'Children\'s Health Center',
    ),
    DoctorModel(
      id: 'd4',
      name: 'Dr. James Brown',
      specialty: 'Neurologist',
      rating: 4.9,
      reviewCount: 2100,
      experience: '20 years',
      consultationFee: 60.0,
      isAvailable: true,
      about:
          'Dr. James Brown is a leading neurologist specializing in migraine, epilepsy, and neurodegenerative disorders.',
      location: 'Brain & Spine Center',
    ),
    DoctorModel(
      id: 'd5',
      name: 'Dr. Lisa Anderson',
      specialty: 'Orthopedic',
      rating: 4.6,
      reviewCount: 650,
      experience: '8 years',
      consultationFee: 55.0,
      isAvailable: false,
      about:
          'Dr. Lisa Anderson specializes in sports medicine and joint replacement surgery.',
      location: 'Sports Medicine Clinic',
    ),
  ];
}

class WorkingHours {
  final String weekdays;
  final String saturday;
  final String sunday;

  WorkingHours({
    this.weekdays = '09:00 AM - 05:00 PM',
    this.saturday = '10:00 AM - 02:00 PM',
    this.sunday = 'Closed',
  });

  factory WorkingHours.fromApi(Map<String, dynamic> json) {
    return WorkingHours(
      weekdays: json['weekdays']?.toString() ?? '09:00 AM - 05:00 PM',
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
