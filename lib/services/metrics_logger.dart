// lib/services/metrics_logger.dart
//
// Automated Metrics Logging Service for Aural Sight
// --------------------------------------------------
// Logs every detection/command attempt to a local Hive box.
// All writes are fire-and-forget (unawaited) and silently fail.
// No new dependencies – uses Hive which is already in the project.
//
// Usage:
//   await MetricsLogger().init();          // once, at app startup
//   MetricsLogger().logDetection(...)      // after each detection (non-blocking)
//   final metrics = await MetricsLogger().getMetrics('ocr');
//   final csv     = await MetricsLogger().exportCsv();
//   await MetricsLogger().clearLogs();

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

// ──────────────────────────────────────────────
// Data model stored inside Hive
// ──────────────────────────────────────────────
class MetricEntry {
  final String timestamp;
  final String module;
  final String input;
  final String actualOutput;
  final bool success;
  final double confidence;
  final double responseTimeSeconds;

  const MetricEntry({
    required this.timestamp,
    required this.module,
    required this.input,
    required this.actualOutput,
    required this.success,
    required this.confidence,
    required this.responseTimeSeconds,
  });

  /// Serialise to a plain Map so it can be stored in a generic Hive box.
  Map<String, dynamic> toMap() => {
        'timestamp': timestamp,
        'module': module,
        'input': input,
        'actualOutput': actualOutput,
        'success': success,
        'confidence': confidence,
        'responseTimeSeconds': responseTimeSeconds,
      };

  factory MetricEntry.fromMap(Map map) => MetricEntry(
        timestamp: map['timestamp'] as String? ?? '',
        module: map['module'] as String? ?? '',
        input: map['input'] as String? ?? '',
        actualOutput: map['actualOutput'] as String? ?? '',
        success: map['success'] as bool? ?? false,
        confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
        responseTimeSeconds:
            (map['responseTimeSeconds'] as num?)?.toDouble() ?? 0.0,
      );

  /// Single CSV row (no quoting needed; values are clean primitives).
  String toCsvRow() =>
      '$timestamp,$module,"$input","$actualOutput",$success,${confidence.toStringAsFixed(4)},${responseTimeSeconds.toStringAsFixed(4)}';
}

// ──────────────────────────────────────────────
// Computed metrics summary
// ──────────────────────────────────────────────
class ModuleMetrics {
  final String module;
  final int totalAttempts;
  final int successful;
  final int errors;
  final double accuracy;        // successful / totalAttempts  (0–1)
  final double errorRate;       // errors / totalAttempts       (0–1)
  final double avgResponseTime; // seconds

  const ModuleMetrics({
    required this.module,
    required this.totalAttempts,
    required this.successful,
    required this.errors,
    required this.accuracy,
    required this.errorRate,
    required this.avgResponseTime,
  });

  @override
  String toString() =>
      'ModuleMetrics($module | attempts=$totalAttempts | success=$successful | '
      'errors=$errors | accuracy=${(accuracy * 100).toStringAsFixed(1)}% | '
      'avgRT=${avgResponseTime.toStringAsFixed(3)}s)';
}

// ──────────────────────────────────────────────
// Main singleton service
// ──────────────────────────────────────────────
class MetricsLogger {
  // Singleton
  static final MetricsLogger _instance = MetricsLogger._internal();
  factory MetricsLogger() => _instance;
  MetricsLogger._internal();

  // ── Configuration ──
  static bool _enabled = true;

  /// Call MetricsLogger.setEnabled(false) to disable all logging at runtime.
  static void setEnabled(bool value) => _enabled = value;
  static bool get isEnabled => _enabled;

  // ── Internal state ──
  static const String _boxName = 'aural_sight_metrics';
  Box? _box;
  bool _initialized = false;
  final List<MetricEntry> _memoryEntries = <MetricEntry>[];
  String? _logFilePath;

  // ── Initialisation ──

  /// Must be called once before using the logger.
  /// Safe to await; silently ignores any Hive errors.
  Future<void> init() async {
    if (_initialized) return;
    try {
      // Hive.initFlutter() is already called in loading_screen.dart
      // so we just open our box here.
      _box = await Hive.openBox(_boxName);
      final appDir = await getApplicationDocumentsDirectory();
      _logFilePath = '${appDir.path}/aural_sight_metrics.log';
      await File(_logFilePath!).create(recursive: true);
      _initialized = true;
    } catch (_) {
      // Fall back to in-memory logging so the app still reports metrics.
      _initialized = true;
    }
  }

  // ── Core logging method ──

