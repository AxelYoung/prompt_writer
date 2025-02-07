import 'package:hive_flutter/hive_flutter.dart';
import '../models/chat_history.dart';
import 'package:intl/intl.dart';
import '../models/task_config.dart';
import '../services/task_service.dart';

class ChatHistoryService {
  static const String chatHistoryBox = 'chat_histories';
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
      taskPurpose: '这是测试任务1的目的',
      corpus: '这是测试任务1的语料',
      model1Prompt: '这是测试任务1的模型1提示词',
      model2Prompt: '这是测试任务1的模型2提示词',
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
      taskPurpose: '这是测试任务2的目的',
      corpus: '这是测试任务2的语料',
      model1Prompt: '这是测试任务2的模型1提示词',
      model2Prompt: '这是测试任务2的模型2提示词',
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
    String? taskPurpose,
    String? corpus,
    String? model1Prompt,
    String? model2Prompt,
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
      // 如果是新的历史记录，从 TaskService 获取任务配置
      final tasks = TaskService.getAllTasks();
      final baseTaskName = taskName.split('_').first;
      final task = tasks.firstWhere(
        (t) => t.name == baseTaskName,
        orElse: () => TaskConfig(
          name: baseTaskName,
          description: '',
          taskPurpose: taskPurpose ?? '',
          corpus: corpus ?? '',
          model1Prompt: model1Prompt ?? '',
          model2Prompt: model2Prompt ?? '',
          model3Prompt: '',
        ),
      );

      history = ChatHistory(
        taskName: taskName,
        messages: [message],
        taskPurpose: taskPurpose ?? task.taskPurpose,
        corpus: corpus ?? task.corpus,
        model1Prompt: model1Prompt ?? task.model1Prompt,
        model2Prompt: model2Prompt ?? task.model2Prompt,
      );
    } else {
      history.messages.add(message);
      // 更新任务设置（如果提供了新的值）
      if (taskPurpose != null) history.taskPurpose = taskPurpose;
      if (corpus != null) history.corpus = corpus;
      if (model1Prompt != null) history.model1Prompt = model1Prompt;
      if (model2Prompt != null) history.model2Prompt = model2Prompt;
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

  // 删除指定任务
  static Future<void> deleteTask(String taskName) async {
    if (_box == null) {
      throw StateError('ChatHistoryService 未初始化');
    }
    await _box!.delete(taskName);
  }

  static Future<void> createHistory(ChatHistory history) async {
    if (_box == null) {
      throw StateError('ChatHistoryService 未初始化');
    }
    await _box!.put(history.taskName, history);
  }

  static ChatHistory? getHistory(String taskName) {
    if (_box == null) {
      throw StateError('ChatHistoryService 未初始化');
    }
    return _box!.get(taskName);
  }

  static Future<void> updateHistory(ChatHistory history) async {
    if (_box == null) {
      throw StateError('ChatHistoryService 未初始化');
    }
    await _box!.put(history.taskName, history);
  }
} 