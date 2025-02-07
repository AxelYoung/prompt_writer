import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import '../models/chat_history.dart';
import '../services/chat_history_service.dart';
import '../services/task_service.dart';
import '../models/task_config.dart';
import 'package:intl/intl.dart';
import 'package:window_manager/window_manager.dart';

class HistoryResultsPage extends StatefulWidget {
  const HistoryResultsPage({super.key});

  @override
  State<HistoryResultsPage> createState() => _HistoryResultsPageState();
}

class _HistoryResultsPageState extends State<HistoryResultsPage> {
  late List<ChatHistory> histories;
  bool isLoading = true;
  String selectedSection = 'general';
  String searchQuery = '';
  bool showPriorityOnly = false;
  String selectedTimeRange = '所有时间';
  bool enableNotifications = true;
  String bannerStyle = '默认';

  @override
  void initState() {
    super.initState();
    _loadHistories();
  }

  Future<void> _loadHistories() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      final taskNames = ChatHistoryService.getAllTaskNames();
      histories = taskNames.map((taskName) {
        final history = ChatHistoryService.getHistory(taskName);
        if (history != null) {
          return history;
        } else {
          return ChatHistory(
            taskName: taskName,
            messages: ChatHistoryService.getTaskMessages(taskName),
            taskPurpose: '',  // 提供默认空字符串
            corpus: '',       // 提供默认空字符串
            model1Prompt: '', // 提供默认空字符串
            model2Prompt: '', // 提供默认空字符串
          );
        }
      }).toList();
    } catch (e) {
      print('加载历史记录错误: $e');
      histories = [];
    }
    
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return NeumorphicTheme(
      themeMode: ThemeMode.light,
      theme: const NeumorphicThemeData(
        baseColor: Colors.white,
        lightSource: LightSource.topLeft,
        depth: 4,
        intensity: 0.9,
        shadowDarkColor: Color(0xFFADB5BD),
        shadowLightColor: Colors.white,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Row(
          children: [
            // 侧边栏
            Container(
              width: 280,
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 固定在顶部的标题
                  DragToMoveArea(
                    child: Neumorphic(
                      style: NeumorphicStyle(
                        depth: -3,
                        intensity: 0.8,
                        boxShape: NeumorphicBoxShape.roundRect(
                          const BorderRadius.vertical(bottom: Radius.circular(12)),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            NeumorphicIcon(
                              Icons.history,
                              size: 24,
                              style: const NeumorphicStyle(
                                depth: 2,
                                intensity: 0.8,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '历史记录',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // 搜索栏
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Neumorphic(
                      style: NeumorphicStyle(
                        depth: -3,
                        intensity: 0.8,
                        boxShape: NeumorphicBoxShape.roundRect(
                          BorderRadius.circular(12),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.search, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(
                                  hintText: "搜索历史记录...",
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    searchQuery = value;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 可滚动的历史记录列表
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : histories.isEmpty
                            ? Center(
                                child: Text(
                                  '暂无历史记录',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                itemCount: histories.length,
                                itemBuilder: (context, index) {
                                  final history = histories[index];
                                  final taskName = ChatHistoryService.getDisplayName(history.taskName);
                                  return _buildNavItem(
                                    icon: Icons.article_outlined,
                                    label: taskName,
                                    id: history.taskName,
                                    subtitle: '${history.messages.length} 条对话',
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
            
            // 分隔线
            Container(
              width: 1,
              color: const Color(0xFFE9ECEF),
            ),
            
            // 主内容区域
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : selectedSection.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              NeumorphicIcon(
                                Icons.article_outlined,
                                size: 64,
                                style: const NeumorphicStyle(
                                  depth: 2,
                                  intensity: 0.7,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '请选择一条历史记录',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        )
                      : _buildHistoryDetail(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required String id,
    String? subtitle,
  }) {
    final isSelected = selectedSection == id;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: NeumorphicButton(
        style: NeumorphicStyle(
          depth: isSelected ? -2 : 2,
          intensity: 0.8,
          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
        ),
        padding: const EdgeInsets.all(12),
        onPressed: () {
          setState(() {
            selectedSection = id;
          });
        },
        child: Row(
          children: [
            NeumorphicIcon(
              icon,
              size: 20,
              style: NeumorphicStyle(
                depth: isSelected ? 2 : 1,
                intensity: 0.7,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryDetail() {
    final history = histories.firstWhere(
      (h) => h.taskName == selectedSection,
      orElse: () => ChatHistory(taskName: '', messages: []),
    );

    if (history.messages.isEmpty) {
      return const Center(child: Text('未找到历史记录'));
    }

    // 按循环次数分组消息
    final messagesByLoop = <int, List<ChatMessage>>{};
    for (var message in history.messages) {
      if (!messagesByLoop.containsKey(message.loopCount)) {
        messagesByLoop[message.loopCount] = [];
      }
      messagesByLoop[message.loopCount]!.add(message);
    }

    // 获取最大循环次数
    final maxLoopCount = messagesByLoop.keys.reduce((a, b) => a > b ? a : b);
    
    // 获取最后一轮的模型1和模型2的输出
    final lastLoopMessages = messagesByLoop[maxLoopCount] ?? [];
    final model1Message = lastLoopMessages.firstWhere(
      (m) => m.modelIndex == 1,
      orElse: () => ChatMessage(
        loopCount: maxLoopCount,
        modelIndex: 1,
        sendMessage: '',
        responseMessage: '未找到模型1输出',
        timestamp: DateTime.now(),
      ),
    );
    final model2Message = lastLoopMessages.firstWhere(
      (m) => m.modelIndex == 2,
      orElse: () => ChatMessage(
        loopCount: maxLoopCount,
        modelIndex: 2,
        sendMessage: '',
        responseMessage: '未找到模型2输出',
        timestamp: DateTime.now(),
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Text(
            ChatHistoryService.getDisplayName(history.taskName),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // 任务设置信息
          _buildTaskInfo(history.taskName),
          const SizedBox(height: 32),
          
          // 内容区域
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Prompt 部分
                Expanded(
                  child: Neumorphic(
                    style: NeumorphicStyle(
                      depth: 3,
                      intensity: 0.8,
                      boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              NeumorphicIcon(
                                Icons.edit_note,
                                size: 28,
                                style: const NeumorphicStyle(
                                  depth: 2,
                                  intensity: 0.7,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Prompt',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '循环 $maxLoopCount',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Text(
                                model1Message.responseMessage,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 24),
                
                // 测试结果部分
                Expanded(
                  child: Neumorphic(
                    style: NeumorphicStyle(
                      depth: 3,
                      intensity: 0.8,
                      boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              NeumorphicIcon(
                                Icons.analytics,
                                size: 28,
                                style: const NeumorphicStyle(
                                  depth: 2,
                                  intensity: 0.7,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '测试结果',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '循环 $maxLoopCount',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Text(
                                model2Message.responseMessage,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 新增方法：构建任务信息展示
  Widget _buildTaskInfo(String taskName) {
    // 从 ChatHistoryService 获取历史记录
    final history = ChatHistoryService.getHistory(taskName);
    if (history == null) return const SizedBox.shrink();

    return Neumorphic(
      style: NeumorphicStyle(
        depth: 2,
        intensity: 0.8,
        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                NeumorphicIcon(
                  Icons.settings,
                  size: 20,
                  style: const NeumorphicStyle(
                    depth: 2,
                    intensity: 0.7,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '任务设置',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (history.taskPurpose != null || history.corpus != null || 
                history.model1Prompt != null || history.model2Prompt != null)
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (history.taskPurpose != null && history.taskPurpose!.isNotEmpty)
                    _buildInfoChip(
                      label: '任务目的',
                      value: history.taskPurpose!,
                      icon: Icons.flag,
                    ),
                  if (history.corpus != null && history.corpus!.isNotEmpty)
                    _buildInfoChip(
                      label: '语料',
                      value: history.corpus!,
                      icon: Icons.description,
                    ),
                  if (history.model1Prompt != null && history.model1Prompt!.isNotEmpty)
                    _buildInfoChip(
                      label: '模型1提示词',
                      value: history.model1Prompt!,
                      icon: Icons.psychology,
                    ),
                  if (history.model2Prompt != null && history.model2Prompt!.isNotEmpty)
                    _buildInfoChip(
                      label: '模型2提示词',
                      value: history.model2Prompt!,
                      icon: Icons.psychology_outlined,
                    ),
                ],
              )
            else
              Center(
                child: Text(
                  '暂无任务设置信息',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Neumorphic(
        style: NeumorphicStyle(
          depth: -2,
          intensity: 0.8,
          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
} 