// lib/screens/profile_completion_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../design_system/widgets/modern_button.dart';
import '../design_system/widgets/modern_card.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_spacing.dart';
import '../design_system/app_typography.dart';
import '../services/user_profile_service.dart';
import '../models/user_profile_model.dart';

class ProfileCompletionScreen extends StatefulWidget {
  final VoidCallback onCompleted;
  
  const ProfileCompletionScreen({
    super.key,
    required this.onCompleted,
  });

  @override
  State<ProfileCompletionScreen> createState() => _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserProfileService _userProfileService = UserProfileService();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  
  String? _selectedFavoriteTeam;
  String? _selectedFavoriteLeague;
  DateTime? _selectedBirthDate;
  bool _isLoading = false;
  UserProfile? _currentProfile;

  final List<String> _popularTeams = [
    'Manchester United', 'Manchester City', 'Liverpool', 'Arsenal', 'Chelsea',
    'Barcelona', 'Real Madrid', 'Atletico Madrid', 'Bayern Munich', 'Borussia Dortmund',
    'Juventus', 'AC Milan', 'Inter Milan', 'PSG', 'Galatasaray', 'Fenerbahçe', 'Beşiktaş'
  ];

  final List<String> _popularLeagues = [
    'Premier League', 'La Liga', 'Bundesliga', 'Serie A', 'Ligue 1', 'Süper Lig'
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentProfile() async {
    final profile = await _userProfileService.loadUserProfile();
    if (profile != null && mounted) {
      setState(() {
        _currentProfile = profile;
        _displayNameController.text = profile.displayName;
        _bioController.text = profile.bio ?? '';
        _locationController.text = profile.location ?? '';
        _selectedFavoriteTeam = profile.supportedTeam?.name;
        _selectedFavoriteLeague = profile.favoriteLeague;
        _selectedBirthDate = profile.birthDate;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      await _userProfileService.updateProfileDetails(
        displayName: _displayNameController.text.trim(),
        bio: _bioController.text.trim(),
        location: _locationController.text.trim(),
      );
      if (_selectedFavoriteLeague != null) {
        await _userProfileService.setFavoriteLeague(_selectedFavoriteLeague!);
      }
      if (_selectedFavoriteTeam != null) {
        await _userProfileService.setSupportedTeam(FavoriteTeam(
          name: _selectedFavoriteTeam!, 
          league: _selectedFavoriteLeague ?? 'Türkiye - Süper Lig',
          season: '2024-2025',
          logoUrl: ''
        ));
      }
      
      if (mounted) {
        widget.onCompleted();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil kaydedilirken hata oluştu: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _skipProfile() async {
    try {
      // Profili geçildi olarak işaretle
      await _userProfileService.markProfileAsComplete();
      if (mounted) {
        widget.onCompleted();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata oluştu: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _selectBirthDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)), // En az 13 yaş
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (date != null) {
      setState(() {
        _selectedBirthDate = date;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                
                // Header
                _buildHeader()
                  .animate()
                  .fadeIn(duration: const Duration(milliseconds: 600))
                  .slideY(begin: -0.3, duration: const Duration(milliseconds: 600)),
                
                const SizedBox(height: 40),
                
                // Profile form
                ModernCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Temel Bilgiler',
                        style: AppTypography.headlineSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Display Name
                      _buildDisplayNameField()
                        .animate()
                        .fadeIn(duration: const Duration(milliseconds: 400))
                        .slideX(begin: -0.3, duration: const Duration(milliseconds: 400)),
                      
                      const SizedBox(height: 16),
                      
                      // Email (read-only)
                      _buildEmailField()
                        .animate()
                        .fadeIn(duration: const Duration(milliseconds: 500))
                        .slideX(begin: 0.3, duration: const Duration(milliseconds: 500)),
                      
                      const SizedBox(height: 16),
                      
                      // Birth Date
                      _buildBirthDateField()
                        .animate()
                        .fadeIn(duration: const Duration(milliseconds: 600))
                        .slideX(begin: -0.3, duration: const Duration(milliseconds: 600)),
                      
                      const SizedBox(height: 16),
                      
                      // Location
                      _buildLocationField()
                        .animate()
                        .fadeIn(duration: const Duration(milliseconds: 700))
                        .slideX(begin: 0.3, duration: const Duration(milliseconds: 700)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Football preferences
                ModernCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Futbol Tercihlerin',
                        style: AppTypography.headlineSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Favorite League
                      _buildFavoriteLeagueField()
                        .animate()
                        .fadeIn(duration: const Duration(milliseconds: 800))
                        .slideX(begin: -0.3, duration: const Duration(milliseconds: 800)),
                      
                      const SizedBox(height: 16),
                      
                      // Favorite Team
                      _buildFavoriteTeamField()
                        .animate()
                        .fadeIn(duration: const Duration(milliseconds: 900))
                        .slideX(begin: 0.3, duration: const Duration(milliseconds: 900)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Bio
                ModernCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hakkında',
                        style: AppTypography.headlineSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      _buildBioField()
                        .animate()
                        .fadeIn(duration: const Duration(milliseconds: 1000))
                        .slideY(begin: 0.3, duration: const Duration(milliseconds: 1000)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Save button
                ModernButton(
                  text: 'Profili Tamamla',
                  onPressed: _isLoading ? null : _saveProfile,
                  isLoading: _isLoading,
                  isFullWidth: true,
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  icon: const Icon(Icons.check_circle),
                )
                .animate()
                .fadeIn(duration: const Duration(milliseconds: 1100))
                .scale(duration: const Duration(milliseconds: 1100)),
                
                const SizedBox(height: 16),
                
                // Skip button
                TextButton(
                  onPressed: _skipProfile,
                  child: Text(
                    'Şimdilik Geç',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
                .animate()
                .fadeIn(duration: const Duration(milliseconds: 1200)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.person_add,
            size: 40,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 24),
        
        Text(
          'Profilini Tamamla',
          style: AppTypography.headlineLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'Daha kişisel bir deneyim için profilini tamamla',
          style: AppTypography.bodyLarge.copyWith(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.grey[300] 
                : Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDisplayNameField() {
    return TextFormField(
      controller: _displayNameController,
      decoration: InputDecoration(
        labelText: 'Ad Soyad *',
        prefixIcon: const Icon(Icons.person_outline),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Lütfen adınızı girin';
        }
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      initialValue: _currentProfile?.email ?? '',
      enabled: false,
      decoration: InputDecoration(
        labelText: 'E-posta',
        prefixIcon: const Icon(Icons.email_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark 
            ? Colors.grey[800]?.withOpacity(0.3)
            : Colors.grey[100],
      ),
      style: TextStyle(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.grey[400]
            : Colors.grey[600],
      ),
    );
  }

  Widget _buildBirthDateField() {
    return InkWell(
      onTap: _selectBirthDate,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Doğum Tarihi',
          prefixIcon: const Icon(Icons.cake_outlined),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          _selectedBirthDate != null
              ? '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}'
              : 'Doğum tarihinizi seçin',
          style: TextStyle(
            color: _selectedBirthDate != null 
                ? null 
                : Theme.of(context).hintColor,
          ),
        ),
      ),
    );
  }

  Widget _buildLocationField() {
    return TextFormField(
      controller: _locationController,
      decoration: InputDecoration(
        labelText: 'Konum',
        prefixIcon: const Icon(Icons.location_on_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildFavoriteLeagueField() {
    return DropdownButtonFormField<String>(
      value: _selectedFavoriteLeague,
      decoration: InputDecoration(
        labelText: 'Favori Lig',
        prefixIcon: const Icon(Icons.emoji_events_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: _popularLeagues.map((league) {
        return DropdownMenuItem(
          value: league,
          child: Text(league),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedFavoriteLeague = value;
        });
      },
    );
  }

  Widget _buildFavoriteTeamField() {
    return DropdownButtonFormField<String>(
      value: _selectedFavoriteTeam,
      decoration: InputDecoration(
        labelText: 'Favori Takım',
        prefixIcon: const Icon(Icons.sports_soccer_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: _popularTeams.map((team) {
        return DropdownMenuItem(
          value: team,
          child: Text(team),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedFavoriteTeam = value;
        });
      },
    );
  }

  Widget _buildBioField() {
    return TextFormField(
      controller: _bioController,
      maxLines: 3,
      maxLength: 200,
      decoration: InputDecoration(
        labelText: 'Hakkında',
        prefixIcon: const Icon(Icons.edit_outlined),
        hintText: 'Kendin hakkında birkaç kelime...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
