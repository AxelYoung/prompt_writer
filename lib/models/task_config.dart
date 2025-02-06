import 'package:hive/hive.dart';

part 'task_config.g.dart';

@HiveType(typeId: 2)
class TaskConfig {
  @HiveField(0)
  String name; // 任务名称

  @HiveField(1)
  String description; // 任务描述

  @HiveField(2)
  String taskPurpose; // 总任务目的

  @HiveField(3)
  String model1Prompt; // 模型1的prompt

  @HiveField(4)
  String model2Prompt; // 模型2的prompt

  @HiveField(5)
  String model3Prompt; // 模型3的prompt

  @HiveField(6)
  String corpus; // 语料

  TaskConfig({
    required this.name,
    required this.description,
    required this.taskPurpose,
    required this.model1Prompt,
    required this.model2Prompt,
    required this.model3Prompt,
    this.corpus = '', // 默认为空字符串
  });

  // 创建默认配置
  factory TaskConfig.createDefault(String name, String description) {
    return TaskConfig(
      name: name,
      description: description,
      taskPurpose: '请描述任务目的',
      model1Prompt: '模型1的提示词',
      model2Prompt: '模型2的提示词',
      model3Prompt: '模型3的提示词',
      corpus: '请输入语料', // 添加默认语料
    );
  }
} 