import 'package:cloud_firestore/cloud_firestore.dart';

enum CallType {
  voice,   // 📞 Voice Call
  video,   // 🎥 Video Call
}

enum AppointmentStatus {
  pending,    // Chờ xác nhận (không dùng vì auto-confirm)
  confirmed,  // Đã xác nhận
  completed,  // Đã hoàn thành
  cancelled,  // Đã hủy
}

class Appointment {
  final String appointmentId;
  final String userId;
  final String expertId;
  final String expertName;
  final String? expertAvatarUrl;
  
  final CallType callType;
  final DateTime appointmentDate;
  final int durationMinutes;
  
  final double price;
  final AppointmentStatus status;
  final String? userNotes;
  
  final DateTime createdAt;
  final DateTime? cancelledAt;

  Appointment({
    required this.appointmentId,
    required this.userId,
    required this.expertId,
    required this.expertName,
    this.expertAvatarUrl,
    required this.callType,
    required this.appointmentDate,
    required this.durationMinutes,
    required this.price,
    this.status = AppointmentStatus.confirmed,
    this.userNotes,
    DateTime? createdAt,
    this.cancelledAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Getters
  String get callTypeLabel {
    return callType == CallType.voice ? '📞 Voice Call' : '🎥 Video Call';
  }

  String get callTypeIcon {
    return callType == CallType.voice ? '📞' : '🎥';
  }

  bool get isPending => status == AppointmentStatus.pending;
  bool get isConfirmed => status == AppointmentStatus.confirmed;
  bool get isCompleted => status == AppointmentStatus.completed;
  bool get isCancelled => status == AppointmentStatus.cancelled;

  bool get canCancel {
    if (status != AppointmentStatus.confirmed) return false;
    final now = DateTime.now();
    final hoursDiff = appointmentDate.difference(now).inHours;
    return hoursDiff >= 4; // Phải >= 4 giờ
  }

  DateTime get endTime {
    return appointmentDate.add(Duration(minutes: durationMinutes));
  }

  // Calculate price based on call type and duration
  static double calculatePrice(CallType callType, int duration) {
    final basePricePerHour = callType == CallType.voice ? 100000.0 : 150000.0;
    return duration == 30 ? basePricePerHour / 2 : basePricePerHour;
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'appointmentId': appointmentId,
      'userId': userId,
      'expertId': expertId,
      'expertName': expertName,
      'expertAvatarUrl': expertAvatarUrl,
      'callType': callType.name,
      'appointmentDate': Timestamp.fromDate(appointmentDate),
      'durationMinutes': durationMinutes,
      'price': price,
      'status': status.name,
      'userNotes': userNotes,
      'createdAt': Timestamp.fromDate(createdAt),
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
    };
  }

  // Create from Firestore document
  factory Appointment.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Appointment(
      appointmentId: doc.id,
      userId: data['userId'] ?? '',
      expertId: data['expertId'] ?? '',
      expertName: data['expertName'] ?? '',
      expertAvatarUrl: data['expertAvatarUrl'],
      callType: CallType.values.firstWhere(
        (e) => e.name == data['callType'],
        orElse: () => CallType.video,
      ),
      appointmentDate: (data['appointmentDate'] as Timestamp).toDate(),
      durationMinutes: data['durationMinutes'] ?? 60,
      price: (data['price'] ?? 0.0).toDouble(),
      status: AppointmentStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => AppointmentStatus.confirmed,
      ),
      userNotes: data['userNotes'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      cancelledAt: (data['cancelledAt'] as Timestamp?)?.toDate(),
    );
  }

  // Copy with method for updating fields
  Appointment copyWith({
    AppointmentStatus? status,
    DateTime? cancelledAt,
  }) {
    return Appointment(
      appointmentId: appointmentId,
      userId: userId,
      expertId: expertId,
      expertName: expertName,
      expertAvatarUrl: expertAvatarUrl,
      callType: callType,
      appointmentDate: appointmentDate,
      durationMinutes: durationMinutes,
      price: price,
      status: status ?? this.status,
      userNotes: userNotes,
      createdAt: createdAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }
}
