import 'package:flutter/material.dart';
import '../models/prompt_config.dart';
import '../services/hive_service.dart';
import '../models/task_config.dart';
import '../services/task_service.dart';
import 'package:window_manager/window_manager.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late List<PromptConfig> configs;
  late PromptConfig selectedConfig;
  bool isLoading = true;
  final _nameController = TextEditingController();
  
  // 添加所有输入框的 controller
  final _apiKeyControllers = List.generate(3, (_) => TextEditingController());
  final _baseUrlControllers = List.generate(3, (_) => TextEditingController());
  final _modelControllers = List.generate(3, (_) => TextEditingController());
  final _temperatureControllers = List.generate(3, (_) => TextEditingController());
  final _topPControllers = List.generate(3, (_) => TextEditingController());
  final _maxTokensControllers = List.generate(3, (_) => TextEditingController());
  final _presencePenaltyControllers = List.generate(3, (_) => TextEditingController());
  final _frequencyPenaltyControllers = List.generate(3, (_) => TextEditingController());

  @override
  void initState() {
    super.initState();
    _loadConfigs();
  }

  // 更新所有输入框的值
  void _updateTextFields() {
    _nameController.text = selectedConfig.name;
    
    for (int i = 0; i < 3; i++) {
      final model = selectedConfig.models[i];
      _apiKeyControllers[i].text = model.apiKey;
      _baseUrlControllers[i].text = model.baseUrl;
      _modelControllers[i].text = model.model;
      _temperatureControllers[i].text = model.temperature;
      _topPControllers[i].text = model.topP;
      _maxTokensControllers[i].text = model.maxTokens;
      _presencePenaltyControllers[i].text = model.presencePenalty;
      _frequencyPenaltyControllers[i].text = model.frequencyPenalty;
    }
  }

  Future<void> _loadConfigs() async {
    configs = HiveService.getAllConfigs();
    if (configs.isEmpty) {
      await HiveService.createDefaultConfig('默认配置', '默认API配置');
      configs = HiveService.getAllConfigs();
    }
    selectedConfig = configs.first;
    _updateTextFields();
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _saveConfig() async {
    // 确保所有字段都有值
    selectedConfig.name = _nameController.text.trim();
    if (selectedConfig.name.isEmpty) {
      selectedConfig.name = '默认配置';
    }
    
    for (int i = 0; i < 3; i++) {
      final model = selectedConfig.models[i];
      model.apiKey = _apiKeyControllers[i].text.trim();
      model.baseUrl = _baseUrlControllers[i].text.trim();
      model.model = _modelControllers[i].text.trim();
      model.temperature = _temperatureControllers[i].text.trim();
      model.topP = _topPControllers[i].text.trim();
      model.maxTokens = _maxTokensControllers[i].text.trim();
      model.presencePenalty = _presencePenaltyControllers[i].text.trim();
      model.frequencyPenalty = _frequencyPenaltyControllers[i].text.trim();
      
      // 设置默认值
      if (model.baseUrl.isEmpty) model.baseUrl = 'https://api.openai.com';
      if (model.temperature.isEmpty) model.temperature = '0.7';
      if (model.topP.isEmpty) model.topP = '1';
      if (model.maxTokens.isEmpty) model.maxTokens = '2000';
      if (model.presencePenalty.isEmpty) model.presencePenalty = '0';
      if (model.frequencyPenalty.isEmpty) model.frequencyPenalty = '0';
    }

    final index = configs.indexOf(selectedConfig);
    await HiveService.updateConfig(index, selectedConfig);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('配置已保存')),
    );
  }

  Future<void> _createNewConfig() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _NewConfigDialog(),
    );
    
    if (result != null) {
      await HiveService.createDefaultConfig(result, '新建配置');
      await _loadConfigs();
    }
  }

  // 在配置切换时更新所有输入框的值
  void _onConfigChanged(PromptConfig? value) {
    if (value == null) {
      _createNewConfig();
    } else {
      setState(() {
        selectedConfig = value;
        _updateTextFields();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DragToMoveArea(
              child: Text(
                '设置',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // API 配置部分
            MouseRegion(
              cursor: SystemMouseCursors.basic,
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'API 设置',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          DropdownButton<PromptConfig>(
                            value: selectedConfig,
                            items: [
                              ...configs.map((config) => DropdownMenuItem<PromptConfig>(
                                    value: config,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(config.name),
                                        const SizedBox(width: 8),
                                        MouseRegion(
                                          cursor: SystemMouseCursors.click,
                                          child: GestureDetector(
                                            onTap: () async {
                                              if (configs.length <= 1) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('无法删除最后一个配置'),
                                                    backgroundColor: Colors.orange,
                                                  ),
                                                );
                                                return;
                                              }

                                              final result = await showDialog<bool>(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: const Text('确认删除'),
                                                  content: Text('确定要删除配置"${config.name}"吗？'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(context, false),
                                                      child: const Text('取消'),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () => Navigator.pop(context, true),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Colors.red,
                                                      ),
                                                      child: const Text('删除'),
                                                    ),
                                                  ],
                                                ),
                                              );

                                              if (result == true) {
                                                final index = configs.indexOf(config);
                                                if (config == selectedConfig) {
                                                  final newConfig = configs.firstWhere((c) => c != config);
                                                  setState(() {
                                                    selectedConfig = newConfig;
                                                    _updateTextFields();
                                                  });
                                                }
                                                await HiveService.deleteConfig(index);
                                                await _loadConfigs();
                                              }
                                            },
                                            child: const Icon(
                                              Icons.close,
                                              size: 18,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                              const DropdownMenuItem(
                                value: null,
                                child: Text('+ 新建配置'),
                              ),
                            ],
                            onChanged: _onConfigChanged,
                          ),
                          const SizedBox(width: 20),
                          FilledButton.icon(
                            onPressed: _saveConfig,
                            icon: const Icon(Icons.save),
                            label: const Text('保存'),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: TextField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: '配置名称',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  selectedConfig.name = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      // API 配置卡片
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _ModelConfigCard(
                                title: '模型1',
                                config: selectedConfig.models[0],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: _ModelConfigCard(
                                title: '模型2',
                                config: selectedConfig.models[1],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: _ModelConfigCard(
                                title: '模型3',
                                config: selectedConfig.models[2],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // 任务配置部分
            _TaskConfigSection(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // 释放所有 controller
    _nameController.dispose();
    for (var controller in [
      ..._apiKeyControllers,
      ..._baseUrlControllers,
      ..._modelControllers,
      ..._temperatureControllers,
      ..._topPControllers,
      ..._maxTokensControllers,
      ..._presencePenaltyControllers,
      ..._frequencyPenaltyControllers,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }
}

class _ModelConfigCard extends StatefulWidget {
  final String title;
  final ModelConfig config;

  const _ModelConfigCard({
    required this.title,
    required this.config,
  });

  @override
  State<_ModelConfigCard> createState() => _ModelConfigCardState();
}

class _ModelConfigCardState extends State<_ModelConfigCard> {
  bool showAdvanced = false;
  
  // 添加所有输入框的 controller
  final _apiKeyController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _modelController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _topPController = TextEditingController();
  final _maxTokensController = TextEditingController();
  final _presencePenaltyController = TextEditingController();
  final _frequencyPenaltyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _updateTextFields();
  }

  void _updateTextFields() {
    _apiKeyController.text = widget.config.apiKey;
    _baseUrlController.text = widget.config.baseUrl;
    _modelController.text = widget.config.model;
    _temperatureController.text = widget.config.temperature;
    _topPController.text = widget.config.topP;
    _maxTokensController.text = widget.config.maxTokens;
    _presencePenaltyController.text = widget.config.presencePenalty;
    _frequencyPenaltyController.text = widget.config.frequencyPenalty;
  }

  @override
  void didUpdateWidget(covariant _ModelConfigCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config != widget.config) {
      _updateTextFields();
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    _temperatureController.dispose();
    _topPController.dispose();
    _maxTokensController.dispose();
    _presencePenaltyController.dispose();
    _frequencyPenaltyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue[50],
      child: SizedBox(
        height: double.infinity,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Microsoft YaHei',
                  ),
                ),
                const SizedBox(height: 16),
                // 必要参数
                _buildTextField('API Key', _apiKeyController, (value) {
                  setState(() => widget.config.apiKey = value);
                }),
                const SizedBox(height: 8),
                _buildTextField('Base URL', _baseUrlController, (value) {
                  setState(() => widget.config.baseUrl = value);
                }),
                const SizedBox(height: 8),
                _buildTextField('Model', _modelController, (value) {
                  setState(() => widget.config.model = value);
                }),
                const SizedBox(height: 16),
                // 高级设置（折叠）
                Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                  ),
                  child: ExpansionTile(
                    title: const Text('高级设置', style: TextStyle(fontFamily: 'Microsoft YaHei')),
                    initiallyExpanded: showAdvanced,
                    onExpansionChanged: (value) {
                      setState(() => showAdvanced = value);
                    },
                    children: [
                      _buildSlider('Temperature', _temperatureController, (value) {
                        setState(() => widget.config.temperature = value);
                      }, 0, 2),
                      _buildSlider('Top P', _topPController, (value) {
                        setState(() => widget.config.topP = value);
                      }, 0, 1),
                      _buildNumberField('Max Tokens', _maxTokensController, (value) {
                        setState(() => widget.config.maxTokens = value);
                      }),
                      _buildSlider('Presence Penalty', _presencePenaltyController, (value) {
                        setState(() => widget.config.presencePenalty = value);
                      }, -2, 2),
                      _buildSlider('Frequency Penalty', _frequencyPenaltyController, (value) {
                        setState(() => widget.config.frequencyPenalty = value);
                      }, -2, 2),
                      SwitchListTile(
                        title: const Text('Stream', style: TextStyle(fontFamily: 'Microsoft YaHei')),
                        value: widget.config.stream,
                        onChanged: (value) {
                          setState(() => widget.config.stream = value);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, ValueChanged<String> onChanged) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        labelStyle: const TextStyle(fontFamily: 'Microsoft YaHei'),
      ),
      style: const TextStyle(fontFamily: 'Microsoft YaHei'),
      onChanged: onChanged,
    );
  }

  Widget _buildNumberField(String label, TextEditingController controller, ValueChanged<String> onChanged) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        labelStyle: const TextStyle(fontFamily: 'Microsoft YaHei'),
      ),
      style: const TextStyle(fontFamily: 'Microsoft YaHei'),
      keyboardType: TextInputType.number,
      onChanged: onChanged,
    );
  }

  Widget _buildSlider(String label, TextEditingController controller, ValueChanged<String> onChanged, double min, double max) {
    final doubleValue = double.tryParse(controller.text) ?? min;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ${doubleValue.toStringAsFixed(2)}',
          style: const TextStyle(fontFamily: 'Microsoft YaHei'),
        ),
        Slider(
          value: doubleValue.clamp(min, max),
          min: min,
          max: max,
          divisions: 100,
          label: doubleValue.toStringAsFixed(2),
          onChanged: (newValue) {
            controller.text = newValue.toString();
            onChanged(newValue.toString());
          },
        ),
      ],
    );
  }
}

class _NewConfigDialog extends StatefulWidget {
  @override
  State<_NewConfigDialog> createState() => _NewConfigDialogState();
}

class _NewConfigDialogState extends State<_NewConfigDialog> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新建配置', style: TextStyle(fontFamily: 'Microsoft YaHei')),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: '配置名称',
          border: OutlineInputBorder(),
          labelStyle: TextStyle(fontFamily: 'Microsoft YaHei'),
        ),
        style: const TextStyle(fontFamily: 'Microsoft YaHei'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消', style: TextStyle(fontFamily: 'Microsoft YaHei')),
        ),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              Navigator.pop(context, _controller.text);
            }
          },
          child: const Text('确定', style: TextStyle(fontFamily: 'Microsoft YaHei')),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _TaskConfigSection extends StatefulWidget {
  @override
  State<_TaskConfigSection> createState() => _TaskConfigSectionState();
}

