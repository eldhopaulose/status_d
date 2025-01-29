// // lib/controllers/status_controller.dart
// import 'package:easy_folder_picker/FolderPicker.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'dart:io';
// import 'package:path_provider/path_provider.dart';
// import 'package:path/path.dart' as path;
// import 'package:shared_preferences/shared_preferences.dart';

// class StatusController extends GetxController {
//   RxList<FileSystemEntity> statusItems = <FileSystemEntity>[].obs;
//   RxBool isLoading = false.obs;
//   RxString currentSavePath = ''.obs;

//   // Storage key for SharedPreferences
//   static const String SAVE_PATH_KEY = 'status_save_path';

//   // WhatsApp status paths for different versions
//   final String waPath = "/storage/emulated/0/WhatsApp/Media/.Statuses";
//   final String waBusinessPath =
//       "/storage/emulated/0/WhatsApp Business/Media/.Statuses";
//   final String androidDataPath =
//       "/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/.Statuses";

//   @override
//   void onInit() {
//     super.onInit();
//     loadSavedPath();
//     checkPermission();
//   }

//   Future<void> loadSavedPath() async {
//     final prefs = await SharedPreferences.getInstance();
//     String? savedPath = prefs.getString(SAVE_PATH_KEY);
//     if (savedPath != null && savedPath.isNotEmpty) {
//       currentSavePath.value = savedPath;
//     } else {
//       await savePath('/storage/emulated/0/Ws Statuses');
//     }
//   }

//   Future<void> savePath(String newPath) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString(SAVE_PATH_KEY, newPath);
//     currentSavePath.value = newPath;
//   }

//   Future<void> pickSaveDirectory() async {
//     try {
//       // Using easy_folder_picker to select directory
//       Directory directory = Directory(currentSavePath.value);
//       if (!await directory.exists()) {
//         directory = Directory(FolderPicker.rootPath);
//       }

//       Directory? newDirectory = await FolderPicker.pick(
//         allowFolderCreation: true,
//         context: Get.context!,
//         rootDirectory: directory,
//         shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.all(Radius.circular(10))),
//       );

//       if (newDirectory != null) {
//         await savePath(newDirectory.path);
//         Get.snackbar('Success', 'Save location updated successfully');
//       }
//     } catch (e) {
//       Get.snackbar('Error', 'Failed to pick directory: $e');
//     }
//   }

//   Future<void> checkPermission() async {
//     if (await _requestPermission(Permission.storage)) {
//       loadStatusItems();
//     } else {
//       Get.snackbar('Permission Denied',
//           'Please grant storage permission to access statuses');
//     }

//     // For Android 11 and above
//     if (await _requestPermission(Permission.manageExternalStorage)) {
//       loadStatusItems();
//     }
//   }

//   Future<bool> _requestPermission(Permission permission) async {
//     if (await permission.isGranted) {
//       return true;
//     } else {
//       var result = await permission.request();
//       return result.isGranted;
//     }
//   }

//   Future<void> loadStatusItems() async {
//     isLoading.value = true;
//     statusItems.clear();

//     List<String> possiblePaths = [waPath, waBusinessPath, androidDataPath];

//     for (String statusPath in possiblePaths) {
//       final Directory directory = Directory(statusPath);
//       if (await directory.exists()) {
//         final List<FileSystemEntity> items = directory
//             .listSync()
//             .where((item) =>
//                 item.path.endsWith('.jpg') ||
//                 item.path.endsWith('.mp4') ||
//                 item.path.endsWith('.jpeg'))
//             .toList();
//         statusItems.addAll(items);
//       }
//     }

//     isLoading.value = false;
//   }

//   Future<bool> saveStatus(FileSystemEntity status) async {
//     try {
//       final String fileName = path.basename(status.path);
//       final String savePath = currentSavePath.value;

//       // Create save directory if it doesn't exist
//       final saveDir = Directory(savePath);
//       if (!await saveDir.exists()) {
//         await saveDir.create(recursive: true);
//       }

//       // Copy file to save directory
//       if (status is File) {
//         final String newPath = path.join(savePath, fileName);
//         await (status as File).copy(newPath);
//         Get.snackbar('Success', 'Status saved to: $savePath');
//         return true;
//       }
//       return false;
//     } catch (e) {
//       Get.snackbar('Error', 'Failed to save status: $e');
//       return false;
//     }
//   }
// }

