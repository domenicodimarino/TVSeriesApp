import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'database_helper.dart';
import 'series.dart';
import 'main.dart';
import 'widgets/series_image.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  static const routeName = '/analytics';

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<Series> _allSeries = [];
  bool _isLoading = true;
  Map<String, dynamic> _monthlyStats = {};
  Map<String, dynamic> _weeklyStats = {};
  Map<String, int> _platformStats = {};
  int _totalCompleted = 0;
  int _inProgress = 0;
  int? _touchedIndex;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      
      final series = await DatabaseHelper.instance.getAllSeries();
      final monthly = await DatabaseHelper.instance.getMonthlyStats(now.year, now.month);
      final weekly = await DatabaseHelper.instance.getWeeklyStats(now);
      final platforms = await DatabaseHelper.instance.getPlatformStats();
      final completed = await DatabaseHelper.instance.getTotalCompletedSeries();
      final inProgress = await DatabaseHelper.instance.getTotalInProgressSeries();

      final platformStatsInt = <String, int>{};
      platforms.forEach((key, value) {
        platformStatsInt[key] = value is int ? value : int.tryParse(value.toString()) ?? 0;
      });

      setState(() {
        _allSeries = series;
        _monthlyStats = monthly;
        _weeklyStats = weekly;
        _platformStats = platformStatsInt;
        _totalCompleted = completed;
        _inProgress = inProgress;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Map<String, int> get _generalStats {
    final total = _allSeries.length;
    final toWatch = total - _totalCompleted - _inProgress;
    
    return {
      'total': total,
      'completed': _totalCompleted,
      'inProgress': _inProgress,
      'toWatch': toWatch > 0 ? toWatch : 0,
    };
  }

  Map<String, int> get _genreDistribution {
    final distribution = <String, int>{};
    for (final series in _allSeries) {
      final genres = series.genere.split(',').map((g) => g.trim().toLowerCase());
      for (final genre in genres) {
        if (genre.isNotEmpty) {
          distribution[genre] = (distribution[genre] ?? 0) + 1;
        }
      }
    }
    return distribution;
  }

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
          _buildTimeStatsSection(),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth < 500 ? 2 : 4;

    return _buildSection(
      title: '📊 Statistiche generali',
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: crossAxisCount,
        childAspectRatio: 1.5,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: [
          _buildStatCard('Totale', stats['total']!, Colors.blue),
          _buildStatCard('Completate', stats['completed']!, Colors.green),
          _buildStatCard('In Corso', stats['inProgress']!, Colors.orange),
          _buildStatCard('Da Guardare', stats['toWatch']!, Colors.red),
        ],
      ),
    );
  }

  Widget _buildTimeStatsSection() {
    return _buildSection(
      title: '⏱️ Statistiche temporali',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Completate Settimana', 
                  _weeklyStats['completed'] ?? 0, 
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Completate Mese', 
                  _monthlyStats['completed'] ?? 0, 
                  Colors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Aggiunte Settimana', 
                  _weeklyStats['added'] ?? 0, 
                  Colors.indigo,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Aggiunte Mese', 
                  _monthlyStats['added'] ?? 0, 
                  Colors.amber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionSection() {
    final genreData = _genreDistribution;
    final platformData = _platformStats;
    
    return _buildSection(
      title: '📈 Distribuzione',
      child: Column(
        children: [
          _buildChartContainer(
            title: 'Per genere',
            child: _buildPieChart(genreData),
          ),
          const SizedBox(height: 16),
          _buildChartContainer(
            title: 'Per piattaforma',
            child: _buildBarChart(platformData),
          ),
        ],
      ),
    );
  }

  Widget _buildMostWatchedSection() {
    final mostWatched = _mostWatchedSeries;
    
    return _buildSection(
      title: '🏆 Serie più seguite',
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
      title: '📋 Progressi di visione',
      child: Column(
        children: seriesWithProgress.take(10).map((series) {
          return _buildProgressTile(series);
        }).toList(),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth < 400 ? 8.0 : 16.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF23272F),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: screenWidth < 400 ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: padding),
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
        mainAxisAlignment: MainAxisAlignment.center,
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildChartContainer({required String title, required Widget child}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isPortrait = screenHeight > screenWidth;
    
    final horizontalPadding = screenWidth < 400 ? 8.0 : 16.0;
    // Aumenta il padding verticale in modalità portrait
    final verticalPadding = isPortrait ? 24.0 : (screenWidth < 400 ? 8.0 : 12.0);
    final titleFontSize = screenWidth < 400 ? 12.0 : 14.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF181c23),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: titleFontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: isPortrait ? verticalPadding : verticalPadding/2),
          child,
          // Aggiunta di spazio extra in fondo in modalità portrait
          if (isPortrait) SizedBox(height: 12.0),
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
    // Per rendere maiuscola la prima lettera del genere
    final List<String> labels = data.keys
        .map((g) => g.isNotEmpty ? g[0].toUpperCase() + g.substring(1) : g)
        .toList();
    int index = 0;
    
    data.forEach((label, value) {
      final isTouched = index == _touchedIndex;
      final fontSize = isTouched ? 16.0 : 14.0;
      final radius = isTouched ? 70.0 : 60.0;
      
      pieSections.add(
        PieChartSectionData(
          color: colors[index % colors.length],
          value: value.toDouble(),
          title: '$value',
          radius: radius,
          titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: isTouched ? FontWeight.bold : FontWeight.normal,
            color: Colors.white,
          ),
        ),
      );
      index++;
    });

    return SizedBox(
      height: MediaQuery.of(context).size.width < 400 ? 160 : 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      _touchedIndex = null;
                      return;
                    }
                    final touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    if (touchedIndex >= 0 && touchedIndex < labels.length) {
                      _touchedIndex = touchedIndex;
                    } else {
                      _touchedIndex = null;
                    }
                  });
                },
              ),
              sections: pieSections,
              centerSpaceRadius: 40,
              sectionsSpace: 0,
            ),
          ),
          if (_touchedIndex != null && _touchedIndex! >= 0 && _touchedIndex! < labels.length)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Text(
                labels[_touchedIndex!], // Mostra la label capitalizzata
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBarChart(Map<String, int> data) {
    if (data.isEmpty) {
      return const Center(
        child: Text('Nessun dato disponibile', style: TextStyle(color: Colors.white70)),
      );
    }

    final labels = data.keys.toList();
    final values = data.values.toList();
    final total = values.fold<int>(0, (sum, v) => sum + v);
    final barHeight = 32.0;

    return Column(
      children: List.generate(labels.length, (i) {
        final percent = total == 0 ? 0.0 : (values[i] / total * 100);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            children: [
              // Label piattaforma
              SizedBox(
                width: 110,
                child: Text(
                  labels[i],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // Barra
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: percent / 100,
                    child: Container(
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB71C1C),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Percentuale
              SizedBox(
                width: 60,
                child: Text(
                  '${percent.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }),
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
            child: SeriesImage(
              series: series,
              width: 40,
              height: 60,
              borderRadius: BorderRadius.circular(4),
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
            child: SeriesImage(
              series: series,
              width: 40,
              height: 60,
              borderRadius: BorderRadius.circular(4),
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