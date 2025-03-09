import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'shortcut_config.freezed.dart';
part 'shortcut_config.g.dart';

@freezed
class ShortcutConfig with _$ShortcutConfig {
  const factory ShortcutConfig({
    required String id,
    required String name,
    required String description,
    @SingleActivatorConverter() required SingleActivator activator,
    required String category,
  }) = _ShortcutConfig;

  factory ShortcutConfig.fromJson(Map<String, dynamic> json) => _$ShortcutConfigFromJson(json);
}

/// 快捷键激活器转换器
class SingleActivatorConverter implements JsonConverter<SingleActivator, Map<String, dynamic>> {
  const SingleActivatorConverter();

  @override
  SingleActivator fromJson(Map<String, dynamic> json) {
    return SingleActivator(
      LogicalKeyboardKey(json['trigger'] as int),
      control: json['control'] as bool? ?? false,
      shift: json['shift'] as bool? ?? false,
      alt: json['alt'] as bool? ?? false,
      meta: json['meta'] as bool? ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson(SingleActivator activator) {
    return {
      'trigger': activator.trigger.keyId,
      'control': activator.control,
      'shift': activator.shift,
      'alt': activator.alt,
      'meta': activator.meta,
    };
  }
} 