import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import '../../core/services/localization_service.dart';
import '../../models/meditation.dart';
import 'dart:math' as math;

class MeditationDetailPage extends StatefulWidget {
  final Meditation meditation;

  const MeditationDetailPage({super.key, required this.meditation});

  @override
  State<MeditationDetailPage> createState() => _MeditationDetailPageState();
}

class _MeditationDetailPageState extends State<MeditationDetailPage>
    with SingleTickerProviderStateMixin {
  final ap.AudioPlayer _audioPlayer = ap.AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  // Animation controller for waveform
  late AnimationController _waveAnimationController;
  late Animation<double> _waveAnimation;
  final List<double> _waveHeights = List.generate(30, (index) {
    // Create varied heights for more natural look
    final random = math.Random(index);
    return 0.2 + (random.nextDouble() * 0.4); // Heights between 0.2 and 0.6
  });
  int _animationFrame = 0;

  @override
  void initState() {
    super.initState();
    _setupAudioPlayer();
    _setupWaveAnimation();
  }

  void _setupWaveAnimation() {
    _waveAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );

    _waveAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _waveAnimationController,
              curve: Curves.linear,
            ),
          )
          ..addListener(() {
            if (_isPlaying && mounted) {
              setState(() {
                _animationFrame++;
                // Create smooth wave-like motion with varied patterns
                for (int i = 0; i < _waveHeights.length; i++) {
                  // Multiple overlapping sine waves for natural effect
                  final time = _animationFrame * 0.08;
                  final position = i / _waveHeights.length;

                  // Main wave
                  final wave1 = math.sin(time + position * math.pi * 2) * 0.25;

                  // Secondary wave (different frequency)
                  final wave2 =
                      math.sin(time * 1.3 + position * math.pi * 1.5) * 0.2;

                  // Tertiary wave (slower, adds depth)
                  final wave3 =
                      math.sin(time * 0.7 + position * math.pi * 2.5) * 0.15;

                  // High frequency variation
                  final wave4 =
                      math.sin(time * 2.1 + position * math.pi * 3) * 0.1;

                  // Combine all waves
                  _waveHeights[i] = 0.4 + wave1 + wave2 + wave3 + wave4;

                  // Smooth clamping
                  _waveHeights[i] = _waveHeights[i].clamp(0.2, 0.9);
                }
              });
            }
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed && _isPlaying) {
              _waveAnimationController.forward(from: 0.0);
            }
          });
  }

  void _setupAudioPlayer() {
    // Listen to player state changes
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == ap.PlayerState.playing;
        });
      }
    });

    // Listen to duration changes
    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });

    // Listen to position changes
    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });

    // Listen to completion
    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
  }

  Future<void> _playPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      _waveAnimationController.stop();
    } else {
      if (widget.meditation.audioUrl != null &&
          widget.meditation.audioUrl!.isNotEmpty) {
        // Play from URL
        await _audioPlayer.play(ap.UrlSource(widget.meditation.audioUrl!));
        _waveAnimationController.forward();
      } else {
        // If no URL, show a message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Audio file not available'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _stop() async {
    await _audioPlayer.stop();
    _waveAnimationController.stop();
    _waveAnimationController.reset();
    setState(() {
      _position = Duration.zero;
      _animationFrame = 0;
      // Reset wave heights to base pattern
      for (int i = 0; i < _waveHeights.length; i++) {
        _waveHeights[i] = 0.3 + (math.Random(i).nextDouble() * 0.3);
      }
    });
  }

  Future<void> _seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Color _getCategoryColor() {
    switch (widget.meditation.category) {
      case MeditationCategory.stress:
        return const Color(0xFFE8F5E9);
      case MeditationCategory.anxiety:
        return const Color(0xFFE3F2FD);
      case MeditationCategory.sleep:
        return const Color(0xFFD1F2EB);
      case MeditationCategory.focus:
        return const Color(0xFFFFF3E0);
    }
  }

  Color _getCategoryDarkColor() {
    switch (widget.meditation.category) {
      case MeditationCategory.stress:
        return const Color(0xFF4CAF50);
      case MeditationCategory.anxiety:
        return const Color(0xFF2196F3);
      case MeditationCategory.sleep:
        return const Color(0xFF00BCD4);
      case MeditationCategory.focus:
        return const Color(0xFFFF9800);
    }
  }

  String _getCategoryText() {
    switch (widget.meditation.category) {
      case MeditationCategory.stress:
        return context.l10n.stress.toUpperCase();
      case MeditationCategory.anxiety:
        return context.l10n.anxiety.toUpperCase();
      case MeditationCategory.sleep:
        return context.l10n.sleep.toUpperCase();
      case MeditationCategory.focus:
        return context.l10n.focus.toUpperCase();
    }
  }

  String _getLevelText() {
    switch (widget.meditation.level) {
      case MeditationLevel.beginner:
        return context.l10n.beginner.toUpperCase();
      case MeditationLevel.intermediate:
        return context.l10n.intermediate.toUpperCase();
      case MeditationLevel.advanced:
        return context.l10n.advanced.toUpperCase();
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _waveAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor();
    final categoryDarkColor = _getCategoryDarkColor();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              categoryColor,
              categoryColor.withValues(alpha: 0.6),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with back button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(IconsaxPlusLinear.arrow_left),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        // TODO: Add to favorites
                      },
                      icon: const Icon(IconsaxPlusLinear.heart),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // Category and Level badges
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: categoryDarkColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _getCategoryText(),
                              style: TextStyle(
                                color: categoryDarkColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _getLevelText(),
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Title
                      Text(
                        widget.meditation.title,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          height: 1.2,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Duration and Rating
                      Row(
                        children: [
                          Row(
                            children: [
                              Icon(
                                IconsaxPlusLinear.clock,
                                size: 20,
                                color: Colors.black54,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${widget.meditation.duration} ${context.l10n.min}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 24),
                          Row(
                            children: [
                              const Icon(
                                IconsaxPlusBold.star,
                                size: 20,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${widget.meditation.rating.toStringAsFixed(1)} (${widget.meditation.totalReviews})',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Description
                      Text(
                        context.l10n.about,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.meditation.description,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Audio Player Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: categoryDarkColor.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Enhanced Waveform visualization
                            Container(
                              height: 90,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: List.generate(_waveHeights.length, (
                                  index,
                                ) {
                                  // Static pattern for paused state
                                  final staticPattern = [
                                    0.3,
                                    0.5,
                                    0.4,
                                    0.6,
                                    0.7,
                                    0.8,
                                    0.75,
                                    0.85,
                                    0.9,
                                    0.95,
                                    0.9,
                                    0.85,
                                    0.8,
                                    0.9,
                                    0.85,
                                    0.9,
                                    0.95,
                                    0.9,
                                    0.8,
                                    0.75,
                                    0.7,
                                    0.65,
                                    0.6,
                                    0.5,
                                    0.45,
                                    0.4,
                                    0.35,
                                    0.4,
                                    0.3,
                                    0.35,
                                  ];

                                  // Calculate progress percentage for this bar
                                  final progress = _duration.inSeconds > 0
                                      ? _position.inSeconds /
                                            _duration.inSeconds
                                      : 0.0;
                                  final barProgress =
                                      (index / _waveHeights.length);
                                  final isPlayed = barProgress <= progress;

                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 80),
                                    curve: Curves.easeInOutSine,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                    ),
                                    width: 4,
                                    height: _isPlaying
                                        ? 20 + (_waveHeights[index] * 50)
                                        : 20 +
                                              (staticPattern[index %
                                                      staticPattern.length] *
                                                  50),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: isPlayed
                                            ? [
                                                categoryDarkColor,
                                                categoryDarkColor.withValues(alpha: 
                                                  0.7,
                                                ),
                                              ]
                                            : [
                                                Colors.grey.shade300,
                                                Colors.grey.shade200,
                                              ],
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                      boxShadow: isPlayed && _isPlaying
                                          ? [
                                              BoxShadow(
                                                color: categoryDarkColor
                                                    .withValues(alpha: 0.3),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : [],
                                    ),
                                  );
                                }),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Progress bar
                            Column(
                              children: [
                                SliderTheme(
                                  data: SliderThemeData(
                                    trackHeight: 4,
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 8,
                                    ),
                                    overlayShape: const RoundSliderOverlayShape(
                                      overlayRadius: 16,
                                    ),
                                    activeTrackColor: categoryDarkColor,
                                    inactiveTrackColor: categoryColor,
                                    thumbColor: categoryDarkColor,
                                    overlayColor: categoryDarkColor.withValues(alpha: 
                                      0.2,
                                    ),
                                  ),
                                  child: Slider(
                                    min: 0,
                                    max: _duration.inSeconds.toDouble(),
                                    value: _position.inSeconds.toDouble().clamp(
                                      0,
                                      _duration.inSeconds.toDouble(),
                                    ),
                                    onChanged: (value) {
                                      _seek(Duration(seconds: value.toInt()));
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDuration(_position),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      Text(
                                        _formatDuration(_duration),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Control buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Rewind 15s
                                IconButton(
                                  onPressed: () {
                                    final newPosition =
                                        _position - const Duration(seconds: 15);
                                    _seek(
                                      newPosition < Duration.zero
                                          ? Duration.zero
                                          : newPosition,
                                    );
                                  },
                                  icon: const Icon(IconsaxPlusLinear.backward_10_seconds),
                                  iconSize: 32,
                                  color: categoryDarkColor,
                                ),

                                const SizedBox(width: 20),

                                // Play/Pause button
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        categoryDarkColor,
                                        categoryDarkColor.withValues(alpha: 0.7),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: categoryDarkColor.withValues(alpha: 
                                          0.4,
                                        ),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    onPressed: _playPause,
                                    icon: Icon(
                                      _isPlaying
                                          ? IconsaxPlusBold.pause
                                          : IconsaxPlusBold.play,
                                      size: 40,
                                    ),
                                    iconSize: 40,
                                    color: Colors.white,
                                    padding: const EdgeInsets.all(20),
                                  ),
                                ),

                                const SizedBox(width: 20),

                                // Forward 15s
                                IconButton(
                                  onPressed: () {
                                    final newPosition =
                                        _position + const Duration(seconds: 15);
                                    _seek(
                                      newPosition > _duration
                                          ? _duration
                                          : newPosition,
                                    );
                                  },
                                  icon: const Icon(IconsaxPlusLinear.forward_10_seconds),
                                  iconSize: 32,
                                  color: categoryDarkColor,
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Stop button
                            if (_isPlaying || _position > Duration.zero)
                              TextButton.icon(
                                onPressed: _stop,
                                icon: const Icon(IconsaxPlusBold.stop),
                                label: Text(context.l10n.stop),
                                style: TextButton.styleFrom(
                                  foregroundColor: categoryDarkColor,
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
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
