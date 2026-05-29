import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_theme.dart';

class AudioPromptPlayer extends ConsumerStatefulWidget {
  final String? url;
  final String? textToSpeak;
  final bool autoPlay;
  final bool isSmall;
  final String? language;

  const AudioPromptPlayer({
    super.key,
    this.url,
    this.textToSpeak,
    this.autoPlay = false,
    this.isSmall = false,
    this.language,
  });

  @override
  ConsumerState<AudioPromptPlayer> createState() => _AudioPromptPlayerState();
}

class _AudioPromptPlayerState extends ConsumerState<AudioPromptPlayer> {
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
      WidgetsBinding.instance.addPostFrameCallback((_) => _play());
    }
  }

  @override
  void didUpdateWidget(AudioPromptPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url ||
        oldWidget.textToSpeak != widget.textToSpeak) {
      _hasError = false;
      if (widget.autoPlay) {
        _play();
      }
    }
  }

  Future<void> _play() async {
    final hasUrl = widget.url != null && widget.url!.isNotEmpty;
    final hasText =
        widget.textToSpeak != null && widget.textToSpeak!.isNotEmpty;

    if (!hasUrl && !hasText) return;

    try {
      if (hasUrl) {
        await ref.read(ttsServiceProvider).stop();
        await _player.stop();
        await _player.play(UrlSource(widget.url!));
      } else if (hasText) {
        await _player.stop();
        setState(() => _isPlaying = true);
        await ref
            .read(ttsServiceProvider)
            .speak(widget.textToSpeak!, language: widget.language);
        if (mounted) setState(() => _isPlaying = false);
      }

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
          _isPlaying = false;
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
    final double iconSize = widget.isSmall ? 20 : 32;
    final double padding = widget.isSmall ? AppSpacing.xs : AppSpacing.sm;

    final hasContent =
        (widget.url != null && widget.url!.isNotEmpty) ||
        (widget.textToSpeak != null && widget.textToSpeak!.isNotEmpty);

    if (!hasContent) return const SizedBox.shrink();

    return IconButton(
      onPressed: _hasError ? null : _play,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      icon: Container(
        padding: EdgeInsets.all(padding),
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
          size: iconSize,
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
