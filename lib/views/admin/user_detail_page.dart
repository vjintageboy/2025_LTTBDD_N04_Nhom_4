import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/app_user.dart';
import '../../core/constants/app_colors.dart';

/// Admin user detail — read / update / delete a single user.
/// Pops with `true` when something changed so the list can reload.
class UserDetailPage extends StatefulWidget {
  final Map<String, dynamic> data;

  const UserDetailPage({super.key, required this.data});

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  static const Color _kBg = Color(0xFFDBFCDF);

  final _supabase = Supabase.instance.client;
  late final AppUser _user = AppUser.fromMap(widget.data);

  late final TextEditingController _nameController =
      TextEditingController(text: _user.displayName);
  late String? _gender = widget.data['gender'] as String?;
  late DateTime? _dob = widget.data['date_of_birth'] != null
      ? DateTime.tryParse(widget.data['date_of_birth'].toString())
      : null;
  late bool _isBanned = widget.data['is_banned'] as bool? ?? false;
  late String? _banReason = widget.data['ban_reason'] as String?;

  bool _dirty = false; // any change made → pop(true)
  bool _isSaving = false;

  DateTime? get _lastLogin => widget.data['last_login'] != null
      ? DateTime.tryParse(widget.data['last_login'].toString())
      : null;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _userInitial() {
    final name = _user.displayName.trim();
    if (name.isNotEmpty) return name.characters.first.toUpperCase();
    final email = _user.email.trim();
    if (email.isNotEmpty) return email.characters.first.toUpperCase();
    return '?';
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final initial = _dob ?? DateTime(2000);
    DateTime? picked = initial;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _DobPickerSheet(
        initial: initial,
        firstDate: DateTime(1900),
        lastDate: now,
        onChanged: (d) => picked = d,
      ),
    );

