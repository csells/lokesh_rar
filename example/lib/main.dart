// example/lib/main.dart
//
// Example app demonstrating the RAR plugin on all supported platforms:
// - Android, iOS (mobile)
// - Linux, macOS, Windows (desktop)
// - Web

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:rar/rar.dart';

// Conditional imports for platform-specific code
import 'platform_stub.dart'
    if (dart.library.io) 'platform_io.dart'
    if (dart.library.html) 'platform_web.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _status = 'Ready';
  String _platformInfo = '';
  List<String> _fileList = [];
  bool _isProcessing = false;
  String? _passwordInput;

  @override
  void initState() {
    super.initState();
    _initPlatform();
  }

  Future<void> _initPlatform() async {
    await requestPlatformPermissions();
    setState(() {
      _platformInfo = getPlatformName();
    });
  }

  Future<String?> _getDestinationPath() async {
    // Get platform-appropriate destination directory
    try {
      if (kIsWeb) {
        // On web, we use a virtual path
        return '/extracted';
      }

      final directory = await getApplicationDocumentsDirectory();
      return '${directory.path}/rar_extracted';
    } catch (e) {
      return null;
    }
  }

  Future<void> _pickAndExtractRarFile() async {
    setState(() {
      _isProcessing = true;
      _status = 'Selecting RAR file...';
      _fileList = [];
    });

    try {
      // Pick a RAR file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['rar'],
        withData: kIsWeb, // On web, we need the file bytes
      );

      if (result == null || result.files.isEmpty) {
        setState(() {
          _status = 'No file selected';
          _isProcessing = false;
        });
        return;
      }

      final file = result.files.single;
      String? filePath = file.path;

      // On web, we need to handle file data differently
      if (kIsWeb) {
        if (file.bytes == null) {
          setState(() {
            _status = 'Could not read file data (web)';
            _isProcessing = false;
          });
          return;
        }
        // Store file data in virtual file system for web
        storeWebFileData(file.name, file.bytes!);
        filePath = file.name;
      }

      if (filePath == null) {
        setState(() {
          _status = 'Invalid file path';
          _isProcessing = false;
        });
        return;
      }

      setState(() {
        _status = 'Selected: ${file.name}';
      });

      // Get the destination directory
      final extractPath = await _getDestinationPath();
      if (extractPath == null) {
        setState(() {
          _status = 'Could not access storage directory';
          _isProcessing = false;
        });
        return;
      }

      // Create destination directory if needed (non-web platforms)
      if (!kIsWeb) {
        await createDirectory(extractPath);
      }

      setState(() {
        _status = 'Extracting to $extractPath...';
      });

      // Extract the RAR file
      final extractResult = await Rar.extractRarFile(
        rarFilePath: filePath,
        destinationPath: extractPath,
        password: _passwordInput,
      );

      if (extractResult['success'] == true) {
        setState(() {
          _status = 'Extraction successful: ${extractResult['message']}';
        });

        // List the extracted files
        final files = await listDirectoryContents(extractPath);
        setState(() {
          _fileList = files;
        });
      } else {
        setState(() {
          _status = 'Extraction failed: ${extractResult['message']}';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _listRarContents() async {
    setState(() {
      _isProcessing = true;
      _status = 'Selecting RAR file...';
      _fileList = [];
    });

    try {
      // Pick a RAR file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['rar'],
        withData: kIsWeb,
      );

      if (result == null || result.files.isEmpty) {
        setState(() {
          _status = 'No file selected';
          _isProcessing = false;
        });
        return;
      }

      final file = result.files.single;
      String? filePath = file.path;

      // On web, handle file data differently
      if (kIsWeb) {
        if (file.bytes == null) {
          setState(() {
            _status = 'Could not read file data (web)';
            _isProcessing = false;
          });
          return;
        }
        storeWebFileData(file.name, file.bytes!);
        filePath = file.name;
      }

      if (filePath == null) {
        setState(() {
          _status = 'Invalid file path';
          _isProcessing = false;
        });
        return;
      }

      setState(() {
        _status = 'Listing contents of: ${file.name}';
      });

      // List RAR contents
      final listResult = await Rar.listRarContents(
        rarFilePath: filePath,
        password: _passwordInput,
      );

      if (listResult['success'] == true) {
        final files = listResult['files'];
        setState(() {
          _status = 'Listed ${(files as List).length} files in archive';
          _fileList = List<String>.from(files);
        });
      } else {
        setState(() {
          _status = 'Failed to list contents: ${listResult['message']}';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String password = _passwordInput ?? '';
        return AlertDialog(
          title: const Text('Archive Password'),
          content: TextField(
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'Enter password (leave empty for none)',
            ),
            onChanged: (value) => password = value,
            controller: TextEditingController(text: _passwordInput),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _passwordInput = null;
                });
                Navigator.pop(context);
              },
              child: const Text('Clear'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _passwordInput = password.isEmpty ? null : password;
                });
                Navigator.pop(context);
              },
              child: const Text('Set'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RAR Plugin Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('RAR Plugin Example'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            IconButton(
              icon: Icon(_passwordInput != null ? Icons.lock : Icons.lock_open),
              tooltip: 'Set password',
              onPressed: _showPasswordDialog,
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Platform info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Platform: $_platformInfo',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (_passwordInput != null)
                          Text(
                            'Password: ****',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Status
                Card(
                  color: _status.contains('failed') || _status.contains('Error')
                      ? Colors.red.shade50
                      : _status.contains('successful')
                          ? Colors.green.shade50
                          : null,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      _status,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _listRarContents,
                        icon: const Icon(Icons.list),
                        label: const Text('List Contents'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _pickAndExtractRarFile,
                        icon: const Icon(Icons.unarchive),
                        label: const Text('Extract'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Processing indicator
                if (_isProcessing)
                  const LinearProgressIndicator(),

                const SizedBox(height: 16),

                // File list
                if (_fileList.isNotEmpty) ...[
                  Text(
                    'Files (${_fileList.length}):',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Card(
                      child: ListView.builder(
                        itemCount: _fileList.length,
                        itemBuilder: (context, index) {
                          final fileName = _fileList[index];
                          final isDirectory = fileName.endsWith('/');
                          return ListTile(
                            leading: Icon(
                              isDirectory ? Icons.folder : Icons.insert_drive_file,
                              color: isDirectory ? Colors.amber : Colors.blue,
                            ),
                            title: Text(
                              fileName,
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                            dense: true,
                          );
                        },
                      ),
                    ),
                  ),
                ] else
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Select a RAR file to list or extract its contents',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
