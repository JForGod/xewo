// 2025-05-13: 新增 - TTS异常处理测试

import 'package:flutter_test/flutter_test.dart';
import 'package:xewo/src/features/ai_assistant/domain/tts/tts_exception.dart';

void main() {
  group('TTSException', () {
    test('should create from message', () {
      final exception = TTSException.fromMessage(
        '测试异常',
        type: TTSErrorType.playback,
        severity: TTSErrorSeverity.minor,
        code: 'TEST_ERROR'
      );
      
      expect(exception.message, '测试异常');
      expect(exception.type, TTSErrorType.playback);
      expect(exception.severity, TTSErrorSeverity.minor);
      expect(exception.code, 'TEST_ERROR');
      expect(exception.originalError, isNull);
    });
    
    test('should create from error', () {
      final originalError = Exception('原始错误');
      final exception = TTSException.fromError(
        originalError,
        type: TTSErrorType.network,
        severity: TTSErrorSeverity.moderate,
        code: 'NETWORK_ERROR'
      );
      
      expect(exception.message, originalError.toString());
      expect(exception.type, TTSErrorType.network);
      expect(exception.severity, TTSErrorSeverity.moderate);
      expect(exception.code, 'NETWORK_ERROR');
      expect(exception.originalError, originalError);
    });
    
    test('should create initialization error', () {
      final exception = TTSException.initialization(
        '初始化失败',
        severity: TTSErrorSeverity.severe,
        code: 'INIT_FAILED'
      );
      
      expect(exception.message, '初始化失败');
      expect(exception.type, TTSErrorType.initialization);
      expect(exception.severity, TTSErrorSeverity.severe);
      expect(exception.code, 'INIT_FAILED');
    });
    
    test('should create configuration error', () {
      final exception = TTSException.configuration(
        '配置错误',
        severity: TTSErrorSeverity.moderate,
        code: 'CONFIG_ERROR'
      );
      
      expect(exception.message, '配置错误');
      expect(exception.type, TTSErrorType.configuration);
      expect(exception.severity, TTSErrorSeverity.moderate);
      expect(exception.code, 'CONFIG_ERROR');
    });
    
    test('should create playback error', () {
      final exception = TTSException.playback(
        '播放错误',
        severity: TTSErrorSeverity.minor,
        code: 'PLAYBACK_ERROR'
      );
      
      expect(exception.message, '播放错误');
      expect(exception.type, TTSErrorType.playback);
      expect(exception.severity, TTSErrorSeverity.minor);
      expect(exception.code, 'PLAYBACK_ERROR');
    });
    
    test('should create resource error', () {
      final exception = TTSException.resource(
        '资源错误',
        severity: TTSErrorSeverity.severe,
        code: 'RESOURCE_ERROR'
      );
      
      expect(exception.message, '资源错误');
      expect(exception.type, TTSErrorType.resource);
      expect(exception.severity, TTSErrorSeverity.severe);
      expect(exception.code, 'RESOURCE_ERROR');
    });
    
    test('should create network error', () {
      final exception = TTSException.network(
        '网络错误',
        severity: TTSErrorSeverity.moderate,
        code: 'NETWORK_ERROR'
      );
      
      expect(exception.message, '网络错误');
      expect(exception.type, TTSErrorType.network);
      expect(exception.severity, TTSErrorSeverity.moderate);
      expect(exception.code, 'NETWORK_ERROR');
    });
    
    test('should create system error', () {
      final exception = TTSException.system(
        '系统错误',
        severity: TTSErrorSeverity.severe,
        code: 'SYSTEM_ERROR'
      );
      
      expect(exception.message, '系统错误');
      expect(exception.type, TTSErrorType.system);
      expect(exception.severity, TTSErrorSeverity.severe);
      expect(exception.code, 'SYSTEM_ERROR');
    });
    
    test('should check shouldRetry', () {
      final minorException = TTSException.fromMessage(
        '轻微错误',
        severity: TTSErrorSeverity.minor
      );
      expect(minorException.shouldRetry, isTrue);
      
      final moderateException = TTSException.fromMessage(
        '中等错误',
        severity: TTSErrorSeverity.moderate
      );
      expect(moderateException.shouldRetry, isTrue);
      
      final severeException = TTSException.fromMessage(
        '严重错误',
        severity: TTSErrorSeverity.severe
      );
      expect(severeException.shouldRetry, isFalse);
      
      final fatalException = TTSException.fromMessage(
        '致命错误',
        severity: TTSErrorSeverity.fatal
      );
      expect(fatalException.shouldRetry, isFalse);
    });
    
    test('should check shouldReset', () {
      final minorException = TTSException.fromMessage(
        '轻微错误',
        severity: TTSErrorSeverity.minor
      );
      expect(minorException.shouldReset, isFalse);
      
      final severeException = TTSException.fromMessage(
        '严重错误',
        severity: TTSErrorSeverity.severe
      );
      expect(severeException.shouldReset, isTrue);
    });
    
    test('should check shouldRestart', () {
      final severeException = TTSException.fromMessage(
        '严重错误',
        severity: TTSErrorSeverity.severe
      );
      expect(severeException.shouldRestart, isFalse);
      
      final fatalException = TTSException.fromMessage(
        '致命错误',
        severity: TTSErrorSeverity.fatal
      );
      expect(fatalException.shouldRestart, isTrue);
    });
    
    test('should convert to JSON', () {
      final exception = TTSException.fromMessage(
        '测试异常',
        type: TTSErrorType.playback,
        severity: TTSErrorSeverity.minor,
        code: 'TEST_ERROR'
      );
      
      final json = exception.toJson();
      
      expect(json['message'], '测试异常');
      expect(json['type'], contains('playback'));
      expect(json['severity'], contains('minor'));
      expect(json['code'], 'TEST_ERROR');
      expect(json['timestamp'], isNotNull);
    });
    
    test('should format toString', () {
      final exception = TTSException.fromMessage(
        '测试异常',
        type: TTSErrorType.playback,
        severity: TTSErrorSeverity.minor,
        code: 'TEST_ERROR'
      );
      
      final string = exception.toString();
      
      expect(string, contains('测试异常'));
      expect(string, contains('playback'));
      expect(string, contains('minor'));
      expect(string, contains('TEST_ERROR'));
    });
  });
  
  group('TTSErrorHandler', () {
    test('should execute with retry', () async {
      int attempts = 0;
      final result = await TTSErrorHandler.executeWithRetry(() async {
        attempts++;
        if (attempts < 2) {
          throw TTSException.playback('尝试失败', severity: TTSErrorSeverity.minor);
        }
        return 'success';
      });
      
      expect(result, 'success');
      expect(attempts, 2);
    });
    
    test('should fail after max retries', () async {
      int attempts = 0;
      
      try {
        await TTSErrorHandler.executeWithRetry(() async {
          attempts++;
          throw TTSException.playback('尝试失败', severity: TTSErrorSeverity.minor);
        }, maxAttempts: 3);
        fail('应该抛出异常');
      } catch (e) {
        expect(e, isA<TTSException>());
        expect((e as TTSException).code, 'MAX_RETRIES_EXCEEDED');
      }
      
      expect(attempts, 3);
    });
    
    test('should not retry when exception severity is high', () async {
      int attempts = 0;
      
      expect(() async {
        await TTSErrorHandler.executeWithRetry(() async {
          attempts++;
          throw TTSException.system('严重错误', severity: TTSErrorSeverity.fatal);
        });
      }, throwsA(isA<TTSException>().having(
        (e) => e.severity, 'severity', TTSErrorSeverity.fatal
      )));
      
      expect(attempts, 1);
    });
    
    test('should handle custom retry condition', () async {
      int attempts = 0;
      
      expect(() async {
        await TTSErrorHandler.executeWithRetry(() async {
          attempts++;
          throw Exception('一般异常');
        }, shouldRetry: (e) => false);
      }, throwsA(isA<Exception>()));
      
      expect(attempts, 1);
    });
  });
} 