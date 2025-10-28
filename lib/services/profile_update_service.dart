// lib/services/profile_update_service.dart
import 'dart:async';

class ProfileUpdateService {
  static final StreamController<ProfileUpdateEvent> _controller = 
      StreamController<ProfileUpdateEvent>.broadcast();
  
  static Stream<ProfileUpdateEvent> get updates => _controller.stream;
  
  // Profil fotoğrafı güncellendiğinde
  static void notifyProfileImageUpdated(String? imagePath) {
    _controller.add(ProfileUpdateEvent(
      type: ProfileUpdateType.profileImage,
      data: {'imagePath': imagePath},
    ));
  }
  
  // Profil bilgileri güncellendiğinde
  static void notifyProfileUpdated() {
    _controller.add(ProfileUpdateEvent(
      type: ProfileUpdateType.profile,
      data: {},
    ));
  }
  
  // Favori takım eklendiğinde
  static void notifyFavoriteTeamAdded(String teamName, String league) {
    _controller.add(ProfileUpdateEvent(
      type: ProfileUpdateType.favoriteTeam,
      data: {'teamName': teamName, 'league': league},
    ));
  }
  
  // Analytics güncellendiğinde
  static void notifyAnalyticsUpdated() {
    _controller.add(ProfileUpdateEvent(
      type: ProfileUpdateType.analytics,
      data: {},
    ));
  }
  
  // Çıkış yapıldığında
  static void notifySignOut() {
    _controller.add(ProfileUpdateEvent(
      type: ProfileUpdateType.signOut,
      data: {},
    ));
  }
  
  static void dispose() {
    _controller.close();
  }
}

enum ProfileUpdateType {
  profileImage,
  profile,
  favoriteTeam,
  analytics,
  signOut,
}

class ProfileUpdateEvent {
  final ProfileUpdateType type;
  final Map<String, dynamic> data;
  
  ProfileUpdateEvent({
    required this.type,
    required this.data,
  });
}