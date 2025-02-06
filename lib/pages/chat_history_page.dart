import 'package:flutter/material.dart';
import '../services/chat_history_service.dart';
import '../models/chat_history.dart';
import 'package:intl/intl.dart';

class ChatHistoryPage extends StatefulWidget {
  const ChatHistoryPage({super.key});

  @override
  State<ChatHistoryPage> createState() => _ChatHistoryPageState();
}

class _ChatHistoryPageState extends State<ChatHistoryPage> {
  String? selectedTask;
  ChatMessage? selectedMessage;
  List<ChatMessage> currentMessages = [];

  @override
  Widget build(BuildContext context) {
    final taskNames = ChatHistoryService.getAllTaskNames();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // 第一栏：任务列表
          Container(
            width: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                  child: const Text(
                    '任务列表',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Microsoft YaHei',
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: taskNames.length,
                    itemBuilder: (context, index) {
                      final taskName = taskNames[index];
                      return ListTile(
                        title: Text(
                          ChatHistoryService.getDisplayName(taskName),
                          style: const TextStyle(fontFamily: 'Microsoft YaHei'),
                        ),
                        selected: selectedTask == taskName,
                        onTap: () {
                          setState(() {
                            selectedTask = taskName;
                            currentMessages = ChatHistoryService.getTaskMessages(taskName);
                            selectedMessage = null;
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // 第二栏：消息概览
          if (selectedTask != null) Container(
            width: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                  child: const Text(
                    '消息列表',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Microsoft YaHei',
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: currentMessages.length,
                    itemBuilder: (context, index) {
                      final message = currentMessages[index];
                      return ListTile(
                        title: Text(
                          '循环次数: ${message.loopCount}',
                          style: const TextStyle(fontFamily: 'Microsoft YaHei'),
                        ),
                        subtitle: Text(
                          '模型 ${message.modelIndex}',
                          style: const TextStyle(fontFamily: 'Microsoft YaHei'),
                        ),
                        selected: selectedMessage == message,
                        onTap: () {
                          setState(() {
                            selectedMessage = message;
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // 第三栏：消息详情
          if (selectedMessage != null) Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    ),
                    child: const Text(
                      '消息详情',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Microsoft YaHei',
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
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontFamily: 'Microsoft YaHei',
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '发送消息：',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Microsoft YaHei',
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 8, bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SelectableText(
                              selectedMessage!.sendMessage,
                              style: const TextStyle(fontFamily: 'Microsoft YaHei'),
                            ),
                          ),
                          const Text(
                            '返回消息：',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Microsoft YaHei',
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SelectableText(
                              selectedMessage!.responseMessage,
                              style: const TextStyle(fontFamily: 'Microsoft YaHei'),
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
      ),
    );
  }
} 