class _TaskConfigSectionState extends State<_TaskConfigSection> {
  late List<TaskConfig> tasks;
  late TaskConfig selectedTask;
  bool isLoading = true;
  final _nameController = TextEditingController();
  
  // 添加任务相关的 controller
  final _taskPurposeController = TextEditingController();
  final _corpusController = TextEditingController();
  final _model1PromptController = TextEditingController();
  final _model2PromptController = TextEditingController();
  final _model3PromptController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  // 更新所有输入框的值
  void _updateTextFields() {
    _nameController.text = selectedTask.name;
    _taskPurposeController.text = selectedTask.taskPurpose ?? '';
    _corpusController.text = selectedTask.corpus ?? '';
    _model1PromptController.text = selectedTask.model1Prompt ?? '';
    _model2PromptController.text = selectedTask.model2Prompt ?? '';
    _model3PromptController.text = selectedTask.model3Prompt ?? '';
  }

  Future<void> _loadTasks() async {
    tasks = TaskService.getAllTasks();
    if (tasks.isEmpty) {
      await TaskService.createDefaultTask('默认任务', '默认任务配置');
      tasks = TaskService.getAllTasks();
    }
    selectedTask = tasks.first;
    _updateTextFields();
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _saveTask() async {
    final index = tasks.indexOf(selectedTask);
    await TaskService.updateTask(index, selectedTask);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('任务已保存')),
    );
  }

  Future<void> _createNewTask() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _NewTaskDialog(),
    );
    
    if (result != null) {
      await TaskService.createDefaultTask(result, '新建任务');
      await _loadTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '任务设置',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    DropdownButton<TaskConfig>(
                      value: selectedTask,
                      items: [
                        ...tasks.map((task) => DropdownMenuItem<TaskConfig>(
                              value: task,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(task.name),
                                  const SizedBox(width: 8),
                                  MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: () async {
                                        if (tasks.length <= 1) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('无法删除最后一个任务'),
                                              backgroundColor: Colors.orange,
                                            ),
                                          );
                                          return;
                                        }

                                        final result = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('确认删除'),
                                            content: Text('确定要删除任务"${task.name}"吗？'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context, false),
                                                child: const Text('取消'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(context, true),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                ),
                                                child: const Text('删除'),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (result == true) {
                                          final index = tasks.indexOf(task);
                                          if (task == selectedTask) {
                                            final newTask = tasks.firstWhere((t) => t != task);
                                            setState(() {
                                              selectedTask = newTask;
                                              _nameController.text = newTask.name;
                                            });
                                          }
                                          await TaskService.deleteTask(index);
                                          await _loadTasks();
                                        }
                                      },
                                      child: const Icon(
                                        Icons.close,
                                        size: 18,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                        const DropdownMenuItem(
                          value: null,
                          child: Text('+ 新建任务'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          _createNewTask();
                        } else {
                          setState(() {
                            selectedTask = value;
                            _nameController.text = value.name;
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 20),
                    FilledButton.icon(
                      onPressed: _saveTask,
                      icon: const Icon(Icons.save),
                      label: const Text('保存'),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: '任务名称',
                          border: OutlineInputBorder(),
                          labelStyle: TextStyle(fontFamily: 'Microsoft YaHei'),
                        ),
                        style: const TextStyle(fontFamily: 'Microsoft YaHei'),
                        onChanged: (value) {
                          setState(() {
                            selectedTask.name = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Card(
                          elevation: 0,
                          color: Colors.blue[50],
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '总任务目的',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Microsoft YaHei',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  maxLines: 5,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: '任务目的',
                                    labelStyle: TextStyle(fontFamily: 'Microsoft YaHei'),
                                  ),
                                  style: const TextStyle(fontFamily: 'Microsoft YaHei'),
                                  controller: _taskPurposeController,
                                  onChanged: (value) {
                                    setState(() {
                                      selectedTask.taskPurpose = value;
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  '任务语料',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Microsoft YaHei',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  maxLines: 5,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: '语料内容',
                                    labelStyle: TextStyle(fontFamily: 'Microsoft YaHei'),
                                  ),
                                  style: const TextStyle(fontFamily: 'Microsoft YaHei'),
                                  controller: _corpusController,
                                  onChanged: (value) {
                                    setState(() {
                                      selectedTask.corpus = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            _buildPromptCard('模型1提示词', selectedTask.model1Prompt ?? '', (value) {
                              setState(() => selectedTask.model1Prompt = value);
                            }),
                            const SizedBox(height: 16),
                            _buildPromptCard('模型2提示词', selectedTask.model2Prompt ?? '', (value) {
                              setState(() => selectedTask.model2Prompt = value);
                            }),
                            const SizedBox(height: 16),
                            _buildPromptCard('模型3提示词', selectedTask.model3Prompt ?? '', (value) {
                              setState(() => selectedTask.model3Prompt = value);
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPromptCard(String title, String value, ValueChanged<String> onChanged) {
    TextEditingController controller;
    switch (title) {
      case '模型1提示词':
        controller = _model1PromptController;
        break;
      case '模型2提示词':
        controller = _model2PromptController;
        break;
      case '模型3提示词':
        controller = _model3PromptController;
        break;
      default:
        throw ArgumentError('未知的提示词类型: $title');
    }

    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Microsoft YaHei',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelStyle: TextStyle(fontFamily: 'Microsoft YaHei'),
              ),
              style: const TextStyle(fontFamily: 'Microsoft YaHei'),
              controller: controller,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taskPurposeController.dispose();
    _corpusController.dispose();
    _model1PromptController.dispose();
    _model2PromptController.dispose();
    _model3PromptController.dispose();
    super.dispose();
  }
}

class _NewTaskDialog extends StatefulWidget {
  @override
  State<_NewTaskDialog> createState() => _NewTaskDialogState();
}

class _NewTaskDialogState extends State<_NewTaskDialog> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新建任务', style: TextStyle(fontFamily: 'Microsoft YaHei')),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: '任务名称',
          border: OutlineInputBorder(),
          labelStyle: TextStyle(fontFamily: 'Microsoft YaHei'),
        ),
        style: const TextStyle(fontFamily: 'Microsoft YaHei'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消', style: TextStyle(fontFamily: 'Microsoft YaHei')),
        ),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              Navigator.pop(context, _controller.text);
            }
          },
          child: const Text('确定', style: TextStyle(fontFamily: 'Microsoft YaHei')),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
} 