import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'database_helper.dart';
import 'series.dart';
import 'main.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

    static const routeName = '/analytics';

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<Series> _allSeries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final series = await DatabaseHelper.instance.getAllSeries();
      setState(() {
        _allSeries = series;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // Calcola statistiche generali
  Map<String, int> get _generalStats {
    final total = _allSeries.length;
    final completed = _allSeries.where((s) => s.stato == 'Completata').length;
    final inProgress = _allSeries.where((s) => s.stato == 'In corso').length;
    final toWatch = _allSeries.where((s) => s.stato == 'Da guardare').length;
    
    return {
      'total': total,
      'completed': completed,
      'inProgress': inProgress,
      'toWatch': toWatch,
    };
  }

  // Calcola episodi visti per settimana/mese
  Map<String, double> get _viewingStats {
    final totalEpisodes = _allSeries.fold<int>(0, (sum, s) => sum + s.watchedEpisodes);
    final now = DateTime.now();
    
    // Calcola giorni dall'aggiunta della prima serie
    final oldestSeries = _allSeries
        .where((s) => s.dateAdded != null)
        .fold<DateTime?>(null, (oldest, s) {
      if (oldest == null) return s.dateAdded;
      return s.dateAdded!.isBefore(oldest) ? s.dateAdded : oldest;
    });
    
    final daysSinceStart = oldestSeries != null 
        ? now.difference(oldestSeries).inDays 
        : 1;
    
    final weeksActive = (daysSinceStart / 7).ceil();
    final monthsActive = (daysSinceStart / 30).ceil();
    
    return {
      'episodesPerWeek': weeksActive > 0 ? totalEpisodes / weeksActive : 0,
      'episodesPerMonth': monthsActive > 0 ? totalEpisodes / monthsActive : 0,
      'totalEpisodes': totalEpisodes.toDouble(),
    };
  }

  // Distribuzione per genere
  Map<String, int> get _genreDistribution {
    final distribution = <String, int>{};
    for (final series in _allSeries) {
      distribution[series.genere] = (distribution[series.genere] ?? 0) + 1;
    }
    return distribution;
  }

  // Distribuzione per piattaforma
  Map<String, int> get _platformDistribution {
    final distribution = <String, int>{};
    for (final series in _allSeries) {
      distribution[series.piattaforma] = (distribution[series.piattaforma] ?? 0) + 1;
    }
    return distribution;
  }

  // Serie più seguite (per episodi visti)
  List<Series> get _mostWatchedSeries {
    final sorted = List<Series>.from(_allSeries);
    sorted.sort((a, b) => b.watchedEpisodes.compareTo(a.watchedEpisodes));
    return sorted.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFB71C1C),
        title: const Text(
          'Analisi & Statistiche',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allSeries.isEmpty
              ? _buildEmptyState()
              : _buildAnalyticsContent(),
      bottomNavigationBar: CustomFooter(onSeriesAdded: _loadData),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 80, color: Colors.white70),
          SizedBox(height: 16),
          Text(
            'Nessuna serie da analizzare',
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
          SizedBox(height: 8),
          Text(
            'Aggiungi delle serie per vedere le statistiche',
            style: TextStyle(color: Colors.white54, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGeneralStatsSection(),
          const SizedBox(height: 24),
          _buildViewingStatsSection(),
          const SizedBox(height: 24),
          _buildDistributionSection(),
          const SizedBox(height: 24),
          _buildMostWatchedSection(),
          const SizedBox(height: 24),
          _buildProgressSection(),
          const SizedBox(height: 90),
        ],
      ),
    );
  }

  Widget _buildGeneralStatsSection() {
    final stats = _generalStats;
    
    return _buildSection(
      title: '📊 Statistiche Generali',
      child: Row(
        children: [
          Expanded(child: _buildStatCard('Totale', stats['total']!, Colors.blue)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('Completate', stats['completed']!, Colors.green)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('In Corso', stats['inProgress']!, Colors.orange)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('Da Guardare', stats['toWatch']!, Colors.red)),
        ],
      ),
    );
  }

  Widget _buildViewingStatsSection() {
    final stats = _viewingStats;
    
    return _buildSection(
      title: '⏱️ Statistiche Visione',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Episodi/Settimana', 
                  stats['episodesPerWeek']!.toStringAsFixed(1), 
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Episodi/Mese', 
                  stats['episodesPerMonth']!.toStringAsFixed(1), 
                  Colors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            'Episodi Totali Visti', 
            stats['totalEpisodes']!.toInt(), 
            Colors.indigo,
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionSection() {
    final genreData = _genreDistribution;
    final platformData = _platformDistribution;
    
    return _buildSection(
      title: '📈 Distribuzione',
      child: Column(
        children: [
          _buildChartContainer(
            title: 'Per Genere',
            child: _buildPieChart(genreData),
          ),
          const SizedBox(height: 16),
          _buildChartContainer(
            title: 'Per Piattaforma',
            child: _buildBarChart(platformData),
          ),
        ],
      ),
    );
  }

  Widget _buildMostWatchedSection() {
    final mostWatched = _mostWatchedSeries;
    
    return _buildSection(
      title: '🏆 Serie Più Seguite',
      child: Column(
        children: mostWatched.asMap().entries.map((entry) {
          final index = entry.key;
          final series = entry.value;
          return _buildMostWatchedTile(series, index + 1);
        }).toList(),
      ),
    );
  }

  Widget _buildProgressSection() {
    final seriesWithProgress = _allSeries
        .where((s) => s.totalEpisodes > 0)
        .toList()
      ..sort((a, b) => b.completionPercentage.compareTo(a.completionPercentage));
    
    return _buildSection(
      title: '📋 Progressi di Visione',
      child: Column(
        children: seriesWithProgress.take(10).map((series) {
          return _buildProgressTile(series);
        }).toList(),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF23272F),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, dynamic value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChartContainer({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF181c23),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildPieChart(Map<String, int> data) {
    if (data.isEmpty) {
      return const Center(
        child: Text('Nessun dato disponibile', style: TextStyle(color: Colors.white70)),
      );
    }

    final colors = [
      Colors.blue, Colors.green, Colors.orange, Colors.red, 
      Colors.purple, Colors.teal, Colors.pink, Colors.amber
    ];

    final List<PieChartSectionData> pieSections = [];
    int index = 0;
    data.forEach((label, value) {
      pieSections.add(
        PieChartSectionData(
          color: colors[index % colors.length],
          value: value.toDouble(),
          title: '$label\n$value',
          radius: 60,
          titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
        ),
      );
      index++;
    });

    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: pieSections,
          centerSpaceRadius: 40,
          sectionsSpace: 0,
        ),
      ),
    );
  }

  Widget _buildBarChart(Map<String, int> data) {
    if (data.isEmpty) {
      return const Center(
        child: Text('Nessun dato disponibile', style: TextStyle(color: Colors.white70)),
      );
    }

    final List<BarChartGroupData> barGroups = [];
    final List<String> labels = data.keys.toList();
    for (int i = 0; i < labels.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: data[labels[i]]!.toDouble(),
              color: const Color(0xFFB71C1C),
              width: 20,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          barGroups: barGroups,
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < labels.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        labels[index],
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label ($value)',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMostWatchedTile(Series series, int rank) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF181c23),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _getRankColor(rank),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              series.imageUrl,
              width: 40,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                width: 40,
                height: 60,
                color: Colors.grey[800],
                child: const Icon(Icons.broken_image, color: Colors.white70, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  series.title,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${series.watchedEpisodes} episodi visti',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTile(Series series) {
    final percentage = series.completionPercentage;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF181c23),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              series.imageUrl,
              width: 40,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                width: 40,
                height: 60,
                color: Colors.grey[800],
                child: const Icon(Icons.broken_image, color: Colors.white70, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  series.title,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${series.watchedEpisodes}/${series.totalEpisodes} episodi',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.grey[700],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    percentage == 100 ? Colors.green : const Color(0xFFB71C1C),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${percentage.toStringAsFixed(0)}%',
            style: TextStyle(
              color: percentage == 100 ? Colors.green : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1: return Colors.amber;
      case 2: return Colors.grey[400]!;
      case 3: return Colors.orange[700]!;
      default: return const Color(0xFFB71C1C);
    }
  }
}

// Classe helper per i dati dei grafici
class ChartData {
  final String name;
  final double value;

  ChartData(this.name, this.value);
}