// // lib/views/status_page.dart

// class StatusPage extends StatelessWidget {
//   final StatusController controller = Get.put(StatusController());

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('WhatsApp Status Saver'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.folder),
//             onPressed: () => controller.pickSaveDirectory(),
//           ),
//           IconButton(
//             icon: Icon(Icons.refresh),
//             onPressed: () => controller.loadStatusItems(),
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // Save path display
//           Obx(() => Padding(
//                 padding: EdgeInsets.all(8),
//                 child: Text(
//                   'Save Location: ${controller.currentSavePath.value}',
//                   style: TextStyle(fontSize: 12),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               )),
//           // Status items grid
//           Expanded(
//             child: Obx(() {
//               if (controller.isLoading.value) {
//                 return Center(child: CircularProgressIndicator());
//               }

//               if (controller.statusItems.isEmpty) {
//                 return Center(child: Text('No status items found'));
//               }

//               return GridView.builder(
//                 padding: EdgeInsets.all(8),
//                 gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                   crossAxisCount: 2,
//                   crossAxisSpacing: 8,
//                   mainAxisSpacing: 8,
//                 ),
//                 itemCount: controller.statusItems.length,
//                 itemBuilder: (context, index) {
//                   final item = controller.statusItems[index];
//                   final bool isVideo = item.path.endsWith('.mp4');

//                   return GestureDetector(
//                     onTap: () {
//                       // Implement status preview
//                     },
//                     child: Stack(
//                       children: [
//                         Container(
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(8),
//                             image: DecorationImage(
//                               fit: BoxFit.cover,
//                               image: isVideo
//                                   ? FileImage(File(item.path))
//                                   : FileImage(File(item.path)),
//                             ),
//                           ),
//                         ),
//                         Positioned(
//                           right: 8,
//                           bottom: 8,
//                           child: IconButton(
//                             icon: Icon(Icons.download, color: Colors.white),
//                             onPressed: () => controller.saveStatus(item),
//                           ),
//                         ),
//                         if (isVideo)
//                           Positioned(
//                             left: 8,
//                             top: 8,
//                             child: Icon(Icons.play_circle, color: Colors.white),
//                           ),
//                       ],
//                     ),
//                   );
//                 },
//               );
//             }),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // lib/main.dart

// void main() {
//   runApp(
//     GetMaterialApp(
//       title: 'WhatsApp Status Saver',
//       theme: ThemeData(
//         primarySwatch: Colors.green,
//         visualDensity: VisualDensity.adaptivePlatformDensity,
//       ),
//       home: StatusPage(),
//     ),
//   );
// }

// lib/controllers/status_controller.dart
import 'package:easy_folder_picker/FolderPicker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

class StatusController extends GetxController {
  RxList<FileSystemEntity> statusItems = <FileSystemEntity>[].obs;
  RxBool isLoading = false.obs;
  RxString currentSavePath = ''.obs;

  // Storage keys for SharedPreferences
  static const String SAVE_PATH_KEY = 'status_save_path';
  static const String CUSTOM_SAVE_PATH_KEY = 'custom_save_path';

  // Default save paths
  static const String DEFAULT_SAVE_PATH = '/storage/emulated/0/Ws Statuses';
  static const String CUSTOM_SAVE_DIR = 'StatusSaver';

  // WhatsApp status paths
  final String waPath = "/storage/emulated/0/WhatsApp/Media/.Statuses";
  final String waBusinessPath =
      "/storage/emulated/0/WhatsApp Business/Media/.Statuses";
  final String androidDataPath =
      "/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/.Statuses";

  @override
  void onInit() {
    super.onInit();
    initializeSavePaths();
    checkPermission();
  }

  Future<void> initializeSavePaths() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Try to load custom save path first
      String? customPath = prefs.getString(CUSTOM_SAVE_PATH_KEY);
      if (customPath != null && await Directory(customPath).exists()) {
        currentSavePath.value = customPath;
        return;
      }

      // Try to load default save path
      String? defaultPath = prefs.getString(SAVE_PATH_KEY);
      if (defaultPath != null && await Directory(defaultPath).exists()) {
        currentSavePath.value = defaultPath;
        return;
      }