    if (picked != null && picked != _dob) {
      setState(() {
        _dob = picked;
        _dirty = true;
      });
    }
  }

  // ---- Update ----
  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await _supabase.from('users').update({
        'full_name': _nameController.text.trim(),
        'gender': _gender,
        'date_of_birth': _dob?.toIso8601String(),
      }).eq('id', _user.id);
      _dirty = true;
      _snack('Đã lưu thay đổi');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _snack('Lỗi: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ---- Ban / Unban (update) ----
  Future<void> _toggleBan() async {
    if (_isBanned) {
      try {
        await _supabase.from('users').update({
          'is_banned': false,
          'ban_reason': null,
        }).eq('id', _user.id);
        setState(() {
          _isBanned = false;
          _banReason = null;
          _dirty = true;
        });
        _snack('Đã mở khóa người dùng');
      } catch (e) {
        _snack('Lỗi: $e');
      }
      return;
    }

    final reason = await _showBanDialog();
    if (reason == null) return;
    try {
      await _supabase.from('users').update({
        'is_banned': true,
        'ban_reason': reason,
      }).eq('id', _user.id);
      setState(() {
        _isBanned = true;
        _banReason = reason;
        _dirty = true;
      });
      _snack('Đã khóa người dùng');
    } catch (e) {
      _snack('Lỗi: $e');
    }
  }

  // ---- Delete ----
  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Xóa người dùng'),
        content: Text('Bạn có chắc muốn xóa ${_user.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _supabase.from('users').delete().eq('id', _user.id);
      _snack('Đã xóa người dùng');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _snack('Lỗi: $e');
    }
  }

  Future<String?> _showBanDialog() {
    String? reason;
    return showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Khóa người dùng'),
        content: TextField(
          decoration: const InputDecoration(hintText: 'Lý do khóa...'),
          onChanged: (v) => reason = v,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, reason),
            child: const Text('Khóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _dirty);
      },
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          backgroundColor: _kBg,
          elevation: 0,
          foregroundColor: AppColors.osOnSurface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _dirty),
          ),
          title: Text(
            'Chi tiết người dùng',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: AppColors.osOnSurface,
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Identity header
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.osPrimaryContainer,
                  child: Text(
                    _userInitial(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.osOnPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _user.email,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: AppColors.osOnSurfaceVariant,
                    ),
                  ),
                ),
                if (_isBanned)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'BỊ KHÓA',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // ---- Editable fields (Update) ----
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Họ tên', style: _labelStyle),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    style: GoogleFonts.manrope(color: AppColors.osOnSurface),
                    onChanged: (_) => _dirty = true,
                    decoration: _fieldDecoration('Nhập họ tên'),
                  ),
                  const SizedBox(height: 16),
                  Text('Giới tính', style: _labelStyle),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    initialValue: _gender,
                    style: GoogleFonts.manrope(color: AppColors.osOnSurface),
                    decoration: _fieldDecoration('Chưa chọn'),
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('Nam')),
                      DropdownMenuItem(value: 'female', child: Text('Nữ')),
                      DropdownMenuItem(value: 'other', child: Text('Khác')),
                    ],
                    onChanged: (v) => setState(() {
                      _gender = v;
                      _dirty = true;
                    }),
                  ),
                  const SizedBox(height: 16),
                  Text('Ngày sinh', style: _labelStyle),
                  const SizedBox(height: 8),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _pickDob,
                      borderRadius: BorderRadius.circular(14),
                      child: InputDecorator(
                        decoration: _fieldDecoration(null).copyWith(
                          suffixIcon: const Icon(
                            Icons.calendar_today_rounded,
                            size: 18,
                            color: AppColors.osPrimary,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.cake_rounded,
                              size: 18,
                              color: AppColors.osOnSurfaceVariant,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _dob != null ? _formatDate(_dob!) : 'Chọn ngày sinh',
                              style: GoogleFonts.manrope(
                                fontSize: 15,
                                fontWeight: _dob != null
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: _dob != null
                                    ? AppColors.osOnSurface
                                    : AppColors.osOnSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ---- Read-only info ----
            _card(
              child: Column(
                children: [
                  _infoRow(Icons.local_fire_department_outlined, 'Streak',
                      '${_user.streakCount} ngày'),
                  _infoRow(
                    Icons.event_outlined,
                    'Tham gia',
                    _user.createdAt != null
                        ? _formatDate(_user.createdAt!)
                        : 'N/A',
                  ),
                  _infoRow(
                    Icons.login_outlined,
                    'Đăng nhập gần nhất',
                    _lastLogin != null ? _formatDate(_lastLogin!) : 'Chưa có',
                  ),
                  if (_isBanned && _banReason != null && _banReason!.isNotEmpty)
                    _infoRow(Icons.warning_amber_rounded, 'Lý do khóa',
                        _banReason!),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ---- Save (Update) ----
            FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.osPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Lưu thay đổi',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _toggleBan,
                    icon: Icon(
                      _isBanned ? Icons.check_circle_outline : Icons.block,
                      size: 18,
                      color: _isBanned
                          ? AppColors.osPrimary
                          : Colors.red.shade700,
                    ),
                    label: Text(_isBanned ? 'Mở khóa' : 'Khóa'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _isBanned
                          ? AppColors.osPrimary
                          : Colors.red.shade700,
                      side: BorderSide(
                        color: _isBanned
                            ? AppColors.osOutlineVariant
                            : Colors.red.shade200,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _delete,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Xóa'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---- small helpers ----
  TextStyle get _labelStyle => GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.osOnSurfaceVariant,
      );

  InputDecoration _fieldDecoration(String? hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.manrope(color: AppColors.osOnSurfaceVariant),
        filled: true,
        fillColor: AppColors.osSurfaceContainer,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.osPrimary, width: 2),
        ),
      );

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.osSurfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F0B361D),
              blurRadius: 32,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: child,
      );

  Widget _infoRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.osOnSurfaceVariant),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: AppColors.osOnSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.osOnSurface,
                ),
              ),
            ),
          ],
        ),
      );
}

/// Premium bottom-sheet date picker with Cupertino-style wheel pickers.
class _DobPickerSheet extends StatefulWidget {
  final DateTime initial;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onChanged;

  const _DobPickerSheet({
    required this.initial,
    required this.firstDate,
    required this.lastDate,
    required this.onChanged,
  });

  @override
  State<_DobPickerSheet> createState() => _DobPickerSheetState();
}

