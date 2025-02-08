import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import '../models/prompt_config.dart';

class HiveService {
  static const String promptConfigBox = 'promptConfigs';
  static const String backupDir = 'backups';
  
  static Future<void> init() async {
    try {
      // 注册适配器
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(PromptConfigAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(ModelConfigAdapter());
      }
      
      // 获取文档目录
      final appDocumentDir = await getApplicationDocumentsDirectory();
      final backupPath = '${appDocumentDir.path}/$backupDir';
      
      // 创建备份目录
      await Directory(backupPath).create(recursive: true);
      
      // 打开盒子（如果不存在则创建）
      if (!Hive.isBoxOpen(promptConfigBox)) {
        await Hive.openBox<PromptConfig>(promptConfigBox);
      }
      
      // 如果盒子是空的，创建默认配置
      final box = Hive.box<PromptConfig>(promptConfigBox);
      if (box.isEmpty) {
        await createDefaultConfig('默认配置', '默认API配置');
      }
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
    await createBackup(); // 添加配置后创建备份
  }

  // 更新配置
  static Future<void> updateConfig(int index, PromptConfig config) async {
    try {
      final box = Hive.box<PromptConfig>(promptConfigBox);
      
      // 验证 box 是否正确打开
      if (!box.isOpen) {
        throw Exception('Hive box 未打开');
      }
      
      // 验证索引是否有效
      if (index < 0 || index >= box.length) {
        throw Exception('无效的配置索引: $index');
      }
      
      print('准备更新配置:');
      print('  索引: $index');
      print('  配置名称: ${config.name}');
      for (int i = 0; i < config.models.length; i++) {
        final model = config.models[i];
        print('  模型${i + 1}:');
        print('    API Key: ${model.apiKey}');
        print('    Base URL: ${model.baseUrl}');
        print('    Model: ${model.model}');
        print('    Temperature: ${model.temperature}');
        print('    Top P: ${model.topP}');
        print('    Max Tokens: ${model.maxTokens}');
        print('    Presence Penalty: ${model.presencePenalty}');
        print('    Frequency Penalty: ${model.frequencyPenalty}');
      }
      
      // 保存配置
      await box.putAt(index, config);
      print('成功更新配置: ${config.name} at index $index');
      
      // 验证保存是否成功
      final savedConfig = box.getAt(index);
      if (savedConfig == null) {
        throw Exception('保存后无法读取配置');
      }
      print('验证保存结果:');
      print('  配置名称: ${savedConfig.name}');
      for (int i = 0; i < savedConfig.models.length; i++) {
        final model = savedConfig.models[i];
        print('  模型${i + 1}:');
        print('    API Key: ${model.apiKey}');
        print('    Base URL: ${model.baseUrl}');
        print('    Model: ${model.model}');
        print('    Temperature: ${model.temperature}');
        print('    Top P: ${model.topP}');
        print('    Max Tokens: ${model.maxTokens}');
        print('    Presence Penalty: ${model.presencePenalty}');
        print('    Frequency Penalty: ${model.frequencyPenalty}');
      }
      
      // 创建备份
      await createBackup();
    } catch (e) {
      print('更新配置失败: $e');
      rethrow;
    }
  }

  // 删除配置
  static Future<void> deleteConfig(int index) async {
    final box = Hive.box<PromptConfig>(promptConfigBox);
    await box.deleteAt(index);
    await createBackup(); // 删除配置后创建备份
  }

  // 创建默认配置
  static Future<void> createDefaultConfig(String name, String description) async {
    final config = PromptConfig.createDefault(name, description);
    await addConfig(config);
  }

  // 创建备份
  static Future<void> createBackup() async {
    try {
      final appDocumentDir = await getApplicationDocumentsDirectory();
      final backupPath = '${appDocumentDir.path}/$backupDir';
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupFile = File('$backupPath/backup_$timestamp.hive');
      
      final box = Hive.box<PromptConfig>(promptConfigBox);
      final configs = box.values.toList();
      
      // 将数据序列化为 JSON
      final jsonData = configs.map((config) => {
        'name': config.name,
        'description': config.description,
        'systemPrompts': config.systemPrompts,
        'models': config.models.map((model) => {
          'model': model.model,
          'apiKey': model.apiKey,
          'baseUrl': model.baseUrl,
          'temperature': model.temperature,
          'topP': model.topP,
          'maxTokens': model.maxTokens,
          'n': model.n,
          'presencePenalty': model.presencePenalty,
          'frequencyPenalty': model.frequencyPenalty,
          'headers': model.headers,
          'stream': model.stream,
        }).toList(),
      }).toList();
      
      // 写入备份文件
      await backupFile.writeAsString(jsonEncode(jsonData));
      
      // 只保留最近的5个备份
      final dir = Directory(backupPath);
      final files = await dir.list().toList();
      if (files.length > 5) {
        files.sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));
        for (var i = 0; i < files.length - 5; i++) {
          await files[i].delete();
        }
      }
    } catch (e) {
      print('创建备份失败: $e');
    }
  }

  // 从备份恢复
  static Future<bool> restoreFromBackup(String backupFileName) async {
    try {
      final appDocumentDir = await getApplicationDocumentsDirectory();
      final backupPath = '${appDocumentDir.path}/$backupDir/$backupFileName';
      final backupFile = File(backupPath);
      
      if (!await backupFile.exists()) {
        throw Exception('备份文件不存在');
      }
      
      // 读取备份文件
      final jsonString = await backupFile.readAsString();
      final jsonData = jsonDecode(jsonString) as List;
      
      // 清空当前数据
      final box = Hive.box<PromptConfig>(promptConfigBox);
      await box.clear();
      
      // 恢复数据
      for (final configData in jsonData) {
        final config = PromptConfig(
          name: configData['name'],
          description: configData['description'],
          systemPrompts: Map<String, String>.from(configData['systemPrompts']),
          models: (configData['models'] as List).map((modelData) => ModelConfig(
            model: modelData['model'],
            apiKey: modelData['apiKey'],
            baseUrl: modelData['baseUrl'],
            temperature: modelData['temperature'],
            topP: modelData['topP'],
            maxTokens: modelData['maxTokens'],
            n: modelData['n'],
            presencePenalty: modelData['presencePenalty'],
            frequencyPenalty: modelData['frequencyPenalty'],
            headers: Map<String, String>.from(modelData['headers']),
            stream: modelData['stream'],
          )).toList(),
        );
        await box.add(config);
      }
      
      return true;
    } catch (e) {
      print('从备份恢复失败: $e');
      return false;
    }
  }

  // 获取所有备份文件
  static Future<List<String>> getBackupFiles() async {
    try {
      final appDocumentDir = await getApplicationDocumentsDirectory();
      final backupPath = '${appDocumentDir.path}/$backupDir';
      final dir = Directory(backupPath);
      
      if (!await dir.exists()) {
        return [];
      }
      
      final files = await dir.list()
          .where((entity) => entity is File && entity.path.endsWith('.hive'))
          .map((entity) => entity.path.split('/').last)
          .toList();
      
      return files;
    } catch (e) {
      print('获取备份文件列表失败: $e');
      return [];
    }
  }

  // 清理所有数据
  static Future<void> clearAll() async {
    try {
      final box = Hive.box<PromptConfig>(promptConfigBox);
      await box.clear();
      await createBackup(); // 清理后创建一个空备份
    } catch (e) {
      print('清理数据失败: $e');
      rethrow;
    }
  }

  // 清除所有 Hive 数据
  static Future<void> clearAllData() async {
    try {
      // 清除 promptConfigs
      if (Hive.isBoxOpen(promptConfigBox)) {
        final box = Hive.box<PromptConfig>(promptConfigBox);
        await box.clear();
      }
      
      // 清除 chat_histories
      if (Hive.isBoxOpen('chat_histories')) {
        final box = Hive.box('chat_histories');
        await box.clear();
      }
      
      // 删除所有 Hive 数据文件
      await Hive.deleteFromDisk();
      
      // 重新初始化
      await init();
      
      print('已清除所有 Hive 数据并重新初始化');
    } catch (e) {
      print('清除 Hive 数据失败: $e');
      rethrow;
    }
  }
} 