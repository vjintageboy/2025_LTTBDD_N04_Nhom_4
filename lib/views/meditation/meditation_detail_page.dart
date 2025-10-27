import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../models/meditation.dart';

class MeditationDetailPage extends StatefulWidget {
  final Meditation meditation;

  const MeditationDetailPage({
    super.key,
    required this.meditation,
  });

  @override
  State<MeditationDetailPage> createState() => _MeditationDetailPageState();
}

class _MeditationDetailPageState extends State<MeditationDetailPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    // Listen to player state changes
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
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
    } else {
      if (widget.meditation.audioUrl != null && widget.meditation.audioUrl!.isNotEmpty) {
        // Play from URL
        await _audioPlayer.play(UrlSource(widget.meditation.audioUrl!));
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
    setState(() {
      _position = Duration.zero;
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
    return widget.meditation.category.toString().split('.').last.toUpperCase();
  }

  String _getLevelText() {
    return widget.meditation.level.toString().split('.').last.toUpperCase();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
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
              categoryColor.withOpacity(0.6),
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
                      icon: const Icon(Icons.arrow_back),
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
                      icon: const Icon(Icons.favorite_border),
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
                              color: categoryDarkColor.withOpacity(0.2),
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
                              color: Colors.white.withOpacity(0.8),
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
                                Icons.access_time,
                                size: 20,
                                color: Colors.black54,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${widget.meditation.duration} min',
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
                                Icons.star,
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
                        'About',
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
                              color: categoryDarkColor.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Waveform visualization (placeholder)
                            Container(
                              height: 80,
                              decoration: BoxDecoration(
                                color: categoryColor.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    20,
                                    (index) => Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 2),
                                      width: 4,
                                      height: _isPlaying
                                          ? 20 + (index % 5) * 10
                                          : 10 + (index % 4) * 5,
                                      decoration: BoxDecoration(
                                        color: categoryDarkColor.withOpacity(
                                          _isPlaying ? 0.8 : 0.4,
                                        ),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                ),
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
                                    overlayColor: categoryDarkColor.withOpacity(0.2),
                                  ),
                                  child: Slider(
                                    min: 0,
                                    max: _duration.inSeconds.toDouble(),
                                    value: _position.inSeconds
                                        .toDouble()
                                        .clamp(0, _duration.inSeconds.toDouble()),
                                    onChanged: (value) {
                                      _seek(Duration(seconds: value.toInt()));
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                    final newPosition = _position - const Duration(seconds: 15);
                                    _seek(newPosition < Duration.zero ? Duration.zero : newPosition);
                                  },
                                  icon: const Icon(Icons.replay_10),
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
                                        categoryDarkColor.withOpacity(0.7),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: categoryDarkColor.withOpacity(0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    onPressed: _playPause,
                                    icon: Icon(
                                      _isPlaying ? Icons.pause : Icons.play_arrow,
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
                                    final newPosition = _position + const Duration(seconds: 15);
                                    _seek(newPosition > _duration ? _duration : newPosition);
                                  },
                                  icon: const Icon(Icons.forward_10),
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
                                icon: const Icon(Icons.stop),
                                label: const Text('Stop'),
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
