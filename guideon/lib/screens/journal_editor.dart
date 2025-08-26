import 'package:flutter/material.dart';
import '../models/journal_entry.dart';
import '../services/journal_repository.dart';

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
                        color: Color(0xFFDBF1F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xFF2E7AA1)),
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
    // Simple preset colors
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

  void _addImages() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image picker coming soon')),
    );
  }

  void _save() {
    final repo = JournalRepository.instance;
    final e = widget.entry;
    final newEntry = JournalEntry(
      id: e?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      date: _date,
      moodEmoji: _mood,
      title: _titleCtrl.text.trim(),
      body: _bodyCtrl.text.trim(),
      cardColor: _cardColor,
      imagePaths: e?.imagePaths ?? const [],
      stickers: e?.stickers ?? const [],
    );
    if (e == null) {
      repo.add(newEntry);
    } else {
      repo.update(newEntry);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAEFEF),
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
                  TextButton(
                    onPressed: _save,
                    child: const Text('SAVE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
                  )
                ],
              ),
            ),

            // Editor card
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
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
                  padding: const EdgeInsets.fromLTRB(16, 16, 12, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '${_date.day} ',
                            style: const TextStyle(
                              color: Color(0xFF154D71),
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Coiny',
                            ),
                          ),
                          InkWell(
                            onTap: _pickDate,
                            child: Row(
                              children: [
                                Text(
                                  _monthYear(_date),
                                  style: const TextStyle(
                                    color: Color(0xFF154D71),
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Comfortaa',
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down, color: Color(0xFF154D71)),
                              ],
                            ),
                          ),
                          const Spacer(),
                          InkWell(
                            onTap: _pickMood,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDBF1F5),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF154D71)),
                              ),
                              child: Text(_mood, style: const TextStyle(fontSize: 20)),
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
                      const SizedBox(height: 16),
                      // Vertical action buttons (stickers, color, images)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _circleButton(icon: Icons.emoji_emotions_outlined, onTap: _addSticker),
                            const SizedBox(height: 12),
                            _circleButton(icon: Icons.brush_outlined, onTap: _pickColor),
                            const SizedBox(height: 12),
                            _circleButton(icon: Icons.add_photo_alternate_outlined, onTap: _addImages),
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFDBF1F5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF154D71).withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Icon(icon, color: const Color(0xFF154D71)),
      ),
    );
  }
}
