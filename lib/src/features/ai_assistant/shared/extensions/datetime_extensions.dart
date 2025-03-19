import 'package:intl/intl.dart';

/// 日期时间扩展
extension DateTimeExtensions on DateTime {
  /// 格式化日期时间为字符串
  String format(String pattern) {
    return DateFormat(pattern).format(this);
  }
  
  /// 格式化为标准日期 (yyyy-MM-dd)
  String get toDateString {
    return format('yyyy-MM-dd');
  }
  
  /// 格式化为标准时间 (HH:mm:ss)
  String get toTimeString {
    return format('HH:mm:ss');
  }
  
  /// 格式化为标准日期时间 (yyyy-MM-dd HH:mm:ss)
  String get toDateTimeString {
    return format('yyyy-MM-dd HH:mm:ss');
  }
  
  /// 格式化为人类友好的相对时间
  String get toFriendlyString {
    final now = DateTime.now();
    final difference = now.difference(this);
    
    // 未来时间
    if (difference.isNegative) {
      final absDifference = difference.abs();
      
      if (absDifference.inDays > 365) {
        return '${(absDifference.inDays / 365).floor()}年后';
      } else if (absDifference.inDays > 30) {
        return '${(absDifference.inDays / 30).floor()}个月后';
      } else if (absDifference.inDays > 0) {
        return '${absDifference.inDays}天后';
      } else if (absDifference.inHours > 0) {
        return '${absDifference.inHours}小时后';
      } else if (absDifference.inMinutes > 0) {
        return '${absDifference.inMinutes}分钟后';
      } else {
        return '刚刚';
      }
    }
    
    // 过去时间
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}年前';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}个月前';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
  
  /// 获取当前日期时间的开始时刻 (00:00:00.000)
  DateTime get startOfDay {
    return DateTime(year, month, day);
  }
  
  /// 获取当前日期时间的结束时刻 (23:59:59.999)
  DateTime get endOfDay {
    return DateTime(year, month, day, 23, 59, 59, 999);
  }
  
  /// 获取当前日期时间所在周的开始时刻 (周一00:00:00.000)
  DateTime get startOfWeek {
    final daysToSubtract = weekday - 1;
    return DateTime(year, month, day - daysToSubtract);
  }
  
  /// 获取当前日期时间所在周的结束时刻 (周日23:59:59.999)
  DateTime get endOfWeek {
    final daysToAdd = 7 - weekday;
    return DateTime(year, month, day + daysToAdd, 23, 59, 59, 999);
  }
  
  /// 获取当前日期时间所在月的开始时刻 (1日00:00:00.000)
  DateTime get startOfMonth {
    return DateTime(year, month, 1);
  }
  
  /// 获取当前日期时间所在月的结束时刻 (月末23:59:59.999)
  DateTime get endOfMonth {
    return DateTime(year, month + 1, 0, 23, 59, 59, 999);
  }
  
  /// 获取当前日期时间所在年的开始时刻 (1月1日00:00:00.000)
  DateTime get startOfYear {
    return DateTime(year, 1, 1);
  }
  
  /// 获取当前日期时间所在年的结束时刻 (12月31日23:59:59.999)
  DateTime get endOfYear {
    return DateTime(year, 12, 31, 23, 59, 59, 999);
  }
  
  /// 添加天数
  DateTime addDays(int days) {
    return add(Duration(days: days));
  }
  
  /// 添加小时
  DateTime addHours(int hours) {
    return add(Duration(hours: hours));
  }
  
  /// 添加分钟
  DateTime addMinutes(int minutes) {
    return add(Duration(minutes: minutes));
  }
  
  /// 添加秒
  DateTime addSeconds(int seconds) {
    return add(Duration(seconds: seconds));
  }
  
  /// 添加月份
  DateTime addMonths(int months) {
    var newMonth = month + months;
    var newYear = year;
    
    while (newMonth > 12) {
      newMonth -= 12;
      newYear++;
    }
    
    while (newMonth < 1) {
      newMonth += 12;
      newYear--;
    }
    
    final lastDayOfMonth = DateTime(newYear, newMonth + 1, 0).day;
    final newDay = day > lastDayOfMonth ? lastDayOfMonth : day;
    
    return DateTime(newYear, newMonth, newDay, hour, minute, second, millisecond, microsecond);
  }
  
