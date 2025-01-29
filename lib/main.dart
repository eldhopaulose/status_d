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

  // Storage key for SharedPreferences
  static const String SAVE_PATH_KEY = 'status_save_path';

  // WhatsApp status paths for different versions
  final String waPath = "/storage/emulated/0/WhatsApp/Media/.Statuses";
  final String waBusinessPath =
      "/storage/emulated/0/WhatsApp Business/Media/.Statuses";
  final String androidDataPath =
      "/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/.Statuses";

  @override
  void onInit() {
    super.onInit();
    loadSavedPath();
    checkPermission();
  }

  Future<void> loadSavedPath() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedPath = prefs.getString(SAVE_PATH_KEY);
    if (savedPath != null && savedPath.isNotEmpty) {
      currentSavePath.value = savedPath;
    } else {
      await savePath('/storage/emulated/0/Ws Statuses');
    }
  }

  Future<void> savePath(String newPath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SAVE_PATH_KEY, newPath);
    currentSavePath.value = newPath;
  }

  Future<void> pickSaveDirectory() async {
    try {
      // Using easy_folder_picker to select directory
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
        await savePath(newDirectory.path);
        Get.snackbar('Success', 'Save location updated successfully');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick directory: $e');
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

    isLoading.value = false;
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
      Get.snackbar('Error', 'Failed to save status: $e');
      return false;
    }
  }
}

// lib/views/status_page.dart

class StatusPage extends StatelessWidget {
  final StatusController controller = Get.put(StatusController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('WhatsApp Status Saver'),
        actions: [
          IconButton(
            icon: Icon(Icons.folder),
            onPressed: () => controller.pickSaveDirectory(),
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => controller.loadStatusItems(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Save path display
          Obx(() => Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'Save Location: ${controller.currentSavePath.value}',
                  style: TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )),
          // Status items grid
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return Center(child: CircularProgressIndicator());
              }

              if (controller.statusItems.isEmpty) {
                return Center(child: Text('No status items found'));
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

                  return GestureDetector(
                    onTap: () {
                      // Implement status preview
                    },
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              fit: BoxFit.cover,
                              image: isVideo
                                  ? FileImage(File(item.path))
                                  : FileImage(File(item.path)),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: IconButton(
                            icon: Icon(Icons.download, color: Colors.white),
                            onPressed: () => controller.saveStatus(item),
                          ),
                        ),
                        if (isVideo)
                          Positioned(
                            left: 8,
                            top: 8,
                            child: Icon(Icons.play_circle, color: Colors.white),
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
}

// lib/main.dart

void main() {
  runApp(
    GetMaterialApp(
      title: 'WhatsApp Status Saver',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: StatusPage(),
    ),
  );
}
