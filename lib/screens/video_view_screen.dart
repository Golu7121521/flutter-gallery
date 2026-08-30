import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../providers/favorites_provider.dart';
import '../providers/trash_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/viewer_action_bar.dart';
import '../widgets/more_options_sheet.dart';
import '../widgets/delete_confirm_dialog.dart';

class VideoViewScreen extends StatefulWidget {
  final List<AssetEntity> assets;
  final int initialIndex;

  const VideoViewScreen({
    super.key,
    required this.assets,
    required this.initialIndex,
  });

  @override
  State<VideoViewScreen> createState() => _VideoViewScreenState();
}

class _VideoViewScreenState extends State<VideoViewScreen> {
  late int _index;
  VideoPlayerController? _controller;
  bool _chromeVisible = true;
  bool _isLandscape = false;
  bool _loading = true;
  String? _error;
  bool _isLikelyCodecIssue = false;
  int _retryAttempt = 0;
  double _speed = 1.0;
  Timer? _hideTimer;

  // Gesture state
  double _dragStartVolume = 0;
  double _dragStartBrightness = 0;
  bool _isHolding = false;
  String? _seekFeedback;
  Timer? _seekFeedbackTimer;

  AssetEntity get _current => widget.assets[_index];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    try {
      WakelockPlus.enable();
    } catch (_) {
      // Wakelock is a nice-to-have; ignore if unsupported on this device.
    }
    _loadVideo();
  }

  Future<void> _loadVideo({bool isManualRetry = false, bool isInternalRetry = false}) async {
    if (!isInternalRetry) _retryAttempt = 0;
    setState(() {
      _loading = true;
      _error = null;
      _isLikelyCodecIssue = false;
    });

    // Detach and dispose the previous controller safely before creating
    // a new one, so its listener never fires against a disposed instance.
    final oldController = _controller;
    _controller = null;
    oldController?.removeListener(_onVideoTick);
    await oldController?.dispose();

    try {
      final controller = await _createController(preferContentUri: _retryAttempt == 0);
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      controller.addListener(_onVideoTick);
      setState(() {
        _controller = controller;
        _loading = false;
      });
      controller.play();
      _resetHideTimer();
    } catch (e) {
      final message = e.toString();
      final looksLikeCodecInit = message.contains('MediaCodecVideoRenderer') ||
          message.contains('ExoPlaybackException') ||
          message.contains('MediaCodec');

      // Codec initialization failures are sometimes transient, or specific
      // to one data-source strategy. Silently retry a couple of times —
      // alternating between content:// URI and a copied temp file — before
      // surfacing an error to the user.
      if (looksLikeCodecInit && _retryAttempt < 2) {
        _retryAttempt++;
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        return _loadVideo(isInternalRetry: true);
      }

      if (!mounted) return;
      setState(() {
        _loading = false;
        _isLikelyCodecIssue = looksLikeCodecInit;
        _error = 'This video could not be played.\n$message';
      });
    }
  }

  /// Builds a [VideoPlayerController] for the current asset.
  ///
  /// On Android we prefer a MediaStore `content://` URI (via
  /// `AssetEntity.getMediaUrl()`) over a copied temp file. `AssetEntity.file`
  /// copies the media into the app's cache first, and for large/high-bitrate
  /// videos (e.g. 1080p/4K camera recordings) that copy can occasionally be
  /// incomplete or have subtly different container metadata — which is a
  /// common real-world cause of `MediaCodecVideoRenderer` init failures even
  /// though `format_supported=YES`. Reading directly via content URI lets
  /// ExoPlayer pull the original, untouched file from the system.
  ///
  /// [preferContentUri] lets callers force the cached-file strategy instead
  /// (used as a fallback on retry, in case one strategy fails for a
  /// particular video/device combination but the other succeeds).
  Future<VideoPlayerController> _createController({bool preferContentUri = true}) async {
    if (preferContentUri && Platform.isAndroid) {
      final url = await _current.getMediaUrl();
      if (url != null && url.isNotEmpty) {
        return VideoPlayerController.contentUri(Uri.parse(url));
      }
      // Fall back to the cached file if a content URL isn't available.
    }

    final file = await _current.file;
    if (file == null) {
      throw Exception('Could not access this video file on device.');
    }
    return VideoPlayerController.file(file);
  }

  void _onVideoTick() {
    if (!mounted || _controller == null) return;
    final value = _controller!.value;
    if (value.position >= value.duration &&
        value.duration.inMilliseconds > 0 &&
        !value.isPlaying) {
      final autoplay = context.read<SettingsProvider>().autoplayNext;
      if (autoplay) _playNext();
    }
    setState(() {});
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _chromeVisible = false);
    });
  }

  void _toggleChrome() {
    setState(() => _chromeVisible = !_chromeVisible);
    if (_chromeVisible) _resetHideTimer();
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null) return;
    setState(() {
      c.value.isPlaying ? c.pause() : c.play();
    });
    _resetHideTimer();
  }

  void _seekBy(Duration offset) {
    final c = _controller;
    if (c == null) return;
    final newPos = c.value.position + offset;
    c.seekTo(newPos < Duration.zero ? Duration.zero : newPos);
    _resetHideTimer();
  }

  void _playNext() {
    if (_index < widget.assets.length - 1) {
      setState(() => _index++);
      _loadVideo();
    }
  }

  void _playPrevious() {
    if (_index > 0) {
      setState(() => _index--);
      _loadVideo();
    }
  }

  void _setSpeed(double speed) {
    _controller?.setPlaybackSpeed(speed);
    setState(() => _speed = speed);
  }

  void _rotate() {
    setState(() => _isLandscape = !_isLandscape);
    if (_isLandscape) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
  }

  Future<void> _share() async {
    final file = await _current.file;
    if (file != null) {
      await Share.shareXFiles([XFile(file.path)]);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDeleteConfirmDialog(context);
    if (!confirmed) return;
    final trash = context.read<TrashProvider>();
    trash.addToTrash(_current);
    await PhotoManager.editor.deleteWithIds([_current.id]);
    if (mounted) Navigator.pop(context);
  }

  void _showSeekFeedback(String text) {
    _seekFeedbackTimer?.cancel();
    setState(() => _seekFeedback = text);
    _seekFeedbackTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _seekFeedback = null);
    });
  }

  @override
  void dispose() {
    _controller?.removeListener(_onVideoTick);
    _controller?.dispose();
    _hideTimer?.cancel();
    _seekFeedbackTimer?.cancel();
    try {
      WakelockPlus.disable();
    } catch (_) {}
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final favorites = context.watch<FavoritesProvider>();
    final c = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      body: _error != null
          ? _buildErrorState()
          : c == null || !c.value.isInitialized
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : GestureDetector(
              onTap: _toggleChrome,
              onDoubleTapDown: (details) {
                final width = MediaQuery.of(context).size.width;
                if (details.globalPosition.dx < width / 2) {
                  _seekBy(const Duration(seconds: -10));
                  _showSeekFeedback('-10s');
                } else {
                  _seekBy(const Duration(seconds: 10));
                  _showSeekFeedback('+10s');
                }
              },
              onLongPressStart: settings.gestureControl
                  ? (_) {
                      setState(() => _isHolding = true);
                      _setSpeed(2.0);
                    }
                  : null,
              onLongPressEnd: settings.gestureControl
                  ? (_) {
                      setState(() => _isHolding = false);
                      _setSpeed(1.0);
                    }
                  : null,
              onVerticalDragStart: settings.gestureControl
                  ? (details) async {
                      _dragStartVolume = await VolumeController().getVolume();
                      _dragStartBrightness =
                          await ScreenBrightness().current;
                    }
                  : null,
              onVerticalDragUpdate: settings.gestureControl
                  ? (details) {
                      final width = MediaQuery.of(context).size.width;
                      final delta = -details.delta.dy / 200;
                      if (details.globalPosition.dx < width / 2) {
                        // Left side -> brightness
                        final newVal =
                            (_dragStartBrightness + delta).clamp(0.0, 1.0);
                        ScreenBrightness().setScreenBrightness(newVal);
                        _dragStartBrightness = newVal;
                      } else {
                        // Right side -> volume
                        final newVal =
                            (_dragStartVolume + delta).clamp(0.0, 1.0);
                        VolumeController().setVolume(newVal);
                        _dragStartVolume = newVal;
                      }
                    }
                  : null,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: AspectRatio(
                      aspectRatio: (c.value.aspectRatio.isFinite && c.value.aspectRatio > 0)
                          ? c.value.aspectRatio
                          : 16 / 9,
                      child: VideoPlayer(c),
                    ),
                  ),
                  if (_isHolding)
                    Positioned(
                      top: 40,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _pill('2x speed'),
                      ),
                    ),
                  if (_seekFeedback != null)
                    Center(child: _pill(_seekFeedback!)),
                  if (_chromeVisible) _buildTopBar(context),
                  if (_chromeVisible)
                    _buildBottomControls(context, c, favorites),
                ],
              ),
            ),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white70, size: 48),
              const SizedBox(height: 16),
              Text(
                _error ?? 'This video could not be played.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              if (_isLikelyCodecIssue) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'This looks like a device/emulator video decoder (codec) '
                    'limitation, not an app bug. It commonly happens on '
                    'Android emulators that lack full hardware AVC decoding. '
                    'Try a real device, a different emulator system image '
                    '(Google Play, x86_64, with Host GPU enabled), or a '
                    'differently-encoded video file.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back', style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () => _loadVideo(isManualRetry: true),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black54, Colors.transparent],
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const Spacer(),
              PopupMenuButton<double>(
                icon: const Icon(Icons.speed_rounded, color: Colors.white),
                onSelected: _setSpeed,
                itemBuilder: (_) => [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
                    .map((s) => PopupMenuItem(value: s, child: Text('${s}x')))
                    .toList(),
              ),
              IconButton(
                onPressed: _rotate,
                icon: const Icon(Icons.screen_rotation_rounded, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(
      BuildContext context, VideoPlayerController c, FavoritesProvider favorites) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(_formatDuration(c.value.position),
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2.5,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    ),
                    child: Slider(
                      value: c.value.position.inMilliseconds
                          .clamp(0, c.value.duration.inMilliseconds)
                          .toDouble(),
                      min: 0,
                      max: c.value.duration.inMilliseconds.toDouble().clamp(1, double.infinity),
                      activeColor: Colors.white,
                      inactiveColor: Colors.white30,
                      onChanged: (v) {
                        c.seekTo(Duration(milliseconds: v.toInt()));
                      },
                    ),
                  ),
                ),
                Text(_formatDuration(c.value.duration),
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _playPrevious,
                icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 32),
              ),
              IconButton(
                onPressed: () => _seekBy(const Duration(seconds: -10)),
                icon: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 28),
              ),
              IconButton(
                onPressed: _togglePlay,
                icon: Icon(
                  c.value.isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                  color: Colors.white,
                  size: 52,
                ),
              ),
              IconButton(
                onPressed: () => _seekBy(const Duration(seconds: 10)),
                icon: const Icon(Icons.forward_10_rounded, color: Colors.white, size: 28),
              ),
              IconButton(
                onPressed: _playNext,
                icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 32),
              ),
            ],
          ),
          ViewerActionBar(
            onShare: _share,
            onEdit: () {},
            onFavorite: () => favorites.toggle(_current.id),
            isFavorite: favorites.isFavorite(_current.id),
            onDelete: _delete,
            onMore: () => showMoreOptionsSheet(context, _current),
          ),
        ],
      ),
    );
  }
}
