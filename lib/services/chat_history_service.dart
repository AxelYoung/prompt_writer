import 'package:hive_flutter/hive_flutter.dart';
import '../models/chat_history.dart';
import 'package:intl/intl.dart';

class ChatHistoryService {
  static const String chatHistoryBox = 'chatHistory';
  static Box<ChatHistory>? _box;

  // 初始化
  static Future<void> init() async {
    try {
      // 注册适配器
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(ChatHistoryAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(ChatMessageAdapter());
      }
      
      // 打开盒子
      if (!Hive.isBoxOpen(chatHistoryBox)) {
        _box = await Hive.openBox<ChatHistory>(chatHistoryBox);
        
        // 如果是空的，添加一些测试数据
        if (_box!.isEmpty) {
          await addTestData();
        }
      } else {
        _box = Hive.box<ChatHistory>(chatHistoryBox);
      }
    } catch (e) {
      print('ChatHistoryService 初始化错误: $e');
      rethrow;
    }
  }

  // 添加测试数据
  static Future<void> addTestData() async {
    // 任务1的消息
    await addMessage(
      taskName: '测试任务1',
      loopCount: 1,
      modelIndex: 1,
      sendMessage: '这是发送给模型1的第一条消息',
      responseMessage: '这是模型1的第一次回复，测试长文本效果测试长文本效果测试长文本效果测试长文本效果测试长文本效果测试长文本效果',
    );

    await addMessage(
      taskName: '测试任务1',
      loopCount: 1,
      modelIndex: 2,
      sendMessage: '这是发送给模型2的消息，包含了模型1的结果',
      responseMessage: '这是模型2的回复，可能会比较长一些这是模型2的回复，可能会比较长一些这是模型2的回复，可能会比较长一些',
    );

    // 任务2的消息
    await addMessage(
      taskName: '测试任务2',
      loopCount: 1,
      modelIndex: 1,
      sendMessage: '任务2的第一条消息',
      responseMessage: '任务2模型1的回复',
    );

    await addMessage(
      taskName: '测试任务2',
      loopCount: 2,
      modelIndex: 1,
      sendMessage: '任务2的第二轮消息',
      responseMessage: '任务2第二轮的回复',
    );
  }

  // 获取所有任务名称（按时间倒序）
  static List<String> getAllTaskNames() {
    if (_box == null) {
      throw StateError('ChatHistoryService 未初始化');
    }
    final taskNames = _box!.keys.cast<String>().toList();
    taskNames.sort((a, b) => b.compareTo(a)); // 按时间倒序排序
    return taskNames;
  }

  // 获取任务的显示名称（去除时间戳）
  static String getDisplayName(String taskName) {
    final parts = taskName.split('_');
    if (parts.length > 1) {
      // 如果包含时间戳，返回基础名称和格式化的时间
      final baseName = parts.first;
      final timestamp = _parseTimestamp(parts.last);
      if (timestamp != null) {
        final formattedTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp);
        return '$baseName ($formattedTime)';
      }
    }
    return taskName;
  }

  // 解析时间戳
  static DateTime? _parseTimestamp(String timestamp) {
    try {
      if (timestamp.length >= 14) {
        final year = int.parse(timestamp.substring(0, 4));
        final month = int.parse(timestamp.substring(4, 6));
        final day = int.parse(timestamp.substring(6, 8));
        final hour = int.parse(timestamp.substring(9, 11));
        final minute = int.parse(timestamp.substring(11, 13));
        final second = int.parse(timestamp.substring(13, 15));
        return DateTime(year, month, day, hour, minute, second);
      }
    } catch (e) {
      print('时间戳解析错误: $e');
    }
    return null;
  }

  // 获取指定任务的所有对话记录
  static List<ChatMessage> getTaskMessages(String taskName) {
    if (_box == null) {
      throw StateError('ChatHistoryService 未初始化');
    }
    final history = _box!.get(taskName);
    return history?.messages ?? [];
  }

  // 添加新的对话记录
  static Future<void> addMessage({
    required String taskName,
    required int loopCount,
    required int modelIndex,
    required String sendMessage,
    required String responseMessage,
  }) async {
    if (_box == null) {
      throw StateError('ChatHistoryService 未初始化');
    }

    final message = ChatMessage(
      loopCount: loopCount,
      modelIndex: modelIndex,
      sendMessage: sendMessage,
      responseMessage: responseMessage,
    );

    ChatHistory? history = _box!.get(taskName);
    if (history == null) {
      history = ChatHistory(
        taskName: taskName,
        messages: [message],
      );
    } else {
      history.messages.add(message);
    }
    await _box!.put(taskName, history);
  }

  // 清除所有数据
  static Future<void> clearAll() async {
    if (_box == null) {
      throw StateError('ChatHistoryService 未初始化');
    }
    await _box!.clear();
  }
} 