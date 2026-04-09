import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../core/models/pro_dashboard_data.dart';
import '../../../core/models/pro_profile.dart';
import '../../../core/router/pro_route_paths.dart';
import '../../../core/utils/pro_module_helper.dart';
import '../../../core/widgets/pro_stat_card.dart';

class ProInsightsScreen extends StatefulWidget {
  const ProInsightsScreen({super.key, required this.profile});

  final ProProfile profile;

  @override
  State<ProInsightsScreen> createState() => _ProInsightsScreenState();
}

class _ProInsightsScreenState extends State<ProInsightsScreen> {
  late Future<ProDashboardData> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboard();
  }

  @override
  void didUpdateWidget(covariant ProInsightsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.userId != widget.profile.userId) {
      _dashboardFuture = _loadDashboard();
    }
  }

  Future<ProDashboardData> _loadDashboard() async {
    final response = Map<String, dynamic>.from(
      await ApiClient.get('/pro/${widget.profile.userId}/dashboard') as Map,
    );
    return ProDashboardData.fromJson(response);
  }

  Future<void> _refresh() async {
    final future = _loadDashboard();
    setState(() => _dashboardFuture = future);
    await future;
  }

  Future<void> _openPrimaryQueue() {
    switch (widget.profile.type) {
      case ProProfileType.shop:
        return context.push(ProRoutePaths.shopQueue);
      case ProProfileType.provider:
        return context.push(ProRoutePaths.providerQueue);
      case ProProfileType.doctor:
        return context.push(ProRoutePaths.doctorAppointments);
      case ProProfileType.delivery:
        return context.push(ProRoutePaths.deliveryQueue);
      case ProProfileType.rider:
        return context.push(ProRoutePaths.riderQueue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileColor = ProModuleHelper.getProfileColor(widget.profile.type);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Insights'),
        backgroundColor: profileColor,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<ProDashboardData>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snapshot.error.toString().replaceFirst('Exception: ', ''),
                ),
              ),
            );
          }

          final data = snapshot.data!;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  data.headline.isNotEmpty
                      ? data.headline
                      : 'Live module insights',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (data.scopeNote?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text(
                    data.scopeNote!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.grey,
                      height: 1.45,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                if (data.stats.isNotEmpty)
                  for (var index = 0; index < data.stats.length; index += 2)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _MetricCard(metric: data.stats[index]),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: data.stats.length > index + 1
                                ? _MetricCard(metric: data.stats[index + 1])
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                if (data.highlightedRequest != null) ...[
                  const SizedBox(height: 8),
                  _HighlightedRequestCard(
                    highlight: data.highlightedRequest!,
                    color: profileColor,
                    onOpen: _openPrimaryQueue,
                  ),
                ],
                if (data.moduleSummaries.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Recent Module Activity',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...data.moduleSummaries.map(
                    (summary) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _InsightSummaryCard(summary: summary),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final ProDashboardMetric metric;

  @override
  Widget build(BuildContext context) {
    return ProStatCard(
      title: metric.title,
      value: metric.value,
      icon: Icons.pie_chart_outline,
      color: AppColors.primary,
      trend: metric.trend,
      isUp: metric.isUp,
    );
  }
}

class _HighlightedRequestCard extends StatelessWidget {
  const _HighlightedRequestCard({
    required this.highlight,
    required this.color,
    required this.onOpen,
  });

  final ProDashboardHighlight highlight;
  final Color color;
  final Future<void> Function() onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Highlighted Request',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            highlight.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (highlight.amount?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              highlight.amount!,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          if (highlight.lines.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...highlight.lines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  line,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.86),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: onOpen,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: color,
            ),
            child: Text(highlight.ctaLabel),
          ),
        ],
      ),
    );
  }
}

class _InsightSummaryCard extends StatelessWidget {
  const _InsightSummaryCard({required this.summary});

  final ProDashboardModuleSummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              summary.title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              summary.subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.grey),
            ),
            if (summary.metrics.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: summary.metrics
                    .map(
                      (metric) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(metric),
                      ),
                    )
                    .toList(),
              ),
            ],
            if (summary.recentItems.isNotEmpty) ...[
              const SizedBox(height: 14),
              ...summary.recentItems
                  .take(3)
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.subtitle,
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  [
                                    item.status,
                                    if ((item.amount ?? '').isNotEmpty)
                                      item.amount!,
                                    if ((item.meta ?? '').isNotEmpty)
                                      item.meta!,
                                  ].join(' • '),
                                  style: const TextStyle(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w600,
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
          ],
        ),
      ),
    );
  }
}
