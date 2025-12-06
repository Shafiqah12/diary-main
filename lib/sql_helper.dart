import 'package:flutter/foundation.dart'; // For kIsWeb
// Core sembast
import 'package:sembast/sembast_io.dart'; // For mobile/desktop (file system)
import 'package:sembast_web/sembast_web.dart'; // For web (IndexedDB)
import 'package:path_provider/path_provider.dart'; // To get app directory for mobile/desktop
import 'package:path/path.dart'; // To join paths

class SQLHelper {
  static const String dbName = 'diaryawie.db';
  static Database? _database; // Sembast database instance

  // Private constructor to prevent direct instantiation
  SQLHelper._();

  // Singleton instance
  static final SQLHelper _instance = SQLHelper._();

  // Factory constructor to return the singleton instance
  factory SQLHelper() {
    return _instance;
  }

  // Get the database instance
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _openDatabase();
    return _database!;
  }

  // Open the database based on the platform
  static Future<Database> _openDatabase() async {
    if (kIsWeb) {
      // For web, use IndexedDB
      return await databaseFactoryWeb.openDatabase(dbName);
    } else {
      // For mobile/desktop, use file system
      final appDocumentDir = await getApplicationDocumentsDirectory();
      final dbPath = join(appDocumentDir.path, dbName);
      return await databaseFactoryIo.openDatabase(dbPath);
    }
  }

  // Define the store (similar to a table in relational databases)
  // We use `int` as the key type because we want auto-incrementing IDs.
  static final _diaryStore = intMapStoreFactory.store('diaries');

  // Create new diary
  // This method inserts a new record into the database.
  static Future<int> createDiary(
      String feeling, String? description, String createdAt, String? emotionImage) async { // Added emotionImage
    final db = await database;
    final data = {
      'feeling': feeling,
      'description': description,
      'createdAt': createdAt,
      'emotionImage': emotionImage, // Store emotion image path
    };
    // Add the record to the store; returns the auto-generated key (ID).
    final id = await _diaryStore.add(db, data);
    return id;
  }

  // Read all diaries
  // This method fetches all records from the database.
  static Future<List<Map<String, dynamic>>> getDiaries() async {
    final db = await database;
    // Find all records; returns a list of snapshots.
    final snapshots = await _diaryStore.find(db);
    // Convert snapshots to a list of maps, including the record's key (ID).
    return snapshots.map((snapshot) {
      final Map<String, dynamic> mutableMap = Map<String, dynamic>.from(snapshot.value);
      mutableMap['id'] = snapshot.key; // Add the key (ID) to the mutable map
      return mutableMap;
    }).toList();
  }

  // Read a single diary by id
  // This method fetches a single record identified by its ID (key).
  static Future<Map<String, dynamic>?> getSingleDiary(int id) async {
    final db = await database;
    // Get a specific record snapshot by its key.
    final snapshot = await _diaryStore.record(id).getSnapshot(db);
    if (snapshot != null) {
      // IMPORTANT: snapshot.value returns an immutable map. Create a mutable copy.
      final Map<String, dynamic> mutableMap = Map<String, dynamic>.from(snapshot.value);
      mutableMap['id'] = snapshot.key; // Add the key (ID) to the mutable map
      return mutableMap;
    }
    return null; // Return null if no record is found with the given ID.
  }

  // Update an diary by id
  // This method updates an existing record identified by its ID (key).
  static Future<Object> updateDiary(
      int id, String feeling, String? description, String createdAt, String? emotionImage) async { // Added emotionImage
    final db = await database;
    final data = {
      'feeling': feeling,
      'description': description,
      'createdAt': createdAt,
      'emotionImage': emotionImage, // Update emotion image path
    };
    // Update the record; returns the count of updated records (1 if successful, 0 if not found).
    final count = await _diaryStore.record(id).update(db, data);
    return count ?? 0; // If update returns null (record not found), return 0. This line is typically fine.
  }

  // Delete a diary by id
  // This method deletes a record identified by its ID (key).
  static Future<void> deleteDiary(int id) async {
    final db = await database;
    // Delete the record; returns the count of deleted records (1 if successful, 0 if not found).
    final count = await _diaryStore.record(id).delete(db);
    if (kDebugMode) {
      print('Deleted $count record(s) with ID: $id');
    }
  }
}
