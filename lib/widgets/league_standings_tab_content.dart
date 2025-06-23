// lib/widgets/league_standings_tab_content.dart (EKSİK PARAMETRE EKLENDİ)
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

const double _kFixedColumnWidth = 150.0;
const double _kCellWidth = 42.0;
const double _kFormCellWidth = 80.0;
const double _kRowHeight = 52.0;
const double _kLogoSize = 26.0;

class StandingsTableWidget extends StatelessWidget {
  final ThemeData theme;
  final List<Map<String, dynamic>> standingsData;
  final Function(BuildContext, Map<String, dynamic>) onTeamTap;
  // EKSİK OLAN ve ŞİMDİ EKLENEN PARAMETRE:
  final String leagueName; 

  const StandingsTableWidget({
    super.key,
    required this.theme,
    required this.standingsData,
    required this.onTeamTap,
    required this.leagueName, // Constructor'a da eklendi
  });

  @override
  Widget build(BuildContext context) {
    if (standingsData.isEmpty) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text("Puan durumu verisi yok.", style: theme.textTheme.bodyMedium)));
    }

    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFixedColumn(context),
          Expanded(
            child: SingleChildScrollView(
              // Her tabloya kendi benzersiz anahtarını veriyoruz.
              key: PageStorageKey<String>('scrollable_standings_$leagueName'),
              scrollDirection: Axis.horizontal,
              child: _buildScrollableColumns(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedColumn(BuildContext context) {
    final headerStyle = theme.textTheme.bodySmall!.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8));
    return SizedBox(
      width: _kFixedColumnWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              height: _kRowHeight,
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: theme.dividerColor, width: 0.5))),
              child: Row(children: [
                SizedBox(width: 28, child: Text('#', style: headerStyle, textAlign: TextAlign.center)),
                const SizedBox(width: 4),
                Expanded(child: Text('Takım', style: headerStyle)),
              ])),
          ...List.generate(standingsData.length, (index) {
            final teamData = standingsData[index];
            final bool isEvenRow = (index) % 2 != 0;
            return InkWell(
              onTap: () => onTeamTap(context, teamData),
              child: Container(
                  height: _kRowHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  color: isEvenRow ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.15) : null,
                  child: Row(children: [
                    SizedBox(width: 28,
                        child: Text(teamData['pos'].toString(),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500))),
                    const SizedBox(width: 4),
                    if (teamData['logo_url'] != null)
                      Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: CachedNetworkImage(
                              imageUrl: teamData['logo_url'],
                              width: _kLogoSize,
                              height: _kLogoSize,
                              fit: BoxFit.contain,
                              placeholder: (c, u) => const SizedBox(width: _kLogoSize, height: _kLogoSize),
                              errorWidget: (c, u, e) => Icon(Icons.shield_outlined, size: _kLogoSize)))
                    else
                      Padding(padding: const EdgeInsets.only(right: 8.0),
                          child: Icon(Icons.shield, size: _kLogoSize,
                              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.15))),
                    Expanded(
                        child: Text(teamData['teamDisplayName'],
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)))
                  ])),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildScrollableColumns(BuildContext context) {
    final headerStyle = theme.textTheme.bodySmall!.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8));
    final pointStyle =
    theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary);

    Widget buildStatCell(Widget child, double width) =>
        SizedBox(width: width, height: _kRowHeight, child: Center(child: child));

    Widget buildFormIcons(List<Map<String, dynamic>> formMatches) {
      List<Widget> formWidgets = [];
      final matchesToDisplay = formMatches.take(3).toList();
      for (int i = 0; i < 3; i++) {
        if (i < matchesToDisplay.length) {
          final match = matchesToDisplay[i];
          final bool isMostRecent = (i == 0);
          IconData iconData;
          Color iconColor;
          String result = match['result']?.toString() ?? "";
          if (result.startsWith("G")) {
            iconData = Icons.check_circle_rounded; iconColor = Colors.green.shade500;
          } else if (result.startsWith("B")) {
            iconData = Icons.remove_circle_rounded; iconColor = Colors.grey.shade500;
          } else if (result.startsWith("M")) {
            iconData = Icons.cancel_rounded; iconColor = Colors.red.shade500;
          } else {
            iconData = Icons.circle_outlined; iconColor = Colors.grey.shade400;
          }
          Widget iconWidget = Icon(iconData, color: iconColor, size: 18);
          if (isMostRecent) {
            iconWidget = Container(
                padding: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: iconColor.withOpacity(0.8), width: 1.5)),
                child: iconWidget);
          }
          formWidgets.add(Padding(padding: const EdgeInsets.symmetric(horizontal: 3.0), child: iconWidget));
        } else {
          formWidgets.add(Padding(padding: const EdgeInsets.symmetric(horizontal: 3.0),
              child: Icon(Icons.remove, color: Colors.grey.shade300, size: 18)));
        }
      }
      return Row(mainAxisAlignment: MainAxisAlignment.center, children: formWidgets);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
            height: _kRowHeight,
            decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: theme.dividerColor, width: 0.5))),
            child: Row(children: [
              buildStatCell(Text('OM', style: headerStyle), _kCellWidth),
              buildStatCell(Text('G', style: headerStyle), _kCellWidth),
              buildStatCell(Text('B', style: headerStyle), _kCellWidth),
              buildStatCell(Text('M', style: headerStyle), _kCellWidth),
              buildStatCell(Text('P', style: headerStyle), _kCellWidth),
              buildStatCell(Text('AG', style: headerStyle), _kCellWidth),
              buildStatCell(Text('YG', style: headerStyle), _kCellWidth),
              buildStatCell(Text('A', style: headerStyle), _kCellWidth),
              buildStatCell(Text('Son 3', style: headerStyle), _kFormCellWidth)
            ])),
        ...List.generate(standingsData.length, (index) {
          final teamData = standingsData[index];
          final bool isEvenRow = (index) % 2 != 0;
          return InkWell(
              onTap: () => onTeamTap(context, teamData),
              child: Container(
                  color: isEvenRow ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.15) : null,
                  child: Row(children: [
                    buildStatCell(Text(teamData['om'].toString()), _kCellWidth),
                    buildStatCell(Text(teamData['g'].toString()), _kCellWidth),
                    buildStatCell(Text(teamData['b'].toString()), _kCellWidth),
                    buildStatCell(Text(teamData['m'].toString()), _kCellWidth),
                    buildStatCell(Text(teamData['pts'].toString(), style: pointStyle), _kCellWidth),
                    buildStatCell(Text(teamData['ag'].toString()), _kCellWidth),
                    buildStatCell(Text(teamData['yg'].toString()), _kCellWidth),
                    buildStatCell(Text(teamData['a'].toString()), _kCellWidth),
                    buildStatCell(buildFormIcons(teamData['formMatches']), _kFormCellWidth)
                  ])));
        }),
      ],
    );
  }
}