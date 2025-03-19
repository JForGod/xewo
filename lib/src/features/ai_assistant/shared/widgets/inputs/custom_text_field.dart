import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/theme_constants.dart';

/// 输入框尺寸
enum CustomTextFieldSize {
  small,
  medium,
  large,
}

/// 自定义输入框
class CustomTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? errorText;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool obscureText;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final CustomTextFieldSize size;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final bool readOnly;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final bool showCursor;
  final bool showCounter;
  final BoxConstraints? prefixIconConstraints;
  final BoxConstraints? suffixIconConstraints;
  final EdgeInsetsGeometry? contentPadding;
  final TextCapitalization textCapitalization;
  
  /// 构造函数
  const CustomTextField({
    Key? key,
    this.label,
    this.hint,
    this.errorText,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.done,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.size = CustomTextFieldSize.medium,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.readOnly = false,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.inputFormatters,
    this.showCursor = true,
    this.showCounter = false,
    this.prefixIconConstraints,
    this.suffixIconConstraints,
    this.contentPadding,
    this.textCapitalization = TextCapitalization.none,
  }) : super(key: key);
  
  @override
  _CustomTextFieldState createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  
  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }
  
  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }
  
  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final height = _getInputHeight();
    final fontSize = _getFontSize();
    final effectiveContentPadding = widget.contentPadding ?? _getContentPadding();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 标签
        if (widget.label != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              widget.label!,
              style: TextStyle(
                fontSize: fontSize * 0.875,
                fontWeight: FontWeight.w500,
                color: widget.enabled
                    ? theme.textTheme.bodyMedium?.color
                    : theme.disabledColor,
              ),
            ),
          ),
        ],
        
        // 输入框
        SizedBox(
          height: widget.maxLines == 1 ? height : null,
          child: TextField(
            controller: widget.controller,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            obscureText: widget.obscureText,
            maxLines: widget.maxLines,
            minLines: widget.minLines,
            maxLength: widget.maxLength,
            onChanged: widget.onChanged,
            onEditingComplete: widget.onEditingComplete,
            onSubmitted: widget.onSubmitted,
            readOnly: widget.readOnly,
            enabled: widget.enabled,
            autofocus: widget.autofocus,
            focusNode: _focusNode,
            inputFormatters: widget.inputFormatters,
            showCursor: widget.showCursor,
            textCapitalization: widget.textCapitalization,
            style: TextStyle(
              fontSize: fontSize,
              color: widget.enabled ? null : theme.disabledColor,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              errorText: widget.errorText,
              contentPadding: effectiveContentPadding,
              filled: true,
              fillColor: widget.enabled
                  ? (_isFocused
                      ? theme.inputDecorationTheme.fillColor?.withOpacity(0.8)
                      : theme.inputDecorationTheme.fillColor)
                  : theme.disabledColor.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ThemeConstants.borderRadius),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ThemeConstants.borderRadius),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ThemeConstants.borderRadius),
                borderSide: BorderSide(
                  color: theme.primaryColor,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ThemeConstants.borderRadius),
                borderSide: BorderSide(
                  color: theme.colorScheme.error,
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ThemeConstants.borderRadius),
                borderSide: BorderSide(
                  color: theme.colorScheme.error,
                  width: 1.5,
                ),
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      size: _getIconSize(),
                      color: widget.enabled
                          ? theme.hintColor
                          : theme.disabledColor,
                    )
                  : null,
              prefixIconConstraints: widget.prefixIconConstraints,
              suffixIcon: widget.suffixIcon != null
                  ? IconButton(
                      icon: Icon(
                        widget.suffixIcon,
                        size: _getIconSize(),
                        color: widget.enabled
                            ? theme.hintColor
                            : theme.disabledColor,
                      ),
                      onPressed: widget.enabled ? widget.onSuffixIconPressed : null,
                    )
                  : null,
              suffixIconConstraints: widget.suffixIconConstraints,
              counterText: widget.showCounter ? null : '',
            ),
          ),
        ),
      ],
    );
  }
  
  /// 获取输入框高度
  double _getInputHeight() {
    switch (widget.size) {
      case CustomTextFieldSize.small:
        return ThemeConstants.inputHeightSmall;
      case CustomTextFieldSize.medium:
        return ThemeConstants.inputHeight;
      case CustomTextFieldSize.large:
        return ThemeConstants.inputHeightLarge;
    }
  }
  
  /// 获取字体大小
  double _getFontSize() {
    switch (widget.size) {
      case CustomTextFieldSize.small:
        return ThemeConstants.fontSizeSmall;
      case CustomTextFieldSize.medium:
        return ThemeConstants.fontSize;
      case CustomTextFieldSize.large:
        return ThemeConstants.fontSizeLarge;
    }
  }
  
  /// 获取内边距
  EdgeInsetsGeometry _getContentPadding() {
    switch (widget.size) {
      case CustomTextFieldSize.small:
        return EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case CustomTextFieldSize.medium:
        return EdgeInsets.symmetric(horizontal: 16, vertical: 12);
      case CustomTextFieldSize.large:
        return EdgeInsets.symmetric(horizontal: 20, vertical: 16);
    }
  }
  
  /// 获取图标尺寸
  double _getIconSize() {
    switch (widget.size) {
      case CustomTextFieldSize.small:
        return ThemeConstants.iconSizeSmall;
      case CustomTextFieldSize.medium:
        return ThemeConstants.iconSize;
      case CustomTextFieldSize.large:
        return ThemeConstants.iconSizeLarge;
    }
  }
}
