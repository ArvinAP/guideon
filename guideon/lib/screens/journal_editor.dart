import 'package:flutter/material.dart';
import '../models/journal_entry.dart';
import '../services/journal_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

class JournalEditorPage extends StatefulWidget {
  final JournalEntry? entry; // if null -> creating new
  const JournalEditorPage({super.key, this.entry});

  @override
  State<JournalEditorPage> createState() => _JournalEditorPageState();
}

class _JournalEditorPageState extends State<JournalEditorPage> {
  late DateTime _date;
  String _mood = '🙂';
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  Color _cardColor = Colors.white;

  // Image handling
  final ImagePicker _picker = ImagePicker();
  final List<String> _imageUrls = []; // existing URLs from entry
  final List<XFile> _newImages = []; // newly picked local files
  final Map<String, double> _imageHeights = {}; // per-image adjustable height
  // For Web previews/uploads, cache bytes of newly picked images
  final Map<String, Uint8List> _newImageBytes = {}; // key -> bytes

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    if (e != null) {
      _date = e.date;
      _mood = e.moodEmoji;
      _titleCtrl.text = e.title;
      _bodyCtrl.text = e.body;
      _cardColor = e.cardColor;
      _imageUrls.addAll(e.imagePaths);
    } else {
      _date = DateTime.now();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _pickMood() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: const ['😄','🙂','😐','😔','😢','😤','😴','😇']
              .map((e) => GestureDetector(
                    onTap: () => Navigator.pop(_, e),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBF1F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2E7AA1)),
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 28)),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
    if (choice != null) setState(() => _mood = choice);
  }

  void _pickColor() async {
    final colors = [
      Colors.white,
      const Color(0xFFFFF9C4),
      const Color(0xFFC8E6C9),
      const Color(0xFFBBDEFB),
      const Color(0xFFFFCDD2),
    ];
    final choice = await showModalBottomSheet<Color>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: colors
              .map((c) => GestureDetector(
                    onTap: () => Navigator.pop(_, c),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: c,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF154D71)),
                      ),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
    if (choice != null) setState(() => _cardColor = choice);
  }

  void _addSticker() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sticker picker coming soon')),
    );
  }

  Future<void> _addImages() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(_, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(_, 'gallery'),
            ),
          ],
        ),
      ),
    );

    if (choice == 'camera') {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _newImages.add(picked));
        if (kIsWeb) {
          final key = _keyForImage(x: picked);
          final bytes = await picked.readAsBytes();
          setState(() => _newImageBytes[key] = bytes);
        }
      }
    } else if (choice == 'gallery') {
      final picked = await _picker.pickMultiImage(
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked.isNotEmpty) {
        setState(() => _newImages.addAll(picked));
        if (kIsWeb) {
          for (final x in picked) {
            final key = _keyForImage(x: x);
            final bytes = await x.readAsBytes();
            _newImageBytes[key] = bytes;
          }
          setState(() {});
        }
      }
    }
  }

  void _save() {
    final repo = JournalRepository.instance;
    final e = widget.entry;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to save.')),
      );
      return;
    }

    final entryId = e?.id ?? DateTime.now().millisecondsSinceEpoch.toString();

    Future<List<String>> uploadNewImages() async {
      if (_newImages.isEmpty) return const [];
      final storage = firebase_storage.FirebaseStorage.instance;
      final List<String> urls = [];
      for (final img in _newImages) {
        final fileName = DateTime.now().microsecondsSinceEpoch.toString();
        final ref = storage
            .ref()
            .child('users/${user.uid}/journals/$entryId/$fileName.jpg');
        if (kIsWeb) {
          final key = _keyForImage(x: img);
          final bytes = _newImageBytes[key] ?? await img.readAsBytes();
          await ref.putData(
            bytes,
            firebase_storage.SettableMetadata(contentType: 'image/jpeg'),
          );
        } else {
          final file = File(img.path);
          await ref.putFile(
            file,
            firebase_storage.SettableMetadata(contentType: 'image/jpeg'),
          );
        }
        final url = await ref.getDownloadURL();
        urls.add(url);
      }
      return urls;
    }

    () async {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saving journal...')),
      );

      final uploaded = await uploadNewImages();
      final combinedImages = [..._imageUrls, ...uploaded];

      final newEntry = JournalEntry(
        id: entryId,
        date: _date,
        moodEmoji: _mood,
        title: _titleCtrl.text.trim(),
        body: _bodyCtrl.text.trim(),
        cardColor: _cardColor,
        imagePaths: combinedImages,
        stickers: e?.stickers ?? const [],
      );

      if (e == null) {
        await repo.add(newEntry);
      } else {
        await repo.update(newEntry);
      }

      if (!mounted) return;
      Navigator.pop(context);
    }();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9ED),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black54),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.more_horiz, color: Colors.black54),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4A100),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextButton(
                      onPressed: _save,
                      child: const Text(
                        'SAVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Coiny',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Editor card
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 12, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '${_date.day}',
                            style: const TextStyle(
                              color: Color(0xFFF4A100),
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Coiny',
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: _pickDate,
                            child: Row(
                              children: [
                                Text(
                                  _monthYear(_date),
                                  style: const TextStyle(
                                    color: Color(0xFFF4A100),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Comfortaa',
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down, color: Color(0xFFF4A100), size: 20),
                              ],
                            ),
                          ),
                          const Spacer(),
                          InkWell(
                            onTap: _pickMood,
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2EC4B6),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(_mood, style: const TextStyle(fontSize: 24)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _titleCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Title',
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          fontFamily: 'Comfortaa',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _bodyCtrl,
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        decoration: const InputDecoration(
                          hintText: 'Write more here...',
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(
                          fontFamily: 'Comfortaa',
                          fontSize: 16,
                        ),
                      ),

                      // Inline image previews (Option A)
                      if (_imageUrls.isNotEmpty || _newImages.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ..._imageUrls.map((u) {
                              final keyId = _keyForImage(url: u);
                              return _resizableImageTile(
                                image: NetworkImage(u),
                                keyId: keyId,
                                onRemove: () {
                                  setState(() {
                                    _imageUrls.remove(u);
                                    _imageHeights.remove(keyId);
                                  });
                                },
                              );
                            }),
                            ..._newImages.map((x) {
                              final keyId = _keyForImage(x: x);
                              final provider = kIsWeb
                                  ? ( _newImageBytes[keyId] != null
                                      ? MemoryImage(_newImageBytes[keyId]!)
                                      : null )
                                  : FileImage(File(x.path)) as ImageProvider?;
                              if (provider == null) return const SizedBox.shrink();
                              return _resizableImageTile(
                                image: provider,
                                keyId: keyId,
                                onRemove: () {
                                  setState(() {
                                    _newImages.remove(x);
                                    _newImageBytes.remove(keyId);
                                    _imageHeights.remove(keyId);
                                  });
                                },
                              );
                            }),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Vertical action buttons
                      Align(
                        alignment: Alignment.centerRight,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _circleButton(icon: Icons.emoji_emotions, onTap: _addSticker),
                            const SizedBox(height: 16),
                            _circleButton(icon: Icons.brush, onTap: _pickColor),
                            const SizedBox(height: 16),
                            _circleButton(icon: Icons.image, onTap: _addImages),
                          ],
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
    );
  }

  String _monthYear(DateTime d) {
    const months = [
      'January','February','March','April','May','June','July','August','September','October','November','December'
    ];
    return '${months[d.month - 1]} ${d.year}';
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFF2EC4B6),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  // Helpers for resizable inline images
  String _keyForImage({String? url, XFile? x}) => url ?? 'local:${x!.path}';

  Widget _resizableImageTile({
    required ImageProvider image,
    required String keyId,
    required VoidCallback onRemove,
  }) {
    final double currentHeight =
        ((_imageHeights[keyId] ?? 220)).clamp(120.0, 500.0).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image(
                image: image,
                width: double.infinity,
                height: currentHeight,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ),
            // Bottom-right drag handle to resize like modern doc editors
            Positioned(
              right: 8,
              bottom: 8,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanUpdate: (details) {
                  final next = (currentHeight + details.delta.dy)
                      .clamp(120.0, 500.0)
                      .toDouble();
                  setState(() => _imageHeights[keyId] = next);
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.open_in_full,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
