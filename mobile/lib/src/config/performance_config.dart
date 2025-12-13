/// Performance configuration for Shield AI
/// Optimized for 10,000+ concurrent users and 99.9% uptime
library;

class PerformanceConfig {
  // API Configuration
  static const int apiTimeoutSeconds = 15; // Reduced from 30 for better UX
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(milliseconds: 500);

  // Cache Configuration
  static const Duration apiCacheDuration = Duration(minutes: 5);
  static const Duration fraudResultCacheDuration = Duration(hours: 1);
  static const Duration transactionCacheDuration = Duration(minutes: 2);

  // Performance Targets
  static const Duration targetFrameTime = Duration(milliseconds: 16); // 60 FPS
  static const Duration targetStartupTime = Duration(seconds: 2); // Sub-3s cold start
  static const int targetMemoryUsageMB = 80; // Under 100MB on low-end devices

  // Network Optimization
  static const int maxConcurrentRequests = 3;
  static const Duration requestDebounceTime = Duration(milliseconds: 300);

  // Image Optimization
  static const int maxImageWidth = 800;
  static const int maxImageHeight = 600;
  static const int imageQuality = 85;

  // List Virtualization
  static const int listPageSize = 20;
  static const int preloadThreshold = 5;

  // Background Processing
  static const Duration backgroundTaskInterval = Duration(hours: 4);
  static const int maxBackgroundRetries = 5;

  // Monitoring
  static const Duration performanceLogInterval = Duration(minutes: 5);
  static const Duration healthCheckInterval = Duration(minutes: 1);

  // Feature Flags for Performance
  static const bool enableImageOptimization = true;
  static const bool enableRequestCaching = true;
  static const bool enableListVirtualization = true;
  static const bool enableBackgroundSync = true;
  static const bool enablePerformanceMonitoring = true;

  // Low-end device optimizations
  static const bool reduceAnimationsOnLowEnd = true;
  static const bool disableHeavyFeaturesOnLowRAM = true;
  static const int lowMemoryThresholdMB = 512;
}