  /// Logs one detection event.
  /// This is non-blocking: it schedules the write and returns immediately.
  ///
  /// [module]           – 'object_detection' | 'ocr' | 'gesture' | 'voice'
  /// [input]            – description of the input (e.g. 'camera_frame')
  /// [actualOutput]     – what the module returned (label, text, gesture name…)
  /// [success]          – whether this attempt is considered successful
  /// [confidence]       – model confidence score (0.0–1.0); use 1.0 for binary tasks
  /// [responseTime]     – wall-clock seconds the operation took
  void logDetection({
    required String module,
    required String input,
    required String actualOutput,
    required bool success,
    double confidence = 1.0,
    double responseTime = 0.0,
  }) {
    if (!_enabled) return;

    final entry = MetricEntry(
      timestamp: DateTime.now().toIso8601String(),
      module: module,
      input: input,
      actualOutput: actualOutput,
      success: success,
      confidence: confidence,
      responseTimeSeconds: responseTime,
    );

    _memoryEntries.add(entry);
    unawaited(_writeEntry(entry));
    unawaited(_persistEntryToDisk(entry));
    _printLiveSummary(entry);
  }

  // ── Internal write (async, silently fails) ──

  Future<void> _writeEntry(MetricEntry entry) async {
    try {
      if (_box == null || !_box!.isOpen) return;
      await _box!.add(entry.toMap());
    } catch (_) {
      // Persisting to Hive is optional; in-memory logging still works.
    }
  }

  Future<void> _persistEntryToDisk(MetricEntry entry) async {
    try {
      if (!_initialized) {
        await init();
      }
      final total = _memoryEntries.length;
      final success = _memoryEntries.where((e) => e.success).length;
      final errors = total - success;
      final accuracy = total > 0 ? (success / total) * 100 : 0.0;
      final errorRate = total > 0 ? (errors / total) * 100 : 0.0;
      final avgRt = total > 0
          ? _memoryEntries.fold<double>(0.0, (sum, e) => sum + e.responseTimeSeconds) / total
          : 0.0;

      final line =
          '[Metrics] module=${entry.module} total=$total success=$success errors=$errors '
          'accuracy=${accuracy.toStringAsFixed(1)}% errorRate=${errorRate.toStringAsFixed(1)}% '
          'avgRT=${avgRt.toStringAsFixed(3)}s input=${entry.input} result=${entry.actualOutput}';
      await _appendLine(line);
    } catch (_) {
      // Safe fallback: do not crash the app.
    }
  }

  Future<void> _appendLine(String line) async {
    try {
      if (_logFilePath == null) {
        await init();
      }
      final file = File(_logFilePath ?? 'aural_sight_metrics.log');
      await file.create(recursive: true);
      final sink = file.openWrite(mode: FileMode.append);
      sink.writeln(line);
      await sink.flush();
      await sink.close();
    } catch (_) {
      // Safe fallback: do not crash the app.
    }
  }

  void _printLiveSummary(MetricEntry entry) {
    if (!kDebugMode) return;

    final total = _memoryEntries.length;
    final success = _memoryEntries.where((e) => e.success).length;
    final errors = total - success;
    final accuracy = total > 0 ? (success / total) * 100 : 0.0;
    final errorRate = total > 0 ? (errors / total) * 100 : 0.0;
    final avgRt = total > 0
        ? _memoryEntries.fold<double>(0.0, (sum, e) => sum + e.responseTimeSeconds) / total
        : 0.0;

    print(
      '[Metrics] module=${entry.module} total=$total success=$success errors=$errors '
      'accuracy=${accuracy.toStringAsFixed(1)}% errorRate=${errorRate.toStringAsFixed(1)}% '
      'avgRT=${avgRt.toStringAsFixed(3)}s input=${entry.input} result=${entry.actualOutput}',
    );
  }

  // ── Query / Analytics ──

  /// Returns all raw entries, optionally filtered by [module].
  Future<List<MetricEntry>> getAllEntries({String? module}) async {
    try {
      final entries = _memoryEntries
          .where((e) => module == null || e.module == module)
          .toList();
      return entries;
    } catch (_) {
      return [];
    }
  }

  /// Computes summary metrics for a specific module.
  Future<ModuleMetrics> getMetrics(String module) async {
    final entries = await getAllEntries(module: module);
    final total = entries.length;
    if (total == 0) {
      return ModuleMetrics(
        module: module,
        totalAttempts: 0,
        successful: 0,
        errors: 0,
        accuracy: 0,
        errorRate: 0,
        avgResponseTime: 0,
      );
    }
    final successful = entries.where((e) => e.success).length;
    final errors = total - successful;
    final avgRT = entries.map((e) => e.responseTimeSeconds).reduce((a, b) => a + b) / total;
    return ModuleMetrics(
      module: module,
      totalAttempts: total,
      successful: successful,
      errors: errors,
      accuracy: successful / total,
      errorRate: errors / total,
      avgResponseTime: avgRT,
    );
  }

  /// Returns summary metrics for all known modules.
  Future<Map<String, ModuleMetrics>> getAllMetrics() async {
    final modules = ['object_detection', 'ocr', 'gesture', 'voice'];
    final result = <String, ModuleMetrics>{};
    for (final m in modules) {
      result[m] = await getMetrics(m);
    }
    return result;
  }

