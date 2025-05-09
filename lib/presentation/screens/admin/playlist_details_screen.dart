import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiwee/business_logic/model/playlist.dart';
import 'package:tiwee/business_logic/model/validation_log.dart';
import 'package:tiwee/business_logic/provider/playlist_provider.dart';
import 'package:tiwee/business_logic/services/playlist_service.dart';

class PlaylistDetailsScreen extends ConsumerWidget {
  final Playlist playlist;

  const PlaylistDetailsScreen({
    super.key,
    required this.playlist,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(playlist.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              try {
                await ref.read(playlistServiceProvider).validatePlaylist(playlist.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Playlist validada com sucesso')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao validar playlist: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            title: 'Informações Gerais',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('URL:', playlist.url),
                const SizedBox(height: 8),
                _buildInfoRow(
                  'Status:',
                  _getStatusLabel(playlist.status),
                  color: _getStatusColor(playlist.status),
                ),
                if (playlist.error != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow('Erro:', playlist.error!, color: Colors.red),
                ],
                const SizedBox(height: 8),
                _buildInfoRow(
                  'Última verificação:',
                  _formatDateTime(playlist.lastChecked),
                ),
                if (playlist.responseTime > 0) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Tempo de resposta:',
                    '${playlist.responseTime.toStringAsFixed(2)}s',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Tags',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: playlist.tags.isEmpty
                ? [const Text('Nenhuma tag adicionada')]
                : playlist.tags.map((tag) => Chip(
                    label: Text(tag),
                    backgroundColor: Colors.grey.withOpacity(0.1),
                  )).toList(),
            ),
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Canais',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  'Total de canais:',
                  playlist.channelCount.toString(),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Canais por categoria:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (playlist.categoryCount.isEmpty)
                  const Text('Nenhuma categoria encontrada')
                else
                  ...playlist.categoryCount.entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildInfoRow(
                      '${entry.key}:',
                      entry.value.toString(),
                    ),
                  )),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Histórico de Validação',
            child: StreamBuilder<List<ValidationLog>>(
              stream: ref.read(playlistServiceProvider).getValidationLogs(playlist.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Text('Erro ao carregar histórico: ${snapshot.error}');
                }

                final logs = snapshot.data ?? [];
                if (logs.isEmpty) {
                  return const Text('Nenhum registro de validação encontrado');
                }

                return Column(
                  children: logs.map((log) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(_formatDateTime(log.timestamp)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Status: ${_getStatusLabel(log.status)}'),
                          if (log.error != null)
                            Text('Erro: ${log.error}'),
                          Text('Tempo de resposta: ${log.responseTime.toStringAsFixed(2)}s'),
                          Text('Canais: ${log.channelCount}'),
                        ],
                      ),
                    ),
                  )).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: color != null ? TextStyle(color: color) : null,
          ),
        ),
      ],
    );
  }

  String _getStatusLabel(PlaylistStatus status) {
    switch (status) {
      case PlaylistStatus.active:
        return 'Ativa';
      case PlaylistStatus.offline:
        return 'Offline';
      case PlaylistStatus.slow:
        return 'Lenta';
      case PlaylistStatus.error:
        return 'Erro';
      case PlaylistStatus.unknown:
        return 'Desconhecido';
    }
  }

  Color _getStatusColor(PlaylistStatus status) {
    switch (status) {
      case PlaylistStatus.active:
        return Colors.green;
      case PlaylistStatus.offline:
        return Colors.red;
      case PlaylistStatus.slow:
        return Colors.orange;
      case PlaylistStatus.error:
        return Colors.red;
      case PlaylistStatus.unknown:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
} 