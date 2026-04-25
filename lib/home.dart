import 'package:flutter/material.dart';

class RootHomePage extends StatelessWidget {
  const RootHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "NekoSU",
          style: TextStyle(fontWeight: FontWeight.normal, fontSize: 24.0),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        children: [
          const SizedBox(height: 8),
          // 1. 核心状态卡片
          _buildStatusCard(context),
          const SizedBox(height: 24),

          // 2. 功能网格标题
          Text("核心功能", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),

          // 3. 功能网格
          GridView.count(
            shrinkWrap: true, // 嵌套在 ListView 中必须设置
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1, // 调整卡片长宽比
            children: [
              _buildFeatureItem(
                context,
                Icons.security,
                "超级用户",
                "管理 Root 权限",
                Colors.blue,
              ),
              _buildFeatureItem(
                context,
                Icons.extension,
                "模块管理",
                "安装与管理插件",
                Colors.orange,
              ),
              _buildFeatureItem(
                context,
                Icons.history,
                "授权记录",
                "查看最近活动",
                Colors.green,
              ),
              _buildFeatureItem(
                context,
                Icons.verified_user_outlined,
                "环境检查",
                "检测 Root 隐藏状态",
                Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              "NKSU 已激活",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "内核版本: 5.15.xx-gki | v1.0.2 (2024)",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 功能项构建
  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
