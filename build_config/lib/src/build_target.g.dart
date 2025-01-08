// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_target.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BuildTarget _$BuildTargetFromJson(Map<String, dynamic> json) => BuildTarget(
      autoApplyBuilders: json['autoApplyBuilders'] as bool?,
      sources:
          json['sources'] == null ? null : InputSet.fromJson(json['sources']),
      dependencies:
          (json['dependencies'] as List<dynamic>?)?.map((e) => e as String),
      builders: (json['builders'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(
            k, TargetBuilderConfig.fromJson(e as Map<String, dynamic>)),
      ),
    );

TargetBuilderConfig _$TargetBuilderConfigFromJson(Map<String, dynamic> json) =>
    TargetBuilderConfig(
      isEnabled: json['enabled'] as bool?,
      generateFor: json['generateFor'] == null
          ? null
          : InputSet.fromJson(json['generateFor']),
      options: json['options'] as Map<String, dynamic>?,
      devOptions: json['devOptions'] as Map<String, dynamic>?,
      releaseOptions: json['releaseOptions'] as Map<String, dynamic>?,
    );

GlobalBuilderConfig _$GlobalBuilderConfigFromJson(Map<String, dynamic> json) =>
    GlobalBuilderConfig(
      options: json['options'] as Map<String, dynamic>?,
      devOptions: json['devOptions'] as Map<String, dynamic>?,
      releaseOptions: json['releaseOptions'] as Map<String, dynamic>?,
      runsBefore: (json['runsBefore'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
