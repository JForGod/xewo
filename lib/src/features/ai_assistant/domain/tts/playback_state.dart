// 2025-05-15: 新增 - 统一的播放状态枚举

/// TTS播放状态枚举
enum PlaybackState {
  /// 初始状态，未开始播放
  none,
  
  /// 正在播放
  playing,
  
  /// 已暂停
  paused,
  
  /// 已停止
  stopped,
  
  /// 播放出错
  error
}

/// TTS播放模式枚举
enum PlaybackMode {
  /// 短文本模式，适合短句和简短回复
  shortText,
  
  /// 长文本模式，适合长段落和文章
  longText,
  
  /// 代码模式，适合代码朗读
  code,
  
  /// 提醒模式，适合通知和警告
  alert
} 