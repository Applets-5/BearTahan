import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/audio_contexts.dart';

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
  late final Future<void> _audioContextReady;
  bool _isPlaying = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _audioContextReady = _player.setAudioContext(promptAudioContext());
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
      await _audioContextReady;
      if (hasUrl) {
        await ref.read(ttsServiceProvider).stop();
        await _player.stop();
        Source source = UrlSource(widget.url!);
        try {
          final cachedFile = await DefaultCacheManager().getFileFromCache(
            widget.url!,
          );
          if (cachedFile != null) {
            source = DeviceFileSource(cachedFile.file.path);
          }
        } catch (error) {
          debugPrint('Unable to read cached prompt audio: $error');
        }
        await _player.play(source);
      } else if (hasText) {
        final ttsService = ref.read(ttsServiceProvider);
        await ttsService.stop();
        await _player.stop();
        if (mounted) setState(() => _isPlaying = true);
        String? cachedPath;
        try {
          cachedPath = await ttsService.cachedAudioPath(
            widget.textToSpeak!,
            language: widget.language,
          );
        } catch (error) {
          debugPrint('Unable to read cached TTS prompt: $error');
        }
        if (cachedPath != null) {
          await _player.play(DeviceFileSource(cachedPath));
        } else {
          await ttsService.speak(
            widget.textToSpeak!,
            language: widget.language,
          );
          if (mounted) setState(() => _isPlaying = false);
        }
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
