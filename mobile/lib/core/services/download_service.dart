import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart' as path;
import 'package:teekoob/core/services/network_service.dart';
import 'package:teekoob/core/config/app_config.dart';
import 'package:teekoob/core/models/book_model.dart';
import 'package:teekoob/core/models/podcast_model.dart';
import 'package:permission_handler/permission_handler.dart';

enum DownloadStatus {
  queued,
  downloading,
  completed,
  failed,
  paused,
  cancelled,
}

enum DownloadType {
  bookAudio,
  bookEbook,
  podcastEpisode,
}

class DownloadItem {
  final String id;
  final String itemId; // book_id or podcast_episode_id
  final DownloadType type;
  final String url;
  final String? localPath;
  final DownloadStatus status;
  final int? progress; // 0-100
  final int? totalBytes;
  final int? downloadedBytes;
  final String? error;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? podcastId; // For episodes, store the podcast ID

  DownloadItem({
    required this.id,
    required this.itemId,
    required this.type,
    required this.url,
    this.localPath,
    required this.status,
    this.progress,
    this.totalBytes,
    this.downloadedBytes,
    this.error,
    required this.createdAt,
    this.completedAt,
    this.podcastId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_id': itemId,
      'type': type.toString().split('.').last,
      'url': url,
      'local_path': localPath,
      'status': status.toString().split('.').last,
      'progress': progress,
      'total_bytes': totalBytes,
      'downloaded_bytes': downloadedBytes,
      'error': error,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'podcast_id': podcastId,
    };
  }

  factory DownloadItem.fromJson(Map<String, dynamic> json) {
    return DownloadItem(
      id: json['id'] as String,
      itemId: json['item_id'] as String,
      type: DownloadType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => DownloadType.bookAudio,
      ),
      url: json['url'] as String,
      localPath: json['local_path'] as String?,
      status: DownloadStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => DownloadStatus.queued,
      ),
      progress: json['progress'] as int?,
      totalBytes: json['total_bytes'] as int?,
      downloadedBytes: json['downloaded_bytes'] as int?,
      error: json['error'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      podcastId: json['podcast_id'] as String?,
    );
  }
}

