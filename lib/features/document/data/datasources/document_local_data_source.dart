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
      version: 1,
      onCreate: (db, version) => db.execute('''
        CREATE TABLE $_table (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          sourceType TEXT NOT NULL,
          filePath TEXT NOT NULL,
          extractedText TEXT NOT NULL,
          detectedLanguage TEXT,
          createdAt TEXT NOT NULL
        )
      '''),
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
