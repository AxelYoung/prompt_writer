import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DragToMoveArea(
              child: Row(
                children: [
                  Icon(
                    Icons.info,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '关于',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // 项目介绍
            _buildSection(
              context,
              title: '项目介绍',
              icon: Icons.description,
              child: Text(
                '本项目是一个基于多模型协同的提示词优化工具。通过让多个大语言模型互相交互，'
                '类似于 GAN (生成对抗网络) 的方式，不断优化和改进提示词的质量。'
                '每个模型都可以对其他模型生成的结果进行评估和改进，从而达到更好的效果。',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 24),

            // 技术栈
            _buildSection(
              context,
              title: '技术栈',
              icon: Icons.code,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildChip(context, 'Flutter', Icons.flutter_dash),
                  _buildChip(context, 'Material Design 3', Icons.style),
                  _buildChip(context, 'Hive 数据库', Icons.storage),
                  _buildChip(context, 'OpenAI API', Icons.api),
                  _buildChip(context, 'Claude API', Icons.psychology),
                  _buildChip(context, 'Window Manager', Icons.window),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 开源协议
            _buildSection(
              context,
              title: '开源协议',
              icon: Icons.gavel,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '本项目使用 MIT 许可证开源。以下是主要使用的开源项目：',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildLinkItem(
                    context,
                    title: 'Flutter',
                    description: '谷歌的开源 UI 框架',
                    url: 'https://flutter.dev',
                  ),
                  _buildLinkItem(
                    context,
                    title: 'Hive',
                    description: '轻量级键值数据库',
                    url: 'https://docs.hivedb.dev',
                  ),
                  _buildLinkItem(
                    context,
                    title: 'window_manager',
                    description: 'Flutter 桌面窗口管理',
                    url: 'https://pub.dev/packages/window_manager',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 版本信息
            _buildSection(
              context,
              title: '版本信息',
              icon: Icons.info_outline,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '版本: 1.0.0',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '构建日期: 2025.02',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label, IconData icon) {
    return Chip(
      avatar: Icon(
        icon,
        size: 18,
        color: Theme.of(context).colorScheme.onSecondaryContainer,
      ),
      label: Text(label),
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      labelStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSecondaryContainer,
      ),
    );
  }

  Widget _buildLinkItem(
    BuildContext context, {
    required String title,
    required String description,
    required String url,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => launchUrl(Uri.parse(url)),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Icon(
                Icons.link,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 