class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  final NetworkService _networkService = NetworkService();
  Database? _database;
  final Map<String, DownloadItem> _activeDownloads = {};
  static bool _databaseFactoryInitialized = false;
  static Future<void>? _initDatabaseFuture;
  
  Future<void> initialize() async {
    _networkService.initialize();
    await _initDatabase();
  }

  Future<void> _initDatabase() async {
    // If database is already initialized, return
    if (_database != null) return;
    
    // If initialization is in progress, wait for it
    if (_initDatabaseFuture != null) {
      await _initDatabaseFuture;
      return;
    }
    
    // Start initialization and store the future
    _initDatabaseFuture = _doInitDatabase();
    await _initDatabaseFuture;
  }
  
  Future<void> _doInitDatabase() async {
    try {
      // Initialize databaseFactory for web platform (only once, globally)
      if (kIsWeb && !_databaseFactoryInitialized) {
        // Initialize FFI for web using sqflite_common_ffi_web
        databaseFactory = databaseFactoryFfiWeb;
        _databaseFactoryInitialized = true;
        print('🔧 DownloadService: Initialized databaseFactoryFfiWeb for web platform');
      } else if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS) && !_databaseFactoryInitialized) {
        // Initialize FFI for desktop platforms (Linux, Windows, macOS)
        // Note: sqfliteFfiInit() may not be needed in newer versions, but try it
        try {
          sqfliteFfiInit();
        } catch (e) {
          print('⚠️ DownloadService: sqfliteFfiInit() failed (might not be needed): $e');
        }
        databaseFactory = databaseFactoryFfi;
        _databaseFactoryInitialized = true;
        print('🔧 DownloadService: Initialized databaseFactoryFfi for desktop platform');
      }
      // Note: For Android/iOS, use the default databaseFactory (no initialization needed)
      
      // For web, use a simple string path. For mobile/desktop, use getDatabasesPath()
      String dbPath;
      if (kIsWeb) {
        // Web uses a simple string for the database name
        dbPath = 'downloads.db';
        print('🔧 DownloadService: Using web database path: $dbPath');
      } else {
        // Mobile and desktop use full path
        dbPath = path.join(await getDatabasesPath(), 'downloads.db');
        print('🔧 DownloadService: Using platform database path: $dbPath');
      }
      
      _database = await openDatabase(
        dbPath,
        version: 2, // Incremented to trigger onUpgrade for existing databases
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS downloads (
            id TEXT PRIMARY KEY,
            item_id TEXT NOT NULL,
            type TEXT NOT NULL,
            url TEXT NOT NULL,
            local_path TEXT,
            status TEXT NOT NULL,
            progress INTEGER,
            total_bytes INTEGER,
            downloaded_bytes INTEGER,
            error TEXT,
            created_at TEXT NOT NULL,
            completed_at TEXT,
            podcast_id TEXT
          )
        ''');
        
        // Add podcast_id column if it doesn't exist (for migrations)
        try {
          await db.execute('ALTER TABLE downloads ADD COLUMN podcast_id TEXT');
        } catch (e) {
          // Column might already exist, ignore
        }
        
        await db.execute('CREATE INDEX IF NOT EXISTS idx_item_id ON downloads(item_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_status ON downloads(status)');
        
        // Create book_metadata table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS book_metadata (
            book_id TEXT PRIMARY KEY,
            metadata TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        
        // Create podcast_metadata table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS podcast_metadata (
            podcast_id TEXT PRIMARY KEY,
            metadata TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Ensure metadata tables exist (for existing databases)
        try {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS book_metadata (
              book_id TEXT PRIMARY KEY,
              metadata TEXT NOT NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS podcast_metadata (
              podcast_id TEXT PRIMARY KEY,
              metadata TEXT NOT NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
          
          // Add podcast_id column if it doesn't exist
          try {
            await db.execute('ALTER TABLE downloads ADD COLUMN podcast_id TEXT');
          } catch (e) {
            // Column might already exist
          }
        } catch (e) {
          print('⚠️ Error upgrading database: $e');
        }
      },
      );
      print('✅ DownloadService: Database initialized successfully');
    } catch (e) {
      print('❌ DownloadService: Error initializing database: $e');
      rethrow;
    } finally {
      // Clear the future once initialization is complete
      _initDatabaseFuture = null;
    }
  }

  Future<bool> _requestStoragePermission() async {
    // On web, storage permissions work differently - we can proceed
    if (kIsWeb) {
      print('🔐 Web platform: Storage permissions not required');
      return true;
    }
    
    if (Platform.isAndroid) {
      print('🔐 Requesting storage permissions...');
      
      // For app-specific directories, we usually don't need permissions
      // But let's try to get permissions for better compatibility
      try {
        // Try app-specific storage first (usually doesn't need permission)
        final appDir = await getExternalStorageDirectory();
        if (appDir != null) {
          final testDir = Directory(path.join(appDir.path, 'downloads'));
          if (!await testDir.exists()) {
            await testDir.create(recursive: true);
          }
          print('✅ App-specific storage accessible');
          return true;
        }
      } catch (e) {
        print('⚠️ App-specific storage test failed: $e');
      }
      
      // Try storage permission for older Android
      try {
        final storageStatus = await Permission.storage.request();
        if (storageStatus.isGranted) {
          print('✅ Storage permission granted');
          return true;
        }
      } catch (e) {
        print('⚠️ Storage permission request failed: $e');
      }
      
      // Try audio permission for Android 13+
      try {
        final audioStatus = await Permission.audio.request();
        if (audioStatus.isGranted) {
          print('✅ Audio permission granted');
          return true;
        }
      } catch (e) {
        print('⚠️ Audio permission request failed: $e');
      }
      
      print('⚠️ No explicit permissions granted, but continuing with app-specific directory');
      return true; // Return true anyway - app-specific dir usually works
    }
    return true; // iOS doesn't need explicit permission for app directory
  }

  Future<String> _getDownloadDirectory() async {
    // On web, we can't use traditional file system paths
    // Use a virtual path that works with browser storage
    if (kIsWeb) {
      // For web, we'll use a virtual path format
      // The actual storage will be handled differently (IndexedDB or browser download)
      return '/downloads';
    }
    
    if (Platform.isAndroid) {
      // Use app-specific external directory
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        final downloadsDir = Directory(path.join(directory.path, 'downloads'));
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }
        return downloadsDir.path;
      }
    }
    
    // Fallback to app documents directory
    final directory = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory(path.join(directory.path, 'downloads'));
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }
    return downloadsDir.path;
  }

  String _getFileName(String url, DownloadType type) {
    final uri = Uri.parse(url);
    final fileName = path.basename(uri.path);
    
    if (fileName.isEmpty || !fileName.contains('.')) {
      final extension = type == DownloadType.bookEbook 
          ? (url.contains('.pdf') ? '.pdf' : '.txt')
          : (url.contains('.mp3') ? '.mp3' : '.m4a');
      return '${DateTime.now().millisecondsSinceEpoch}$extension';
    }
    
    return fileName;
  }

  // Download complete book (metadata, ebook content, and audio)
  Future<void> downloadCompleteBook(Book book) async {
    final hasPermission = await _requestStoragePermission();
    if (!hasPermission) {
      throw Exception('Storage permission denied');
    }

    print('📥 DownloadService: Starting complete download for book: ${book.id}');
    
    try {
      // Download book metadata (store as JSON)
      print('📥 DownloadService: Saving book metadata...');
      await _saveBookMetadata(book);
      print('✅ DownloadService: Book metadata saved');
      
      // Download ebook content if available
      if (book.ebookContent != null && book.ebookContent!.isNotEmpty) {
        print('📥 DownloadService: Downloading ebook content...');
        await downloadBookEbook(book.id, book.ebookContent!);
        print('✅ DownloadService: Ebook content downloaded');
      } else if (book.ebookUrl != null && book.ebookUrl!.isNotEmpty) {
        print('📥 DownloadService: Downloading ebook from URL...');
        await downloadBookEbook(book.id, book.ebookUrl!);
        print('✅ DownloadService: Ebook downloaded from URL');
      }
      
      // Download audio if available
      if (book.audioUrl != null && book.audioUrl!.isNotEmpty) {
        print('📥 DownloadService: Downloading audio...');
        await downloadBookAudio(book.id, book.audioUrl!);
        print('✅ DownloadService: Audio downloaded');
      }
      
      // Verify all downloads are completed
      final completed = await getCompletedDownloads();
      final bookDownloads = completed.where((d) => 
        d.itemId == book.id && 
        (d.type == DownloadType.bookAudio || d.type == DownloadType.bookEbook)
      ).toList();
      
      print('✅ DownloadService: Complete book download finished: ${book.id}');
      print('✅ DownloadService: Verified ${bookDownloads.length} downloads for book ${book.id}:');
      for (final d in bookDownloads) {
        print('   - ${d.type}: ${d.status} (${d.localPath ?? 'no path'})');
      }
    } catch (e) {
      print('❌ Error downloading complete book: $e');
      rethrow;
    }
  }
  
  Future<void> _saveBookMetadata(Book book) async {
    if (_database == null) await _initDatabase();
    
    // Ensure table exists (should be created in _initDatabase, but check anyway)
    try {
      await _database!.execute('''
        CREATE TABLE IF NOT EXISTS book_metadata (
          book_id TEXT PRIMARY KEY,
          metadata TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
    } catch (e) {
      print('⚠️ Error creating book_metadata table (may already exist): $e');
    }
    
    // Save book as JSON
    try {
      final metadataJson = book.toJson();
      await _database!.insert(
        'book_metadata',
        {
          'book_id': book.id,
          'metadata': jsonEncode(metadataJson),
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('✅ Book metadata saved: ${book.id}');
    } catch (e) {
      print('❌ Error saving book metadata: $e');
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>?> getBookMetadata(String bookId) async {
    if (_database == null) await _initDatabase();
    
    try {
      // Ensure table exists
      try {
        await _database!.execute('''
          CREATE TABLE IF NOT EXISTS book_metadata (
            book_id TEXT PRIMARY KEY,
            metadata TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
      } catch (e) {
        // Ignore - table might already exist
      }
      
      final maps = await _database!.query(
        'book_metadata',
        where: 'book_id = ?',
        whereArgs: [bookId],
      );
      
      if (maps.isEmpty) return null;
      
      final metadataStr = maps.first['metadata'] as String;
      return jsonDecode(metadataStr) as Map<String, dynamic>;
    } catch (e) {
      print('❌ Error getting book metadata: $e');
      return null;
    }
  }

  // Download complete podcast (metadata + all episodes)
  Future<void> downloadCompletePodcast(Podcast podcast, List<PodcastEpisode> episodes) async {
    final hasPermission = await _requestStoragePermission();
    if (!hasPermission) {
      throw Exception('Storage permission denied');
    }

    try {
      // Download podcast metadata (store as JSON)
      await _savePodcastMetadata(podcast);
      
      // Download all episodes
      for (final episode in episodes) {
        if (episode.audioUrl != null && episode.audioUrl!.isNotEmpty) {
          try {
            await downloadPodcastEpisode(episode.id, episode.audioUrl!, podcastId: podcast.id);
          } catch (e) {
            print('⚠️ Error downloading episode ${episode.id}: $e');
            // Continue with other episodes
          }
        }
      }
    } catch (e) {
      print('❌ Error downloading complete podcast: $e');
      rethrow;
    }
  }
  
  Future<void> _savePodcastMetadata(Podcast podcast) async {
    if (_database == null) await _initDatabase();
    
    // Ensure table exists (should be created in _initDatabase, but check anyway)
    try {
      await _database!.execute('''
        CREATE TABLE IF NOT EXISTS podcast_metadata (
          podcast_id TEXT PRIMARY KEY,
          metadata TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
    } catch (e) {
      print('⚠️ Error creating podcast_metadata table (may already exist): $e');
    }
    
    // Save podcast as JSON
    try {
      final metadataJson = podcast.toJson();
      await _database!.insert(
        'podcast_metadata',
        {
          'podcast_id': podcast.id,
          'metadata': jsonEncode(metadataJson),
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('✅ Podcast metadata saved: ${podcast.id}');
    } catch (e) {
      print('❌ Error saving podcast metadata: $e');
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>?> getPodcastMetadata(String podcastId) async {
    if (_database == null) await _initDatabase();
    
    try {
      // Ensure table exists
      try {
        await _database!.execute('''
          CREATE TABLE IF NOT EXISTS podcast_metadata (
            podcast_id TEXT PRIMARY KEY,
            metadata TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
      } catch (e) {
        // Ignore - table might already exist
      }
      
      final maps = await _database!.query(
        'podcast_metadata',
        where: 'podcast_id = ?',
        whereArgs: [podcastId],
      );
      
      if (maps.isEmpty) return null;
      
      final metadataStr = maps.first['metadata'] as String;
      return jsonDecode(metadataStr) as Map<String, dynamic>;
    } catch (e) {
      print('❌ Error getting podcast metadata: $e');
      return null;
    }
  }

  Future<String> downloadBookAudio(String bookId, String audioUrl) async {
    final hasPermission = await _requestStoragePermission();
    if (!hasPermission) {
      throw Exception('Storage permission denied');
    }

    final downloadId = '${DownloadType.bookAudio.toString().split('.').last}_$bookId';
    
    // Check if already downloaded
    final existing = await getDownload(downloadId);
    if (existing != null && existing.status == DownloadStatus.completed && existing.localPath != null) {
      if (kIsWeb) {
        // On web, check database instead of file system
        return existing.localPath!;
      } else {
        final file = File(existing.localPath!);
        if (await file.exists()) {
          return existing.localPath!;
        }
      }
    }

    final downloadDir = await _getDownloadDirectory();
    final fileName = _getFileName(audioUrl, DownloadType.bookAudio);
    final filePath = path.join(downloadDir, fileName);

    final downloadItem = DownloadItem(
      id: downloadId,
      itemId: bookId,
      type: DownloadType.bookAudio,
      url: audioUrl,
      status: DownloadStatus.downloading,
      progress: 0,
      createdAt: DateTime.now(),
    );

    await _saveDownload(downloadItem);
    _activeDownloads[downloadId] = downloadItem;

    try {
      print('⬇️ Starting audio file download...');
      
      if (!kIsWeb) {
        // On mobile/desktop, ensure parent directory exists
        final file = File(filePath);
        final parentDir = file.parent;
        if (!await parentDir.exists()) {
          await parentDir.create(recursive: true);
        }
      }
      
      final response = await _networkService.download(
        audioUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = ((received / total) * 100).toInt();
            final updatedItem = DownloadItem(
              id: downloadItem.id,
              itemId: downloadItem.itemId,
              type: downloadItem.type,
              url: downloadItem.url,
              localPath: downloadItem.localPath,
              status: downloadItem.status,
              progress: progress,
              totalBytes: total,
              downloadedBytes: received,
              error: downloadItem.error,
              createdAt: downloadItem.createdAt,
              completedAt: downloadItem.completedAt,
              podcastId: downloadItem.podcastId,
            );
            _activeDownloads[downloadId] = updatedItem;
            _saveDownload(updatedItem);
          }
        },
      );

      final currentItem = _activeDownloads[downloadId] ?? downloadItem;
      int fileSize = currentItem.totalBytes ?? 0;
      
      if (!kIsWeb) {
        // On mobile/desktop, get file size from file system
        final file = File(filePath);
        fileSize = await file.length();
      } else {
        // On web, use total bytes from download response or estimate
        fileSize = currentItem.totalBytes ?? response.data?.length ?? 0;
      }
      
      final completedItem = DownloadItem(
        id: downloadId,
        itemId: bookId,
        type: DownloadType.bookAudio,
        url: audioUrl,
        localPath: filePath,
        status: DownloadStatus.completed,
        progress: 100,
        totalBytes: currentItem.totalBytes ?? fileSize,
        downloadedBytes: currentItem.totalBytes ?? fileSize,
        createdAt: downloadItem.createdAt,
        completedAt: DateTime.now(),
      );

      await _saveDownload(completedItem);
      _activeDownloads.remove(downloadId);

      print('✅ Audio download completed: $filePath');
      print('✅ File size: $fileSize bytes');
      print('✅ DownloadItem saved with ID: $downloadId, status: ${completedItem.status}, itemId: ${completedItem.itemId}');
      
      // Verify the download was saved
      final saved = await getDownload(downloadId);
      if (saved != null) {
        print('✅ Verified download saved: ${saved.status} for ${saved.itemId}');
      } else {
        print('❌ WARNING: Download not found after save!');
      }
      
      return filePath;
    } catch (e) {
      final failedItem = DownloadItem(
        id: downloadId,
        itemId: bookId,
        type: DownloadType.bookAudio,
        url: audioUrl,
        status: DownloadStatus.failed,
        error: e.toString(),
        createdAt: downloadItem.createdAt,
      );

      await _saveDownload(failedItem);
      _activeDownloads.remove(downloadId);
      throw e;
    }
  }

  Future<String> downloadBookEbook(String bookId, String ebookUrlOrContent) async {
    final hasPermission = await _requestStoragePermission();
    if (!hasPermission) {
      throw Exception('Storage permission denied');
    }

    final downloadId = '${DownloadType.bookEbook.toString().split('.').last}_$bookId';
    
    // Check if already downloaded
    final existing = await getDownload(downloadId);
    if (existing != null && existing.status == DownloadStatus.completed && existing.localPath != null) {
      if (kIsWeb) {
        // On web, check database instead of file system
        return existing.localPath!;
      } else {
        final file = File(existing.localPath!);
        if (await file.exists()) {
          return existing.localPath!;
        }
      }
    }

    final downloadDir = await _getDownloadDirectory();
    
    // If it's direct content (string), save it as text file
    // If it's a URL, download it
    String filePath;
    if (ebookUrlOrContent.startsWith('http') || ebookUrlOrContent.startsWith('/')) {
      // It's a URL - download it
      final fileName = _getFileName(ebookUrlOrContent, DownloadType.bookEbook);
      filePath = path.join(downloadDir, fileName);
    } else {
      // It's direct content - save as text file
      final fileName = '$bookId.txt';
      filePath = path.join(downloadDir, fileName);
    }

    final downloadItem = DownloadItem(
      id: downloadId,
      itemId: bookId,
      type: DownloadType.bookEbook,
      url: ebookUrlOrContent,
      status: DownloadStatus.downloading,
      progress: 0,
      createdAt: DateTime.now(),
    );

    await _saveDownload(downloadItem);
    _activeDownloads[downloadId] = downloadItem;

    try {
      if (ebookUrlOrContent.startsWith('http') || ebookUrlOrContent.startsWith('/')) {
        // Download from URL
        print('⬇️ Downloading ebook from URL...');
        
        if (!kIsWeb) {
          // On mobile/desktop, ensure parent directory exists
          final file = File(filePath);
          final parentDir = file.parent;
          if (!await parentDir.exists()) {
            await parentDir.create(recursive: true);
          }
        }
        
        final response = await _networkService.download(
          ebookUrlOrContent,
          filePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = ((received / total) * 100).toInt();
            final updatedItem = DownloadItem(
              id: downloadItem.id,
              itemId: downloadItem.itemId,
              type: downloadItem.type,
              url: downloadItem.url,
              localPath: downloadItem.localPath,
              status: downloadItem.status,
              progress: progress,
              totalBytes: total,
              downloadedBytes: received,
              error: downloadItem.error,
              createdAt: downloadItem.createdAt,
              completedAt: downloadItem.completedAt,
              podcastId: downloadItem.podcastId,
            );
            _activeDownloads[downloadId] = updatedItem;
            _saveDownload(updatedItem);
          }
        },
      );
      } else {
        // Save direct content
        print('📝 Saving ebook content...');
        
        if (kIsWeb) {
          // On web, store content in database instead of file system
          // Store the ebook content in the book_metadata table
          if (_database == null) await _initDatabase();
          
          final metadataJson = jsonEncode({
            'content': ebookUrlOrContent,
            'type': 'ebook',
            'saved_at': DateTime.now().toIso8601String(),
          });
          
          await _database!.insert(
            'book_metadata',
            {
              'book_id': bookId,
              'metadata': metadataJson,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          
          // Use a virtual path for web
          filePath = '/downloads/$bookId.txt';
          print('✅ Ebook content saved to database (${ebookUrlOrContent.length} characters)');
        } else {
          // On mobile/desktop, save to file system
          final file = File(filePath);
          
          // Ensure parent directory exists
          final parentDir = file.parent;
          if (!await parentDir.exists()) {
            await parentDir.create(recursive: true);
          }
          
          await file.writeAsString(ebookUrlOrContent);
          print('✅ Ebook content saved: $filePath (${ebookUrlOrContent.length} characters)');
        }
        final contentLength = ebookUrlOrContent.length;
        final updatedItem = DownloadItem(
          id: downloadItem.id,
          itemId: downloadItem.itemId,
          type: downloadItem.type,
          url: downloadItem.url,
          localPath: downloadItem.localPath,
          status: downloadItem.status,
          progress: 100,
          totalBytes: contentLength,
          downloadedBytes: contentLength,
          error: downloadItem.error,
          createdAt: downloadItem.createdAt,
          completedAt: downloadItem.completedAt,
          podcastId: downloadItem.podcastId,
        );
        _activeDownloads[downloadId] = updatedItem;
        _saveDownload(updatedItem);
      }

      final completedItem = DownloadItem(
        id: downloadId,
        itemId: bookId,
        type: DownloadType.bookEbook,
        url: ebookUrlOrContent,
        localPath: filePath,
        status: DownloadStatus.completed,
        progress: 100,
        totalBytes: downloadItem.totalBytes,
        downloadedBytes: downloadItem.totalBytes,
        createdAt: downloadItem.createdAt,
        completedAt: DateTime.now(),
      );

      await _saveDownload(completedItem);
      _activeDownloads.remove(downloadId);

      print('✅ Ebook download completed: $filePath');
      print('✅ DownloadItem saved with ID: $downloadId, status: ${completedItem.status}, itemId: ${completedItem.itemId}');
      
      // Verify the download was saved
      final saved = await getDownload(downloadId);
      if (saved != null) {
        print('✅ Verified ebook download saved: ${saved.status} for ${saved.itemId}');
      } else {
        print('❌ WARNING: Ebook download not found after save!');
      }
      
      return filePath;
    } catch (e) {
      final failedItem = DownloadItem(
        id: downloadId,
        itemId: bookId,
        type: DownloadType.bookEbook,
        url: ebookUrlOrContent,
        status: DownloadStatus.failed,
        error: e.toString(),
        createdAt: downloadItem.createdAt,
      );

      await _saveDownload(failedItem);
      _activeDownloads.remove(downloadId);
      throw e;
    }
  }

  Future<String> downloadPodcastEpisode(String episodeId, String audioUrl, {String? podcastId}) async {
    final hasPermission = await _requestStoragePermission();
    if (!hasPermission) {
      throw Exception('Storage permission denied');
    }

    final downloadId = '${DownloadType.podcastEpisode.toString().split('.').last}_$episodeId';
    
    // Check if already downloaded
    final existing = await getDownload(downloadId);
    if (existing != null && existing.status == DownloadStatus.completed && existing.localPath != null) {
      final file = File(existing.localPath!);
      if (await file.exists()) {
        return existing.localPath!;
      }
    }

    final downloadDir = await _getDownloadDirectory();
    final fileName = _getFileName(audioUrl, DownloadType.podcastEpisode);
    final filePath = path.join(downloadDir, fileName);

    final downloadItem = DownloadItem(
      id: downloadId,
      itemId: episodeId,
      type: DownloadType.podcastEpisode,
      url: audioUrl,
      status: DownloadStatus.downloading,
      progress: 0,
      createdAt: DateTime.now(),
      podcastId: podcastId,
    );

    await _saveDownload(downloadItem);
    _activeDownloads[downloadId] = downloadItem;

    try {
      final response = await _networkService.download(
        audioUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = ((received / total) * 100).toInt();
            final updatedItem = DownloadItem(
              id: downloadItem.id,
              itemId: downloadItem.itemId,
              type: downloadItem.type,
              url: downloadItem.url,
              localPath: downloadItem.localPath,
              status: downloadItem.status,
              progress: progress,
              totalBytes: total,
              downloadedBytes: received,
              error: downloadItem.error,
              createdAt: downloadItem.createdAt,
              completedAt: downloadItem.completedAt,
              podcastId: downloadItem.podcastId,
            );
            _activeDownloads[downloadId] = updatedItem;
            _saveDownload(updatedItem);
          }
        },
      );

      final currentItem = _activeDownloads[downloadId] ?? downloadItem;
      final completedItem = DownloadItem(
        id: downloadId,
        itemId: episodeId,
        type: DownloadType.podcastEpisode,
        url: audioUrl,
        localPath: filePath,
        status: DownloadStatus.completed,
        progress: 100,
        totalBytes: currentItem.totalBytes,
        downloadedBytes: currentItem.totalBytes,
        createdAt: downloadItem.createdAt,
        completedAt: DateTime.now(),
        podcastId: podcastId,
      );

      await _saveDownload(completedItem);
      _activeDownloads.remove(downloadId);

      return filePath;
    } catch (e) {
      final failedItem = DownloadItem(
        id: downloadId,
        itemId: episodeId,
        type: DownloadType.podcastEpisode,
        url: audioUrl,
        status: DownloadStatus.failed,
        error: e.toString(),
        createdAt: downloadItem.createdAt,
        podcastId: podcastId,
      );

      await _saveDownload(failedItem);
      _activeDownloads.remove(downloadId);
      throw e;
    }
  }

  Future<void> _saveDownload(DownloadItem item) async {
    if (_database == null) await _initDatabase();
    await _database!.insert(
      'downloads',
      item.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<DownloadItem?> getDownload(String downloadId) async {
    if (_database == null) await _initDatabase();
    final maps = await _database!.query(
      'downloads',
      where: 'id = ?',
      whereArgs: [downloadId],
    );

    if (maps.isEmpty) return null;
    return DownloadItem.fromJson(maps.first);
  }

  Future<List<DownloadItem>> getAllDownloads({DownloadStatus? status}) async {
    try {
      if (_database == null) {
        try {
          await _initDatabase().timeout(const Duration(seconds: 5));
        } catch (e) {
          print('❌ DownloadService: Failed to initialize database in getAllDownloads: $e');
          return [];
        }
      }
      
      if (_database == null) {
        print('⚠️ DownloadService: Database is null after initialization attempt');
        return [];
      }
      
      List<Map<String, dynamic>> maps;
      
      if (status != null) {
        maps = await _database!.query(
          'downloads',
          where: 'status = ?',
          whereArgs: [status.toString().split('.').last],
          orderBy: 'created_at DESC',
        );
      } else {
        maps = await _database!.query(
          'downloads',
          orderBy: 'created_at DESC',
        );
      }

      return maps.map((map) => DownloadItem.fromJson(map)).toList();
    } catch (e) {
      print('❌ DownloadService: Error in getAllDownloads: $e');
      return [];
    }
  }

  Future<List<DownloadItem>> getCompletedDownloads({DownloadType? type}) async {
    try {
      if (_database == null) {
        try {
          await _initDatabase().timeout(const Duration(seconds: 5));
        } catch (e) {
          print('❌ DownloadService: Failed to initialize database in getCompletedDownloads: $e');
          return [];
        }
      }
      
      if (_database == null) {
        print('⚠️ DownloadService: Database is null after initialization attempt');
        return [];
      }
      
      List<Map<String, dynamic>> maps;
      
      final statusString = DownloadStatus.completed.toString().split('.').last;
      print('🔍 DownloadService: Getting completed downloads with status: $statusString');
      
      if (type != null) {
        final typeString = type.toString().split('.').last;
        maps = await _database!.query(
          'downloads',
          where: 'status = ? AND type = ?',
          whereArgs: [statusString, typeString],
          orderBy: 'completed_at DESC',
        );
        print('🔍 DownloadService: Found ${maps.length} completed downloads of type $typeString');
      } else {
        maps = await _database!.query(
          'downloads',
          where: 'status = ?',
          whereArgs: [statusString],
          orderBy: 'completed_at DESC',
        );
        print('🔍 DownloadService: Found ${maps.length} total completed downloads');
      }

      final items = maps.map((map) {
        try {
          return DownloadItem.fromJson(map);
        } catch (e) {
          print('❌ DownloadService: Error parsing download item: $e');
          print('❌ DownloadService: Map data: $map');
          return null;
        }
      }).whereType<DownloadItem>().toList();
      
      print('🔍 DownloadService: Parsed ${items.length} download items');
      for (final item in items) {
        print('  - ${item.type} for ${item.itemId}: ${item.status}');
      }
      
      return items;
    } catch (e) {
      print('❌ DownloadService: Error in getCompletedDownloads: $e');
      return [];
    }
  }

  Future<bool> isDownloaded(String itemId, DownloadType type) async {
    if (_database == null) await _initDatabase();
    final maps = await _database!.query(
      'downloads',
      where: 'item_id = ? AND type = ? AND status = ?',
      whereArgs: [
        itemId,
        type.toString().split('.').last,
        DownloadStatus.completed.toString().split('.').last,
      ],
    );

    if (maps.isEmpty) return false;
    
    final item = DownloadItem.fromJson(maps.first);
    if (item.localPath != null) {
      final file = File(item.localPath!);
      return await file.exists();
    }
    
    return false;
  }

  Future<String?> getLocalPath(String itemId, DownloadType type) async {
    // Try to find by item_id
    if (_database == null) await _initDatabase();
    final maps = await _database!.query(
      'downloads',
      where: 'item_id = ? AND type = ? AND status = ?',
      whereArgs: [
        itemId,
        type.toString().split('.').last,
        DownloadStatus.completed.toString().split('.').last,
      ],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      final item = DownloadItem.fromJson(maps.first);
      if (item.localPath != null) {
        final file = File(item.localPath!);
        if (await file.exists()) {
          return item.localPath;
        }
      }
    }
    
    return null;
  }
  
  Future<String?> getBookAudioPath(String bookId) async {
    return getLocalPath(bookId, DownloadType.bookAudio);
  }
  
  Future<String?> getBookEbookPath(String bookId) async {
    return getLocalPath(bookId, DownloadType.bookEbook);
  }
  
  Future<String?> getPodcastEpisodePath(String episodeId) async {
    return getLocalPath(episodeId, DownloadType.podcastEpisode);
  }
  
  Future<DownloadItem?> getDownloadProgress(String itemId, DownloadType type) async {
    final downloadId = '${type.toString().split('.').last}_${itemId}';
    final item = _activeDownloads[downloadId];
    if (item != null) return item;
    return await getDownload(downloadId);
  }

  Future<void> deleteDownload(String downloadId) async {
    if (_database == null) await _initDatabase();
    
    final item = await getDownload(downloadId);
    if (item != null && item.localPath != null) {
      try {
        final file = File(item.localPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('Error deleting file: $e');
      }
    }
    
    await _database!.delete(
      'downloads',
      where: 'id = ?',
      whereArgs: [downloadId],
    );
    
    _activeDownloads.remove(downloadId);
  }

  Future<void> deleteAllDownloads() async {
    if (_database == null) await _initDatabase();
    
    final allDownloads = await getAllDownloads();
    for (final item in allDownloads) {
      if (item.localPath != null) {
        try {
          final file = File(item.localPath!);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          print('Error deleting file: $e');
        }
      }
    }
    
    await _database!.delete('downloads');
    _activeDownloads.clear();
  }

  DownloadItem? getActiveDownload(String downloadId) {
    return _activeDownloads[downloadId];
  }

  Map<String, DownloadItem> getActiveDownloads() {
    return Map.from(_activeDownloads);
  }
  
  // Get all podcasts that have downloaded episodes
  Future<List<String>> getPodcastsWithDownloadedEpisodes() async {
    if (_database == null) await _initDatabase();
    
    try {
      // Get all completed podcast episode downloads with podcast_id
      final episodeDownloads = await _database!.query(
        'downloads',
        where: 'type = ? AND status = ? AND podcast_id IS NOT NULL',
        whereArgs: [
          DownloadType.podcastEpisode.toString().split('.').last,
          DownloadStatus.completed.toString().split('.').last,
        ],
      );
      
      // Extract unique podcast IDs
      final podcastIds = <String>{};
      for (final row in episodeDownloads) {
        final podcastId = row['podcast_id'] as String?;
        if (podcastId != null && podcastId.isNotEmpty) {
          podcastIds.add(podcastId);
        }
      }
      
      // Also include podcasts with metadata stored
      try {
        final podcastMetadata = await _database!.query('podcast_metadata');
        for (final row in podcastMetadata) {
          final podcastId = row['podcast_id'] as String;
          podcastIds.add(podcastId);
        }
      } catch (e) {
        // Table might not exist yet
      }
      
      return podcastIds.toList();
    } catch (e) {
      print('❌ Error getting podcasts with downloaded episodes: $e');
      return [];
    }
  }
}

