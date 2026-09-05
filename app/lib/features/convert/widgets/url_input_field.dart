import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

class UrlInputField extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const UrlInputField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<UrlInputField> createState() => _UrlInputFieldState();
}

class _UrlInputFieldState extends State<UrlInputField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(UrlInputField old) {
    super.didUpdateWidget(old);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
      _controller.selection =
          TextSelection.collapsed(offset: widget.value.length);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isNotEmpty) {
      _controller.text = text;
      widget.onChanged(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 14),
            child: Icon(Icons.link, size: 20, color: Color(0xFF8E8E93)),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: widget.onChanged,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                hintText: '뉴스 기사 URL을 입력하세요',
                hintStyle: TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 14),
              ),
              style: const TextStyle(fontSize: 14, color: AppColors.ink),
            ),
          ),
          if (widget.value.isEmpty)
            TextButton(
              onPressed: _paste,
              child: const Text('붙여넣기',
                  style: TextStyle(fontSize: 13, color: AppColors.primary)),
            )
          else
            IconButton(
              icon: const Icon(Icons.clear, size: 18, color: Color(0xFF8E8E93)),
              onPressed: () {
                _controller.clear();
                widget.onChanged('');
              },
            ),
        ],
      ),
    );
  }
}
