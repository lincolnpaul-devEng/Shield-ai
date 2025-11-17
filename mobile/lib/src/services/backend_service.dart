import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:process_run/process_run.dart';

class BackendService {
  static const String backendUrl = 'http://localhost:5000';
  static const String healthEndpoint = '/health';

  /// Check if backend server is running
  static Future<bool> _isBackendRunning() async {
    try {
      final response = await http.get(
        Uri.parse('$backendUrl$healthEndpoint'),
      ).timeout(const Duration(seconds: 3));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Start the Flask backend server
  static Future<void> startBackendServer() async {
    try {
      // First check if backend is already running
      final isRunning = await _isBackendRunning();
      if (isRunning) {
        print('Backend is already running on $backendUrl');
        return;
      }

      print('Starting Flask backend server...');

      // Get the backend directory path (assuming it's at ../backend relative to mobile)
      final backendDir = Directory('../backend').absolute.path;

      // Check if backend directory exists
      if (!Directory(backendDir).existsSync()) {
        throw Exception('Backend directory not found at: $backendDir');
      }

      // Check if Python is available
      final shell = Shell();
      final pythonCheck = await shell.run('python --version');
      if (pythonCheck.exitCode != 0) {
        throw Exception('Python is not available in PATH');
      }

      // Check if requirements are installed (optional but helpful)
      final requirementsPath = '$backendDir/requirements.txt';
      if (File(requirementsPath).existsSync()) {
        print('Installing Python dependencies...');
        await shell.run('pip install -r requirements.txt', workingDirectory: backendDir);
      }

      // Start the Flask server in the background
      print('Starting Flask server...');
      final process = await shell.start(
        'python run.py',
        workingDirectory: backendDir,
        runInShell: true,
      );

      // Wait a bit for the server to start
      await Future.delayed(const Duration(seconds: 3));

      // Verify the server started successfully
      final serverStarted = await _isBackendRunning();
      if (serverStarted) {
        print('Backend server started successfully on $backendUrl');
      } else {
        throw Exception('Backend server failed to start');
      }

    } catch (e) {
      print('Failed to start backend server: $e');
      rethrow;
    }
  }

  /// Stop the backend server (if needed)
  static Future<void> stopBackendServer() async {
    try {
      final shell = Shell();

      // On Windows, kill Python processes
      if (Platform.isWindows) {
        await shell.run('taskkill /F /IM python.exe /T');
      } else {
        // On Unix-like systems
        await shell.run('pkill -f "python run.py"');
      }

      print('Backend server stopped');
    } catch (e) {
      print('Failed to stop backend server: $e');
    }
  }
}