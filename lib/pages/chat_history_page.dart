import 'package:flutter/material.dart';
import '../services/chat_history_service.dart';
import '../models/chat_history.dart';
import 'package:intl/intl.dart';
import 'package:window_manager/window_manager.dart';

class ChatHistoryPage extends StatefulWidget {
  const ChatHistoryPage({super.key});

  @override
  State<ChatHistoryPage> createState() => _ChatHistoryPageState();
}

class _ChatHistoryPageState extends State<ChatHistoryPage> {
  String? selectedTask;
  ChatMessage? selectedMessage;
  List<ChatMessage> currentMessages = [];
  String _selectedTaskTab = 'all';
  String _selectedMessageTab = 'all';

  @override
  Widget build(BuildContext context) {
    final taskNames = ChatHistoryService.getAllTaskNames();
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        // 第一栏：任务列表
        Container(
          width: 200,
          color: colorScheme.surfaceVariant.withOpacity(0.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DragToMoveArea(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '任务列表',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
                        onPressed: () {
                          // 显示更多选项菜单
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _buildTaskTab('全部', 'all')),
                      Expanded(child: _buildTaskTab('最近', 'recent')),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: taskNames.length,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemBuilder: (context, index) {
                    final taskName = taskNames[index];
                    final isSelected = selectedTask == taskName;
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? colorScheme.secondaryContainer : null,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                ChatHistoryService.getDisplayName(taskName),
                                style: textTheme.bodyMedium?.copyWith(
                                  color: isSelected ? colorScheme.onSecondaryContainer : colorScheme.onSurface,
                                ),
                              ),
                            ),
                            if (isSelected)
                              InkWell(
                                onTap: () async {
                                  final result = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('确认删除'),
                                      content: Text('确定要删除任务"${ChatHistoryService.getDisplayName(taskName)}"吗？'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('取消'),
                                        ),
                                        FilledButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text('删除'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (result == true && mounted) {
                                    // 先切换到其他任务
                                    final otherTask = taskNames.firstWhere((t) => t != taskName, orElse: () => '');
                                    setState(() {
                                      if (otherTask.isNotEmpty) {
                                        selectedTask = otherTask;
                                        currentMessages = ChatHistoryService.getTaskMessages(otherTask);
                                      } else {
                                        selectedTask = null;
                                        currentMessages = [];
                                      }
                                      selectedMessage = null;
                                    });
                                    
                                    // 删除任务
                                    await ChatHistoryService.deleteTask(taskName);
                                    
                                    // 刷新状态
                                    setState(() {});
                                  }
                                },
                                child: Icon(
                                  Icons.close,
                                  size: 16,
                                  color: colorScheme.onSecondaryContainer,
                                ),
                              ),
                          ],
                        ),
                        selected: isSelected,
                        selectedTileColor: colorScheme.secondaryContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        onTap: () {
                          setState(() {
                            selectedTask = taskName;
                            currentMessages = ChatHistoryService.getTaskMessages(taskName);
                            selectedMessage = null;
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        
        // 分隔线
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: colorScheme.outlineVariant,
        ),
        
        // 第二栏：消息概览
        if (selectedTask != null) Container(
          width: 250,
          color: colorScheme.surfaceVariant.withOpacity(0.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DragToMoveArea(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '消息列表',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
                        onPressed: () {
                          // 显示更多选项菜单
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _buildMessageTab('全部', 'all')),
                      Expanded(child: _buildMessageTab('模型1', 'model1')),
                      Expanded(child: _buildMessageTab('模型2', 'model2')),
                      Expanded(child: _buildMessageTab('模型3', 'model3')),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: currentMessages.length,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemBuilder: (context, index) {
                    final message = currentMessages[index];
                    final isSelected = selectedMessage == message;
                    if (_selectedMessageTab != 'all') {
                      final modelNum = _selectedMessageTab.substring(5);
                      if (message.modelIndex.toString() != modelNum) {
                        return const SizedBox.shrink();
                      }
                    }
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? colorScheme.secondaryContainer : null,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        title: Text(
                          '循环次数: ${message.loopCount}',
                          style: textTheme.bodyMedium?.copyWith(
                            color: isSelected ? colorScheme.onSecondaryContainer : colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          '模型 ${message.modelIndex}',
                          style: textTheme.bodySmall?.copyWith(
                            color: isSelected ? colorScheme.onSecondaryContainer : colorScheme.onSurfaceVariant,
                          ),
                        ),
                        selected: isSelected,
                        selectedTileColor: colorScheme.secondaryContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        onTap: () {
                          setState(() {
                            selectedMessage = message;
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        
        // 分隔线
        if (selectedTask != null) VerticalDivider(
          width: 1,
          thickness: 1,
          color: colorScheme.outlineVariant,
        ),
        
        // 第三栏：消息详情
        if (selectedMessage != null) Expanded(
          child: Container(
            color: colorScheme.surface,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DragToMoveArea(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '消息详情',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
                          onPressed: () {
                            // 显示更多选项菜单
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '时间：${DateFormat('yyyy-MM-dd HH:mm:ss').format(selectedMessage!.timestamp)}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '发送消息：',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SelectableText(
                            selectedMessage!.sendMessage,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '返回消息：',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SelectableText(
                            selectedMessage!.responseMessage,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskTab(String label, String value) {
    final isSelected = _selectedTaskTab == value;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedTaskTab = value;
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w500 : null,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageTab(String label, String value) {
    final isSelected = _selectedMessageTab == value;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedMessageTab = value;
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w500 : null,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}