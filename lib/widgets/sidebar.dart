import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class Sidebar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onIndexChanged;

  const Sidebar({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      color: Colors.black,
      child: Column(
        children: [
          const DragToMoveArea(
            child: SizedBox(height: 20),
          ),
          _buildIcon(Icons.home, 0, '主页'),
          _buildIcon(Icons.chat, 1, '对话历史'),
          _buildIcon(Icons.history, 2, '历史结果'),
          _buildIcon(Icons.settings, 3, '设置'),
          _buildIcon(Icons.info_outline, 4, '关于'),
          const Expanded(
            child: DragToMoveArea(
              child: SizedBox(
                width: double.infinity,
              ),
            ),
          ),
          _buildWindowButton(
            Icons.minimize,
            '最小化',
            () async => await windowManager.minimize(),
          ),
          _buildWindowButton(
            Icons.crop_square,
            '最大化',
            () async {
              if (await windowManager.isMaximized()) {
                await windowManager.unmaximize();
              } else {
                await windowManager.maximize();
              }
            },
          ),
          _buildWindowButton(
            Icons.close,
            '关闭',
            () async => await windowManager.close(),
            hoverColor: Colors.red,
          ),
          const SizedBox(height: 15),
        ],
      ),
    );
  }

  Widget _buildIcon(IconData icon, int index, String tooltip) {
    final bool isActive = currentIndex == index;
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      verticalOffset: 20,
      child: Container(
        width: 50,
        height: 50,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onIndexChanged(index),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFFF5722) : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: isActive ? Colors.white : Colors.grey,
                  size: 26,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWindowButton(
    IconData icon,
    String tooltip,
    VoidCallback onPressed, {
    Color? hoverColor,
  }) {
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      verticalOffset: 20,
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            hoverColor: hoverColor?.withOpacity(0.1) ?? Colors.white.withOpacity(0.05),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: hoverColor ?? Colors.grey,
                  size: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 