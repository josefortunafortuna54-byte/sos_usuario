import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/media_service.dart';

class MediaScreen extends StatefulWidget {
  final String occurrenceId;
  const MediaScreen({super.key, required this.occurrenceId});

  @override
  State<MediaScreen> createState() => _MediaScreenState();
}

class _MediaScreenState extends State<MediaScreen> {
  final _picker = ImagePicker();
  List<Map<String, dynamic>> _media = [];
  bool _loading = true;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    try {
      _media = await MediaService.listar(widget.occurrenceId);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _escolherCamera() async => _picker.pickImage(source: ImageSource.camera).then((f) => f != null ? _upload(File(f.path), false) : null);
  Future<void> _escolherGaleria() async => _picker.pickImage(source: ImageSource.gallery).then((f) => f != null ? _upload(File(f.path), false) : null);
  Future<void> _escolherVideo() async => _picker.pickVideo(source: ImageSource.gallery).then((f) => f != null ? _upload(File(f.path), true) : null);

  Future<void> _upload(File file, bool isVideo) async {
    setState(() => _uploading = true);
    try {
      await MediaService.upload(occurrenceId: widget.occurrenceId, file: file, isVideo: isVideo);
      await _carregar();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
    }
    if (mounted) setState(() => _uploading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fotos e Vídeos', style: TextStyle(fontSize: 14)),
        backgroundColor: const Color(0xFF0D1F3C),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.add_photo_alternate_outlined, color: Colors.white54),
            onSelected: (v) {
              if (v == 'camera') _escolherCamera();
              if (v == 'galeria') _escolherGaleria();
              if (v == 'video') _escolherVideo();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'camera', child: ListTile(leading: Icon(Icons.camera_alt), title: Text('Tirar foto'), dense: true)),
              const PopupMenuItem(value: 'galeria', child: ListTile(leading: Icon(Icons.photo_library), title: Text('Galeria'), dense: true)),
              const PopupMenuItem(value: 'video', child: ListTile(leading: Icon(Icons.videocam), title: Text('Vídeo'), dense: true)),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _uploading
              ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(height: 12), Text('A enviar...', style: TextStyle(color: Colors.white54))]))
              : _media.isEmpty
                  ? const Center(child: Text('Nenhuma foto ou vídeo anexado.', style: TextStyle(color: Colors.white38)))
                  : GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4),
                      itemCount: _media.length,
                      itemBuilder: (_, i) {
                        final item = _media[i];
                        final url = item['url'] as String;
                        final isVideo = item['type'] == 'video';
                        return GestureDetector(
                          onTap: () => _preview(url, isVideo),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white38)),
                              if (isVideo) const Center(child: Icon(Icons.play_circle, color: Colors.white, size: 32)),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }

  void _preview(String url, bool isVideo) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        child: isVideo
            ? const Center(child: Text('Vídeo', style: TextStyle(color: Colors.white)))
            : InteractiveViewer(child: Image.network(url, fit: BoxFit.contain)),
      ),
    );
  }
}
