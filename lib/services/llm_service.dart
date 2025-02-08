import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../models/prompt_config.dart';
import 'dart:typed_data';

class LLMService {
  static LLMService? _instance;
  
  // 添加超时时间配置
  static const Duration defaultTimeout = Duration(minutes: 5);
  
  // 私有构造函数
  LLMService._();
  
  // 单例模式
  static LLMService get instance {
    _instance ??= LLMService._();
    return _instance!;
  }

  // 处理响应编码
  String _decodeResponse(http.Response response) {
    // 获取响应头中的编码信息
    String? charset;
    String? contentType = response.headers['content-type'];
    if (contentType != null && contentType.contains('charset=')) {
      charset = contentType.split('charset=')[1].split(';')[0].trim();
    }

    // 如果没有指定编码，默认尝试 UTF-8
    if (charset == null || charset.toLowerCase() == 'utf-8') {
      try {
        return utf8.decode(response.bodyBytes);
      } catch (e) {
        print('UTF-8解码失败，尝试其他编码: $e');
      }
    }

    // 如果 UTF-8 解码失败，尝试其他编码
    try {
      // 尝试使用 Latin1 解码
      String decoded = latin1.decode(response.bodyBytes);
      // 如果解码后包含中文字符，说明可能需要二次转换
      if (decoded.contains(RegExp(r'[\u4e00-\u9fa5]'))) {
        return decoded;
      }
      // 尝试将 Latin1 转换为 UTF-8
      return utf8.decode(latin1.encode(decoded));
    } catch (e) {
      print('所有编码尝试都失败，返回原始响应: $e');
      return response.body;
    }
  }

  // 调用大模型API
  Future<String> callModel({
    required ModelConfig modelConfig,
    required String prompt,
    String? systemPrompt,
    Duration timeout = defaultTimeout,  // 添加超时参数
  }) async {
    try {
      // 检查必要参数
      if (modelConfig.apiKey.isEmpty) {
        throw Exception('API密钥不能为空');
      }
      if (modelConfig.baseUrl.isEmpty) {
        throw Exception('API地址不能为空');
      }
      if (modelConfig.model.isEmpty) {
        throw Exception('模型名称不能为空');
      }

      // 构建完整的API URL
      final baseUrl = modelConfig.baseUrl.trim();
      final apiUrl = baseUrl.endsWith('/')
          ? '${baseUrl}v1/chat/completions'
          : '${baseUrl}/v1/chat/completions';

      // 构建请求头
      final headers = {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json; charset=utf-8',
        'Accept-Charset': 'utf-8',
        'Authorization': 'Bearer ${modelConfig.apiKey}',
        ...modelConfig.headers,
      };

      // 构建消息数组
      final messages = [
        if (systemPrompt != null)
          {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': prompt}
      ];

      // 构建请求体
      final body = jsonEncode({
        'model': modelConfig.model,
        'messages': messages,
        'temperature': modelConfig.temperatureValue,
        'top_p': modelConfig.topPValue,
        'max_tokens': modelConfig.maxTokensValue,
        'n': modelConfig.nValue,
        'presence_penalty': modelConfig.presencePenaltyValue,
        'frequency_penalty': modelConfig.frequencyPenaltyValue,
        'stream': modelConfig.stream,
      });

      print('发送请求到: $apiUrl');
      print('请求参数: $body');
      print('超时时间设置: ${timeout.inSeconds}秒');

      // 发送请求
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: body,
      ).timeout(
        timeout,
        onTimeout: () {
          throw TimeoutException('API请求超时（${timeout.inSeconds}秒）');
        },
      );

      print('响应状态码: ${response.statusCode}');
      print('响应头: ${response.headers}');

      // 使用新的解码方法处理响应
      final decodedBody = _decodeResponse(response);
      print('解码后的响应内容: $decodedBody');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(decodedBody);
        
        // 检查响应格式
        if (jsonResponse['choices'] == null || 
            jsonResponse['choices'].isEmpty ||
            jsonResponse['choices'][0]['message'] == null) {
          throw FormatException('API响应格式错误: $jsonResponse');
        }
        
        final content = jsonResponse['choices'][0]['message']['content'] as String;
        return content;
      } else {
        // 解析错误响应
        String errorMessage;
        try {
          final errorJson = jsonDecode(decodedBody);
          errorMessage = errorJson['error']?['message'] ?? '未知错误';
        } catch (e) {
          errorMessage = decodedBody;
        }
        
        throw Exception('API调用失败 (${response.statusCode}): $errorMessage');
      }
    } on TimeoutException catch (e) {
      print('API调用超时: $e');
      return '错误: API调用超时（${timeout.inSeconds}秒），请检查网络连接或重试';
    } on FormatException catch (e) {
      print('响应格式错误: $e');
      return '错误: API响应格式错误，请联系管理员';
    } catch (e) {
      print('API调用错误: $e');
      return '错误: ${e.toString()}';
    }
  }
} 