import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BibleVersesListPage extends StatelessWidget {
  const BibleVersesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF7A5C00)),
        title: const Text(
          'Bible Verses',
          style: TextStyle(
            color: Color(0xFF1E88E5),
            fontFamily: 'Coiny',
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFEAEFEF),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('verses')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(child: Text('Failed to load verses'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;

          return Column(
            children: [
              // total count
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Total no. of Verses: ${docs.length}',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Comfortaa',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final text = (data["text"] ?? '').toString();
                    final reference = (data['reference'] ?? '').toString();
                    final description = (data['description'] ?? '').toString();

                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF2B3), // bible yellow
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(2, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            text.isEmpty ? '—' : '"$text"',
                            style: const TextStyle(
                              color: Colors.black87,
                              height: 1.3,
                              fontFamily: 'Comfortaa',
                            ),
                          ),
                          if (reference.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              '— $reference',
                              style: const TextStyle(
                                color: Color(0xFF7A5C00),
                                fontStyle: FontStyle.italic,
                                fontFamily: 'Comfortaa',
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF7A5C00),
                                ),
                                onPressed: () async {
                                  final textCtrl =
                                      TextEditingController(text: text);
                                  final refCtrl =
                                      TextEditingController(text: reference);
                                  final descCtrl =
                                      TextEditingController(text: description);
                                  await showDialog(
                                    context: context,
                                    builder: (ctx) => Theme(
                                      data: Theme.of(context).copyWith(
                                        dialogBackgroundColor:
                                            const Color(0xFFFFF7D6),
                                        inputDecorationTheme:
                                            const InputDecorationTheme(
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Color(0xFFFFA000)),
                                          ),
                                        ),
                                        textButtonTheme: TextButtonThemeData(
                                          style: TextButton.styleFrom(
                                            foregroundColor:
                                                const Color(0xFFFFA000),
                                          ),
                                        ),
                                        elevatedButtonTheme:
                                            ElevatedButtonThemeData(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFFFFA000),
                                            foregroundColor: Colors.white,
                                            shape: const StadiumBorder(),
                                          ),
                                        ),
                                      ),
                                      child: AlertDialog(
                                        backgroundColor:
                                            const Color(0xFFFFF7D6),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        title: const Text('Edit Verse'),
                                        content: SingleChildScrollView(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              TextField(
                                                controller: textCtrl,
                                                decoration:
                                                    const InputDecoration(
                                                        labelText:
                                                            'Verse text'),
                                                maxLines: 3,
                                              ),
                                              TextField(
                                                controller: refCtrl,
                                                decoration: const InputDecoration(
                                                    labelText:
                                                        'Reference (e.g., John 3:16)'),
                                              ),
                                              TextField(
                                                controller: descCtrl,
                                                decoration: const InputDecoration(
                                                    labelText:
                                                        'Description/Meaning (optional, stored only)'),
                                                maxLines: 3,
                                              ),
                                            ],
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () async {
                                              final newText =
                                                  textCtrl.text.trim();
                                              final newRef =
                                                  refCtrl.text.trim();
                                              final newDesc =
                                                  descCtrl.text.trim();
                                              if (newText.isEmpty) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                      content: Text(
                                                          'Please enter verse text')),
                                                );
                                                return;
                                              }
                                              try {
                                                await doc.reference.update({
                                                  'text': newText,
                                                  'reference': newRef,
                                                  'description': newDesc,
                                                });
                                                if (ctx.mounted)
                                                  Navigator.pop(ctx);
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                      content: Text(
                                                          'Verse updated')),
                                                );
                                              } catch (e) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                      content: Text(
                                                          'Failed to update: $e')),
                                                );
                                              }
                                            },
                                            child: const Text('Save'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                label: const Text(
                                  'Edit',
                                  style: TextStyle(fontFamily: 'Comfortaa'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red.shade700,
                                ),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Delete Verse'),
                                      content: const Text(
                                          'Are you sure you want to delete this verse?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm != true) return;
                                  try {
                                    await doc.reference.delete();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Verse deleted')),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content:
                                              Text('Failed to delete: $e')),
                                    );
                                  }
                                },
                                icon:
                                    const Icon(Icons.delete_outline, size: 20),
                                label: const Text(
                                  'Delete',
                                  style: TextStyle(fontFamily: 'Comfortaa'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFFA000),
        foregroundColor: Colors.white,
        onPressed: () async {
          final textController = TextEditingController();
          final refController = TextEditingController();
          final descController = TextEditingController();
          await showDialog(
            context: context,
            builder: (ctx) => Theme(
              data: Theme.of(context).copyWith(
                dialogBackgroundColor:
                    const Color(0xFFFFF7D6), // light amber tint
                inputDecorationTheme: const InputDecorationTheme(
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFFFA000)),
                  ),
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFFFA000),
                  ),
                ),
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA000),
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
              child: AlertDialog(
                backgroundColor: const Color(0xFFFFF7D6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: const Text('Add Verse'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: textController,
                        decoration:
                            const InputDecoration(labelText: 'Verse text'),
                        maxLines: 3,
                      ),
                      TextField(
                        controller: refController,
                        decoration: const InputDecoration(
                            labelText: 'Reference (e.g., John 3:16)'),
                      ),
                      TextField(
                        controller: descController,
                        decoration: const InputDecoration(
                            labelText:
                                'Description/Meaning (optional, stored only)'),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final text = textController.text.trim();
                      final reference = refController.text.trim();
                      final description = descController.text.trim();
                      if (text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Please enter verse text')),
                        );
                        return;
                      }
                      try {
                        await FirebaseFirestore.instance
                            .collection('verses')
                            .add({
                          'text': text,
                          'reference': reference,
                          'description': description,
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Verse added')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to add: $e')),
                        );
                      }
                    },
                    child: const Text('Add'),
                  ),
                ],
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
