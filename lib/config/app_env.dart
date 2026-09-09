import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 应用运行环境：开发、测试、生产。
enum AppEnv {
  /// 开发环境
  dev,

  /// 测试环境
  staging,

  /// 生产环境
  prod;

  /// 从环境变量 `APP_ENV` 解析。支持 `dev`/`development`、`staging`/`test`、`prod`/`production`。
  static AppEnv parse(String name) {
    switch (name.trim().toLowerCase()) {
      case 'dev':
      case 'development':
        return AppEnv.dev;
      case 'staging':
      case 'test':
      case 'qa':
        return AppEnv.staging;
      case 'prod':
      case 'production':
        return AppEnv.prod;
      default:
        throw ArgumentError('未知环境: $name，请使用 dev / staging / prod');
    }
  }

  bool get isDev => this == AppEnv.dev;
  bool get isStaging => this == AppEnv.staging;
  bool get isProd => this == AppEnv.prod;

  /// 中文展示名，不含「环境」后缀。
  String get label => switch (this) {
    AppEnv.dev => '开发',
    AppEnv.staging => '测试',
    AppEnv.prod => '生产',
  };

  /// 角标文案（英文短码）。
  String get bannerLabel => switch (this) {
    AppEnv.dev => 'DEV',
    AppEnv.staging => 'TEST',
    AppEnv.prod => 'PROD',
  };

  /// 非生产环境角标颜色。
  Color get bannerColor => switch (this) {
    AppEnv.dev => AppColors.sakura,
    AppEnv.staging => AppColors.starPurple,
    AppEnv.prod => AppColors.ink,
  };
}
