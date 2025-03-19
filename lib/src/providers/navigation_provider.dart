import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 当前选中的导航项
final selectedNavItemProvider = StateProvider<String>((ref) => 'home'); 