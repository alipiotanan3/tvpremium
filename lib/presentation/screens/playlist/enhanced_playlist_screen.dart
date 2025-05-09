import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiwee/business_logic/provider/cloud_functions_provider.dart';
import 'package:tiwee/presentation/widgets/main_appbar.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tiwee/business_logic/provider/playlist_management_provider.dart';
import 'package:tiwee/business_logic/model/playlist_quality.dart';
import 'package:tiwee/business_logic/model/playlist_history.dart';
import 'package:tiwee/business_logic/model/playlist_tag.dart';
import 'package:tiwee/business_logic/provider/tag_management_provider.dart';
import 'package:tiwee/business_logic/provider/stream_quality_preferences_provider.dart';
import 'package:tiwee/business_logic/provider/user_permission_provider.dart';
import 'package:tiwee/business_logic/model/user_role.dart';

class EnhancedPlaylistScreen extends ConsumerStatefulWidget {
  const EnhancedPlaylistScreen({super.key});

  @override
  ConsumerState<EnhancedPlaylistScreen> createState() => _EnhancedPlaylistScreenState();
}

class _EnhancedPlaylistScreenState extends ConsumerState<EnhancedPlaylistScreen> {
  final _urlController = TextEditingController();
  String? _selectedPlaylistUrl;
  bool _showAdvancedOptions = false;
  bool _autoRefresh = false;
  int _refreshInterval = 30;
  String? _selectedGroup;
  String _searchQuery = '';
  String? _playlistContent;

