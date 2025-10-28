// lib/widgets/profile_image_picker.dart
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_spacing.dart';
import '../design_system/app_typography.dart';
import '../services/user_service.dart';
import '../services/profile_update_service.dart';
import '../services/user_profile_service.dart';
import '../services/auth_service.dart';

class ProfileImagePicker extends StatefulWidget {
  final String? initialImagePath;
  final Function(String?)? onImageChanged;
  final double size;
  final String? networkImageUrl;

  const ProfileImagePicker({
    Key? key,
    this.initialImagePath,
    this.onImageChanged,
    this.size = 100,
    this.networkImageUrl,
  }) : super(key: key);

  @override
  State<ProfileImagePicker> createState() => _ProfileImagePickerState();
}

class _ProfileImagePickerState extends State<ProfileImagePicker> {
  String? _imagePath;
  late StreamSubscription _profileUpdateSubscription;

  @override
  void initState() {
    super.initState();
    _imagePath = widget.initialImagePath;
    _loadCurrentProfileImage();
    
    // Profil güncellemelerini dinle
    _profileUpdateSubscription = ProfileUpdateService.updates.listen((event) {
      if (event.type == ProfileUpdateType.signOut) {
        // Çıkış yapıldığında profil fotoğrafını temizle
        if (mounted) {
          setState(() {
            _imagePath = null;
          });
        }
      } else if (event.type == ProfileUpdateType.profileImage) {
        // Profil fotoğrafı güncellendiğinde yenile
        if (mounted) {
          setState(() {
            _imagePath = event.data['imagePath'];
          });
        }
      }
    });
  }

  Future<void> _loadCurrentProfileImage() async {
    try {
      String? currentImagePath;
      
      // Kullanıcı giriş yapmışsa UserProfileService'ten al
      if (AuthService.isSignedIn) {
        final userProfileService = UserProfileService();
        final profile = await userProfileService.loadUserProfile();
        currentImagePath = profile?.photoURL;
      }
      
      // Eğer UserProfileService'ten alamadıysak UserService'ten dene
      if (currentImagePath == null || currentImagePath.isEmpty) {
        currentImagePath = await UserService.getProfileImagePath();
      }
      
      if (mounted && currentImagePath != null && currentImagePath.isNotEmpty) {
        setState(() {
          _imagePath = currentImagePath;
        });
      }
    } catch (e) {
      print('Profil fotoğrafı yüklenirken hata: $e');
    }
  }

  @override
  void didUpdateWidget(ProfileImagePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialImagePath != oldWidget.initialImagePath) {
      setState(() {
        _imagePath = widget.initialImagePath;
      });
    }
  }

  @override
  void dispose() {
    _profileUpdateSubscription.cancel();
    super.dispose();
  }

  Widget _buildImageWidget() {
    // Priority: Local file > Network image > Default avatar
    if (_imagePath != null) {
      return ClipOval(
        child: Image.file(
          File(_imagePath!),
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildNetworkOrDefaultImage();
          },
        ),
      );
    } else if (widget.networkImageUrl != null && widget.networkImageUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          widget.networkImageUrl!,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildDefaultAvatar();
          },
        ),
      );
    } else {
      return _buildDefaultAvatar();
    }
  }

  Widget _buildNetworkOrDefaultImage() {
    if (widget.networkImageUrl != null && widget.networkImageUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          widget.networkImageUrl!,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar();
          },
        ),
      );
    } else {
      return _buildDefaultAvatar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showImagePickerOptions(context),
      child: Stack(
        children: [
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _imagePath != null ? null : AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: _buildImageWidget(),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Icon(
      Icons.person,
      size: widget.size * 0.5,
      color: Colors.white,
    );
  }

  void _showImagePickerOptions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                Text(
                  'Profil Fotoğrafı',
                  style: AppTypography.headlineSmall.copyWith(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    fontWeight: AppTypography.bold,
                  ),
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Geçici olarak sadece kaldır seçeneği
                Text(
                  'Profil fotoğrafı özelliği geliştiriliyor...',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildOptionButton(
                      context,
                      'Galeri',
                      Icons.photo_library,
                      () => _pickFromGallery(context),
                    ),
                    _buildOptionButton(
                      context,
                      'Kamera',
                      Icons.camera_alt,
                      () => _takeFromCamera(context),
                    ),
                    if (_imagePath != null)
                      _buildOptionButton(
                        context,
                        'Kaldır',
                        Icons.delete,
                        () => _removePhoto(context),
                        isDestructive: true,
                      ),
                  ],
                ),
                
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveSelectedImage(BuildContext context, String imagePath) async {
    try {
      String? savedPath;
      
      // Kullanıcı giriş yapmışsa UserProfileService kullan
      if (AuthService.isSignedIn) {
        final userProfileService = UserProfileService();
        savedPath = await userProfileService.updateProfileImage(imagePath);
        
        // UserService'e de kaydet (senkronizasyon için)
        if (savedPath != null) {
          await UserService.saveProfileImageFromPath(savedPath);
        }
      } else {
        // Giriş yapmamışsa UserService kullan
        savedPath = await UserService.saveProfileImageFromPath(imagePath);
      }
      
      if (savedPath != null) {
        setState(() {
          _imagePath = savedPath;
        });
        widget.onImageChanged?.call(savedPath);
        
        // Profil fotoğrafı güncellendiğini bildir
        ProfileUpdateService.notifyProfileImageUpdated(savedPath);
        
        // Başarı mesajı göster
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil fotoğrafı başarıyla güncellendi'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        throw Exception('Fotoğraf kaydedilemedi');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fotoğraf kaydetme hatası: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildOptionButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDestructive ? AppColors.error : AppColors.primary;
    
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          
          const SizedBox(height: AppSpacing.sm),
          
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }



  Future<void> _pickFromGallery(BuildContext context) async {
    Navigator.pop(context);
    
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 512,
        maxHeight: 512,
      );
      
      if (pickedFile != null) {
        await _saveSelectedImage(context, pickedFile.path);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Galeri hatası: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _takeFromCamera(BuildContext context) async {
    Navigator.pop(context);
    
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 512,
        maxHeight: 512,
      );
      
      if (pickedFile != null) {
        await _saveSelectedImage(context, pickedFile.path);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kamera hatası: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _removePhoto(BuildContext context) async {
    Navigator.pop(context);
    
    try {
      // Kullanıcı giriş yapmışsa UserProfileService kullan
      if (AuthService.isSignedIn) {
        final userProfileService = UserProfileService();
        await userProfileService.removeProfileImage();
        
        // UserService'ten de sil (senkronizasyon için)
        await UserService.deleteProfileImage();
      } else {
        // Giriş yapmamışsa UserService kullan
        await UserService.deleteProfileImage();
      }
      
      setState(() {
        _imagePath = null;
      });
      widget.onImageChanged?.call(null);
      
      // Profil fotoğrafı kaldırıldığını bildir
      ProfileUpdateService.notifyProfileImageUpdated(null);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil fotoğrafı kaldırıldı'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fotoğraf kaldırma hatası: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}