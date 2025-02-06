import 'package:hive/hive.dart';

part 'prompt_config.g.dart';

@HiveType(typeId: 0)
class PromptConfig {
  @HiveField(0)
  String name; // 配置名称

  @HiveField(1)
  String description; // 配置描述

  @HiveField(2)
  List<ModelConfig> models; // 模型配置列表

  @HiveField(3)
  Map<String, String> systemPrompts; // 系统提示词配置

  PromptConfig({
    required this.name,
    required this.description,
    required this.models,
    required this.systemPrompts,
  });

  // 创建默认配置
  factory PromptConfig.createDefault(String name, String description) {
    return PromptConfig(
      name: name,
      description: description,
      systemPrompts: {
        'default': 'You are a helpful assistant.',
      },
      models: [
        ModelConfig.model1Default(),
        ModelConfig.model2Default(),
        ModelConfig.model3Default(),
      ],
    );
  }
}

@HiveType(typeId: 1)
class ModelConfig {
  @HiveField(0)
  String model; // 模型名称

  @HiveField(1)
  String apiKey; // API密钥

  @HiveField(2)
  String baseUrl;

  @HiveField(3)
  String temperature; // 温度

  @HiveField(4)
  String topP; // 核采样

  @HiveField(5)
  String maxTokens; // 最大令牌数

  @HiveField(6)
  String n; // 生成数量

  @HiveField(7)
  String presencePenalty; // 存在惩罚

  @HiveField(8)
  String frequencyPenalty; // 频率惩罚

  @HiveField(9)
  Map<String, String> headers; // 自定义请求头

  @HiveField(10)
  bool stream; // 是否使用流式响应

  ModelConfig({
    required this.model,
    required this.apiKey,
    required this.baseUrl,
    required this.temperature,
    required this.topP,
    required this.maxTokens,
    required this.n,
    required this.presencePenalty,
    required this.frequencyPenalty,
    required this.headers,
    required this.stream,
  });

  double get temperatureValue => double.tryParse(temperature) ?? 0.7;
  double get topPValue => double.tryParse(topP) ?? 1.0;
  int get maxTokensValue => int.tryParse(maxTokens) ?? 2000;
  int get nValue => int.tryParse(n) ?? 1;
  double get presencePenaltyValue => double.tryParse(presencePenalty) ?? 0.0;
  double get frequencyPenaltyValue => double.tryParse(frequencyPenalty) ?? 0.0;

  // 模型1默认配置
  factory ModelConfig.model1Default() {
    return ModelConfig(
      model: '模型1',
      apiKey: '',
      baseUrl: 'https://api.openai.com',
      temperature: '0.7',
      topP: '1',
      maxTokens: '4000',
      n: '1',
      presencePenalty: '0',
      frequencyPenalty: '0',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      stream: false,
    );
  }

  // 模型2默认配置
  factory ModelConfig.model2Default() {
    return ModelConfig(
      model: '模型2',
      apiKey: '',
      baseUrl: 'https://api.openai.com',
      temperature: '0.7',
      topP: '1',
      maxTokens: '2000',
      n: '1',
      presencePenalty: '0',
      frequencyPenalty: '0',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      stream: false,
    );
  }

  // 模型3默认配置
  factory ModelConfig.model3Default() {
    return ModelConfig(
      model: '模型3',
      apiKey: '',
      baseUrl: 'https://api.openai.com',
      temperature: '0.7',
      topP: '1',
      maxTokens: '2000',
      n: '1',
      presencePenalty: '0',
      frequencyPenalty: '0',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      stream: false,
    );
  }
} 