class _DobPickerSheetState extends State<_DobPickerSheet> {
  late int _day;
  late int _month;
  late int _year;

  static const Color _kBg = Color(0xFFF4FAF5);
  static const Color _kPrimary = AppColors.osPrimary;
  static const Color _kTextPrimary = Color(0xFF1B3A26);
  static const Color _kTextSecondary = Color(0xFF6B8A7A);

  late final List<int> _days = List.generate(
    DateTime(_year, _month + 1, 0).day,
    (i) => i + 1,
  );

  late final List<int> _years = List.generate(
    widget.lastDate.year - widget.firstDate.year + 1,
    (i) => widget.firstDate.year + i,
  ).reversed.toList();

  static const List<String> _monthNames = [
    'Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4',
    'Tháng 5', 'Tháng 6', 'Tháng 7', 'Tháng 8',
    'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12',
  ];

  @override
  void initState() {
    super.initState();
    _year = widget.initial.year;
    _month = widget.initial.month;
    _day = widget.initial.day;
    _clampDay();
  }

  void _clampDay() {
    final maxDay = DateTime(_year, _month + 1, 0).day;
    if (_day > maxDay) _day = maxDay;
  }

  void _onYearChanged(int y) {
    setState(() {
      _year = y;
      _clampDay();
    });
    _emit();
  }

  void _onMonthChanged(int m) {
    setState(() {
      _month = m;
      _clampDay();
    });
    _emit();
  }

  void _onDayChanged(int d) {
    setState(() => _day = d);
    _emit();
  }

  void _emit() => widget.onChanged(DateTime(_year, _month, _day));

  String _formatPreview() {
    final d = DateTime(_year, _month, _day);
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.45,
      decoration: const BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildHeader(),
          _buildPreview(),
          Expanded(child: _buildPickers()),
          _buildConfirmButton(),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }

  Widget _buildHandle() => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: _kTextSecondary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Chọn ngày sinh',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _kTextPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded, color: _kTextSecondary),
            ),
          ],
        ),
      );

  Widget _buildPreview() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _kPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _formatPreview(),
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _kPrimary,
              letterSpacing: 1,
            ),
          ),
        ),
      );

  Widget _buildPickers() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: _WheelColumn(
                items: _years,
                selected: _year,
                label: 'Năm',
                format: (v) => '$v',
                onChanged: _onYearChanged,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              flex: 3,
              child: _WheelColumn(
                items: List.generate(12, (i) => i + 1),
                selected: _month,
                label: 'Tháng',
                format: (v) => _monthNames[v - 1],
                onChanged: _onMonthChanged,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              flex: 2,
              child: _WheelColumn(
                items: _days,
                selected: _day,
                label: 'Ngày',
                format: (v) => v.toString().padLeft(2, '0'),
                onChanged: _onDayChanged,
              ),
            ),
          ],
        ),
      );

  Widget _buildConfirmButton() => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              backgroundColor: _kPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              'Xác nhận',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
}

/// Single scroll-wheel column for day / month / year.
class _WheelColumn extends StatelessWidget {
  final List<int> items;
  final int selected;
  final String label;
  final String Function(int) format;
  final ValueChanged<int> onChanged;

  const _WheelColumn({
    required this.items,
    required this.selected,
    required this.label,
    required this.format,
    required this.onChanged,
  });

  static const double _itemExtent = 40.0;

  @override
  Widget build(BuildContext context) {
    final index = items.indexOf(selected);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _DobPickerSheetState._kTextSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: _itemExtent * 5,
          child: ListWheelScrollView.useDelegate(
            controller: FixedExtentScrollController(initialItem: index),
            itemExtent: _itemExtent,
            physics: const FixedExtentScrollPhysics(),
            diameterRatio: 1.8,
            perspective: 0.003,
            onSelectedItemChanged: (i) => onChanged(items[i]),
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: items.length,
              builder: (context, i) {
                final isSelected = items[i] == selected;
                return Center(
                  child: Text(
                    format(items[i]),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isSelected ? 20 : 16,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                      color: isSelected
                          ? _DobPickerSheetState._kTextPrimary
                          : _DobPickerSheetState._kTextSecondary
                              .withValues(alpha: 0.5),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
