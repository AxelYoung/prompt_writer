import 'package:hive_flutter/hive_flutter.dart';
import '../models/task_config.dart';

class TaskService {
  static const String taskConfigBox = 'taskConfigs';
  static Box<TaskConfig>? _box;

  // 初始化
  static Future<void> init() async {
    try {
      // 注册适配器
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(TaskConfigAdapter());
      }
      
      // 检查 Box 是否已经打开
      if (!Hive.isBoxOpen(taskConfigBox)) {
        // 打开盒子
        _box = await Hive.openBox<TaskConfig>(taskConfigBox);
        
        // 如果是首次打开，创建默认任务
        if (_box!.isEmpty) {
          await createDefaultTask('默认任务', '默认任务配置');
        }
      } else {
        _box = Hive.box<TaskConfig>(taskConfigBox);
      }
    } catch (e) {
      print('TaskService 初始化错误: $e');
      rethrow;
    }
  }

  // 获取所有任务配置
  static List<TaskConfig> getAllTasks() {
    if (_box == null) {
      throw StateError('TaskService 未初始化');
    }
    return _box!.values.toList();
  }

  // 添加新任务配置
  static Future<void> addTask(TaskConfig config) async {
    if (_box == null) {
      throw StateError('TaskService 未初始化');
    }
    await _box!.add(config);
  }

  // 更新任务配置
  static Future<void> updateTask(int index, TaskConfig config) async {
    if (_box == null) {
      throw StateError('TaskService 未初始化');
    }
    await _box!.putAt(index, config);
  }

  // 删除任务配置
  static Future<void> deleteTask(int index) async {
    if (_box == null) {
      throw StateError('TaskService 未初始化');
    }
    await _box!.deleteAt(index);
  }

  // 创建默认任务配置
  static Future<void> createDefaultTask(String name, String description) async {
    final config = TaskConfig.createDefault(name, description);
    await addTask(config);
  }

  // 清理所有数据
  static Future<void> clearAll() async {
    if (_box == null) {
      throw StateError('TaskService 未初始化');
    }
    await _box!.clear();
  }
} 