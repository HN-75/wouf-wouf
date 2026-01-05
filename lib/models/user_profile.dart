/// Genre de l'utilisateur pour personnaliser les phrases
enum UserGender {
  homme,
  femme,
  neutre,
}

extension UserGenderExtension on UserGender {
  String get label {
    switch (this) {
      case UserGender.homme:
        return 'Homme';
      case UserGender.femme:
        return 'Femme';
      case UserGender.neutre:
        return 'Neutre';
    }
  }

  String get appelation {
    switch (this) {
      case UserGender.homme:
        return 'maître';
      case UserGender.femme:
        return 'maîtresse';
      case UserGender.neutre:
        return 'humain';
    }
  }

  String get appelationCourte {
    switch (this) {
      case UserGender.homme:
        return 'boss';
      case UserGender.femme:
        return 'ma belle';
      case UserGender.neutre:
        return 'toi';
    }
  }
}

/// Profil utilisateur stocké localement
class UserProfile {
  final String? dogName;
  final UserGender gender;
  final bool onboardingComplete;

  UserProfile({
    this.dogName,
    this.gender = UserGender.neutre,
    this.onboardingComplete = false,
  });

  Map<String, dynamic> toJson() => {
        'dogName': dogName,
        'gender': gender.index,
        'onboardingComplete': onboardingComplete,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        dogName: json['dogName'] as String?,
        gender: UserGender.values[json['gender'] as int? ?? 2],
        onboardingComplete: json['onboardingComplete'] as bool? ?? false,
      );

  UserProfile copyWith({
    String? dogName,
    UserGender? gender,
    bool? onboardingComplete,
  }) =>
      UserProfile(
        dogName: dogName ?? this.dogName,
        gender: gender ?? this.gender,
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      );
}
