import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/pdf_viewer_viewmodel.dart';

class OptionsDialog extends StatefulWidget {
  const OptionsDialog({Key? key}) : super(key: key);

  @override
  _OptionsDialogState createState() => _OptionsDialogState();
}

class _OptionsDialogState extends State<OptionsDialog> {
  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<PdfViewerViewModel>(context);
    
    return AlertDialog(
      title: const Text('PDF 옵션'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text('야간 모드'),
            value: viewModel.isNightMode,
            onChanged: (value) {
              viewModel.toggleNightMode();
            },
          ),
          ListTile(
            title: const Text('텍스트 크기'),
            subtitle: Slider(
              min: 0.5,
              max: 3.0,
              divisions: 5,
              value: viewModel.textZoomLevel,
              label: viewModel.textZoomLevel.toStringAsFixed(1) + 'x',
              onChanged: (value) {
                viewModel.setTextZoomLevel(value);
              },
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('닫기'),
        ),
      ],
    );
  }
} 