import '../models/prompt_config.dart';
import '../models/task_config.dart';
import '../models/chat_history.dart';
import '../services/chat_history_service.dart';
import '../services/task_service.dart';
import '../services/llm_service.dart';
import 'dart:async';

// 运行状态枚举
enum RunningStatus {
  idle,        // 空闲
  running,     // 运行中
  completed,   // 完成
  error,       // 错误
}

// 运行进度回调
typedef ProgressCallback = void Function(int currentLoop, int modelIndex, String status);
// 完成回调
typedef CompletionCallback = void Function(bool success, String? error);

class ModelService {
  static ModelService? _instance;
  
  // 模型结果
  String model1Result = '';
  String model2Result = '';
  String model3Result = '';
  
  // 配置信息
  late PromptConfig apiConfig;
  late TaskConfig taskConfig;
  late int loopCount;

  // 取消标志
  bool _isCancelled = false;

  // API参数映射
  Map<String, String> modelParams = {};

  // 运行状态
  RunningStatus _status = RunningStatus.idle;
  String? _lastError;
  int currentLoop = 0;
  int currentModelIndex = 0;
  
  // 获取当前状态
  RunningStatus get status => _status;
  String? get lastError => _lastError;
  
  // 私有构造函数
  ModelService._();
  
  // 单例模式
  static ModelService get instance {
    _instance ??= ModelService._();
    return _instance!;
  }
  
  // 初始化服务
  void init({
    required PromptConfig selectedApiConfig,
    required TaskConfig selectedTaskConfig,
    required int selectedLoopCount,
  }) {
    apiConfig = selectedApiConfig;
    taskConfig = selectedTaskConfig;
    loopCount = selectedLoopCount;
    currentLoop = 0;
    currentModelIndex = 0;
    _status = RunningStatus.idle;
    _lastError = null;
    _isCancelled = false;
    
    clearResults();
    _extractParams();
  }

  // 取消运行
  void cancel() {
    if (_status == RunningStatus.running) {
      _isCancelled = true;
      _status = RunningStatus.idle;
      _lastError = '用户取消了运行';
    }
  }

  // 运行模型
  Future<bool> run({
    ProgressCallback? onProgress,
    CompletionCallback? onComplete,
  }) async {
    if (_status == RunningStatus.running) {
      throw StateError('模型正在运行中');
    }

    _status = RunningStatus.running;
    _lastError = null;
    _isCancelled = false;
    final timestamp = DateTime.now();
    final taskRunId = '${taskConfig.name}_${_formatDateTime(timestamp)}';
    final llmService = LLMService.instance;
    
    try {
      for (currentLoop = 1; currentLoop <= loopCount; currentLoop++) {
        if (_isCancelled) {
          break;
        }

        final maxModel = (currentLoop == loopCount) ? 2 : 3;
        
        for (currentModelIndex = 1; currentModelIndex <= maxModel; currentModelIndex++) {
          if (_isCancelled) {
            break;
          }

          // 更新进度
          onProgress?.call(
            currentLoop, 
            currentModelIndex, 
            '正在运行模型 $currentModelIndex (循环 $currentLoop/$loopCount)'
          );

          final prompt = getPrompt(currentModelIndex);
          final modelConfig = getModelConfig(currentModelIndex);
          
          // 调用大模型服务并等待完成
          final response = await llmService.callModel(
            modelConfig: modelConfig,
            prompt: prompt,
            systemPrompt: apiConfig.systemPrompts['default'],
          );
          
          if (_isCancelled) {
            break;
          }

          // 检查是否包含错误信息
          if (response.startsWith('错误:')) {
            throw Exception(response);
          }
          
          // 更新结果
          updateResult(currentModelIndex, response);
          
          // 保存到历史记录
          await ChatHistoryService.addMessage(
            taskName: taskRunId,
            loopCount: currentLoop,
            modelIndex: currentModelIndex,
            sendMessage: prompt,
            responseMessage: response,
          );

          // 每个模型完成后更新进度
          onProgress?.call(
            currentLoop, 
            currentModelIndex, 
            '模型 $currentModelIndex 完成 (循环 $currentLoop/$loopCount)'
          );
        }
      }
      
      _status = _isCancelled ? RunningStatus.idle : RunningStatus.completed;
      onComplete?.call(!_isCancelled, _isCancelled ? '用户取消了运行' : null);
      return !_isCancelled;
    } catch (e) {
      print('运行错误: $e');
      _status = RunningStatus.error;
      _lastError = e.toString();
      onComplete?.call(false, e.toString());
      return false;
    }
  }

  // 检查是否可以继续运行
  bool canProceed() {
    return _status != RunningStatus.running;
  }

