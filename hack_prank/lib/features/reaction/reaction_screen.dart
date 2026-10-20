import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/neon_button.dart';

enum _Step { explain, starting, preview, review, denied, unavailable }

/// Optional, post-reveal reaction photo.
///
/// The camera is opened only after the user reads the explanation and taps
/// "OPEN CAMERA"; a photo is only taken when they press the shutter, and only
/// saved to the gallery when they press SAVE. Nothing is ever uploaded. Audio
/// is never recorded.
class ReactionScreen extends StatefulWidget {
  const ReactionScreen({super.key});

  static const openCameraKey = Key('reaction-open-camera');

  @override
  State<ReactionScreen> createState() => _ReactionScreenState();
}

class _ReactionScreenState extends State<ReactionScreen> with WidgetsBindingObserver {
  _Step _step = _Step.explain;
  CameraController? _camera;
  XFile? _photo;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Release the camera whenever the app is not in the foreground.
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      if (_step == _Step.preview) {
        unawaited(_closeCamera());
        setState(() => _step = _Step.explain);
      }
    }
  }

  Future<void> _openCamera() async {
    setState(() => _step = _Step.starting);
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _step = _Step.unavailable);
        return;
      }
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      // The permission prompt (if any) appears here, after the user opted in.
      final controller = CameraController(front, ResolutionPreset.high, enableAudio: false);
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _camera = controller;
        _step = _Step.preview;
      });
    } on CameraException catch (e) {
      debugPrint('Camera error: ${e.code}');
      if (!mounted) return;
      final denied = e.code.contains('Denied') || e.code.contains('denied');
      setState(() => _step = denied ? _Step.denied : _Step.unavailable);
    } catch (e) {
      debugPrint('Camera unavailable: $e');
      if (mounted) setState(() => _step = _Step.unavailable);
    }
  }

  Future<void> _closeCamera() async {
    final camera = _camera;
    _camera = null;
    await camera?.dispose();
  }

  Future<void> _takePhoto() async {
    final camera = _camera;
    if (camera == null || _busy) return;
    setState(() => _busy = true);
    try {
      final photo = await camera.takePicture();
      await _closeCamera();
      if (!mounted) return;
      setState(() {
        _photo = photo;
        _step = _Step.review;
      });
    } catch (e) {
      _snack('Could not take the photo.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final photo = _photo;
    if (photo == null || _busy) return;
    setState(() => _busy = true);
    try {
      if (!await Gal.hasAccess(toAlbum: true)) {
        await Gal.requestAccess(toAlbum: true);
      }
      await Gal.putImage(photo.path, album: 'Hack Prank');
      await _deleteTemp(photo);
      _snack('Saved to your gallery.');
      if (mounted) Navigator.of(context).pop();
    } on GalException catch (e) {
      _snack(
        e.type == GalExceptionType.accessDenied
            ? 'Gallery permission denied. The photo was not saved.'
            : 'Could not save the photo.',
      );
    } catch (_) {
      _snack('Could not save the photo.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _retake() async {
    final photo = _photo;
    _photo = null;
    if (photo != null) await _deleteTemp(photo);
    await _openCamera();
  }

  Future<void> _discard() async {
    final photo = _photo;
    _photo = null;
    if (photo != null) await _deleteTemp(photo);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _deleteTemp(XFile file) async {
    try {
      await File(file.path).delete();
    } catch (_) {
      // The temporary file is already gone.
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_closeCamera());
    final photo = _photo;
    if (photo != null) unawaited(_deleteTemp(photo));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.revealBackground,
      appBar: AppBar(
        backgroundColor: AppColors.revealBackground,
        foregroundColor: AppColors.revealAccent,
        title: const Text('YOUR REACTION'),
      ),
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() {
    return switch (_step) {
      _Step.explain => _Explain(onOpen: _openCamera),
      _Step.starting => const Center(child: CircularProgressIndicator(color: AppColors.revealAccent)),
      _Step.preview => _Preview(camera: _camera!, busy: _busy, onShutter: _takePhoto),
      _Step.review => _Review(
        photo: _photo!,
        busy: _busy,
        onSave: _save,
        onRetake: _retake,
        onDiscard: _discard,
      ),
      _Step.denied => const _Message(
        icon: Icons.no_photography_outlined,
        text: 'Camera permission was denied, so nothing was captured. '
            'You can allow it later in system settings — the rest of the app works without it.',
      ),
      _Step.unavailable => const _Message(
        icon: Icons.videocam_off_outlined,
        text: 'No camera is available on this device. Everything else still works.',
      ),
    };
  }
}

class _Explain extends StatelessWidget {
  const _Explain({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final style = AppText.display(size: 17, color: AppColors.textPrimary, weight: FontWeight.w500, letterSpacing: 0.3)
        .copyWith(height: 1.4);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.photo_camera_front_outlined, size: 72, color: AppColors.revealAccent),
        const SizedBox(height: 16),
        Text(
          'Capture your reaction',
          textAlign: TextAlign.center,
          style: AppText.display(size: 28, color: AppColors.revealAccent),
        ),
        const SizedBox(height: 18),
        Text('The prank is over — this part is completely optional.', style: style),
        const SizedBox(height: 12),
        for (final line in const [
          'The camera turns on only after you tap OPEN CAMERA below. It was never used during the prank.',
          'Your phone may ask for camera permission. You can say no.',
          'A photo is taken only when you press the shutter button.',
          'You can then Save, Retake or Discard it. It is saved to your gallery only if you tap SAVE.',
          'Nothing is uploaded or shared automatically. No audio is recorded.',
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 3, right: 10),
                  child: Icon(Icons.check_circle_outline, size: 18, color: AppColors.hackerGreen),
                ),
                Expanded(child: Text(line, style: style)),
              ],
            ),
          ),
        const SizedBox(height: 16),
        NeonButton(
          key: ReactionScreen.openCameraKey,
          label: 'OPEN CAMERA',
          icon: Icons.camera_alt_outlined,
          style: NeonButtonStyle.gold,
          onPressed: onOpen,
        ),
        const SizedBox(height: 12),
        NeonButton(
          label: 'NO THANKS',
          style: NeonButtonStyle.secondary,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.camera, required this.busy, required this.onShutter});

  final CameraController camera;
  final bool busy;
  final VoidCallback onShutter;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Center(child: CameraPreview(camera)),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Semantics(
            button: true,
            label: 'Take photo',
            child: GestureDetector(
              onTap: busy ? null : onShutter,
              child: Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.revealAccent, width: 5),
                ),
                padding: const EdgeInsets.all(6),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: busy ? AppColors.textSecondary : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Review extends StatelessWidget {
  const _Review({
    required this.photo,
    required this.busy,
    required this.onSave,
    required this.onRetake,
    required this.onDiscard,
  });

  final XFile photo;
  final bool busy;
  final VoidCallback onSave;
  final VoidCallback onRetake;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(File(photo.path), fit: BoxFit.contain),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Row(
            children: [
              Expanded(
                child: NeonButton(
                  label: 'DISCARD',
                  style: NeonButtonStyle.danger,
                  onPressed: busy ? null : onDiscard,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: NeonButton(
                  label: 'RETAKE',
                  style: NeonButtonStyle.secondary,
                  onPressed: busy ? null : onRetake,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: NeonButton(
                  label: 'SAVE',
                  style: NeonButtonStyle.gold,
                  onPressed: busy ? null : onSave,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            text,
            textAlign: TextAlign.center,
            style: AppText.display(size: 18, weight: FontWeight.w500, letterSpacing: 0.3),
          ),
          const SizedBox(height: 24),
          NeonButton(
            label: 'BACK',
            style: NeonButtonStyle.secondary,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
