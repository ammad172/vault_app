import 'dart:convert';
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path_provider/path_provider.dart';
import 'vault_service.dart';
import '../models/vault_entry.dart';

/// Service for backing up and restoring vault data to/from Google Drive
class BackupService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      drive.DriveApi.driveFileScope,
    ],
  );

  Future<GoogleSignInAccount?> signIn() async {
    return await _googleSignIn.signIn();
  }

  Future<void> backupToDrive() async {
    final account = _googleSignIn.currentUser ?? await _googleSignIn.signIn();
    if (account == null) throw Exception('User not signed in');

    final authClient = await _googleSignIn.authenticatedClient();
    if (authClient == null) throw Exception('Could not authenticate');

    final driveApi = drive.DriveApi(authClient);

    // 1. Export vault data to JSON (now includes entry IDs)
    final entries = VaultService.getEntriesSnapshot();
    final data = entries.map((e) => e.toMap()).toList();
    final jsonString = jsonEncode(data);

    // 2. Write to temp file
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/vault_backup.json');
    await file.writeAsString(jsonString);

    // 3. Upload to Drive
    // Check if file exists to update it, or create new
    final fileList = await driveApi.files.list(
      spaces: 'appDataFolder',
      q: "name = 'vault_backup.json'",
    );

    final media = drive.Media(file.openRead(), file.lengthSync());

    if (fileList.files != null && fileList.files!.isNotEmpty) {
      // Update existing
      final existingFileId = fileList.files!.first.id!;
      await driveApi.files.update(
        drive.File(),
        existingFileId,
        uploadMedia: media,
      );
    } else {
      // Create new
      final driveFile = drive.File()
        ..name = 'vault_backup.json'
        ..parents = ['appDataFolder'];
      
      await driveApi.files.create(
        driveFile,
        uploadMedia: media,
      );
    }
  }

  Future<void> restoreFromDrive() async {
    final account = _googleSignIn.currentUser ?? await _googleSignIn.signIn();
    if (account == null) throw Exception('User not signed in');

    final authClient = await _googleSignIn.authenticatedClient();
    if (authClient == null) throw Exception('Could not authenticate');
    
    final driveApi = drive.DriveApi(authClient);

    // 1. List files in appDataFolder
    final fileList = await driveApi.files.list(
      spaces: 'appDataFolder',
      q: "name = 'vault_backup.json'",
    );

    if (fileList.files?.isEmpty ?? true) {
      throw Exception('No backup found');
    }

    final fileId = fileList.files!.first.id!;

    // 2. Download file
    final media = await driveApi.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final jsonString = await utf8.decodeStream(media.stream);
    
    // 3. Import data with ID preservation
    final List<dynamic> list = jsonDecode(jsonString);
    
    for (final item in list) {
       if (item is Map) {
         // Preserve the original ID from backup (now included in toMap)
         final id = item['id'] as String? ?? 
                    DateTime.now().microsecondsSinceEpoch.toString();
         final entry = VaultEntry.fromMap(id, item);
         await VaultService.saveEntry(entry);
       }
    }
  }
}
