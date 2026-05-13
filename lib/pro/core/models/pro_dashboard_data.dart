class ProDashboardData {
  final String headline;
  final String? scopeNote;
  final List<ProDashboardMetric> stats;
  final List<ProDashboardModuleSummary> moduleSummaries;
  final ProDashboardHighlight? highlightedRequest;

  const ProDashboardData({
    required this.headline,
    this.scopeNote,
    this.stats = const [],
    this.moduleSummaries = const [],
    this.highlightedRequest,
  });

  factory ProDashboardData.fromJson(Map<String, dynamic> json) {
    return ProDashboardData(
      headline: json['headline']?.toString() ?? '',
      scopeNote: json['scopeNote']?.toString(),
      stats: (json['stats'] as List<dynamic>? ?? const [])
          .map((entry) => ProDashboardMetric.fromJson(Map<String, dynamic>.from(entry as Map)))
          .toList(),
      moduleSummaries: (json['moduleSummaries'] as List<dynamic>? ?? const [])
          .map((entry) => ProDashboardModuleSummary.fromJson(Map<String, dynamic>.from(entry as Map)))
          .toList(),
      highlightedRequest: json['highlightedRequest'] is Map
          ? ProDashboardHighlight.fromJson(
              Map<String, dynamic>.from(json['highlightedRequest'] as Map),
            )
          : null,
    );
  }
}

class ProDashboardMetric {
  final String key;
  final String title;
  final String value;
  final String? trend;
  final bool isUp;

  const ProDashboardMetric({
    required this.key,
    required this.title,
    required this.value,
    this.trend,
    this.isUp = true,
  });

  factory ProDashboardMetric.fromJson(Map<String, dynamic> json) {
    return ProDashboardMetric(
      key: json['key']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
      trend: json['trend']?.toString(),
      isUp: json['isUp'] as bool? ?? true,
    );
  }
}

class ProDashboardModuleSummary {
  final String module;
  final String title;
  final String subtitle;
  final List<String> metrics;
  final List<ProDashboardItem> recentItems;
  final String actionLabel;

  const ProDashboardModuleSummary({
    required this.module,
    required this.title,
    required this.subtitle,
    this.metrics = const [],
    this.recentItems = const [],
    required this.actionLabel,
  });

  factory ProDashboardModuleSummary.fromJson(Map<String, dynamic> json) {
    return ProDashboardModuleSummary(
      module: json['module']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      metrics: (json['metrics'] as List<dynamic>? ?? const [])
          .map((entry) => entry.toString())
          .toList(),
      recentItems: (json['recentItems'] as List<dynamic>? ?? const [])
          .map((entry) => ProDashboardItem.fromJson(Map<String, dynamic>.from(entry as Map)))
          .toList(),
      actionLabel: json['actionLabel']?.toString() ?? 'Open',
    );
  }
}

class ProDashboardItem {
  final String id;
  final String title;
  final String subtitle;
  final String status;
  final String? amount;
  final String? meta;

  const ProDashboardItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.status,
    this.amount,
    this.meta,
  });

  factory ProDashboardItem.fromJson(Map<String, dynamic> json) {
    return ProDashboardItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      amount: json['amount']?.toString(),
      meta: json['meta']?.toString(),
    );
  }
}

class ProDashboardHighlight {
  final String requestId;
  final String module;
  final String title;
  final String? amount;
  final List<String> lines;
  final String ctaLabel;

  const ProDashboardHighlight({
    required this.requestId,
    required this.module,
    required this.title,
    this.amount,
    this.lines = const [],
    required this.ctaLabel,
  });

  factory ProDashboardHighlight.fromJson(Map<String, dynamic> json) {
    return ProDashboardHighlight(
      requestId: json['requestId']?.toString() ?? '',
      module: json['module']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      amount: json['amount']?.toString(),
      lines: (json['lines'] as List<dynamic>? ?? const [])
          .map((entry) => entry.toString())
          .toList(),
      ctaLabel: json['ctaLabel']?.toString() ?? 'Open',
    );
  }
}