  // ── Export ──

  /// Exports all log entries as a CSV string.
  Future<String> exportCsv() async {
    try {
      final entries = await getAllEntries();
      if (entries.isEmpty) return 'No data logged yet.';

      const header =
          'timestamp,module,input,actualOutput,success,confidence,responseTimeSeconds';
      final rows = entries.map((e) => e.toCsvRow()).join('\n');
      return '$header\n$rows';
    } catch (_) {
      return 'Error generating CSV.';
    }
  }

  // ── Maintenance ──

  /// Deletes all logged entries.
  Future<void> clearLogs() async {
    try {
      _memoryEntries.clear();
      if (_box == null || !_box!.isOpen) return;
      await _box!.clear();
    } catch (_) {
      // Silent fail
    }
  }

  // ── Debug Console Printing ──

  /// Prints every stored log entry to the console in a readable format.
  /// Only runs in debug mode (kDebugMode). Silently fails on any error.
  Future<void> printAllLogs() async {
    if (!kDebugMode) return;
    try {
      final entries = await getAllEntries();
      // ignore: avoid_print
      void p(String s) => print(s); // local alias to suppress linter per-call

      p('═════════════════════════════════════════════');
      if (entries.isEmpty) {
        p('📊 METRICS LOGS: NO LOGS FOUND');
        p('═════════════════════════════════════════════');
        p('Try using the app (detect objects, read text, use voice, show a gesture)');
        return;
      }

      p('📊 AURAL SIGHT METRICS LOGS');
      p('═════════════════════════════════════════════');
      p('Total Logs: ${entries.length}');
      p('');

      for (int i = 0; i < entries.length; i++) {
        final e = entries[i];
        p('--- Log #${i + 1} ---');
        p('  Module:     ${e.module}');
        p('  Input:      ${e.input}');
        p('  Actual:     ${e.actualOutput}');
        p('  Success:    ${e.success}');
        p('  Confidence: ${e.confidence.toStringAsFixed(4)}');
        p('  Response:   ${e.responseTimeSeconds.toStringAsFixed(3)}s');
        p('  Time:       ${e.timestamp}');
        p('');
      }

      p('═════════════════════════════════════════════');
      p('✅ Total: ${entries.length} logs recorded');
      p('═════════════════════════════════════════════');
    } catch (_) {
      // Silent fail
    }
  }

  /// Prints a compact summary grouped by module.
  /// Only runs in debug mode (kDebugMode). Silently fails on any error.
  Future<void> printSummary() async {
    if (!kDebugMode) return;
    try {
      final allMetrics = await getAllMetrics();
      final allEntries = await getAllEntries();

      // ignore: avoid_print
      void p(String s) => print(s);

      p('═════════════════════════════════════════════');
      p('📊 AURAL SIGHT METRICS SUMMARY');
      p('═════════════════════════════════════════════');

      final total    = allEntries.length;
      final success  = allEntries.where((e) => e.success).length;
      final errors   = total - success;
      final accuracy = total > 0 ? (success / total) * 100 : 0.0;
      final errRate  = total > 0 ? (errors  / total) * 100 : 0.0;
      final avgRT    = total > 0
          ? allEntries.map((e) => e.responseTimeSeconds).reduce((a, b) => a + b) / total
          : 0.0;

      p('Model Evaluations: $total');
      p('Successful Inferences: $success');
      p('Failed Inferences: $errors');
      p('Accuracy:          ${accuracy.toStringAsFixed(2)}%');
      p('Error Rate:        ${errRate.toStringAsFixed(2)}%');
      p('Avg Response Time: ${avgRT.toStringAsFixed(3)}s');
      p('');
      p('--- MODULE BREAKDOWN ---');

      for (final entry in allMetrics.entries) {
        final m = entry.value;
        if (m.totalAttempts == 0) continue; // skip modules with no data
        p('  ${m.module}:');
        p('    Model Evaluations: ${m.totalAttempts}');
        p('    Successful Inferences: ${m.successful}');
        p('    Failed Inferences: ${m.errors}');
        p('    Accuracy:     ${(m.accuracy  * 100).toStringAsFixed(2)}%');
        p('    Error Rate:   ${(m.errorRate * 100).toStringAsFixed(2)}%');
        p('    Avg Response: ${m.avgResponseTime.toStringAsFixed(3)}s');
      }

      p('═════════════════════════════════════════════');
      unawaited(_appendLine(' [MetricsSummary] total=$total success=$success errors=$errors accuracy=${accuracy.toStringAsFixed(2)}% errorRate=${errRate.toStringAsFixed(2)}% avgRT=${avgRT.toStringAsFixed(3)}s'));
    } catch (_) {
      // Silent fail
    }
  }
}
