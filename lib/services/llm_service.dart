import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../models/prompt_config.dart';

class LLMService {
  static LLMService? _instance;
  
  // 私有构造函数
  LLMService._();
  
  // 单例模式
  static LLMService get instance {
    _instance ??= LLMService._();
    return _instance!;
  }

  // 调用大模型API
  Future<String> callModel({
    required ModelConfig modelConfig,
    required String prompt,
    String? systemPrompt,
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
        'Content-Type': 'application/json',
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

      // 发送请求
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: body,
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw TimeoutException('API请求超时');
        },
      );

      print('响应状态码: ${response.statusCode}');
      print('响应内容: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        // 检查响应格式
        if (jsonResponse['choices'] == null || 
            jsonResponse['choices'].isEmpty ||
            jsonResponse['choices'][0]['message'] == null) {
          throw FormatException('API响应格式错误: $jsonResponse');
        }
        
        return jsonResponse['choices'][0]['message']['content'] as String;
      } else {
        // 解析错误响应
        String errorMessage;
        try {
          final errorJson = jsonDecode(response.body);
          errorMessage = errorJson['error']?['message'] ?? '未知错误';
        } catch (e) {
          errorMessage = response.body;
        }
        
        throw Exception('API调用失败 (${response.statusCode}): $errorMessage');
      }
    } on TimeoutException catch (e) {
      print('API调用超时: $e');
      return '错误: API调用超时，请检查网络连接或重试';
    } on FormatException catch (e) {
      print('响应格式错误: $e');
      return '错误: API响应格式错误，请联系管理员';
    } catch (e) {
      print('API调用错误: $e');
      return '错误: ${e.toString()}';
    }
  }
} 