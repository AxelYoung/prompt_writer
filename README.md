# Prompt Writer 数据存储设计文档

## Hive 数据结构概览

项目使用 Hive 作为本地数据存储解决方案，主要包含三个核心数据模型：

1. `PromptConfig`（API 配置）
2. `TaskConfig`（任务配置）
3. `ChatHistory`（对话历史）

### 类型注册表

```dart
// Hive 类型 ID 分配
@HiveType(typeId: 0) class PromptConfig
@HiveType(typeId: 1) class ModelConfig
@HiveType(typeId: 2) class TaskConfig
@HiveType(typeId: 3) class ChatHistory
@HiveType(typeId: 4) class ChatMessage
```

## 详细数据模型

### 1. API 配置 (PromptConfig)

```dart
@HiveType(typeId: 0)
class PromptConfig {
  @HiveField(0) String name;            // 配置名称
  @HiveField(1) String description;     // 配置描述
  @HiveField(2) List<ModelConfig> models; // 模型配置列表
  @HiveField(3) Map<String, String> systemPrompts; // 系统提示词
}

@HiveType(typeId: 1)
class ModelConfig {
  @HiveField(0) String model;           // 模型名称
  @HiveField(1) String apiKey;          // API密钥
  @HiveField(2) String baseUrl;         // 基础URL
  @HiveField(3) String temperature;     // 温度
  @HiveField(4) String topP;           // 核采样
  @HiveField(5) String maxTokens;      // 最大令牌数
  @HiveField(6) String n;              // 生成数量
  @HiveField(7) String presencePenalty; // 存在惩罚
  @HiveField(8) String frequencyPenalty;// 频率惩罚
  @HiveField(9) Map<String, String> headers; // 自定义请求头
  @HiveField(10) bool stream;          // 是否使用流式响应
}
```

### 2. 任务配置 (TaskConfig)

```dart
@HiveType(typeId: 2)
class TaskConfig {
  @HiveField(0) String name;           // 任务名称
  @HiveField(1) String description;    // 任务描述
  @HiveField(2) String taskPurpose;    // 总任务目的
  @HiveField(3) String model1Prompt;   // 模型1的prompt
  @HiveField(4) String model2Prompt;   // 模型2的prompt
  @HiveField(5) String model3Prompt;   // 模型3的prompt
}
```

### 3. 对话历史 (ChatHistory)

```dart
@HiveType(typeId: 3)
class ChatHistory {
  @HiveField(0) String taskName;       // 任务名称
  @HiveField(1) List<ChatMessage> messages; // 对话内容列表
}

@HiveType(typeId: 4)
class ChatMessage {
  @HiveField(0) int loopCount;         // 循环次数
  @HiveField(1) int modelIndex;        // 模型序号（1-3）
  @HiveField(2) String sendMessage;    // 发送的消息
  @HiveField(3) String responseMessage;// 返回的消息
  @HiveField(4) DateTime timestamp;    // 时间戳
}
```

## 服务层实现

### 1. HiveService（API 配置服务）

主要功能：
- 初始化 Hive
- 管理 API 配置的 CRUD 操作
- 提供默认配置创建

关键方法：
```dart
static Future<void> init()              // 初始化服务
static List<PromptConfig> getAllConfigs() // 获取所有配置
static Future<void> addConfig()         // 添加配置
static Future<void> updateConfig()      // 更新配置
static Future<void> deleteConfig()      // 删除配置
static Future<void> createDefaultConfig() // 创建默认配置
```

### 2. TaskService（任务配置服务）

主要功能：
- 管理任务配置的 CRUD 操作
- 提供默认任务创建

关键方法：
```dart
static Future<void> init()              // 初始化服务
static List<TaskConfig> getAllTasks()   // 获取所有任务
static Future<void> addTask()          // 添加任务
static Future<void> updateTask()       // 更新任务
static Future<void> deleteTask()       // 删除任务
static Future<void> createDefaultTask() // 创建默认任务
```

### 3. ChatHistoryService（对话历史服务）

主要功能：
- 管理对话历史的存储和检索
- 提供按任务分组的消息查询
- 支持测试数据生成

关键方法：
```dart
static Future<void> init()              // 初始化服务
static List<String> getAllTaskNames()   // 获取所有任务名称
static List<ChatMessage> getTaskMessages() // 获取指定任务的消息
static Future<void> addMessage()       // 添加新消息
static Future<void> addTestData()      // 添加测试数据
```

## 数据初始化流程

1. 应用启动时，按以下顺序初始化服务：
   ```dart
   await Hive.initFlutter();
   await HiveService.init();
   await TaskService.init();
   await ChatHistoryService.init();
   ```

2. 每个服务初始化时：
   - 注册相应的 Hive 适配器
   - 打开对应的 Hive 盒子
   - 检查并创建默认数据（如果需要）

3. 数据迁移和更新：
   - 目前使用版本为初始版本
   - 后续版本更新时需要添加数据迁移逻辑

## 使用示例

1. 创建新的 API 配置：
```dart
final config = PromptConfig.createDefault('新配置', '描述');
await HiveService.addConfig(config);
```

2. 添加新的对话记录：
```dart
await ChatHistoryService.addMessage(
  taskName: '任务名称',
  loopCount: 1,
  modelIndex: 1,
  sendMessage: '发送的消息',
  responseMessage: '返回的消息',
);
```

3. 查询特定任务的对话记录：
```dart
final messages = ChatHistoryService.getTaskMessages('任务名称');
```

## 注意事项

1. 类型注册：
   - 确保所有 Hive 对象都已正确注册适配器
   - 避免重复的 typeId

2. 数据一致性：
   - 删除配置前检查依赖关系
   - 保持任务名称的唯一性

3. 性能优化：
   - 避免频繁的写入操作
   - 合理使用批量操作

4. 错误处理：
   - 所有服务方法都包含适当的错误处理
   - 提供清晰的错误信息
