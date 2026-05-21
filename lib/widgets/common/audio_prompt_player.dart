import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AudioPromptPlayer extends StatefulWidget {
  final String url;
  final bool autoPlay;

  const AudioPromptPlayer({
    super.key,
    required this.url,
    this.autoPlay = false,
  });

  @override
  State<AudioPromptPlayer> createState() => _AudioPromptPlayerState();
}

class _AudioPromptPlayerState extends State<AudioPromptPlayer> {
  late AudioPlayer _player;
  bool _isPlaying = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    });

    if (widget.autoPlay) {
      _play();
    }
  }

  @override
  void didUpdateWidget(AudioPromptPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _hasError = false;
      if (widget.autoPlay) {
        _play();
      }
    }
  }

  Future<void> _play() async {
    if (widget.url.isEmpty) return;

    try {
      await _player.stop();
      await _player.play(UrlSource(widget.url));
      if (mounted) {
        setState(() {
          _hasError = false;
        });
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _hasError ? null : _play,
      iconSize: 48,
      icon: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: _isPlaying
              ? AppColors.accent.withAlpha(26)
              : AppColors.muted.withAlpha(128),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _hasError
              ? Icons.error_outline
              : _isPlaying
                  ? Icons.stop_rounded
                  : Icons.volume_up_rounded,
          color: _hasError
              ? AppColors.destructive
              : _isPlaying
                  ? AppColors.accent
                  : AppColors.primary,
        ),
      ),
    );
  }
}
