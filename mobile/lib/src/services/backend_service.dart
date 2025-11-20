import 'dart:io';

class BackendService {
  /// Start the Flask backend server
  static Future<void> startBackendServer() async {
    try {
      // Check if backend is already running
      final client = HttpClient();
      final request = await client.get('localhost', 5000, '/health');
      final response = await request.close().timeout(Duration(seconds: 2));
      if (response.statusCode == 200) {
        print('Backend is already running');
        client.close();
        return;
      }
      client.close();
    } catch (e) {
      // Backend not running, start it
      print('Starting Flask backend server...');
      // Run Python backend
      if (Platform.isWindows) {
        await Process.start(
          '..\\backend\\.venv\\Scripts\\python.exe',
          ['run.py'],
          workingDirectory: '../backend',
        );
      } else {
        await Process.start(
          '../backend/.venv/bin/python',
          ['run.py'],
          workingDirectory: '../backend',
        );
      }
    }
  }

  /// Stop the backend server (if needed)
  static Future<void> stopBackendServer() async {
    try {
      // On Windows, kill Python processes
      if (Platform.isWindows) {
        await Process.run('taskkill', ['/F', '/IM', 'python.exe', '/T']);
      } else {
        // On Unix-like systems
        await Process.run('pkill', ['-f', 'python run.py']);
      }

      print('Backend server stopped');
    } catch (e) {
      print('Failed to stop backend server: $e');
    }
  }
}