// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'builder_definition.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BuilderDefinition _$BuilderDefinitionFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['builderFactories', 'import', 'buildExtensions'],
    disallowNullValues: const ['builderFactories', 'import', 'buildExtensions'],
  );
  return BuilderDefinition(
    builderFactories: (json['builderFactories'] as List<dynamic>)
        .map((e) => e as String)
        .toList(),
    buildExtensions: (json['buildExtensions'] as Map<String, dynamic>).map(
      (k, e) =>
          MapEntry(k, (e as List<dynamic>).map((e) => e as String).toList()),
    ),
    import: json['import'] as String,
    target: json['target'] as String?,
    autoApply: $enumDecodeNullable(_$AutoApplyEnumMap, json['autoApply']),
    requiredInputs:
        (json['requiredInputs'] as List<dynamic>?)?.map((e) => e as String),
    runsBefore: (json['runsBefore'] as List<dynamic>?)?.map((e) => e as String),
    appliesBuilders:
        (json['appliesBuilders'] as List<dynamic>?)?.map((e) => e as String),
    isOptional: json['isOptional'] as bool?,
    buildTo: $enumDecodeNullable(_$BuildToEnumMap, json['buildTo']),
    defaults: json['defaults'] == null
        ? null
        : TargetBuilderConfigDefaults.fromJson(
            json['defaults'] as Map<String, dynamic>),
  );
}

const _$AutoApplyEnumMap = {
  AutoApply.none: 'none',
  AutoApply.dependents: 'dependents',
  AutoApply.allPackages: 'all_packages',
  AutoApply.rootPackage: 'root_package',
};

const _$BuildToEnumMap = {
  BuildTo.source: 'source',
  BuildTo.cache: 'cache',
};

PostProcessBuilderDefinition _$PostProcessBuilderDefinitionFromJson(
    Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['builderFactory', 'import'],
    disallowNullValues: const ['builderFactory', 'import'],
  );
  return PostProcessBuilderDefinition(
    builderFactory: json['builderFactory'] as String,
    import: json['import'] as String,
    inputExtensions:
        (json['inputExtensions'] as List<dynamic>?)?.map((e) => e as String),
    target: json['target'] as String?,
    defaults: json['defaults'] == null
        ? null
        : TargetBuilderConfigDefaults.fromJson(
            json['defaults'] as Map<String, dynamic>),
  );
}

TargetBuilderConfigDefaults _$TargetBuilderConfigDefaultsFromJson(
        Map<String, dynamic> json) =>
    TargetBuilderConfigDefaults(
      generateFor: json['generateFor'] == null
          ? null
          : InputSet.fromJson(json['generateFor']),
      options: json['options'] as Map<String, dynamic>?,
      devOptions: json['devOptions'] as Map<String, dynamic>?,
      releaseOptions: json['releaseOptions'] as Map<String, dynamic>?,
    );
