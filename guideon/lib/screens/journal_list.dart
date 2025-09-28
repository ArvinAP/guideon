import 'package:flutter/material.dart';
import '../models/journal_entry.dart';
import '../services/journal_repository.dart';
import 'journal_editor.dart';

class JournalListPage extends StatefulWidget {
  final bool showDeletedInitially;
  const JournalListPage({super.key, this.showDeletedInitially = false});

  @override
  State<JournalListPage> createState() => _JournalListPageState();
}

class _JournalListPageState extends State<JournalListPage> {
  bool _showDeleted = false;

  @override
  void initState() {
    super.initState();
    // Set initial state based on parameter
    _showDeleted = widget.showDeletedInitially;
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
      backgroundColor: const Color(0xFFFFF9ED), // Match dashboard background
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
                          color: Color(0xFFF4A100), // Orange color to match design
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Coiny',
                        ),
                      ),
                    ],
                  ),
                ),

                // Filter chips - only show when there are entries
                if (repo.entries.isNotEmpty || repo.recentlyDeleted.isNotEmpty)
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
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                            selected: !_showDeleted,
                            selectedColor: const Color(0xFFFFF59D), // Yellow/cream color
                            backgroundColor: Colors.white,
                            side: BorderSide.none,
                            onSelected: (v) => setState(() => _showDeleted = false),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: Text(
                              'Recently Deleted',
                              style: const TextStyle(
                                fontFamily: 'Comfortaa',
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                            selected: _showDeleted,
                            selectedColor: const Color(0xFFFFF59D), // Yellow/cream color
                            backgroundColor: Colors.white,
                            side: BorderSide.none,
                            onSelected: (v) => setState(() => _showDeleted = true),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Content list or empty state
                Padding(
                  padding: list.isEmpty 
                      ? const EdgeInsets.fromLTRB(16, 70, 16, 16) // Less top padding for empty state
                      : const EdgeInsets.fromLTRB(16, 100, 16, 80), // Normal padding for list
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

                // Add button - only show when there are entries
                if (repo.entries.isNotEmpty || repo.recentlyDeleted.isNotEmpty)
                  Positioned(
                    right: 24,
                    bottom: 24,
                    child: FloatingActionButton(
                      onPressed: _openCreate,
                      backgroundColor: const Color(0xFF2EC4B6), // Teal color to match design
                      foregroundColor: Colors.white,
                      child: const Icon(Icons.add, size: 28),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Circular icon with plus sign
          GestureDetector(
            onTap: onCreate,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF2EC4B6), // Teal color
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // "Start Journaling" text
          Text(
            'Start Journaling',
            style: const TextStyle(
              color: Colors.grey, // Gray color as shown in design
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'Comfortaa',
            ),
          ),
        ],
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
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date section with large teal number
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${date.day}',
                    style: const TextStyle(
                      color: Color(0xFF2EC4B6), // Teal color for date
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Coiny',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _monthYear(date),
                    style: const TextStyle(
                      color: Color(0xFF2EC4B6), // Teal color for month/year
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Comfortaa',
                    ),
                  ),
                  const Spacer(),
                  // Action buttons (delete/restore) if needed
                  if (onDelete != null || onRestore != null) ...[
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
              const SizedBox(height: 12),
              // Title section
              Text(
                entry.title.isEmpty ? 'Title' : entry.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Comfortaa',
                ),
              ),
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
