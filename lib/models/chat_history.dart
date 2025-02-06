import 'package:hive/hive.dart';

part 'chat_history.g.dart';

@HiveType(typeId: 3)
class ChatHistory {
  @HiveField(0)
  String taskName; // 任务名称

  @HiveField(1)
  List<ChatMessage> messages; // 对话内容列表

  ChatHistory({
    required this.taskName,
    required this.messages,
  });
}

@HiveType(typeId: 4)
class ChatMessage {
  @HiveField(0)
  int loopCount; // 循环次数

  @HiveField(1)
  int modelIndex; // 模型序号（1-3）

  @HiveField(2)
  String sendMessage; // 发送的消息

  @HiveField(3)
  String responseMessage; // 返回的消息

  @HiveField(4)
  DateTime timestamp; // 时间戳

  ChatMessage({
    required this.loopCount,
    required this.modelIndex,
    required this.sendMessage,
    required this.responseMessage,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
} 