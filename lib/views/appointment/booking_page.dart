import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/expert.dart';
import '../../models/appointment.dart';
import '../../services/appointment_service.dart';
import 'widgets/call_type_selector.dart';
import 'widgets/duration_selector.dart';
import 'mock_payment_page.dart';

class BookingPage extends StatefulWidget {
  final Expert expert;

  const BookingPage({
    super.key,
    required this.expert,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final AppointmentService _appointmentService = AppointmentService();
  final TextEditingController _notesController = TextEditingController();

  // Selections
  CallType _selectedCallType = CallType.video;
  int _selectedDuration = 60;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String? _selectedTimeSlot;

  // Data
  List<String> _availableTimeSlots = [];
  List<String> _bookedTimeSlots = [];
  bool _isLoadingSlots = false;

  @override
  void initState() {
    super.initState();
    // Don't auto-select a day - let user choose
    _focusedDay = DateTime.now();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableSlots(DateTime date) async {
    setState(() => _isLoadingSlots = true);

    try {
      // Check if expert is available on this day
      final weekday = DateFormat('EEEE').format(date);
      if (!widget.expert.availability.contains(weekday)) {
        // Expert not available on this day - show no slots
        setState(() {
          _availableTimeSlots = [];
          _isLoadingSlots = false;
        });
        return;
      }

      // Get booked slots from Firestore
      _bookedTimeSlots = await _appointmentService.getBookedTimeSlots(
        widget.expert.expertId,
        date,
      );

      // Generate all possible slots (09:00 - 17:00)
      final allSlots = _appointmentService.generateTimeSlots(
        startTime: '09:00',
        endTime: '17:00',
        intervalMinutes: _selectedDuration,
      );

      // Filter out booked slots and past times
      _availableTimeSlots = allSlots.where((slot) {
        if (_bookedTimeSlots.contains(slot)) return false;

        // If selected day is today, filter out past times
        if (_isSameDay(date, DateTime.now())) {
          final slotTime = _parseSlotTime(date, slot);
          final minAdvanceTime = DateTime.now().add(const Duration(hours: 3));
          return slotTime.isAfter(minAdvanceTime);
        }

        return true;
      }).toList();

      setState(() => _isLoadingSlots = false);
    } catch (e) {
      setState(() => _isLoadingSlots = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading slots: $e')),
        );
      }
    }
  }

  DateTime _parseSlotTime(DateTime date, String slot) {
    final parts = slot.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isDayAvailable(DateTime day) {
    // Check if day is in expert's availability
    final weekday = DateFormat('EEEE').format(day);
    return widget.expert.availability.contains(weekday);
  }

  double get _currentPrice {
    return Appointment.calculatePrice(
      expertBasePrice: widget.expert.pricePerSession,
      callType: _selectedCallType,
      duration: _selectedDuration,
    );
  }

  String _formatPrice(double price) {
    final intPrice = price.toInt();
    final formatter = intPrice.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '₫$formatter';
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!_isDayAvailable(selectedDay)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.expert.fullName} is not available on ${DateFormat('EEEE').format(selectedDay)}',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _selectedTimeSlot = null; // Reset time slot
    });

    _loadAvailableSlots(selectedDay);
  }

  void _onDurationChanged(int duration) {
    setState(() {
      _selectedDuration = duration;
      _selectedTimeSlot = null; // Reset time slot
    });

    if (_selectedDay != null) {
      _loadAvailableSlots(_selectedDay!);
    }
  }

  Future<void> _confirmBooking() async {
    if (_selectedDay == null || _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select date and time'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first')),
      );
      return;
    }

    // Parse selected date and time
    final appointmentDateTime = _parseSlotTime(_selectedDay!, _selectedTimeSlot!);

    // Create appointment
    final appointment = Appointment(
      appointmentId: '', // Will be set by service
      userId: user.uid,
      expertId: widget.expert.expertId,
      expertName: widget.expert.displayName,
      expertAvatarUrl: widget.expert.avatarUrl,
      expertBasePrice: widget.expert.pricePerSession, // ✅ Save expert base price
      callType: _selectedCallType,
      appointmentDate: appointmentDateTime,
      durationMinutes: _selectedDuration,
      userNotes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
      ),
    );

    // Create appointment
    final appointmentId = await _appointmentService.createAppointment(appointment);

    if (mounted) {
      Navigator.pop(context); // Close loading

      if (appointmentId != null) {
        // Success - navigate to mock payment
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MockPaymentPage(
              appointment: appointment,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to book appointment'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Book Appointment',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Expert Info Card
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: widget.expert.avatarUrl != null
                        ? NetworkImage(widget.expert.avatarUrl!)
                        : null,
                    child: widget.expert.avatarUrl == null
                        ? Text(
                            widget.expert.fullName[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.expert.displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.expert.specialization,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Call Type Selector
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: CallTypeSelector(
                selectedType: _selectedCallType,
                onChanged: (type) {
                  setState(() => _selectedCallType = type);
                },
              ),
            ),
            const SizedBox(height: 8),

            // Duration Selector
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: DurationSelector(
                selectedDuration: _selectedDuration,
                callType: _selectedCallType,
                expertBasePrice: widget.expert.pricePerSession, // ✅ Pass expert base price
                onChanged: _onDurationChanged,
              ),
            ),
            const SizedBox(height: 8),

            // Calendar
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Date',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TableCalendar(
                    firstDay: DateTime.now(),
                    lastDay: DateTime.now().add(const Duration(days: 14)),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => _selectedDay != null && _isSameDay(day, _selectedDay!),
                    onDaySelected: _onDaySelected,
                    calendarFormat: CalendarFormat.month,
                    enabledDayPredicate: (day) {
                      final now = DateTime.now();
                      final minDate = now.add(const Duration(hours: 3));
                      return day.isAfter(minDate.subtract(const Duration(days: 1))) &&
                          _isDayAvailable(day);
                    },
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                      disabledTextStyle: TextStyle(color: Colors.grey.shade300),
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Helper message when no date selected
            if (_selectedDay == null)
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.touch_app,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Select a date to view available time slots',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose a date from the calendar above',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Time Slots
            if (_selectedDay != null) ...[
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Time Slots - ${DateFormat('EEE, MMM d').format(_selectedDay!)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_isLoadingSlots)
                      const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF4CAF50),
                        ),
                      )
                    else if (_availableTimeSlots.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Icon(
                                Icons.event_busy,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No available slots for this day',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isDayAvailable(_selectedDay!)
                                    ? 'All slots are fully booked'
                                    : 'Expert is not available on ${DateFormat('EEEE').format(_selectedDay!)}s',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableTimeSlots.map((slot) {
                          final isSelected = _selectedTimeSlot == slot;
                          return InkWell(
                            onTap: () {
                              setState(() => _selectedTimeSlot = slot);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF4CAF50)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF4CAF50)
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Text(
                                slot,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey.shade800,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Notes - Only show when date is selected
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notes (Optional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Any notes for the expert?',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF4CAF50),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Cancellation Policy
              Container(
                width: double.infinity,
                color: Colors.orange.shade50,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You can cancel up to 4 hours before your appointment',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ],

            const SizedBox(height: 80),
          ],
        ),
      ),

      // Bottom Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatPrice(_currentPrice),
                    style: GoogleFonts.roboto(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ElevatedButton(
                  onPressed: (_selectedDay != null && _selectedTimeSlot != null)
                      ? _confirmBooking
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Continue to Payment',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