  /// 添加年份
  DateTime addYears(int years) {
    return DateTime(
      year + years,
      month,
      day,
      hour,
      minute,
      second,
      millisecond,
      microsecond,
    );
  }
  
  /// 检查日期是否为今天
  bool get isToday {
    final now = DateTime.now();
    return now.year == year && now.month == month && now.day == day;
  }
  
  /// 检查日期是否为昨天
  bool get isYesterday {
    final yesterday = DateTime.now().addDays(-1);
    return yesterday.year == year && yesterday.month == month && yesterday.day == day;
  }
  
  /// 检查日期是否为明天
  bool get isTomorrow {
    final tomorrow = DateTime.now().addDays(1);
    return tomorrow.year == year && tomorrow.month == month && tomorrow.day == day;
  }
  
  /// 检查日期是否为同一周
  bool isSameWeek(DateTime other) {
    final startOfThisWeek = startOfWeek;
    final startOfOtherWeek = other.startOfWeek;
    
    return startOfThisWeek.year == startOfOtherWeek.year &&
           startOfThisWeek.month == startOfOtherWeek.month &&
           startOfThisWeek.day == startOfOtherWeek.day;
  }
  
  /// 检查日期是否为同一月
  bool isSameMonth(DateTime other) {
    return year == other.year && month == other.month;
  }
  
  /// 检查日期是否为同一年
  bool isSameYear(DateTime other) {
    return year == other.year;
  }
  
  /// 检查日期是否为周末（周六或周日）
  bool get isWeekend {
    return weekday == DateTime.saturday || weekday == DateTime.sunday;
  }
  
  /// 检查日期是否为工作日（周一至周五）
  bool get isWeekday {
    return !isWeekend;
  }
  
  /// 获取两个日期之间的天数差
  int daysDifference(DateTime other) {
    final difference = difference(other);
    return difference.inDays;
  }
  
  /// 获取两个日期之间的月数差（近似值）
  int monthsDifference(DateTime other) {
    return ((year - other.year) * 12 + month - other.month).abs();
  }
  
  /// 获取两个日期之间的年数差（近似值）
  int yearsDifference(DateTime other) {
    return (year - other.year).abs();
  }
  
  /// 获取该月的总天数
  int get daysInMonth {
    return DateTime(year, month + 1, 0).day;
  }
  
  /// 获取该年的总天数（闰年366天，平年365天）
  int get daysInYear {
    return isLeapYear ? 366 : 365;
  }
  
  /// 检查是否为闰年
  bool get isLeapYear {
    return (year % 4 == 0) && ((year % 100 != 0) || (year % 400 == 0));
  }
  
  /// 获取本季度的起始日期
  DateTime get startOfQuarter {
    final quarterMonth = ((month - 1) ~/ 3) * 3 + 1;
    return DateTime(year, quarterMonth, 1);
  }
  
  /// 获取本季度的结束日期
  DateTime get endOfQuarter {
    final quarterMonth = ((month - 1) ~/ 3) * 3 + 3;
    return DateTime(year, quarterMonth + 1, 0, 23, 59, 59, 999);
  }
  
  /// 获取日期是一年中的第几天
  int get dayOfYear {
    return difference(DateTime(year, 1, 1)).inDays + 1;
  }
  
  /// 获取日期是一年中的第几周
  int get weekOfYear {
    final firstDayOfYear = DateTime(year, 1, 1);
    final daysOffset = (firstDayOfYear.weekday > 4 ? 8 - firstDayOfYear.weekday : 1 - firstDayOfYear.weekday);
    final firstMonday = firstDayOfYear.addDays(daysOffset);
    
    if (isBefore(firstMonday)) {
      return 0;
    }
    
    return (difference(firstMonday).inDays / 7).floor() + 1;
  }
}
