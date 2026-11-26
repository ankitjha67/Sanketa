import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class _Camera {
  _Camera({required this.name, required this.url, this.location = ''});

  factory _Camera.fromJson(Map<String, dynamic> j) => _Camera(
        name: j['name'] as String,
        url: j['url'] as String,
        location: j['location'] as String? ?? '',
      );

  final String name;
  final String url;
  final String location;

  Map<String, dynamic> toJson() => {
        'name': name,
        'url': url,
        'location': location,
      };
}

class IpCameraScreen extends StatefulWidget {
  const IpCameraScreen({super.key});

  @override
  State<IpCameraScreen> createState() => _IpCameraScreenState();
}

class _IpCameraScreenState extends State<IpCameraScreen> {
  List<_Camera> _cameras = [];
  bool _loading = true;
  bool _gridView = true;
  final _nameCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/ip_cameras.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final list = jsonDecode(await f.readAsString()) as List;
        _cameras = list
            .map((j) => _Camera.fromJson(j as Map<String, dynamic>))
            .toList();
      }
    } on Object {/* defaults */}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(
        jsonEncode(_cameras.map((c) => c.toJson()).toList()));
  }

  void _addCamera() {
    final name = _nameCtrl.text.trim();
    final url = _urlCtrl.text.trim();
    if (name.isEmpty || url.isEmpty) return;
    setState(() {
      _cameras.add(_Camera(
        name: name,
        url: url,
        location: _locationCtrl.text.trim(),
      ));
    });
    _nameCtrl.clear();
    _urlCtrl.clear();
    _locationCtrl.clear();
    _save();
  }

  void _deleteCamera(int index) {
    setState(() => _cameras.removeAt(index));
    _save();
  }

  void _castToTv(_Camera cam) {
    final rc = RemoteScope.of(context);
    rc.launch(cam.url);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Casting ${cam.name} to TV'),
        duration: const Duration(seconds: 2),
      ));
  }

  void _copyUrl(String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(
        content: Text('URL copied'),
        duration: Duration(seconds: 1),
      ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: hex(AppColors.surface),
        body: Center(
            child:
                CircularProgressIndicator(color: hex(AppColors.primary))),
      );
    }

    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('IP Cameras',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
        actions: [
          GestureDetector(
            onTap: () => setState(() => _gridView = !_gridView),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                _gridView ? Icons.grid_view : Icons.list,
                size: 20,
                color: hex(AppColors.primary),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(),
          const SizedBox(height: AppSpacing.md),
          _addSection(),
          const SizedBox(height: AppSpacing.md),
          if (_cameras.isEmpty)
            _emptyState()
          else ...[
            Text('Cameras (${_cameras.length})',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (_gridView) _cameraGrid() else _cameraList(),
          ],
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
        padding: const EdgeInsets.symmetric(
            vertical: 24, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.secondary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.secondary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.videocam,
                size: 48, color: hex(AppColors.secondary)),
            const SizedBox(height: 8),
            Text('IP Camera Viewer',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.secondary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Cast your local IP cameras to TV. Add RTSP or HTTP stream URLs from cameras on your network.',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _addSection() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Camera',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface)),
              decoration: _inputDecor('Camera name (e.g. Front Door)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _urlCtrl,
              style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface)),
              decoration: _inputDecor('Stream URL (rtsp://...)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _locationCtrl,
              style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface)),
              decoration: _inputDecor('Location (optional)'),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _addCamera,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: hex(AppColors.primary).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Center(
                  child: Text('Add Camera',
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.primary),
                          weight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      );

  InputDecoration _inputDecor(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: gfont(AppType.bodySm,
            color: hex(AppColors.outline).withValues(alpha: 0.5)),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.md)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(
              color:
                  hex(AppColors.outlineVariant).withValues(alpha: 0.3)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      );

  Widget _cameraGrid() => GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 1.3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: _cameras.asMap().entries.map((e) {
          final cam = e.value;
          return GestureDetector(
            onTap: () => _castToTv(cam),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: hex(AppColors.surfaceContainerLow),
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(
                    color: hex(AppColors.outlineVariant)
                        .withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.videocam,
                          size: 16, color: hex(AppColors.secondary)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _deleteCamera(e.key),
                        child: Icon(Icons.close,
                            size: 14, color: hex(AppColors.outline)),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(cam.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.onSurface),
                          weight: FontWeight.w600,
                          size: 12)),
                  if (cam.location.isNotEmpty)
                    Text(cam.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.outline), size: 9)),
                  const SizedBox(height: 4),
                  Text('Tap to cast',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.primary),
                          size: 9,
                          weight: FontWeight.w600)),
                ],
              ),
            ),
          );
        }).toList(),
      );

  Widget _cameraList() => Column(
        children: _cameras.asMap().entries.map((e) {
          final cam = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: hex(AppColors.surfaceContainerLow),
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(
                    color: hex(AppColors.outlineVariant)
                        .withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color:
                          hex(AppColors.secondary).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: Icon(Icons.videocam,
                        size: 18, color: hex(AppColors.secondary)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cam.name,
                            style: gfont(AppType.bodyMd,
                                color: hex(AppColors.onSurface),
                                weight: FontWeight.w600,
                                size: 12)),
                        Text(
                            cam.location.isEmpty
                                ? cam.url
                                : cam.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: gfont(AppType.bodySm,
                                color: hex(AppColors.outline), size: 10)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _copyUrl(cam.url),
                    child: Icon(Icons.copy,
                        size: 14, color: hex(AppColors.outline)),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _castToTv(cam),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: hex(AppColors.primary)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                      child: Icon(Icons.cast,
                          size: 14, color: hex(AppColors.primary)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _deleteCamera(e.key),
                    child: Icon(Icons.close,
                        size: 14, color: hex(AppColors.outline)),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );

  Widget _emptyState() => Column(
        children: [
          const SizedBox(height: 24),
          Icon(Icons.videocam_off, size: 40, color: hex(AppColors.outline)),
          const SizedBox(height: 8),
          Text('No cameras added',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
              'Add your IP camera stream URLs to view and cast them to your TV.',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11)),
        ],
      );

  Widget _infoCard() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.tertiary).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.tertiary).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline,
                size: 16, color: hex(AppColors.tertiary)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'View IP cameras from your local network on your TV. Add RTSP or HTTP stream URLs. All connections stay on your local network. Camera data is stored locally.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
