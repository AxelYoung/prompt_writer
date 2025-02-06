import 'package:flutter/material.dart';
import '../services/hive_service.dart';
import '../services/task_service.dart';
import '../services/model_service.dart';
import '../models/prompt_config.dart';
import '../models/task_config.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<PromptConfig> apiConfigs;
  late List<TaskConfig> taskConfigs;
  late PromptConfig selectedApiConfig;
  late TaskConfig selectedTaskConfig;
  final _loopCountController = TextEditingController(text: '1');
  bool isLoading = true;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    _loadConfigs();
  }

  Future<void> _loadConfigs() async {
    apiConfigs = HiveService.getAllConfigs();
    taskConfigs = TaskService.getAllTasks();
    
    // 确保 API 配置存在
    if (apiConfigs.isEmpty) {
      await HiveService.createDefaultConfig('默认配置', '默认API配置');
      apiConfigs = HiveService.getAllConfigs();
    }
    selectedApiConfig = apiConfigs.first;
    
    // 确保任务配置存在
    if (taskConfigs.isEmpty) {
      await TaskService.createDefaultTask('默认任务', '默认任务配置');
      taskConfigs = TaskService.getAllTasks();
    }
    selectedTaskConfig = taskConfigs.first;
    
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题部分
            Text(
              'Prompt Writer',
              style: textTheme.displaySmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            
            // 配置选择部分
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '配置选择',
                      style: textTheme.titleLarge,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _buildConfigDropdown(
                            label: 'API 配置',
                            value: selectedApiConfig,
                            items: apiConfigs.map((config) {
                              return DropdownMenuItem(
                                value: config,
                                child: Text(config.name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => selectedApiConfig = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildConfigDropdown(
                            label: '任务配置',
                            value: selectedTaskConfig,
                            items: taskConfigs.map((config) {
                              return DropdownMenuItem(
                                value: config,
                                child: Text(config.name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => selectedTaskConfig = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            label: '循环次数',
                            controller: _loopCountController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // 结果显示部分
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '运行结果',
                      style: textTheme.titleLarge,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _buildResultCard(
                            context,
                            title: '模型 1',
                            content: ModelService.instance.model1Result,
                            isActive: ModelService.instance.status == RunningStatus.running && 
                                    ModelService.instance.currentModelIndex == 1,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildResultCard(
                            context,
                            title: '模型 2',
                            content: ModelService.instance.model2Result,
                            isActive: ModelService.instance.status == RunningStatus.running && 
                                    ModelService.instance.currentModelIndex == 2,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildResultCard(
                            context,
                            title: '模型 3',
                            content: ModelService.instance.model3Result,
                            isActive: ModelService.instance.status == RunningStatus.running && 
                                    ModelService.instance.currentModelIndex == 3,
                          ),
                        ),
                      ],
                    ),
                    if (ModelService.instance.status == RunningStatus.running)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          ModelService.instance.getProgressDescription(),
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // 开始按钮
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: ModelService.instance.canProceed() ? () async {
                      // 初始化模型服务
                      final loopCount = int.tryParse(_loopCountController.text) ?? 1;
                      final service = ModelService.instance;
                      service.init(
                        selectedApiConfig: selectedApiConfig,
                        selectedTaskConfig: selectedTaskConfig,
                        selectedLoopCount: loopCount,
                      );
                      
                      // 运行模型
                      await service.run(
                        onProgress: (loop, modelIndex, status) {
                          if (_mounted && mounted) {
                            setState(() {
                              // 状态更新会触发UI重建
                            });
                          }
                        },
                        onComplete: (success, error) {
                          if (!_mounted || !mounted) return;
                          
                          if (!success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('运行出错: $error'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                          setState(() {
                            // 完成后更新UI
                          });
                        },
                      );
                    } : null,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    icon: ModelService.instance.status == RunningStatus.running
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.play_arrow),
                    label: Text(
                      ModelService.instance.status == RunningStatus.running
                          ? '运行中...'
                          : '开始运行'
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (ModelService.instance.status == RunningStatus.running)
                    OutlinedButton.icon(
                      onPressed: () {
                        ModelService.instance.cancel();
                        setState(() {});
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      icon: const Icon(Icons.stop),
                      label: const Text('取消'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildResultCard(
    BuildContext context, {
    required String title,
    required String content,
    bool isActive = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: isActive ? 4 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive 
              ? colorScheme.primary 
              : colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isActive 
                  ? colorScheme.primaryContainer
                  : colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive 
                        ? Colors.green 
                        : Colors.grey.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              content,
              style: textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mounted = false;
    _loopCountController.dispose();
    super.dispose();
  }
}
