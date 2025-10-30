import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment.dart';

class AppointmentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Create appointment
  Future<String?> createAppointment(Appointment appointment) async {
    try {
      final docRef = _db.collection('appointments').doc();
      final newAppointment = Appointment(
        appointmentId: docRef.id,
        userId: appointment.userId,
        expertId: appointment.expertId,
        expertName: appointment.expertName,
        expertAvatarUrl: appointment.expertAvatarUrl,
        expertBasePrice: appointment.expertBasePrice, // ✅ NEW
        callType: appointment.callType,
        appointmentDate: appointment.appointmentDate,
        durationMinutes: appointment.durationMinutes,
        status: AppointmentStatus.confirmed, // Auto-confirm
        userNotes: appointment.userNotes,
      );

      await docRef.set(newAppointment.toMap());
      return docRef.id;
    } catch (e) {
      print('❌ Error creating appointment: $e');
      return null;
    }
  }

  // Get user appointments
  Future<List<Appointment>> getUserAppointments(String userId) async {
    try {
      final snapshot = await _db
          .collection('appointments')
          .where('userId', isEqualTo: userId)
          .get();

      final appointments = snapshot.docs
          .map((doc) => Appointment.fromSnapshot(doc))
          .toList();
      
      // Sort trong code thay vì Firestore
      appointments.sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
      
      return appointments;
    } catch (e) {
      print('❌ Error getting appointments: $e');
      return [];
    }
  }

  // Stream user appointments (real-time)
  Stream<List<Appointment>> streamUserAppointments(String userId) {
    return _db
        .collection('appointments')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final appointments = snapshot.docs
              .map((doc) => Appointment.fromSnapshot(doc))
              .toList();
          
          // Sort trong code thay vì Firestore
          appointments.sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
          
          return appointments;
        });
  }

  // Cancel appointment
  Future<void> cancelAppointment(String appointmentId) async {
    try {
      await _db.collection('appointments').doc(appointmentId).update({
        'status': AppointmentStatus.cancelled.name,
        'cancelledAt': Timestamp.now(),
      });
    } catch (e) {
      print('❌ Error cancelling appointment: $e');
      rethrow;
    }
  }

  // Get booked time slots for expert on specific date
  Future<List<String>> getBookedTimeSlots(
    String expertId,
    DateTime date,
  ) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      // Simplified query - chỉ filter theo expertId
      final snapshot = await _db
          .collection('appointments')
          .where('expertId', isEqualTo: expertId)
          .get();

      // Filter trong code thay vì Firestore
      final bookedSlots = snapshot.docs
          .map((doc) => Appointment.fromSnapshot(doc))
          .where((apt) {
            // Filter: status = confirmed
            if (apt.status != AppointmentStatus.confirmed) return false;
            
            // Filter: date trong khoảng startOfDay -> endOfDay
            return apt.appointmentDate.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
                   apt.appointmentDate.isBefore(endOfDay.add(const Duration(seconds: 1)));
          })
          .map((apt) => _formatTimeSlot(apt.appointmentDate))
          .toList();

      return bookedSlots;
    } catch (e) {
      print('❌ Error getting booked slots: $e');
      return [];
    }
  }

  String _formatTimeSlot(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Generate available time slots
  List<String> generateTimeSlots({
    required String startTime,
    required String endTime,
    required int intervalMinutes,
  }) {
    final slots = <String>[];
    
    final start = _parseTime(startTime);
    final end = _parseTime(endTime);
    
    DateTime current = start;
    while (current.isBefore(end)) {
      final hour = current.hour.toString().padLeft(2, '0');
      final minute = current.minute.toString().padLeft(2, '0');
      slots.add('$hour:$minute');
      current = current.add(Duration(minutes: intervalMinutes));
    }
    
    return slots;
  }

  DateTime _parseTime(String time) {
    final parts = time.split(':');
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }
}
