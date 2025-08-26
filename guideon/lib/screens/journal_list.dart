import 'package:flutter/material.dart';
import '../models/journal_entry.dart';
import '../services/journal_repository.dart';
import 'journal_editor.dart';

class JournalListPage extends StatefulWidget {
  const JournalListPage({super.key});

  @override
  State<JournalListPage> createState() => _JournalListPageState();
}

class _JournalListPageState extends State<JournalListPage> {
  bool _showDeleted = false;

  @override
  void initState() {
    super.initState();
    // Start Firestore listener
    JournalRepository.instance.init();
  }

  @override
  void dispose() {
    JournalRepository.instance.disposeListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = JournalRepository.instance;

    return Scaffold(
      backgroundColor: const Color(0xFFEAEFEF),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: repo,
          builder: (context, _) {
            final list = _showDeleted ? repo.recentlyDeleted : repo.entries;
            return Stack(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black54),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Journal',
                        style: const TextStyle(
                          color: Color(0xFF154D71),
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Coiny',
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.more_horiz, color: Colors.black54),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),

                // Filter chips
                Positioned(
                  top: 56,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: Text(
                            'All',
                            style: const TextStyle(
                              fontFamily: 'Comfortaa',
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          selected: !_showDeleted,
                          selectedColor: const Color(0xFFFFF59D),
                          onSelected: (v) => setState(() => _showDeleted = false),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Text(
                            'Recently Deleted',
                            style: const TextStyle(
                              fontFamily: 'Comfortaa',
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          selected: _showDeleted,
                          selectedColor: const Color(0xFFFFF59D),
                          onSelected: (v) => setState(() => _showDeleted = true),
                        ),
                      ],
                    ),
                  ),
                ),

                // Content list or empty state
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 100, 16, 80),
                  child: list.isEmpty
                      ? _EmptyState(onCreate: _openCreate)
                      : ListView.separated(
                          itemCount: list.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final e = list[index];
                            return _JournalCard(
                              entry: e,
                              onTap: () => _openEdit(e),
                              onDelete: _showDeleted ? null : () => repo.delete(e.id),
                              onRestore: _showDeleted ? () => repo.restore(e.id) : null,
                            );
                          },
                        ),
                ),

                // Add button
                Positioned(
                  right: 24,
                  bottom: 24,
                  child: FloatingActionButton(
                    onPressed: _openCreate,
                    backgroundColor: const Color(0xFFDBF1F5),
                    foregroundColor: const Color(0xFF154D71),
                    child: const Icon(Icons.edit_note),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _openCreate() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const JournalEditorPage()),
    );
  }

  void _openEdit(JournalEntry e) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => JournalEditorPage(entry: e)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            )
          ],
        ),
        width: double.infinity,
        height: 350,
        child: InkWell(
          onTap: onCreate,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Color(0xFFDBF1F5),
                child: Icon(Icons.add, color: Color(0xFF154D71)),
              ),
              SizedBox(height: 12),
              Text(
                'Start Journaling',
                style: const TextStyle(
                  color: Colors.black45,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Coiny',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JournalCard extends StatelessWidget {
  final JournalEntry entry;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  const _JournalCard({
    required this.entry,
    required this.onTap,
    this.onDelete,
    this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final date = entry.date;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Text(
                '${date.day} ',
                style: const TextStyle(
                  color: Color(0xFF154D71),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Coiny',
                ),
              ),
              Text(
                _monthYear(date),
                style: const TextStyle(
                  color: Color(0xFF154D71),
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Comfortaa',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.title.isEmpty ? 'Title' : entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Comfortaa',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(entry.moodEmoji, style: const TextStyle(fontSize: 18)),
              if (onDelete != null || onRestore != null) ...[
                const SizedBox(width: 8),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: Colors.redAccent,
                    onPressed: onDelete,
                  ),
                if (onRestore != null)
                  IconButton(
                    icon: const Icon(Icons.restore, size: 20),
                    color: Colors.green,
                    onPressed: onRestore,
                  ),
              ]
            ],
          ),
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
}
