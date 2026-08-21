import 'package:doc_sense/features/document/data/models/document_model.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Persists scanned documents locally via SQLite (sqflite).
abstract class DocumentLocalDataSource {
  Future<void> save(DocumentModel document);
  Future<List<DocumentModel>> getAll();
  Future<void> delete(String id);
}

class DocumentLocalDataSourceImpl implements DocumentLocalDataSource {
  static const _dbName = 'doc_sense.db';
  static const _table = 'documents';

  Database? _db;

  Future<Database> get _database async {
    final existing = _db;
    if (existing != null) return existing;
    final db = await _open();
    _db = db;
    return db;
  }

  Future<Database> _open() async {
    final dbPath = p.join(await getDatabasesPath(), _dbName);
    return openDatabase(
      dbPath,
      version: 2,
      onCreate: (db, version) => db.execute('''
        CREATE TABLE $_table (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          sourceType TEXT NOT NULL,
          filePath TEXT NOT NULL,
          extractedText TEXT NOT NULL,
          detectedLanguage TEXT,
          isFavorite INTEGER NOT NULL DEFAULT 0,
          isImportant INTEGER NOT NULL DEFAULT 0,
          createdAt TEXT NOT NULL
        )
      '''),
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE $_table ADD COLUMN isFavorite INTEGER NOT NULL DEFAULT 0',
          );
          await db.execute(
            'ALTER TABLE $_table ADD COLUMN isImportant INTEGER NOT NULL DEFAULT 0',
          );
        }
      },
    );
  }

  @override
  Future<void> save(DocumentModel document) async {
    final db = await _database;
    await db.insert(
      _table,
      document.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<DocumentModel>> getAll() async {
    final db = await _database;
    final rows = await db.query(_table, orderBy: 'createdAt DESC');
    return rows.map(DocumentModel.fromJson).toList();
  }

  @override
  Future<void> delete(String id) async {
    final db = await _database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}
