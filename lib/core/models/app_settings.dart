/// App settings keys stored in database
class AppSettingsKeys {
  AppSettingsKeys._();

  static const String onboardingCompleted = 'onboarding_completed';
  static const String monthlyBudget = 'monthly_budget';
  static const String userName = 'user_name';
  static const String categoriesSeeded = 'categories_seeded';
  static const String lastBackupDate = 'last_backup_date';
  static const String notificationsEnabled = 'notifications_enabled';
  static const String biometricEnabled = 'biometric_enabled';
  static const String themeMode = 'theme_mode'; // 'dark', 'light', 'system'
}

/// App setting model
class AppSetting {
  final int? id;
  final String key;
  final String? value;
  final String? updatedAt;

  const AppSetting({this.id, required this.key, this.value, this.updatedAt});

  Map<String, dynamic> toMap() => {
    'id': id,
    'key': key,
    'value': value,
    'updatedAt': updatedAt ?? DateTime.now().toIso8601String(),
  };

  factory AppSetting.fromMap(Map<String, dynamic> map) => AppSetting(
    id: map['id'],
    key: map['key'] ?? '',
    value: map['value'],
    updatedAt: map['updatedAt'],
  );

  /// Get value as bool
  bool get boolValue => value?.toLowerCase() == 'true';

  /// Get value as double
  double get doubleValue => double.tryParse(value ?? '') ?? 0;

  /// Get value as int
  int get intValue => int.tryParse(value ?? '') ?? 0;

  @override
  String toString() => 'AppSetting(key: $key, value: $value)';
}

/// Onboarding step tracking
enum OnboardingStep {
  welcome,
  budgetSetup,
  moneySourcesSetup,
  completed;

  int get stepNumber {
    switch (this) {
      case OnboardingStep.welcome:
        return 0;
      case OnboardingStep.budgetSetup:
        return 1;
      case OnboardingStep.moneySourcesSetup:
        return 2;
      case OnboardingStep.completed:
        return 3;
    }
  }

  static OnboardingStep fromStep(int step) {
    switch (step) {
      case 0:
        return OnboardingStep.welcome;
      case 1:
        return OnboardingStep.budgetSetup;
      case 2:
        return OnboardingStep.moneySourcesSetup;
      default:
        return OnboardingStep.completed;
    }
  }

  bool get isFirst => this == OnboardingStep.welcome;
  bool get isLast => this == OnboardingStep.completed;

  OnboardingStep get next {
    switch (this) {
      case OnboardingStep.welcome:
        return OnboardingStep.budgetSetup;
      case OnboardingStep.budgetSetup:
        return OnboardingStep.moneySourcesSetup;
      case OnboardingStep.moneySourcesSetup:
        return OnboardingStep.completed;
      case OnboardingStep.completed:
        return OnboardingStep.completed;
    }
  }
}

/// User preferences model (in-memory aggregation)
class UserPreferences {
  final bool onboardingCompleted;
  final double monthlyBudget;
  final String? userName;
  final bool categoriesSeeded;
  final bool notificationsEnabled;
  final bool biometricEnabled;

  const UserPreferences({
    this.onboardingCompleted = false,
    this.monthlyBudget = 0,
    this.userName,
    this.categoriesSeeded = false,
    this.notificationsEnabled = true,
    this.biometricEnabled = false,
  });

  UserPreferences copyWith({
    bool? onboardingCompleted,
    double? monthlyBudget,
    String? userName,
    bool? categoriesSeeded,
    bool? notificationsEnabled,
    bool? biometricEnabled,
  }) {
    return UserPreferences(
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      userName: userName ?? this.userName,
      categoriesSeeded: categoriesSeeded ?? this.categoriesSeeded,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    );
  }

  @override
  String toString() {
    return 'UserPreferences(onboardingCompleted: $onboardingCompleted, '
        'monthlyBudget: $monthlyBudget, userName: $userName)';
  }
}
