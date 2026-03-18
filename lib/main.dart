import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/settings_provider.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    debugPrint('=== APP STARTUP ===');
    debugPrint('Main: Setting preferred orientations...');
    
    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Initialize database FIRST (sequential, not parallel)
    debugPrint('Main: Creating StorageService...');
    final storageService = StorageService();
    
    debugPrint('Main: Initializing StorageService (database)...');
    await storageService.init();
    debugPrint('Main: StorageService initialized successfully');

    // Then initialize settings
    debugPrint('Main: Creating SettingsProvider...');
    final settingsProvider = SettingsProvider();
    
    debugPrint('Main: Loading settings...');
    await settingsProvider.loadSettingsAsync();
    debugPrint('Main: Settings loaded successfully');

    debugPrint('Main: Starting app...');
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
          Provider<StorageService>.value(value: storageService),
        ],
        child: const LoanApp(),
      ),
    );
  } catch (e, stack) {
    debugPrint('');
    debugPrint('================================================');
    debugPrint('FATAL ERROR in main: $e');
    debugPrint('================================================');
    debugPrint('Stack Trace:');
    debugPrint(stack.toString());
    debugPrint('================================================');
    debugPrint('');
    
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('App failed to start', 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                    e.toString(),
                    style: const TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Check debug console for details',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
