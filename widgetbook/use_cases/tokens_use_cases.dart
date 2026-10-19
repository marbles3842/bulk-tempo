// ignore_for_file: depend_on_referenced_packages

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

import 'package:bulk_tempo/core/design_system.dart';

/// Calculation of WCAG relative luminance and contrast ratio.
double _calculateContrastRatio(Color foreground, Color background) {
  final l1 = foreground.computeLuminance();
  final l2 = background.computeLuminance();
  final lighter = l1 > l2 ? l1 : l2;
  final darker = l1 > l2 ? l2 : l1;
  return (lighter + 0.05) / (darker + 0.05);
}

String _hexString(Color color) {
  final a = (color.a * 255).round().toRadixString(16).padLeft(2, '0');
  final r = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
  final g = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
  final b = (color.b * 255).round().toRadixString(16).padLeft(2, '0');
  return '#${r.toUpperCase()}${g.toUpperCase()}${b.toUpperCase()}${a != 'ff' ? ' (${a.toUpperCase()})' : ''}';
}

/// Category containing all design token use cases.
final tokensCategory = WidgetbookCategory(
  name: 'Design Tokens',
  children: [
    WidgetbookComponent(
      name: 'Colors',
      useCases: [
        WidgetbookUseCase(
          name: 'Color Scheme & Semantic Swatches',
          builder: (context) {
            final theme = Theme.of(context);
            final scheme = theme.colorScheme;
            final semanticColors = AppSemanticColors.of(context);

            final colorPairs =
                <({String name, Color bg, Color fg, String role})>[
                  (
                    name: 'Primary',
                    bg: scheme.primary,
                    fg: scheme.onPrimary,
                    role: 'Brand actions and primary buttons',
                  ),
                  (
                    name: 'Primary Container',
                    bg: scheme.primaryContainer,
                    fg: scheme.onPrimaryContainer,
                    role: 'Highlighted containers',
                  ),
                  (
                    name: 'Secondary',
                    bg: scheme.secondary,
                    fg: scheme.onSecondary,
                    role: 'Secondary UI elements',
                  ),
                  (
                    name: 'Secondary Container',
                    bg: scheme.secondaryContainer,
                    fg: scheme.onSecondaryContainer,
                    role: 'Tonal buttons and target fill',
                  ),
                  (
                    name: 'Tertiary',
                    bg: scheme.tertiary,
                    fg: scheme.onTertiary,
                    role: 'Workout series and accent metrics',
                  ),
                  (
                    name: 'Surface',
                    bg: scheme.surface,
                    fg: scheme.onSurface,
                    role: 'Base canvas and app background',
                  ),
                  (
                    name: 'Surface Container Low',
                    bg: scheme.surfaceContainerLow,
                    fg: scheme.onSurface,
                    role: 'Grouped card surfaces',
                  ),
                  (
                    name: 'Surface Container High',
                    bg: scheme.surfaceContainerHigh,
                    fg: scheme.onSurface,
                    role: 'Dialog and sheet surfaces',
                  ),
                  (
                    name: 'Error',
                    bg: scheme.error,
                    fg: scheme.onError,
                    role: 'Destructive actions and validation errors',
                  ),
                  (
                    name: 'Error Container',
                    bg: scheme.errorContainer,
                    fg: scheme.onErrorContainer,
                    role: 'Inline error banners',
                  ),
                  (
                    name: 'Success Container',
                    bg: semanticColors.successContainer,
                    fg: semanticColors.onSuccessContainer,
                    role: 'Positive trends and completed targets',
                  ),
                  (
                    name: 'Warning Container',
                    bg: semanticColors.warningContainer,
                    fg: semanticColors.onWarningContainer,
                    role: 'Stale caches and boundary warnings',
                  ),
                  (
                    name: 'Info Container',
                    bg: semanticColors.infoContainer,
                    fg: semanticColors.onInfoContainer,
                    role: 'System notifications and informational hints',
                  ),
                  (
                    name: 'Achievement Gold',
                    bg: semanticColors.achievementContainer,
                    fg: semanticColors.onAchievementContainer,
                    role: 'Personal records and trophy flags',
                  ),
                ];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Color Scheme & Semantic Contrast Ratios',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  Text(
                    'All foreground/container pairs are verified against WCAG AA (>= 4.5:1) standards for body text and accessible contrast.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 600;
                      return Wrap(
                        spacing: AppSpacing.space3,
                        runSpacing: AppSpacing.space3,
                        children: [
                          for (final pair in colorPairs)
                            SizedBox(
                              width: isWide
                                  ? (constraints.maxWidth - AppSpacing.space3) /
                                        2
                                  : double.infinity,
                              child: _ColorSwatchCard(
                                name: pair.name,
                                background: pair.bg,
                                foreground: pair.fg,
                                role: pair.role,
                                border: pair.name.contains('Achievement')
                                    ? semanticColors.achievementBorder
                                    : null,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Typography',
      useCases: [
        WidgetbookUseCase(
          name: 'Typography Roles & Tabular Figures',
          builder: (context) {
            final theme = Theme.of(context);
            final textTheme = theme.textTheme;

            final roles =
                <({String role, String spec, TextStyle? style, String sample})>[
                  (
                    role: 'Page Title',
                    spec: 'headlineSmall • 24sp • w600',
                    style: textTheme.headlineSmall,
                    sample: 'Weekly Body Weight & Dashboard',
                  ),
                  (
                    role: 'Section Title',
                    spec: 'titleMedium • 16sp • w600',
                    style: textTheme.titleMedium,
                    sample: 'Recent Logged Measurements',
                  ),
                  (
                    role: 'Metric (Tabular Figures)',
                    spec:
                        'headlineMedium • 28sp • w700 • fontFeatures: [tabularFigures()]',
                    style: textTheme.headlineMedium,
                    sample: '82.45 kg  (+0.35 kg/wk)',
                  ),
                  (
                    role: 'Body Text',
                    spec: 'bodyLarge • 16sp • w400',
                    style: textTheme.bodyLarge,
                    sample:
                        'Consistent weigh-ins under identical morning conditions yield accurate rolling averages.',
                  ),
                  (
                    role: 'Supporting Text',
                    spec: 'bodyMedium • 14sp • onSurfaceVariant',
                    style: textTheme.bodyMedium,
                    sample:
                        'Cached measurement data from offline local storage.',
                  ),
                  (
                    role: 'Compact Label',
                    spec: 'labelSmall • 11sp • w600',
                    style: textTheme.labelSmall,
                    sample: 'NEW RECORD • 12 WEEKS LOGGED',
                  ),
                ];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Typography Roles', style: textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.space2),
                  Text(
                    'Semantic type roles scaled via Material 3 textTheme with monospaced tabular figures for metric alignments.',
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  for (final item in roles) ...[
                    AppCard(
                      variant: AppCardVariant.grouped,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                item.role,
                                style: textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(item.spec, style: textTheme.bodySmall),
                            ],
                          ),
                          const Divider(),
                          Text(item.sample, style: item.style),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space3),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Spacing & Shape',
      useCases: [
        WidgetbookUseCase(
          name: 'Visual Scale & Touch Targets',
          builder: (context) {
            final theme = Theme.of(context);
            final scheme = theme.colorScheme;

            final spacingScale = <({String name, double value, String usage})>[
              (name: 'space0', value: AppSpacing.space0, usage: 'Zero inset'),
              (
                name: 'space1',
                value: AppSpacing.space1,
                usage: 'Micro spacing, badge padding',
              ),
              (
                name: 'space2',
                value: AppSpacing.space2,
                usage: 'Inline gap between related icons/labels',
              ),
              (
                name: 'space3',
                value: AppSpacing.space3,
                usage: 'Related content gap, input vertical padding',
              ),
              (
                name: 'space4',
                value: AppSpacing.space4,
                usage: 'Card padding, compact page insets',
              ),
              (
                name: 'space6',
                value: AppSpacing.space6,
                usage: 'Section gap, wide page inset, sheet inset',
              ),
              (
                name: 'space8',
                value: AppSpacing.space8,
                usage: 'Major grouping divider',
              ),
              (
                name: 'space12',
                value: AppSpacing.space12,
                usage: 'Hero headers, expansive separation',
              ),
            ];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AppSpacing 4-Unit Rhythm Scale',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  Text(
                    'Strict 4px geometric progression maintaining consistent visual cadence across all screens.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  for (final step in spacingScale) ...[
                    Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(
                            '${step.name} (${step.value.toInt()}px)',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Container(
                          width: step.value > 0 ? step.value * 3 : 2,
                          height: 20,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space3),
                        Expanded(
                          child: Text(
                            step.usage,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space2),
                  ],
                  const SizedBox(height: AppSpacing.space6),
                  Text(
                    'AppShape Corner Radii Tokens',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  Row(
                    children: [
                      _ShapePreviewBox(
                        title: 'small (8px)',
                        subtitle: 'Badges, inputs, buttons',
                        radius: AppShape.smallRadius,
                      ),
                      const SizedBox(width: AppSpacing.space3),
                      _ShapePreviewBox(
                        title: 'card (16px)',
                        subtitle: 'Content cards',
                        radius: AppShape.cardRadius,
                      ),
                      const SizedBox(width: AppSpacing.space3),
                      _ShapePreviewBox(
                        title: 'sheet/dialog (24px)',
                        subtitle: 'Bottom sheets & modals',
                        radius: AppShape.dialogRadius,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space6),
                  Text(
                    'Minimum Accessible Tap Targets',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  Row(
                    children: [
                      Container(
                        width: AppSpacing.androidMinTapTarget,
                        height: AppSpacing.androidMinTapTarget,
                        decoration: BoxDecoration(
                          border: Border.all(color: scheme.primary, width: 2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Center(
                          child: Text(
                            '48dp',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space3),
                      const Expanded(
                        child: Text(
                          'Android Material minimum touch target: 48 × 48 dp',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  Row(
                    children: [
                      Container(
                        width: AppSpacing.iosMinTapTarget,
                        height: AppSpacing.iosMinTapTarget,
                        decoration: BoxDecoration(
                          border: Border.all(color: scheme.secondary, width: 2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Center(
                          child: Text(
                            '44pt',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space3),
                      const Expanded(
                        child: Text(
                          'iOS Cupertino minimum touch target: 44 × 44 pt',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Icons',
      useCases: [
        WidgetbookUseCase(
          name: 'Platform Icon Mapping Matrix',
          builder: (context) {
            final theme = Theme.of(context);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AppIcons Semantic Mapping',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  Text(
                    'Semantic icon enum decoupled from concrete glyphs, mapping to Material 3, Cupertino, and SF Symbols for native iOS platform views.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  Table(
                    border: TableBorder.all(
                      color: theme.colorScheme.outlineVariant,
                    ),
                    columnWidths: const {
                      0: FlexColumnWidth(2),
                      1: FlexColumnWidth(1.5),
                      2: FlexColumnWidth(1.5),
                      3: FlexColumnWidth(3),
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      TableRow(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHigh,
                        ),
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Text(
                              'Semantic ID',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Text(
                              'Material',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Text(
                              'Cupertino',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Text(
                              'SF Symbol',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      for (final icon in AppIcon.values)
                        TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                icon.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Row(
                                children: [
                                  Icon(
                                    AppIcons.material(icon, selected: false),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    AppIcons.material(icon, selected: true),
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Row(
                                children: [
                                  Icon(
                                    AppIcons.cupertino(icon, selected: false),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    AppIcons.cupertino(icon, selected: true),
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                AppIcons.sfSymbol(icon),
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Chart Theme',
      useCases: [
        WidgetbookUseCase(
          name: 'AppChartTheme & Accessible Table Preview',
          builder: (context) {
            final theme = Theme.of(context);
            final chartTheme = AppChartTheme.of(context);

            final weeklyData =
                <({String week, double weight, double pace, int workouts})>[
                  (
                    week: 'W38 (Sep 15–21)',
                    weight: 81.20,
                    pace: 0.30,
                    workouts: 4,
                  ),
                  (
                    week: 'W39 (Sep 22–28)',
                    weight: 81.55,
                    pace: 0.35,
                    workouts: 4,
                  ),
                  (
                    week: 'W40 (Sep 29–Oct 5)',
                    weight: 81.90,
                    pace: 0.35,
                    workouts: 5,
                  ),
                  (
                    week: 'W41 (Oct 6–12)',
                    weight: 82.30,
                    pace: 0.40,
                    workouts: 3,
                  ),
                ];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AppChartTheme Line & Bar Previews',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  Text(
                    'Tokens for weight series, pace series, workouts, target band fills, and dashed boundary lines.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  AppCard(
                    title: 'Weight History & Target Gain Band',
                    subtitle:
                        'Weekly average line with dashed target boundary band',
                    child: SizedBox(
                      height: 240,
                      child: LineChart(
                        LineChartData(
                          minX: 0,
                          maxX: 3,
                          minY: 80.5,
                          maxY: 83.0,
                          gridData: FlGridData(
                            show: true,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: chartTheme.gridLine,
                              strokeWidth: 1,
                            ),
                          ),
                          titlesData: FlTitlesData(
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1,
                                getTitlesWidget: (val, meta) {
                                  final i = val.toInt();
                                  if (i >= 0 && i < weeklyData.length) {
                                    return Text(
                                      weeklyData[i].week.substring(0, 3),
                                      style: TextStyle(
                                        color: chartTheme.axisLabel,
                                        fontSize: 12,
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 42,
                                getTitlesWidget: (val, meta) => Text(
                                  '${val.toStringAsFixed(1)} kg',
                                  style: TextStyle(
                                    color: chartTheme.axisLabel,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          rangeAnnotations: RangeAnnotations(
                            horizontalRangeAnnotations: [
                              HorizontalRangeAnnotation(
                                y1: 81.0,
                                y2: 82.5,
                                color: chartTheme.targetFill.withValues(
                                  alpha: 0.35,
                                ),
                              ),
                            ],
                          ),
                          extraLinesData: ExtraLinesData(
                            horizontalLines: [
                              HorizontalLine(
                                y: 81.0,
                                color: chartTheme.targetBoundary,
                                strokeWidth: 1.5,
                                dashArray: chartTheme.targetDashPattern,
                              ),
                              HorizontalLine(
                                y: 82.5,
                                color: chartTheme.targetBoundary,
                                strokeWidth: 1.5,
                                dashArray: chartTheme.targetDashPattern,
                              ),
                            ],
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: [
                                for (var i = 0; i < weeklyData.length; i++)
                                  FlSpot(i.toDouble(), weeklyData[i].weight),
                              ],
                              isCurved: false,
                              color: chartTheme.seriesWeight,
                              barWidth: chartTheme.lineStrokeWidth,
                              dotData: const FlDotData(show: true),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  AppCard(
                    title: 'Weekly Workouts Bar Chart',
                    subtitle: 'Completed training sessions per week',
                    child: SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          minY: 0,
                          maxY: 6,
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: chartTheme.gridLine,
                              strokeWidth: 1,
                            ),
                          ),
                          titlesData: FlTitlesData(
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1,
                                getTitlesWidget: (val, meta) {
                                  final i = val.toInt();
                                  if (i >= 0 && i < weeklyData.length) {
                                    return Text(
                                      weeklyData[i].week.substring(0, 3),
                                      style: TextStyle(
                                        color: chartTheme.axisLabel,
                                        fontSize: 12,
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 24,
                                getTitlesWidget: (val, meta) => Text(
                                  val.toInt().toString(),
                                  style: TextStyle(
                                    color: chartTheme.axisLabel,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          barGroups: [
                            for (var i = 0; i < weeklyData.length; i++)
                              BarChartGroupData(
                                x: i,
                                barRods: [
                                  BarChartRodData(
                                    toY: weeklyData[i].workouts.toDouble(),
                                    color: chartTheme.seriesWorkouts,
                                    width: chartTheme.barWidth,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  Text(
                    'Accessible Tabular Data Alternative',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  Table(
                    border: TableBorder.all(
                      color: theme.colorScheme.outlineVariant,
                    ),
                    children: [
                      TableRow(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHigh,
                        ),
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Text(
                              'Week Range',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Text(
                              'Weight Avg',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Text(
                              'Weekly Pace',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Text(
                              'Workouts',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      for (final row in weeklyData)
                        TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(row.week),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                '${row.weight.toStringAsFixed(2)} kg',
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                '+${row.pace.toStringAsFixed(2)} kg/wk',
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text('${row.workouts} sessions'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    ),
  ],
);

class _ColorSwatchCard extends StatelessWidget {
  const _ColorSwatchCard({
    required this.name,
    required this.background,
    required this.foreground,
    required this.role,
    this.border,
  });

  final String name;
  final Color background;
  final Color foreground;
  final String role;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    final contrast = _calculateContrastRatio(foreground, background);
    final isAccessible = contrast >= 4.5;

    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppShape.smallRadius,
        border: Border.all(
          color: border ?? Colors.transparent,
          width: border != null ? 1.5 : 0.0,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: foreground.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${contrast.toStringAsFixed(1)}:1 ${isAccessible ? '✓' : '⚠️'}',
                  style: TextStyle(
                    color: foreground,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            role,
            style: TextStyle(
              color: foreground.withValues(alpha: 0.85),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            'BG: ${_hexString(background)} | FG: ${_hexString(foreground)}',
            style: TextStyle(
              color: foreground.withValues(alpha: 0.7),
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _ShapePreviewBox extends StatelessWidget {
  const _ShapePreviewBox({
    required this.title,
    required this.subtitle,
    required this.radius,
  });

  final String title;
  final String subtitle;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space3),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: radius,
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: AppSpacing.space1),
            Text(subtitle, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
