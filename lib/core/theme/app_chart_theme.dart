import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'app_shape.dart';

part 'app_chart_theme.freezed.dart';

/// Immutable [ThemeExtension] defining semantic chart roles, stroke widths,
/// target band geometry, and tooltip surface pairs.
@Freezed(copyWith: false)
abstract class AppChartTheme extends ThemeExtension<AppChartTheme>
    with _$AppChartTheme {
  const AppChartTheme._();

  static const double defaultChartHeight = 220.0;
  static const double defaultBarRadius = AppShape.subtle;
  static const double defaultBottomAxisReservedSize = 32.0;
  static const double defaultWorkoutsLeftAxisReservedSize = 28.0;
  static const double defaultWeightLeftAxisReservedSize = 48.0;
  static const double defaultPaceLeftAxisReservedSize = 58.0;

  const factory AppChartTheme({
    required Color seriesWeight,
    required Color seriesPace,
    required Color seriesWorkouts,
    required Color targetFill,
    required Color targetBoundary,
    required Color axisLabel,
    required Color gridLine,
    required Color tooltipSurface,
    required Color onTooltipSurface,
    @Default(3.0) double lineStrokeWidth,
    @Default(12.0) double barWidth,
    @Default(AppChartTheme.defaultBarRadius) double barRadius,
    @Default(AppChartTheme.defaultChartHeight) double chartHeight,
    @Default(AppChartTheme.defaultBottomAxisReservedSize)
    double bottomAxisReservedSize,
    @Default(AppChartTheme.defaultWorkoutsLeftAxisReservedSize)
    double workoutsLeftAxisReservedSize,
    @Default(AppChartTheme.defaultWeightLeftAxisReservedSize)
    double weightLeftAxisReservedSize,
    @Default(AppChartTheme.defaultPaceLeftAxisReservedSize)
    double paceLeftAxisReservedSize,
    @Default(<int>[6, 4]) List<int> targetDashPattern,
  }) = _AppChartTheme;

  /// Constructs chart tokens mapped from a Material 3 [ColorScheme].
  factory AppChartTheme.fromColorScheme(ColorScheme scheme) {
    return AppChartTheme(
      seriesWeight: scheme.primary,
      seriesPace: scheme.primary,
      seriesWorkouts: scheme.tertiary,
      targetFill: scheme.secondaryContainer,
      targetBoundary: scheme.onSecondaryContainer,
      axisLabel: scheme.onSurfaceVariant,
      gridLine: scheme.outlineVariant,
      tooltipSurface: scheme.inverseSurface,
      onTooltipSurface: scheme.onInverseSurface,
    );
  }

  /// Resolves [AppChartTheme] from [context], falling back to an instance
  /// derived from `Theme.of(context).colorScheme` if not registered in an
  /// isolated test harness.
  static AppChartTheme of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<AppChartTheme>() ??
        AppChartTheme.fromColorScheme(theme.colorScheme);
  }

  @override
  AppChartTheme copyWith({
    Color? seriesWeight,
    Color? seriesPace,
    Color? seriesWorkouts,
    Color? targetFill,
    Color? targetBoundary,
    Color? axisLabel,
    Color? gridLine,
    Color? tooltipSurface,
    Color? onTooltipSurface,
    double? lineStrokeWidth,
    double? barWidth,
    double? barRadius,
    double? chartHeight,
    double? bottomAxisReservedSize,
    double? workoutsLeftAxisReservedSize,
    double? weightLeftAxisReservedSize,
    double? paceLeftAxisReservedSize,
    List<int>? targetDashPattern,
  }) {
    return AppChartTheme(
      seriesWeight: seriesWeight ?? this.seriesWeight,
      seriesPace: seriesPace ?? this.seriesPace,
      seriesWorkouts: seriesWorkouts ?? this.seriesWorkouts,
      targetFill: targetFill ?? this.targetFill,
      targetBoundary: targetBoundary ?? this.targetBoundary,
      axisLabel: axisLabel ?? this.axisLabel,
      gridLine: gridLine ?? this.gridLine,
      tooltipSurface: tooltipSurface ?? this.tooltipSurface,
      onTooltipSurface: onTooltipSurface ?? this.onTooltipSurface,
      lineStrokeWidth: lineStrokeWidth ?? this.lineStrokeWidth,
      barWidth: barWidth ?? this.barWidth,
      barRadius: barRadius ?? this.barRadius,
      chartHeight: chartHeight ?? this.chartHeight,
      bottomAxisReservedSize:
          bottomAxisReservedSize ?? this.bottomAxisReservedSize,
      workoutsLeftAxisReservedSize:
          workoutsLeftAxisReservedSize ?? this.workoutsLeftAxisReservedSize,
      weightLeftAxisReservedSize:
          weightLeftAxisReservedSize ?? this.weightLeftAxisReservedSize,
      paceLeftAxisReservedSize:
          paceLeftAxisReservedSize ?? this.paceLeftAxisReservedSize,
      targetDashPattern: targetDashPattern ?? this.targetDashPattern,
    );
  }

  @override
  AppChartTheme lerp(covariant ThemeExtension<AppChartTheme>? other, double t) {
    if (other is! AppChartTheme) {
      return this;
    }
    return AppChartTheme(
      seriesWeight: Color.lerp(seriesWeight, other.seriesWeight, t)!,
      seriesPace: Color.lerp(seriesPace, other.seriesPace, t)!,
      seriesWorkouts: Color.lerp(seriesWorkouts, other.seriesWorkouts, t)!,
      targetFill: Color.lerp(targetFill, other.targetFill, t)!,
      targetBoundary: Color.lerp(targetBoundary, other.targetBoundary, t)!,
      axisLabel: Color.lerp(axisLabel, other.axisLabel, t)!,
      gridLine: Color.lerp(gridLine, other.gridLine, t)!,
      tooltipSurface: Color.lerp(tooltipSurface, other.tooltipSurface, t)!,
      onTooltipSurface: Color.lerp(
        onTooltipSurface,
        other.onTooltipSurface,
        t,
      )!,
      lineStrokeWidth:
          ui.lerpDouble(lineStrokeWidth, other.lineStrokeWidth, t) ??
          lineStrokeWidth,
      barWidth: ui.lerpDouble(barWidth, other.barWidth, t) ?? barWidth,
      barRadius: ui.lerpDouble(barRadius, other.barRadius, t) ?? barRadius,
      chartHeight:
          ui.lerpDouble(chartHeight, other.chartHeight, t) ?? chartHeight,
      bottomAxisReservedSize:
          ui.lerpDouble(
            bottomAxisReservedSize,
            other.bottomAxisReservedSize,
            t,
          ) ??
          bottomAxisReservedSize,
      workoutsLeftAxisReservedSize:
          ui.lerpDouble(
            workoutsLeftAxisReservedSize,
            other.workoutsLeftAxisReservedSize,
            t,
          ) ??
          workoutsLeftAxisReservedSize,
      weightLeftAxisReservedSize:
          ui.lerpDouble(
            weightLeftAxisReservedSize,
            other.weightLeftAxisReservedSize,
            t,
          ) ??
          weightLeftAxisReservedSize,
      paceLeftAxisReservedSize:
          ui.lerpDouble(
            paceLeftAxisReservedSize,
            other.paceLeftAxisReservedSize,
            t,
          ) ??
          paceLeftAxisReservedSize,
      targetDashPattern: t < 0.5 ? targetDashPattern : other.targetDashPattern,
    );
  }
}