      // If no valid paths exist, create default path
      await _setupDefaultSavePath();
    } catch (e) {
      print('Error initializing save paths: $e');
      await _setupDefaultSavePath();
    }
  }

  Future<void> _setupDefaultSavePath() async {
    try {
      final Directory defaultDir = Directory(DEFAULT_SAVE_PATH);
      if (!await defaultDir.exists()) {
        await defaultDir.create(recursive: true);
      }
      await savePath(DEFAULT_SAVE_PATH, isCustom: false);
    } catch (e) {
      print('Error setting up default save path: $e');
      Get.snackbar('Error', 'Failed to set up default save location');
    }
  }

  Future<void> savePath(String newPath, {bool isCustom = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = isCustom ? CUSTOM_SAVE_PATH_KEY : SAVE_PATH_KEY;

      // Ensure directory exists
      final Directory dir = Directory(newPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // Save to SharedPreferences
      await prefs.setString(key, newPath);
      currentSavePath.value = newPath;
    } catch (e) {
      print('Error saving path: $e');
      Get.snackbar('Error', 'Failed to save path: $e');
    }
  }

  Future<void> setCustomSavePath(String customPath) async {
    try {
      // Get the external storage directory
      final Directory? externalDir = await getExternalStorageDirectory();
      if (externalDir == null) {
        throw Exception('External storage directory not available');
      }

      // Create custom save path
      final String fullCustomPath =
          path.join(externalDir.path, CUSTOM_SAVE_DIR, customPath);

      await savePath(fullCustomPath, isCustom: true);
      Get.snackbar('Success', 'Custom save location set successfully');
    } catch (e) {
      print('Error setting custom save path: $e');
      Get.snackbar('Error', 'Failed to set custom save location: $e');
    }
  }

  Future<void> pickSaveDirectory() async {
    try {
      Directory directory = Directory(currentSavePath.value);
      if (!await directory.exists()) {
        directory = Directory(FolderPicker.rootPath);
      }

      Directory? newDirectory = await FolderPicker.pick(
        allowFolderCreation: true,
        context: Get.context!,
        rootDirectory: directory,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10))),
      );

      if (newDirectory != null) {
        await savePath(newDirectory.path, isCustom: true);
        Get.snackbar('Success', 'Save location updated successfully');
      }
    } catch (e) {
      print('Error picking directory: $e');
      Get.snackbar('Error', 'Failed to pick directory: $e');
    }
  }

  Future<void> resetToDefaultPath() async {
    try {
      await _setupDefaultSavePath();
      Get.snackbar('Success', 'Reset to default save location');
    } catch (e) {
      print('Error resetting to default path: $e');
      Get.snackbar('Error', 'Failed to reset to default location');
    }
  }

  Future<void> checkPermission() async {
    if (await _requestPermission(Permission.storage)) {
      loadStatusItems();
    } else {
      Get.snackbar('Permission Denied',
          'Please grant storage permission to access statuses');
    }

    // For Android 11 and above
    if (await _requestPermission(Permission.manageExternalStorage)) {
      loadStatusItems();
    }
  }

  Future<bool> _requestPermission(Permission permission) async {
    if (await permission.isGranted) {
      return true;
    } else {
      var result = await permission.request();
      return result.isGranted;
    }
  }

  Future<void> loadStatusItems() async {
    isLoading.value = true;
    statusItems.clear();

    try {
      List<String> possiblePaths = [waPath, waBusinessPath, androidDataPath];

      for (String statusPath in possiblePaths) {
        final Directory directory = Directory(statusPath);
        if (await directory.exists()) {
          final List<FileSystemEntity> items = directory
              .listSync()
              .where((item) =>
                  item.path.endsWith('.jpg') ||
                  item.path.endsWith('.mp4') ||
                  item.path.endsWith('.jpeg'))
              .toList();
          statusItems.addAll(items);
        }
      }
    } catch (e) {
      print('Error loading status items: $e');
      Get.snackbar('Error', 'Failed to load status items');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> saveStatus(FileSystemEntity status) async {
    try {
      final String fileName = path.basename(status.path);
      final String savePath = currentSavePath.value;

      // Create save directory if it doesn't exist
      final saveDir = Directory(savePath);
      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }

      // Copy file to save directory
      if (status is File) {
        final String newPath = path.join(savePath, fileName);
        await (status as File).copy(newPath);
        Get.snackbar('Success', 'Status saved to: $savePath');
        return true;
      }
      return false;
    } catch (e) {
      print('Error saving status: $e');
      Get.snackbar('Error', 'Failed to save status: $e');
      return false;
    }
  }
}

