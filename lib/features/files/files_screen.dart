import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/neumorphic_widgets.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  final TextEditingController _fileNameController = TextEditingController();

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Simulate File Upload'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NeumorphicTextField(
                controller: _fileNameController,
                hintText: 'File name (e.g. b2auth_keys.txt)',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            NeumorphicButton(
              onPressed: () {
                if (_fileNameController.text.isNotEmpty) {
                  context.read<FilesProvider>().uploadFile(
                    _fileNameController.text,
                    '12 KB',
                    'TXT',
                  );
                  _fileNameController.clear();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('File uploaded successfully!'),
                    ),
                  );
                }
              },
              child: const Text('Upload'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filesProvider = Provider.of<FilesProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Secure Storage',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            NeumorphicButton(
              onPressed: _showUploadDialog,
              color: Theme.of(context).primaryColor,
              child: const Row(
                children: [
                  Icon(Icons.cloud_upload, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Upload File',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        NeumorphicCard(
          borderRadius: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Storage Usage (1.2 GB of 10 GB)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: 0.12,
                color: Theme.of(context).primaryColor,
                backgroundColor: Colors.grey.withValues(alpha: 0.2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            itemCount: filesProvider.files.length,
            itemBuilder: (context, i) {
              final file = filesProvider.files[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: NeumorphicCard(
                  borderRadius: 12,
                  child: ListTile(
                    leading: const Icon(Icons.insert_drive_file, size: 30),
                    title: Text(
                      file.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Type: ${file.fileType} • Size: ${file.size}',
                    ),
                    trailing: Text(
                      '${file.lastModified.day}/${file.lastModified.month}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