  @override
  void initState() {
    super.initState();
  }

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
              onPressed: _showSettingsDialog,
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUrlInput(),
            const SizedBox(height: 16),
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
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showExportOptions,
        child: const Icon(Icons.file_download),
      ),
    );
  }

  Widget _buildUrlInput() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Playlist URL',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      hintText: 'Enter playlist URL',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    // TODO: Implement refresh
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.file_upload),
                  onPressed: _showFilePicker,
                ),
                IconButton(
                  icon: const Icon(Icons.content_paste),
                  onPressed: _showPasteDialog,
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Search & Filter',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search streams...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedGroup,
                  hint: const Text('Group'),
                  items: const [
                    DropdownMenuItem(value: 'tv', child: Text('TV')),
                    DropdownMenuItem(value: 'movies', child: Text('Movies')),
                    DropdownMenuItem(value: 'series', child: Text('Series')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedGroup = value;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    final validationAsync = ref.watch(playlistValidationProvider(_selectedPlaylistUrl!));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 18,
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Stream Status',
              style: TextStyle(
                fontSize: 18,
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Compression',
              style: TextStyle(
                fontSize: 18,
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
                      _buildCompressionInfo(
                        'Original',
                        '${(data['originalSize'] / 1024).toStringAsFixed(2)} KB',
                        Colors.blue,
                      ),
                      _buildCompressionInfo(
                        'Comprimido',
                        '${(data['compressedSize'] / 1024).toStringAsFixed(2)} KB',
                        Colors.green,
                      ),
                      _buildCompressionInfo(
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
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
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

  Widget _buildCompressionInfo(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedOptions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Advanced Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Auto-refresh'),
              subtitle: const Text('Automatically refresh playlist'),
              value: _autoRefresh,
              onChanged: (value) {
                setState(() {
                  _autoRefresh = value;
                });
              },
            ),
            if (_autoRefresh)
              ListTile(
                title: const Text('Refresh Interval'),
                subtitle: Slider(
                  value: _refreshInterval.toDouble(),
                  min: 5,
                  max: 60,
                  divisions: 11,
                  label: '$_refreshInterval minutes',
                  onChanged: (value) {
                    setState(() {
                      _refreshInterval = value.round();
                    });
                  },
                ),
              ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Quality Analysis'),
              onTap: () {
                if (_selectedPlaylistUrl != null) {
                  _showQualityAnalysis(_selectedPlaylistUrl!);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Change History'),
              onTap: () {
                if (_selectedPlaylistUrl != null) {
                  _showChangeHistory(_selectedPlaylistUrl!);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.backup),
              title: const Text('Backup Options'),
              onTap: () {
                if (_selectedPlaylistUrl != null) {
                  _showBackupOptions(_selectedPlaylistUrl!);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.label),
              title: const Text('Manage Tags'),
              onTap: () {
                if (_selectedPlaylistUrl != null) {
                  _showTagManagement(_selectedPlaylistUrl!);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Quality Preferences'),
              onTap: _showQualityPreferences,
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('User Permissions'),
              onTap: _showUserPermissions,
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
        title: const Text('Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Advanced Options'),
              value: _showAdvancedOptions,
              onChanged: (value) {
                setState(() {
                  _showAdvancedOptions = value;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Theme'),
              trailing: const Icon(Icons.color_lens),
              onTap: () {
                // TODO: Implement theme selection
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Notifications'),
              trailing: const Icon(Icons.notifications),
              onTap: () {
                // TODO: Implement notification settings
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showFilePicker() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['m3u', 'm3u8', 'txt'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        setState(() {
          _playlistContent = content;
          _urlController.text = result.files.single.path!;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick file: $e')),
      );
    }
  }

  Future<void> _showPasteDialog() async {
    final controller = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paste Content'),
        content: TextField(
          controller: controller,
          maxLines: 10,
          decoration: const InputDecoration(
            hintText: 'Paste your playlist content here...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _playlistContent = controller.text;
                _urlController.text = 'Pasted Content';
              });
              Navigator.pop(context);
            },
            child: const Text('Paste'),
          ),
        ],
      ),
    );
  }

  Future<void> _showExportOptions() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.music_note),
              title: const Text('M3U Format'),
              onTap: () async {
                Navigator.pop(context);
                await _exportPlaylist('m3u');
              },
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('JSON Format'),
              onTap: () async {
                Navigator.pop(context);
                await _exportPlaylist('json');
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('CSV Format'),
              onTap: () async {
                Navigator.pop(context);
                await _exportPlaylist('csv');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPlaylist(String format) async {
    if (_playlistContent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No playlist content to export')),
      );
      return;
    }

    try {
      String content;
      String extension;
      String mimeType;

      switch (format) {
        case 'm3u':
          content = _playlistContent!;
          extension = 'm3u';
          mimeType = 'audio/x-mpegurl';
          break;
        case 'json':
          content = jsonEncode({
            'playlist': _playlistContent!.split('\n'),
            'exported': DateTime.now().toIso8601String(),
          });
          extension = 'json';
          mimeType = 'application/json';
          break;
        case 'csv':
          content = _playlistContent!
              .split('\n')
              .where((line) => line.trim().startsWith('http'))
              .join('\n');
          extension = 'csv';
          mimeType = 'text/csv';
          break;
        default:
          throw Exception('Unsupported format');
      }

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/playlist.$extension');
      await file.writeAsString(content);

      await Share.shareXFiles(
        [XFile(file.path)],
        mimeTypes: [mimeType],
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export playlist: $e')),
      );
    }
  }

  Future<void> _showQualityAnalysis(String streamUrl) async {
    try {
      final quality = await ref.read(playlistQualityProvider(streamUrl).future);
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Stream Quality Analysis'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQualityInfo('Bitrate', '${quality.bitrate.toStringAsFixed(2)} kbps'),
                _buildQualityInfo('Resolution', quality.resolution),
                _buildQualityInfo('Frame Rate', '${quality.frameRate} fps'),
                _buildQualityInfo('Codec', quality.codec),
                _buildQualityInfo('Quality', quality.quality),
                if (quality.isHD) _buildQualityInfo('HD', 'Yes'),
                if (quality.is4K) _buildQualityInfo('4K', 'Yes'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to analyze stream: $e')),
      );
    }
  }

  Widget _buildQualityInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  Future<void> _showChangeHistory(String playlistUrl) async {
    try {
      final history = await ref.read(playlistHistoryProvider(playlistUrl).future);
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Change History'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: history.length,
              itemBuilder: (context, index) {
                final entry = history[index];
                return ListTile(
                  title: Text(entry.action),
                  subtitle: Text(entry.details),
                  trailing: Text(_formatDate(entry.timestamp)),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load history: $e')),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  Future<void> _showBackupOptions(String playlistUrl) async {
    try {
      final backups = await ref.read(playlistBackupsProvider(playlistUrl).future);
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Backup Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _createBackup(playlistUrl);
                },
                child: const Text('Create Backup'),
              ),
              const SizedBox(height: 16),
              if (backups.isNotEmpty) ...[
                const Text('Recent Backups:'),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: backups.length,
                    itemBuilder: (context, index) {
                      final backup = backups[index];
                      return ListTile(
                        title: Text(_formatDate(DateTime.parse(backup['timestamp']))),
                        subtitle: Text('${backup['streamCount']} streams'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.restore),
                              onPressed: () async {
                                Navigator.pop(context);
                                await _restoreBackup(backup['id']);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                Navigator.pop(context);
                                await _deleteBackup(backup['id']);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load backups: $e')),
      );
    }
  }

  Future<void> _createBackup(String playlistUrl) async {
    try {
      if (_playlistContent == null) {
        throw Exception('No playlist content available');
      }

      await ref.read(createBackupProvider({
        'playlistUrl': playlistUrl,
        'content': _playlistContent!,
      }).future);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup created successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create backup: $e')),
      );
    }
  }

  Future<void> _restoreBackup(String backupId) async {
    try {
      final content = await ref.read(restoreBackupProvider(backupId).future);
      setState(() {
        _playlistContent = content;
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup restored successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to restore backup: $e')),
      );
    }
  }

  Future<void> _deleteBackup(String backupId) async {
    try {
      await ref.read(deleteBackupProvider(backupId).future);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete backup: $e')),
      );
    }
  }

  Future<void> _showTagManagement(String playlistUrl) async {
    final tagsAsync = ref.watch(tagsProvider);
    final streamTagsAsync = ref.watch(streamTagsProvider(playlistUrl));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manage Tags'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () => _showCreateTagDialog(),
                child: const Text('Create New Tag'),
              ),
              const SizedBox(height: 16),
              tagsAsync.when(
                data: (tags) => Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: tags.length,
                    itemBuilder: (context, index) {
                      final tag = tags[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(int.parse(tag.color)),
                        ),
                        title: Text(tag.name),
                        subtitle: Text(tag.description ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showEditTagDialog(tag),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteTag(tag.id),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                loading: () => const CircularProgressIndicator(),
                error: (error, stack) => Text('Error: $error'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateTagDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedColor = '#FF0000';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Tag'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Tag Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Color'),
              trailing: CircleAvatar(
                backgroundColor: Color(int.parse(selectedColor)),
              ),
              onTap: () {
                // TODO: Show color picker
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await ref.read(tagManagementServiceProvider).createTag(
                  name: nameController.text,
                  color: selectedColor,
                  description: descriptionController.text,
                  userId: 'current_user_id', // TODO: Get from auth
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditTagDialog(PlaylistTag tag) async {
    final nameController = TextEditingController(text: tag.name);
    final descriptionController = TextEditingController(text: tag.description);
    String selectedColor = tag.color;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Tag'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Tag Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Color'),
              trailing: CircleAvatar(
                backgroundColor: Color(int.parse(selectedColor)),
              ),
              onTap: () {
                // TODO: Show color picker
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final updatedTag = PlaylistTag(
                  id: tag.id,
                  name: nameController.text,
                  color: selectedColor,
                  description: descriptionController.text,
                  createdAt: tag.createdAt,
                  createdBy: tag.createdBy,
                );
                await ref.read(tagManagementServiceProvider).updateTag(updatedTag);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTag(String tagId) async {
    await ref.read(tagManagementServiceProvider).deleteTag(tagId);
  }

  Future<void> _showQualityPreferences() async {
    final preferences = ref.read(streamQualityPreferencesProvider);
    bool preferHD = preferences['preferHD'];
    bool prefer4K = preferences['prefer4K'];
    double minBitrate = preferences['minBitrate'];
    int maxRetries = preferences['maxRetries'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quality Preferences'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Prefer HD'),
              value: preferHD,
              onChanged: (value) {
                setState(() {
                  preferHD = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Prefer 4K'),
              value: prefer4K,
              onChanged: (value) {
                setState(() {
                  prefer4K = value;
                });
              },
            ),
            ListTile(
              title: const Text('Minimum Bitrate (kbps)'),
              subtitle: Slider(
                value: minBitrate,
                min: 500,
                max: 10000,
                divisions: 19,
                label: minBitrate.round().toString(),
                onChanged: (value) {
                  setState(() {
                    minBitrate = value;
                  });
                },
              ),
            ),
            ListTile(
              title: const Text('Max Retries'),
              subtitle: Slider(
                value: maxRetries.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                label: maxRetries.toString(),
                onChanged: (value) {
                  setState(() {
                    maxRetries = value.round();
                  });
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(streamQualityPreferencesProvider.notifier).state = {
                'preferHD': preferHD,
                'prefer4K': prefer4K,
                'minBitrate': minBitrate,
                'maxRetries': maxRetries,
              };
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showUserPermissions() async {
    final usersAsync = ref.watch(userPermissionProvider('current_user_id'));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Permissions'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () => _showGrantPermissionDialog(),
                child: const Text('Grant Permission'),
              ),
              const SizedBox(height: 16),
              usersAsync.when(
                data: (permission) {
                  if (permission == null) {
                    return const Text('No permissions found');
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Role: ${permission.role}'),
                      const SizedBox(height: 8),
                      const Text('Allowed Actions:'),
                      ...permission.allowedActions.map((action) => Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Text('• $action'),
                      )),
                    ],
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (error, stack) => Text('Error: $error'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showGrantPermissionDialog() async {
    UserRole selectedRole = UserRole.viewer;
    final userIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Grant Permission'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: userIdController,
              decoration: const InputDecoration(
                labelText: 'User ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<UserRole>(
              value: selectedRole,
              items: UserRole.values.map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Text(role.name),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedRole = value;
                  });
                }
              },
              decoration: const InputDecoration(
                labelText: 'Role',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (userIdController.text.isNotEmpty) {
                await ref.read(tagManagementServiceProvider).grantPermission(
                  userId: userIdController.text,
                  role: selectedRole,
                  grantedBy: 'current_user_id', // TODO: Get from auth
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Grant'),
          ),
        ],
      ),
    );
  }
} 