import 'package:flutter/material.dart';
import 'package:docman/docman.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WhatsApp Status Downloader',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const WhatsAppStatusScreen(),
    );
  }
}

class WhatsAppStatusScreen extends StatefulWidget {
  const WhatsAppStatusScreen({super.key});

  @override
  State<WhatsAppStatusScreen> createState() => _WhatsAppStatusScreenState();
}

class _WhatsAppStatusScreenState extends State<WhatsAppStatusScreen>
    with SingleTickerProviderStateMixin {
  // SharedPreferences keys
  static const String KEY_STATUS_PATH = 'status_directory_path';
  static const String KEY_DOWNLOAD_PATH = 'download_directory_path';

  List<DocumentFile> _statuses = [];
  bool _isLoading = false;
  String _statusMessage = '';
  late TabController _tabController;
  DocumentFile? _statusDir;
  DocumentFile? _downloadDir;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSavedDirectories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedDirectories() async {
    await _loadSavedStatusDirectory();
    await _loadSavedDownloadDirectory();
  }

  Future<void> _loadSavedStatusDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString(KEY_STATUS_PATH);

    if (savedPath != null) {
      try {
        final dir = await DocMan.pick.directory(
          initDir: savedPath,
        );

        if (dir != null) {
          setState(() {
            _statusDir = dir;
          });
          _loadStatuses();
          return;
        }
      } catch (e) {
        print('Error loading saved status path: $e');
      }
    }

    // If no saved path or error loading it, try default paths
    _initializeStatusDirectory();
  }

  Future<void> _loadSavedDownloadDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString(KEY_DOWNLOAD_PATH);

    if (savedPath != null) {
      try {
        final dir = await DocMan.pick.directory(
          initDir: savedPath,
        );

        if (dir != null) {
          setState(() {
            _downloadDir = dir;
          });
          return;
        }
      } catch (e) {
        print('Error loading saved download path: $e');
      }
    }

    // If no saved path or error, try default download directory
    _initializeDownloadDirectory();
  }

  Future<void> _saveStatusDirectoryPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(KEY_STATUS_PATH, path);
  }

  Future<void> _saveDownloadDirectoryPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(KEY_DOWNLOAD_PATH, path);
  }

  Future<void> _initializeStatusDirectory() async {
    const List<String> whatsappPaths = [
      'Android/media/com.whatsapp/WhatsApp/Media/.Statuses',
    ];

    for (final path in whatsappPaths) {
      try {
        final dir = await DocMan.pick.directory(
          initDir:
              'content://com.android.externalstorage.documents/document/primary%3A$path',
        );

        if (dir != null) {
          await _saveStatusDirectoryPath(
              'content://com.android.externalstorage.documents/document/primary%3A$path');

          setState(() {
            _statusDir = dir;
          });
          _loadStatuses();
          return;
        }
      } catch (e) {
        print('Error accessing path $path: $e');
        continue;
      }
    }

    setState(() {
      _statusMessage = 'Please select WhatsApp status folder manually';
    });
  }

  Future<void> _initializeDownloadDirectory() async {
    try {
      final dir = await DocMan.pick.directory(
        initDir:
            'content://com.android.externalstorage.documents/document/primary%3ADownload',
      );

      if (dir != null) {
        await _saveDownloadDirectoryPath(
            'content://com.android.externalstorage.documents/document/primary%3ADownload');

        setState(() {
          _downloadDir = dir;
        });
      }
    } catch (e) {
      print('Error accessing download directory: $e');
      setState(() {
        _statusMessage = 'Please select download folder manually';
      });
    }
  }

  Future<void> _selectStatusDirectory() async {
    try {
      final dir = await DocMan.pick.directory();
      if (dir != null) {
        await _saveStatusDirectoryPath(dir.uri.toString());

        setState(() {
          _statusDir = dir;
        });
        _loadStatuses();
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error selecting status directory: $e';
      });
    }
  }

  Future<void> _selectDownloadDirectory() async {
    try {
      final dir = await DocMan.pick.directory();
      if (dir != null) {
        await _saveDownloadDirectoryPath(dir.uri.toString());

        setState(() {
          _downloadDir = dir;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error selecting download directory: $e';
      });
    }
  }

  Future<void> _loadStatuses() async {
    if (_statusDir == null) {
      _initializeStatusDirectory();
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Loading statuses...';
      _statuses = [];
    });

    try {
      final files = await _statusDir!.listDocuments(
        mimeTypes: ['image/*', 'video/*'],
      );

      setState(() {
        _statuses = files;
        _statusMessage = 'Found ${files.length} statuses';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading statuses: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadStatus(DocumentFile status) async {
    if (_downloadDir == null) {
      setState(() {
        _statusMessage = 'Please select download directory first';
      });
      await _selectDownloadDirectory();
      if (_downloadDir == null) return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Saving status...';
    });

    try {
      // Copy file to downloads
      final savedFile = await status.copyTo(
        _downloadDir!.uri,
        name:
            'WA_Status_${DateTime.now().millisecondsSinceEpoch}.${status.name.split('.').last}',
      );

      if (savedFile != null) {
        setState(() {
          _statusMessage = 'Status saved successfully!';
        });
      } else {
        setState(() {
          _statusMessage = 'Failed to save status';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error saving status: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<DocumentThumbnail?> _getThumbnail(DocumentFile file) async {
    try {
      return await file.thumbnail(width: 300, height: 300, quality: 80);
    } catch (e) {
      print('Error getting thumbnail: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WhatsApp Status Saver'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Images'),
            Tab(text: 'Videos'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: _isLoading ? null : _selectStatusDirectory,
            tooltip: 'Select Status Folder',
          ),
          IconButton(
            icon: const Icon(Icons.download_for_offline),
            onPressed: _isLoading ? null : _selectDownloadDirectory,
            tooltip: 'Select Download Folder',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadStatuses,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_statusMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _statusMessage,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          if (_isLoading)
            const LinearProgressIndicator()
          else if (_statusDir == null)
            Center(
              child: ElevatedButton.icon(
                onPressed: _selectStatusDirectory,
                icon: const Icon(Icons.folder_open),
                label: const Text('Select Status Folder'),
              ),
            )
          else
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Images Tab
                  _buildStatusGrid(
                    _statuses.where((file) {
                      try {
                        return file.type.startsWith('image/');
                      } catch (e) {
                        print('Error checking file type: $e');
                        return false;
                      }
                    }).toList(),
                  ),
                  // Videos Tab
                  _buildStatusGrid(
                    _statuses.where((file) {
                      try {
                        return file.type.startsWith('video/');
                      } catch (e) {
                        print('Error checking file type: $e');
                        return false;
                      }
                    }).toList(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusGrid(List<DocumentFile> files) {
    if (files.isEmpty) {
      return const Center(
        child: Text('No statuses found'),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              FutureBuilder<DocumentThumbnail?>(
                future: _getThumbnail(file),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return Image.memory(
                      snapshot.data!.bytes,
                      fit: BoxFit.cover,
                    );
                  }
                  return const Center(
                    child: Icon(Icons.image, size: 48),
                  );
                },
              ),
              if (file.type?.startsWith('video/') ?? false)
                const Positioned(
                  right: 8,
                  top: 8,
                  child: Icon(
                    Icons.play_circle_outline,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              Positioned(
                right: 8,
                bottom: 8,
                child: IconButton(
                  icon: const Icon(Icons.download),
                  color: Colors.white,
                  onPressed: () => _downloadStatus(file),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
