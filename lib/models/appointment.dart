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
  final double expertBasePrice; // ✅ NEW: Lưu base price của expert tại thời điểm book
  
  final CallType callType;
  final DateTime appointmentDate;
  final int durationMinutes;
  
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
    required this.expertBasePrice, // ✅ NEW
    required this.callType,
    required this.appointmentDate,
    required this.durationMinutes,
    this.status = AppointmentStatus.confirmed,
    this.userNotes,
    DateTime? createdAt,
    this.cancelledAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // ✅ Getter: Tính giá động
  double get price {
    return calculatePrice(
      expertBasePrice: expertBasePrice,
      callType: callType,
      duration: durationMinutes,
    );
  }

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

  // ✅ Calculate price based on expert base price, call type and duration
  static double calculatePrice({
    required double expertBasePrice,
    required CallType callType,
    required int duration,
  }) {
    double finalPrice = expertBasePrice;
    
    // Voice Call = 67% of Video Call
    if (callType == CallType.voice) {
      finalPrice = finalPrice * 0.67;
    }
    
    // 30min = 50% of 60min
    if (duration == 30) {
      finalPrice = finalPrice * 0.5;
    }
    
    return finalPrice;
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'appointmentId': appointmentId,
      'userId': userId,
      'expertId': expertId,
      'expertName': expertName,
      'expertAvatarUrl': expertAvatarUrl,
      'expertBasePrice': expertBasePrice, // ✅ NEW
      'callType': callType.name,
      'appointmentDate': Timestamp.fromDate(appointmentDate),
      'durationMinutes': durationMinutes,
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
      expertBasePrice: (data['expertBasePrice'] ?? 150000.0).toDouble(), // ✅ NEW
      callType: CallType.values.firstWhere(
        (e) => e.name == data['callType'],
        orElse: () => CallType.video,
      ),
      appointmentDate: (data['appointmentDate'] as Timestamp).toDate(),
      durationMinutes: data['durationMinutes'] ?? 60,
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
      expertBasePrice: expertBasePrice, // ✅ NEW
      callType: callType,
      appointmentDate: appointmentDate,
      durationMinutes: durationMinutes,
      status: status ?? this.status,
      userNotes: userNotes,
      createdAt: createdAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }
}