class StatusPage extends StatelessWidget {
  final StatusController controller = Get.put(StatusController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('WhatsApp Status Saver'),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.folder),
            onSelected: (value) async {
              switch (value) {
                case 'pick':
                  await controller.pickSaveDirectory();
                  break;
                case 'reset':
                  await controller.resetToDefaultPath();
                  break;
                case 'custom':
                  _showCustomPathDialog(context);
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: 'pick',
                child: ListTile(
                  leading: Icon(Icons.folder_open),
                  title: Text('Pick Directory'),
                ),
              ),
              PopupMenuItem(
                value: 'custom',
                child: ListTile(
                  leading: Icon(Icons.create_new_folder),
                  title: Text('Set Custom Path'),
                ),
              ),
              PopupMenuItem(
                value: 'reset',
                child: ListTile(
                  leading: Icon(Icons.restore),
                  title: Text('Reset to Default'),
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => controller.loadStatusItems(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Save path display with better styling
          Obx(() => Container(
                padding: EdgeInsets.all(8),
                color: Colors.grey[200],
                child: Row(
                  children: [
                    Icon(Icons.folder_open, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Save Location: ${controller.currentSavePath.value}',
                        style: TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )),
          // Status items grid
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return Center(child: CircularProgressIndicator());
              }

              if (controller.statusItems.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.hourglass_empty, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No status items found',
                        style: TextStyle(color: Colors.grey),
                      ),
                      TextButton(
                        onPressed: () => controller.loadStatusItems(),
                        child: Text('Refresh'),
                      ),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: EdgeInsets.all(8),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: controller.statusItems.length,
                itemBuilder: (context, index) {
                  final item = controller.statusItems[index];
                  final bool isVideo = item.path.endsWith('.mp4');

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(item.path),
                            fit: BoxFit.cover,
                          ),
                        ),
                        if (isVideo)
                          Positioned(
                            left: 8,
                            top: 8,
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Icon(
                                Icons.play_circle,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.download, color: Colors.white),
                              onPressed: () => controller.saveStatus(item),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showCustomPathDialog(BuildContext context) {
    final TextEditingController pathController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Set Custom Save Path'),
          content: TextField(
            controller: pathController,
            decoration: InputDecoration(
              hintText: 'Enter folder name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text('Save'),
              onPressed: () {
                if (pathController.text.isNotEmpty) {
                  controller.setCustomSavePath(pathController.text);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}

// lib/main.dart
void main() {
  runApp(
    GetMaterialApp(
      title: 'WhatsApp Status Saver',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.green,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: StatusPage(),
    ),
  );
}

// lib/utils/path_utils.dart

class PathUtils {
  static Future<bool> isValidDirectory(String path) async {
    try {
      final directory = Directory(path);
      return await directory.exists();
    } catch (e) {
      return false;
    }
  }

  static Future<bool> createDirectoryIfNotExists(String path) async {
    try {
      final directory = Directory(path);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      return true;
    } catch (e) {
      print('Error creating directory: $e');
      return false;
    }
  }

  static String sanitizePath(String path) {
    // Remove invalid characters and spaces
    return path.replaceAll(RegExp(r'[<>:"/\\|?*]'), '').replaceAll(' ', '_');
  }

  static String getUniqueFileName(String directory, String fileName) {
    String baseFileName = path.basenameWithoutExtension(fileName);
    String extension = path.extension(fileName);
    String newPath = path.join(directory, fileName);
    int counter = 1;

    while (File(newPath).existsSync()) {
      newPath = path.join(
        directory,
        '${baseFileName}_${counter}${extension}',
      );
      counter++;
    }

    return path.basename(newPath);
  }
}

class StatusGridItem extends StatelessWidget {
  final FileSystemEntity item;
  final VoidCallback onDownload;
  final VoidCallback onTap;

  const StatusGridItem({
    Key? key,
    required this.item,
    required this.onDownload,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isVideo = item.path.endsWith('.mp4');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(item.path),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: Icon(Icons.broken_image, color: Colors.grey[600]),
                  );
                },
              ),
            ),
            if (isVideo)
              Positioned(
                left: 8,
                top: 8,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.play_circle,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: Icon(Icons.download, color: Colors.white),
                  onPressed: onDownload,
                  tooltip: 'Save Status',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
