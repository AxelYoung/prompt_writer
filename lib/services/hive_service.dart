import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/prompt_config.dart';

class HiveService {
  static const String promptConfigBox = 'promptConfigs';

  static Future<void> init() async {
    try {
      // 先初始化 Hive
      await Hive.initFlutter();
      
      // 注册适配器
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(PromptConfigAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(ModelConfigAdapter());
      }
      
      // 获取文档目录
      final appDocumentDir = await getApplicationDocumentsDirectory();
      
      // 清理旧数据（如果需要的话）
      if (Hive.isBoxOpen(promptConfigBox)) {
        await Hive.box(promptConfigBox).clear();
      } else {
        await Hive.deleteBoxFromDisk(promptConfigBox);
      }
      
      // 打开盒子
      await Hive.openBox<PromptConfig>(promptConfigBox);
    } catch (e) {
      print('Hive 初始化错误: $e');
      rethrow;
    }
  }

  // 获取所有配置
  static List<PromptConfig> getAllConfigs() {
    final box = Hive.box<PromptConfig>(promptConfigBox);
    return box.values.toList();
  }

  // 添加新配置
  static Future<void> addConfig(PromptConfig config) async {
    final box = Hive.box<PromptConfig>(promptConfigBox);
    await box.add(config);
  }

  // 更新配置
  static Future<void> updateConfig(int index, PromptConfig config) async {
    final box = Hive.box<PromptConfig>(promptConfigBox);
    await box.putAt(index, config);
  }

  // 删除配置
  static Future<void> deleteConfig(int index) async {
    final box = Hive.box<PromptConfig>(promptConfigBox);
    await box.deleteAt(index);
  }

  // 创建默认配置
  static Future<void> createDefaultConfig(String name, String description) async {
    final config = PromptConfig.createDefault(name, description);
    await addConfig(config);
  }

  // 清理所有数据
  static Future<void> clearAll() async {
    final box = Hive.box<PromptConfig>(promptConfigBox);
    await box.clear();
  }
} 