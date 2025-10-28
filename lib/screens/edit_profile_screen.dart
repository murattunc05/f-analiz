// lib/screens/edit_profile_screen.dart
import 'package:flutter/material.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_spacing.dart';
import '../design_system/app_typography.dart';
import '../design_system/widgets/modern_card.dart';
import '../design_system/widgets/modern_button.dart';
import '../design_system/widgets/modern_app_bar.dart';
import '../services/user_profile_service.dart';
import '../services/league_logo_service.dart';
import '../data_service.dart';
import '../models/user_profile_model.dart';
import '../widgets/profile_image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfile? userProfile;
  final VoidCallback? onProfileUpdated;
  
  const EditProfileScreen({
    Key? key,
    this.userProfile,
    this.onProfileUpdated,
  }) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _userProfileService = UserProfileService();
  
  // Bu alanlar doğrudan UserProfile'dan gelecek, bu yüzden controller'a gerek yok.
  String? _favoriteTeam;
  String? _favoriteLeague;
  String? _email;
  String? _photoURL;

  bool _isLoading = true;
  UserProfile? _initialProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _userProfileService.loadUserProfile();
      if (profile != null && mounted) {
        setState(() {
          _initialProfile = profile;
          _nameController.text = profile.displayName;
          _bioController.text = profile.bio ?? '';
          _locationController.text = profile.location ?? '';
          _email = profile.email;
          _photoURL = profile.photoURL;
          _favoriteTeam = profile.supportedTeam?.name;
          _favoriteLeague = profile.favoriteLeague;
        });
      }
    } catch (e) {
      _showSnackBar('Profil verileri yüklenemedi: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _userProfileService.updateProfileDetails(
        displayName: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        location: _locationController.text.trim(),
        favoriteTeam: _favoriteTeam,
        favoriteLeague: _favoriteLeague,
        // photoURL burada güncellenmiyor, ProfileImagePicker kendi yönetiyor.
      );
      
      _showSnackBar('Profil başarıyla güncellendi');
      Navigator.pop(context, true); // true, profil ekranının yenilenmesi gerektiğini belirtir

    } catch (e) {
      _showSnackBar('Profil güncellenirken hata oluştu: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: ModernAppBar(
        title: 'Profili Düzenle',
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : _saveProfile,
            tooltip: 'Kaydet',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildProfilePictureSection(isDark),
                    const SizedBox(height: AppSpacing.xl),
                    _buildTextField(_nameController, 'Ad Soyad', Icons.person_outline, validator: (val) => val!.isEmpty ? 'Ad Soyad boş olamaz' : null),
                    const SizedBox(height: AppSpacing.lg),
                    _buildTextField(_locationController, 'Konum', Icons.location_on_outlined, hint: 'Şehir, Ülke'),
                    const SizedBox(height: AppSpacing.lg),
                    _buildTextField(_bioController, 'Hakkımda', Icons.info_outline, hint: 'Kendinizden bahsedin...', maxLines: 3),
                    const SizedBox(height: AppSpacing.xl),
                    _buildPreferencesSection(isDark),
                    const SizedBox(height: AppSpacing.massive),
                    ModernButton(
                      text: 'Değişiklikleri Kaydet',
                      onPressed: _saveProfile,
                      isLoading: _isLoading,
                      isFullWidth: true,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfilePictureSection(bool isDark) {
    return Center(
      child: ProfileImagePicker(
        networkImageUrl: _photoURL,
        size: 120,
        onImageChanged: (imagePath) async {
          if (imagePath != null) {
            setState(() => _isLoading = true);
            final newPhotoUrl = await _userProfileService.updateProfileImage(imagePath);
            if (newPhotoUrl != null) {
              setState(() {
                _photoURL = newPhotoUrl;
              });
            }
            setState(() => _isLoading = false);
          }
        },
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {String? hint, int maxLines = 1, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
      ),
      maxLines: maxLines,
      validator: validator,
    );
  }

  Widget _buildPreferencesSection(bool isDark) {
    return ModernCard(
      child: Column(
        children: [
          ListTile(
            leading: _favoriteLeague != null 
                ? _buildLeagueIcon(_favoriteLeague!)
                : const Icon(Icons.emoji_events_outlined, color: AppColors.primary),
            title: const Text('Favori Lig'),
            subtitle: Text(_favoriteLeague ?? 'Seçilmedi'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLeagueSelectionDialog(),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.sports_soccer_outlined, color: AppColors.primary),
            title: const Text('Tuttuğu Takım'),
            subtitle: Text(_favoriteTeam ?? 'Seçilmedi'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showTeamSelectionDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildLeagueIcon(String leagueName) {
    final logoUrl = LeagueLogoService.getLeagueLogo(leagueName);
    if (logoUrl != null) {
      return SizedBox(
        width: 24,
        height: 24,
        child: Image.network(
          logoUrl,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => 
              const Icon(Icons.emoji_events_outlined, color: AppColors.primary),
        ),
      );
    }
    return const Icon(Icons.emoji_events_outlined, color: AppColors.primary);
  }

  Future<void> _showLeagueSelectionDialog() async {
    final leagues = LeagueLogoService.getAvailableLeagues();
    
    final selected = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Favori Lig Seç'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: leagues.length,
              itemBuilder: (context, index) {
                final league = leagues[index];
                return ListTile(
                  leading: _buildLeagueIcon(league),
                  title: Text(league),
                  trailing: _favoriteLeague == league 
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () => Navigator.of(context).pop(league),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
          ],
        );
      },
    );
    
    if (selected != null) {
      setState(() {
        _favoriteLeague = selected;
        // Lig değiştiğinde takım seçimini sıfırla
        _favoriteTeam = null;
      });
    }
  }

  Future<void> _showTeamSelectionDialog() async {
    if (_favoriteLeague == null) {
      _showSnackBar('Önce favori lig seçiniz', isError: true);
      return;
    }
    
    final teams = DataService.getTeamsForLeague(_favoriteLeague!);
    if (teams.isEmpty) {
      _showSnackBar('Bu lig için takım listesi bulunamadı', isError: true);
      return;
    }
    
    final selected = await showDialog<String>(
      context: context,
      builder: (context) {
        String searchQuery = '';
        List<String> filteredTeams = teams;
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Takım Seç'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    // Arama alanı
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Takım ara...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          searchQuery = value.toLowerCase();
                          filteredTeams = teams
                              .where((team) => team.toLowerCase().contains(searchQuery))
                              .toList();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Takım listesi
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredTeams.length,
                        itemBuilder: (context, index) {
                          final team = filteredTeams[index];
                          return ListTile(
                            leading: const Icon(Icons.sports_soccer, color: AppColors.primary),
                            title: Text(team),
                            trailing: _favoriteTeam == team 
                                ? const Icon(Icons.check, color: AppColors.primary)
                                : null,
                            onTap: () => Navigator.of(context).pop(team),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('İptal'),
                ),
              ],
            );
          },
        );
      },
    );
    
    if (selected != null) {
      setState(() => _favoriteTeam = selected);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}