  // 获取当前进度描述
  String getProgressDescription() {
    if (_status == RunningStatus.idle) return '准备就绪';
    if (_status == RunningStatus.completed) return '运行完成';
    if (_status == RunningStatus.error) return '发生错误: $_lastError';
    return '正在运行模型 $currentModelIndex (循环 $currentLoop/$loopCount)';
  }

  // 提取所有参数到映射表
  void _extractParams() {
    modelParams.clear();

    // 提取API配置参数
    for (int i = 0; i < 3; i++) {
      final modelConfig = apiConfig.models[i];
      final prefix = '模型${i + 1}';
      
      modelParams['${prefix}_api_key'] = modelConfig.apiKey;
      modelParams['${prefix}_base_url'] = modelConfig.baseUrl;
      modelParams['${prefix}_model'] = modelConfig.model;
      modelParams['${prefix}_temperature'] = modelConfig.temperature;
      modelParams['${prefix}_top_p'] = modelConfig.topP;
      modelParams['${prefix}_max_tokens'] = modelConfig.maxTokens;
      modelParams['${prefix}_presence_penalty'] = modelConfig.presencePenalty;
      modelParams['${prefix}_frequency_penalty'] = modelConfig.frequencyPenalty;
      modelParams['${prefix}_stream'] = modelConfig.stream.toString();
    }

    // 提取任务配置参数
    modelParams['任务名称'] = taskConfig.name;
    modelParams['任务描述'] = taskConfig.description;
    modelParams['总任务目的'] = taskConfig.taskPurpose ?? '';
    modelParams['语料'] = taskConfig.corpus ?? '';
    modelParams['模型1提示词'] = taskConfig.model1Prompt ?? '';
    modelParams['模型2提示词'] = taskConfig.model2Prompt ?? '';
    modelParams['模型3提示词'] = taskConfig.model3Prompt ?? '';
  }

  // 获取参数值
  String getParam(String key) {
    return modelParams[key] ?? '';
  }
  
  // 清空结果
  void clearResults() {
    model1Result = '';
    model2Result = '';
    model3Result = '';
    modelParams.clear();
  }
  
  // 更新模型结果
  void updateResult(int modelIndex, String result) {
    switch (modelIndex) {
      case 1:
        model1Result = result;
        break;
      case 2:
        model2Result = result;
        break;
      case 3:
        model3Result = result;
        break;
    }
  }
  
  // 获取模型结果
  String getResult(int modelIndex) {
    switch (modelIndex) {
      case 1:
        return model1Result;
      case 2:
        return model2Result;
      case 3:
        return model3Result;
      default:
        return '';
    }
  }
  
  // 获取当前配置的提示词
  String getPrompt(int modelIndex) {
    String prompt = switch (modelIndex) {
      1 => taskConfig.model1Prompt ?? '',
      2 => taskConfig.model2Prompt ?? '',
      3 => taskConfig.model3Prompt ?? '',
      _ => '',
    };
    
    return replaceVariables(prompt);
  }
  
  // 替换变量
  String replaceVariables(String text) {
    return text
      .replaceAll('{模型1结果}', model1Result)
      .replaceAll('{模型2结果}', model2Result)
      .replaceAll('{模型3结果}', model3Result)
      .replaceAll('{任务目的}', taskConfig.taskPurpose ?? '')
      .replaceAll('{语料}', taskConfig.corpus ?? '');
  }
  
  // 获取当前配置的API设置
  ModelConfig getModelConfig(int modelIndex) {
    if (modelIndex < 1 || modelIndex > 3) {
      throw ArgumentError('Invalid model index');
    }
    return apiConfig.models[modelIndex - 1];
  }

  // 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}${_pad(dateTime.month)}${_pad(dateTime.day)}_${_pad(dateTime.hour)}${_pad(dateTime.minute)}${_pad(dateTime.second)}';
  }

  // 补零
  String _pad(int number) {
    return number.toString().padLeft(2, '0');
  }

  Future<void> startLoop(String taskName) async {
    final timestamp = DateTime.now();
    final taskRunId = '${taskName}_${_formatDateTime(timestamp)}';
    
    // 获取任务配置
    final task = TaskService.getAllTasks().firstWhere(
      (t) => t.name == taskName,
      orElse: () => TaskConfig(
        name: taskName,
        description: '',
        taskPurpose: '',
        corpus: '',
        model1Prompt: '',
        model2Prompt: '',
        model3Prompt: '',
      ),
    );

    // 创建新的对话历史并存储任务信息
    await ChatHistoryService.createHistory(
      ChatHistory(
        taskName: taskRunId,
        messages: [],
        taskPurpose: task.taskPurpose,
        corpus: task.corpus,
        model1Prompt: task.model1Prompt,
        model2Prompt: task.model2Prompt,
      ),
    );

    // 继续原有的循环逻辑
    // ... existing code ...
  }
} 