// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BuildConfig _$BuildConfigFromJson(Map<String, dynamic> json) => BuildConfig(
      buildTargets: _buildTargetsFromJson(json['targets'] as Map?),
      globalOptions: (json['globalOptions'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(
            k, GlobalBuilderConfig.fromJson(e as Map<String, dynamic>)),
      ),
      builderDefinitions: (json['builders'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, BuilderDefinition.fromJson(e as Map<String, dynamic>)),
      ),
      postProcessBuilderDefinitions:
          (json['post_process_builders'] as Map<String, dynamic>?)?.map(
                (k, e) => MapEntry(
                    k,
                    PostProcessBuilderDefinition.fromJson(
                        e as Map<String, dynamic>)),
              ) ??
              const {},
      additionalPublicAssets: (json['additionalPublicAssets'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
