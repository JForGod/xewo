# TTS系统第五轮修复计划

## 当前编译错误分析

根据编译输出信息，我们可以将剩余错误分为以下几类：

### 1. TTSVoice相关问题
多处代码引用了TTSVoice类中不存在的`locale`属性：
```
lib/src/features/ai_assistant/domain/tts/utils/tts_utils.dart(49,48): error G4127D1E8: The getter 'locale' isn't defined for the class 'TTSVoice'.
lib/src/features/ai_assistant/domain/tts/utils/tts_utils.dart(54,34): error G4127D1E8: The getter 'locale' isn't defined for the class 'TTSVoice'.
lib/src/features/ai_assistant/domain/tts/utils/tts_utils.dart(64,41): error G4127D1E8: The getter 'locale' isn't defined for the class 'TTSVoice'.
```

### 2. 枚举匹配问题
多处枚举没有完全匹配所有枚举值：
```
lib/src/features/ai_assistant/domain/models/interaction_mode.dart(72,13): error G42E56F65: The type 'InteractionMode' is not exhaustively matched by the switch cases since it doesn't match 'InteractionMode.chat'.
lib/src/features/ai_assistant/domain/models/assistant_state.dart(68,13): error G42E56F65: The type 'AssistantState' is not exhaustively matched by the switch cases since it doesn't match 'AssistantState.chat'.
lib/src/features/ai_assistant/data/tts/utils/flutter_tts_helpers.dart(290,11): error G42E56F65: The type 'IosTextToSpeechAudioCategory' is not exhaustively matched by the switch cases since it doesn't match 'IosTextToSpeechAudioCategory.ambientSolo'.
```

### 3. 类型安全问题
涉及空安全和类型转换错误：
```
lib/src/features/ai_assistant/domain/tts/utils/tts_utils.dart(66,12): error G44692867: A value of type 'List<dynamic>' can't be returned from a function with return type 'List<String>'.
lib/src/features/ai_assistant/data/tts/engines/base_tts_engine.dart(398,48): error G7AD6136F: Method 'isEmpty' cannot be called on 'TTSVoiceSettings?' because it is potentially null.
lib/src/features/ai_assistant/data/tts/engines/base_tts_engine.dart(402,31): error GC2F972A8: The argument type 'TTSVoiceSettings?' can't be assigned to the parameter type 'TTSVoiceSettings'.
```

### 4. 常量评估错误
`tts_utils.dart`中多处出现常量评估错误，可能与引用了未定义的常量有关：
```
lib/src/features/ai_assistant/domain/tts/utils/tts_utils.dart(83,26): error G8388A750: Constant evaluation error:
```

### 5. 构造函数参数问题
多处调用构造函数时使用了不存在的参数：
```
lib/src/features/ai_assistant/presentation/providers/tts_providers.dart(93,5): error GC6690633: No named parameter with the name 'defaultEngineType'.
lib/src/features/ai_assistant/presentation/tts/widgets/settings/tts_engine_selector.dart(104,48): error GC6690633: No named parameter with the name 'defaultEngineType'.
```

### 6. 其他错误
```
lib/src/core/utils/app_logger.dart(25,13): error G297C951C: Can't assign to this.
```

## 修复计划

### 第一优先级：核心模型和枚举问题
1. 为`TTSVoice`类添加缺失的`locale`属性
2. 修复`InteractionMode`和`AssistantState`枚举的switch语句，确保匹配所有值
3. 修复`IosTextToSpeechAudioCategory`枚举匹配

### 第二优先级：类型安全问题
1. 修复`tts_utils.dart`中的返回类型错误
2. 处理`base_tts_engine.dart`中的空安全问题
3. 解决常量评估错误

### 第三优先级：构造函数和其他问题
1. 修复构造函数参数问题
2. 解决`app_logger.dart`中的this赋值错误

## 实施路线
1. 先修复`TTSVoice`类定义，确保包含所有必要属性
2. 解决枚举匹配问题，完善switch语句
3. 修复类型安全和空安全问题
4. 解决构造函数参数问题
5. 修复剩余错误并执行全面测试

## 风险管理
1. 修复一类问题可能引入新的错误，需要确保修复不破坏现有功能
2. 部分错误可能与系统其他部分耦合，需谨慎修改
3. 在测试环境中验证每个修复，确保不引入回归 