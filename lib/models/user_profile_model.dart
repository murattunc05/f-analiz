// lib/models/user_profile_model.dart

// FavoriteTeam, UserProfile içinde kullanılacak basit bir veri sınıfı.
class FavoriteTeam {
  final String name;
  final String league;
  final String season; // Örneğin '2023-2024'
  final String? logoUrl;

  const FavoriteTeam({required this.name, required this.league, required this.season, this.logoUrl});

  // Firestore'da saklamak için Map'e dönüştürme
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'league': league,
      'season': season,
      'logoUrl': logoUrl,
    };
  }

  // Firestore'dan okumak için Map'ten oluşturma
  factory FavoriteTeam.fromMap(Map<String, dynamic> map) {
    return FavoriteTeam(
      name: map['name'] ?? '',
      league: map['league'] ?? '',
      season: map['season'] ?? '',
      logoUrl: map['logoUrl'],
    );
  }
}

// Kullanıcı ayarlarını tutan veri sınıfı
class UserSettings {
  final bool notificationsEnabled;
  final String theme;

  const UserSettings({this.notificationsEnabled = true, this.theme = 'system'});

  Map<String, dynamic> toMap() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'theme': theme,
    };
  }

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      theme: map['theme'] ?? 'system',
    );
  }

  UserSettings copyWith({bool? notificationsEnabled, String? theme}) {
    return UserSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      theme: theme ?? this.theme,
    );
  }
}

// Ana kullanıcı profili modeli - Artık tüm verileri içeriyor
class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final String? bio;
  final String? location;
  final DateTime? birthDate;
  final bool isProfileComplete;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Birleştirilmiş ve genişletilmiş alanlar
  final List<FavoriteTeam> favoriteTeams;
  final FavoriteTeam? supportedTeam;
  final String? favoriteLeague; // Bu hala genel bir tercih olarak kalabilir
  final UserSettings settings;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    this.bio,
    this.location,
    this.birthDate,
    this.isProfileComplete = false,
    required this.createdAt,
    required this.updatedAt,
    this.favoriteTeams = const [],
    this.supportedTeam,
    this.favoriteLeague,
    this.settings = const UserSettings(),
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoURL: map['photoURL'],
      bio: map['bio'],
      location: map['location'],
      birthDate: map['birthDate'] != null ? (map['birthDate'] as int).toDate() : null,
      isProfileComplete: map['isProfileComplete'] ?? false,
      createdAt: (map['createdAt'] as int).toDate(),
      updatedAt: (map['updatedAt'] as int).toDate(),
      favoriteLeague: map['favoriteLeague'],
      // Alt nesneleri ve listeleri okuma
      favoriteTeams: (map['favoriteTeams'] as List<dynamic>? ?? [])
          .map((teamMap) => FavoriteTeam.fromMap(teamMap as Map<String, dynamic>))
          .toList(),
      supportedTeam: map['supportedTeam'] != null
          ? FavoriteTeam.fromMap(map['supportedTeam'] as Map<String, dynamic>)
          : null,
      settings: map['settings'] != null
          ? UserSettings.fromMap(map['settings'] as Map<String, dynamic>)
          : const UserSettings(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'bio': bio,
      'location': location,
      'birthDate': birthDate?.millisecondsSinceEpoch,
      'isProfileComplete': isProfileComplete,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'favoriteLeague': favoriteLeague,
      // Alt nesneleri ve listeleri yazma
      'favoriteTeams': favoriteTeams.map((team) => team.toMap()).toList(),
      'supportedTeam': supportedTeam?.toMap(),
      'settings': settings.toMap(),
    };
  }

  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    String? bio,
    String? location,
    DateTime? birthDate,
    bool? isProfileComplete,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<FavoriteTeam>? favoriteTeams,
    FavoriteTeam? supportedTeam,
    String? favoriteLeague,
    UserSettings? settings,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      birthDate: birthDate ?? this.birthDate,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      favoriteTeams: favoriteTeams ?? this.favoriteTeams,
      supportedTeam: supportedTeam ?? this.supportedTeam,
      favoriteLeague: favoriteLeague ?? this.favoriteLeague,
      settings: settings ?? this.settings,
    );
  }
}

// Helper extension for converting milliseconds to DateTime
extension IntToDateTime on int {
  DateTime toDate() => DateTime.fromMillisecondsSinceEpoch(this);
}
