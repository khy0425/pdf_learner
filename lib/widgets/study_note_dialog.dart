class StudyNoteDialog extends StatefulWidget {
  final String pdfPath;
  final int pageNumber;
  final StudyNote? existingNote;

  const StudyNoteDialog({
    required this.pdfPath,
    required this.pageNumber,
    this.existingNote,
    Key? key,
  }) : super(key: key);

  @override
  State<StudyNoteDialog> createState() => _StudyNoteDialogState();
}

class _StudyNoteDialogState extends State<StudyNoteDialog> {
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();
  final List<String> _tags = [];
  String? _aiSuggestion;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingNote != null) {
      _contentController.text = widget.existingNote!.content;
      _tags.addAll(widget.existingNote!.tags);
      _aiSuggestion = widget.existingNote!.aiSuggestion;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '학습 노트 작성',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: '내용',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: const InputDecoration(
                      labelText: '태그',
                      hintText: '태그 입력 후 Enter',
                    ),
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        setState(() {
                          _tags.add(value);
                          _tagController.clear();
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              children: _tags.map((tag) => Chip(
                label: Text(tag),
                onDeleted: () {
                  setState(() {
                    _tags.remove(tag);
                  });
                },
              )).toList(),
            ),
            if (_aiSuggestion != null) ...[
              const SizedBox(height: 16),
              Text(
                'AI 학습 제안',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(_aiSuggestion!),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () async {
                    setState(() => _isLoading = true);
                    try {
                      final suggestion = await context.read<StudyNoteService>()
                          .getAISuggestion(_contentController.text);
                      setState(() {
                        _aiSuggestion = suggestion;
                        _isLoading = false;
                      });
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('AI 제안 생성 실패: $e')),
                      );
                      setState(() => _isLoading = false);
                    }
                  },
                  child: const Text('AI 제안 받기'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _isLoading ? null : () {
                    final note = StudyNote(
                      id: widget.existingNote?.id ?? 
                          DateTime.now().millisecondsSinceEpoch.toString(),
                      pdfPath: widget.pdfPath,
                      pageNumber: widget.pageNumber,
                      content: _contentController.text,
                      createdAt: DateTime.now(),
                      tags: _tags,
                      aiSuggestion: _aiSuggestion,
                    );
                    Navigator.pop(context, note);
                  },
                  child: const Text('저장'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 