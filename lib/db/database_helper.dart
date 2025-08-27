// lib/db/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/transaction_model.dart' as app_models;
import '../models/reminder_model.dart'; // Import correct Reminder model

class DatabaseHelper {
  static const _databaseName = "FinancialRecords.db";
  // Version 2 assumes: v1 was transactions only, v2 adds reminders table (without completionDate)
  static const _databaseVersion = 2;

  // Transactions Table
  static const table = 'transactions';
  static const columnId = 'id';
  static const columnTitle = 'title';
  static const columnAmount = 'amount';
  static const columnDate = 'date';
  static const columnType = 'type';
  static const columnCategory = 'category';
  static const columnDescription = 'description';

  // Reminders Table
  static const reminderTable = 'reminders';
  static const columnReminderId = 'id';
  static const columnReminderTitle = 'title';
  static const columnReminderPersonName = 'personName';
  static const columnReminderPartyType = 'partyType';
  static const columnReminderAmount = 'amount';
  static const columnReminderPaymentMethod = 'paymentMethod';
  static const columnReminderDueDate = 'dueDate';
  static const columnReminderStatus = 'status';
  static const columnReminderNotes = 'notes';
  // NO columnReminderCompletionDate defined

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $table (
            $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnTitle TEXT NOT NULL,
            $columnAmount REAL NOT NULL,
            $columnDate TEXT NOT NULL,
            $columnType TEXT NOT NULL,
            $columnCategory TEXT NOT NULL,
            $columnDescription TEXT
          )
          ''');

    await db.execute('''
          CREATE TABLE $reminderTable (
            $columnReminderId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnReminderTitle TEXT NOT NULL,
            $columnReminderPersonName TEXT NOT NULL,
            $columnReminderPartyType TEXT NOT NULL,
            $columnReminderAmount REAL NOT NULL,
            $columnReminderPaymentMethod TEXT NOT NULL,
            $columnReminderDueDate TEXT NOT NULL,
            $columnReminderStatus TEXT NOT NULL,
            $columnReminderNotes TEXT
          )
          ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) { // If migrating from a DB version that didn't have reminders table
      await db.execute('''
            CREATE TABLE $reminderTable (
              $columnReminderId INTEGER PRIMARY KEY AUTOINCREMENT,
              $columnReminderTitle TEXT NOT NULL,
              $columnReminderPersonName TEXT NOT NULL,
              $columnReminderPartyType TEXT NOT NULL,
              $columnReminderAmount REAL NOT NULL,
              $columnReminderPaymentMethod TEXT NOT NULL,
              $columnReminderDueDate TEXT NOT NULL,
              $columnReminderStatus TEXT NOT NULL,
              $columnReminderNotes TEXT
            )
            ''');
    }
    // Add other upgrade paths if needed for future versions
  }

  // --- Transaction Methods --- (Keep these as they were)
  Future<int> insert(app_models.Transaction transaction) async {
    Database dbClient = await instance.database;
    return await dbClient.insert(table, transaction.toMap());
  }

  Future<List<app_models.Transaction>> getAllTransactions() async {
    Database dbClient = await instance.database;
    final List<Map<String, dynamic>> maps = await dbClient.query(table, orderBy: '$columnDate DESC');
    return List.generate(maps.length, (i) {
      return app_models.Transaction.fromMap(maps[i]);
    });
  }

  Future<List<app_models.Transaction>> getTransactionsByType(app_models.TransactionType type) async {
    Database dbClient = await instance.database;
    final List<Map<String, dynamic>> maps = await dbClient.query(
      table,
      where: '$columnType = ?',
      whereArgs: [type.toString()],
      orderBy: '$columnDate DESC',
    );
    return List.generate(maps.length, (i) {
      return app_models.Transaction.fromMap(maps[i]);
    });
  }

  Future<List<app_models.Transaction>> getTransactionsByDateRange(DateTime startDate, DateTime endDate) async {
    Database dbClient = await instance.database;
    DateTime startOfDay = DateTime(startDate.year, startDate.month, startDate.day);
    DateTime endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    final List<Map<String, dynamic>> maps = await dbClient.query(
      table,
      where: '$columnDate BETWEEN ? AND ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: '$columnDate DESC',
    );
    return List.generate(maps.length, (i) {
      return app_models.Transaction.fromMap(maps[i]);
    });
  }

  Future<List<app_models.Transaction>> getTransactionsForDay(DateTime date) async {
    Database dbClient = await instance.database;
    DateTime startOfDay = DateTime(date.year, date.month, date.day);
    DateTime endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    final List<Map<String, dynamic>> maps = await dbClient.query(
      table,
      where: '$columnDate BETWEEN ? AND ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: '$columnDate DESC',
    );
    return List.generate(maps.length, (i) {
      return app_models.Transaction.fromMap(maps[i]);
    });
  }

  Future<List<app_models.Transaction>> getTransactionsForMonth(int year, int month) async {
    Database dbClient = await instance.database;
    DateTime firstDayOfMonth = DateTime(year, month, 1);
    DateTime lastDayOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);
    final List<Map<String, dynamic>> maps = await dbClient.query(
      table,
      where: '$columnDate BETWEEN ? AND ?',
      whereArgs: [firstDayOfMonth.toIso8601String(), lastDayOfMonth.toIso8601String()],
      orderBy: '$columnDate DESC',
    );
    return List.generate(maps.length, (i) {
      return app_models.Transaction.fromMap(maps[i]);
    });
  }

  Future<int> update(app_models.Transaction transaction) async {
    Database dbClient = await instance.database;
    return await dbClient.update(table, transaction.toMap(),
        where: '$columnId = ?', whereArgs: [transaction.id]);
  }

  Future<int> delete(int id) async {
    Database dbClient = await instance.database;
    return await dbClient.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<double> getTotalIncome({DateTime? startDate, DateTime? endDate}) async {
    Database dbClient = await instance.database;
    String whereClause = "$columnType = ?";
    List<dynamic> whereArgs = [app_models.TransactionType.income.toString()];

    if (startDate != null && endDate != null) {
      DateTime startOfDay = DateTime(startDate.year, startDate.month, startDate.day);
      DateTime endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      whereClause += " AND $columnDate BETWEEN ? AND ?";
      whereArgs.add(startOfDay.toIso8601String());
      whereArgs.add(endOfDay.toIso8601String());
    }

    var result = await dbClient.rawQuery(
        "SELECT SUM($columnAmount) as Total FROM $table WHERE $whereClause",
        whereArgs);
    return (result.first['Total'] as double?) ?? 0.0;
  }

  Future<double> getTotalExpense({DateTime? startDate, DateTime? endDate}) async {
    Database dbClient = await instance.database;
    String whereClause = "$columnType = ?";
    List<dynamic> whereArgs = [app_models.TransactionType.expense.toString()];

    if (startDate != null && endDate != null) {
      DateTime startOfDay = DateTime(startDate.year, startDate.month, startDate.day);
      DateTime endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      whereClause += " AND $columnDate BETWEEN ? AND ?";
      whereArgs.add(startOfDay.toIso8601String());
      whereArgs.add(endOfDay.toIso8601String());
    }
    var result = await dbClient.rawQuery(
        "SELECT SUM($columnAmount) as Total FROM $table WHERE $whereClause",
        whereArgs);
    return (result.first['Total'] as double?) ?? 0.0;
  }


  // --- Reminder Methods ---
  Future<int> insertReminder(Reminder reminder) async {
    Database dbClient = await instance.database;
    // The reminder.toMap() should NOT include completionDate now
    return await dbClient.insert(reminderTable, reminder.toMap());
  }

  Future<List<Reminder>> getAllReminders() async {
    Database dbClient = await instance.database;
    final List<Map<String, dynamic>> maps = await dbClient.query(reminderTable, orderBy: '$columnReminderDueDate ASC');
    return List.generate(maps.length, (i) {
      // Reminder.fromMap should NOT expect completionDate
      return Reminder.fromMap(maps[i]);
    });
  }

  Future<int> updateReminder(Reminder reminder) async {
    Database dbClient = await instance.database;
    // The reminder.toMap() should NOT include completionDate now
    return await dbClient.update(reminderTable, reminder.toMap(),
        where: '$columnReminderId = ?', whereArgs: [reminder.id]);
  }

  Future<int> deleteReminder(int id) async {
    Database dbClient = await instance.database;
    return await dbClient.delete(reminderTable, where: '$columnReminderId = ?', whereArgs: [id]);
  }
}