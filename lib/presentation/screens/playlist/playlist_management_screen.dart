import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiwee/business_logic/provider/cloud_functions_provider.dart';
import 'package:tiwee/presentation/widgets/main_appbar.dart';

class PlaylistManagementScreen extends ConsumerStatefulWidget {
  const PlaylistManagementScreen({super.key});

  @override
  ConsumerState<PlaylistManagementScreen> createState() => _PlaylistManagementScreenState();
}

class _PlaylistManagementScreenState extends ConsumerState<PlaylistManagementScreen> {
  final _urlController = TextEditingController();
  String? _selectedPlaylistUrl;
  bool _showAdvancedOptions = false;
  bool _autoRefresh = false;
  int _refreshInterval = 5; // minutes
  String _selectedGroup = 'Todos';
  String _searchQuery = '';

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppbar(
        widget: Row(
          children: [
            const Text(
              'Gerenciar Playlists',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () => _showSettingsDialog(context),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildUrlInput(),
              const SizedBox(height: 16),
              if (_selectedPlaylistUrl != null) ...[
                _buildSearchAndFilter(),
                const SizedBox(height: 16),
                _buildDashboard(),
                const SizedBox(height: 16),
                _buildStreamStatusTable(),
                const SizedBox(height: 16),
                _buildCompressionChart(),
                if (_showAdvancedOptions) ...[
                  const SizedBox(height: 16),
                  _buildAdvancedOptions(),
                ],
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: _selectedPlaylistUrl != null
          ? FloatingActionButton(
              onPressed: () => _showExportOptions(context),
              child: const Icon(Icons.download),
            )
          : null,
    );
  }

  Widget _buildUrlInput() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'URL da Playlist',
                hintText: 'Digite a URL da playlist M3U',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _selectedPlaylistUrl != null
                      ? () => setState(() {})
                      : null,
                ),
              ),
              onSubmitted: (value) {
                setState(() {
                  _selectedPlaylistUrl = value;
                });
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showFilePicker(),
                    icon: const Icon(Icons.file_upload),
                    label: const Text('Importar Arquivo'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showPasteDialog(),
                    icon: const Icon(Icons.paste),
                    label: const Text('Colar Conteúdo'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar',
                hintText: 'Buscar por nome ou URL',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedGroup,
              decoration: const InputDecoration(
                labelText: 'Filtrar por Grupo',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                DropdownMenuItem(value: 'TV', child: Text('TV')),
                DropdownMenuItem(value: 'Movies', child: Text('Filmes')),
                DropdownMenuItem(value: 'Series', child: Text('Séries')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedGroup = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedOptions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Opções Avançadas',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Atualização Automática'),
              subtitle: Text('Atualizar a cada $_refreshInterval minutos'),
              value: _autoRefresh,
              onChanged: (value) {
                setState(() {
                  _autoRefresh = value;
                });
              },
            ),
            if (_autoRefresh)
              Slider(
                value: _refreshInterval.toDouble(),
                min: 1,
                max: 60,
                divisions: 59,
                label: '$_refreshInterval minutos',
                onChanged: (value) {
                  setState(() {
                    _refreshInterval = value.round();
                  });
                },
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Análise de Qualidade'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showQualityAnalysis(),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Histórico de Alterações'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showChangeHistory(),
            ),
            ListTile(
              leading: const Icon(Icons.backup),
              title: const Text('Backup da Playlist'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showBackupOptions(),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configurações'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Mostrar Opções Avançadas'),
              value: _showAdvancedOptions,
              onChanged: (value) {
                setState(() {
                  _showAdvancedOptions = value;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Tema'),
              trailing: const Icon(Icons.color_lens),
              onTap: () {
                // Implement theme selection
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Notificações'),
              trailing: const Icon(Icons.notifications),
              onTap: () {
                // Implement notification settings
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _showExportOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exportar Playlist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.file_download),
              title: const Text('M3U'),
              onTap: () {
                // Implement M3U export
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_download),
              title: const Text('JSON'),
              onTap: () {
                // Implement JSON export
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_download),
              title: const Text('CSV'),
              onTap: () {
                // Implement CSV export
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _showFilePicker() {
    // Implement file picker
  }

  void _showPasteDialog() {
    // Implement paste dialog
  }

  void _showQualityAnalysis() {
    // Implement quality analysis
  }

  void _showChangeHistory() {
    // Implement change history
  }

  void _showBackupOptions() {
    // Implement backup options
  }

  Widget _buildDashboard() {
    final validationAsync = ref.watch(playlistValidationProvider(_selectedPlaylistUrl!));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            validationAsync.when(
              data: (validation) => GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _buildStatCard(
                    'Total',
                    validation.stats.total.toString(),
                    Icons.stream,
                    Colors.blue,
                  ),
                  _buildStatCard(
                    'TV',
                    validation.stats.tv.toString(),
                    Icons.tv,
                    Colors.green,
                  ),
                  _buildStatCard(
                    'Filmes',
                    validation.stats.movies.toString(),
                    Icons.movie,
                    Colors.orange,
                  ),
                  _buildStatCard(
                    'Séries',
                    validation.stats.series.toString(),
                    Icons.video_library,
                    Colors.purple,
                  ),
                  _buildStatCard(
                    'Inválidos',
                    validation.stats.invalid.toString(),
                    Icons.error,
                    Colors.red,
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text(
                'Erro: ${error.toString()}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamStatusTable() {
    final monitoringAsync = ref.watch(streamMonitoringProvider(_selectedPlaylistUrl!));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status dos Streams',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            monitoringAsync.when(
              data: (data) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Título')),
                    DataColumn(label: Text('URL')),
                    DataColumn(label: Text('Status')),
                  ],
                  rows: (data['results'] as List).map((result) {
                    final status = result['status'];
                    final color = status == 'online' ? Colors.green : Colors.red;
                    return DataRow(
                      cells: [
                        DataCell(Text(result['title'] ?? 'N/A')),
                        DataCell(Text(result['url'])),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                status == 'online' ? Icons.check_circle : Icons.error,
                                color: color,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                status,
                                style: TextStyle(color: color),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text(
                'Erro: ${error.toString()}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompressionChart() {
    final compressionAsync = ref.watch(playlistCompressionProvider(_selectedPlaylistUrl!));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Compressão',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            compressionAsync.when(
              data: (data) => Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildCompressionStat(
                        'Original',
                        '${(data['originalSize'] / 1024).toStringAsFixed(2)} KB',
                        Colors.blue,
                      ),
                      _buildCompressionStat(
                        'Comprimido',
                        '${(data['compressedSize'] / 1024).toStringAsFixed(2)} KB',
                        Colors.green,
                      ),
                      _buildCompressionStat(
                        'Taxa',
                        '${data['compressionRatio']}x',
                        Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: data['compressedSize'] / data['originalSize'],
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text(
                'Erro: ${error.toString()}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompressionStat(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
} 