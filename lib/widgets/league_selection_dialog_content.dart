// lib/widgets/league_selection_dialog_content.dart
import 'package:flutter/material.dart';
import 'package:futbol_analiz_app/utils.dart'; // capitalizeFirstLetterOfWordsUtils için

class LeagueSelectionDialogContent extends StatefulWidget {
  final List<String> availableLeagues;
  final String? currentSelectedLeague;

  const LeagueSelectionDialogContent({
    super.key,
    required this.availableLeagues,
    this.currentSelectedLeague,
  });

  @override
  State<LeagueSelectionDialogContent> createState() => _LeagueSelectionDialogContentState();
}

class _LeagueSelectionDialogContentState extends State<LeagueSelectionDialogContent> {
  List<String> _filteredLeagues = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredLeagues = List.from(widget.availableLeagues);
    _searchController.addListener(() {
      _filterLeagues();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterLeagues() {
    final query = _searchController.text.toLowerCase().trim();
    if (!mounted) return;
    setState(() {
      if (query.isEmpty) {
        _filteredLeagues = List.from(widget.availableLeagues);
      } else {
        _filteredLeagues = widget.availableLeagues
            .where((league) => league.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  // YENİ: Lig adından logo dosya yolunu oluşturan metot
  String _getLeagueLogoAssetName(String leagueName) {
    String normalized = leagueName.toLowerCase();
    const Map<String, String> charMap = { 'ı': 'i', 'ğ': 'g', 'ü': 'u', 'ş': 's', 'ö': 'o', 'ç': 'c', };
    charMap.forEach((trChar, engChar) { normalized = normalized.replaceAll(trChar, engChar); });
    normalized = normalized.replaceAll(' - ', '_').replaceAll(' ', '_').replaceAll(RegExp(r'[^\w_.-]'), '');
    normalized = normalized.replaceAll(RegExp(r'_+'), '_');
    if (normalized.startsWith('_')) {
      normalized = normalized.substring(1);
    }
    if (normalized.endsWith('_')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    if (normalized.isEmpty) return 'assets/logos/leagues/default_league_logo.png';
    return 'assets/logos/leagues/$normalized.png';
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Lig Ara...',
                prefixIcon: Icon(Icons.search, color: theme.inputDecorationTheme.prefixIconColor),
              ),
              style: theme.textTheme.bodyLarge,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _filteredLeagues.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        widget.availableLeagues.isEmpty
                            ? 'Lig bulunmuyor.'
                            : 'Arama kriterlerine uygun lig bulunamadı.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: _filteredLeagues.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      thickness: 0.5,
                      color: theme.dividerTheme.color ?? theme.dividerColor.withOpacity(0.5),
                      indent: 16,
                      endIndent: 16,
                    ),
                    itemBuilder: (context, index) {
                      final leagueName = _filteredLeagues[index];
                      final bool isSelected = leagueName == widget.currentSelectedLeague;
                      final String logoAssetPath = _getLeagueLogoAssetName(leagueName);

                      return ListTile(
                        // YENİ: leading özelliği ile logo eklendi
                        leading: Image.asset(
                          logoAssetPath,
                          width: 28,
                          height: 28,
                          fit: BoxFit.contain,
                          errorBuilder: (ctx, err, stack) => Icon(
                            Icons.shield_outlined,
                            size: 28,
                            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                          ),
                        ),
                        title: Text(
                          capitalizeFirstLetterOfWordsUtils(leagueName),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? theme.colorScheme.primary : null,
                          ),
                        ),
                        trailing: isSelected ? Icon(Icons.check_circle, color: theme.colorScheme.primary) : null,
                        onTap: () {
                          Navigator.pop(context, leagueName);
                        },
                      );
                    },
                  ),
          ),
        ],
      );
  }
}