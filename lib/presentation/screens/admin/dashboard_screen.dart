import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'dart:async';
import 'package:tiwee/business_logic/model/playlist.dart';
import 'package:tiwee/business_logic/provider/auth_provider.dart';
import 'package:tiwee/business_logic/provider/playlist_provider.dart';
import 'package:tiwee/business_logic/services/playlist_service.dart';
import 'package:tiwee/presentation/screens/admin/login_screen.dart';
import 'package:tiwee/presentation/screens/admin/playlist_details_screen.dart';
import 'package:tiwee/presentation/screens/admin/playlist_form_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  static const _pageSize = 10;
  
  final PagingController<String?, Playlist> _pagingController =
      PagingController(firstPageKey: null);
  
  final _searchController = TextEditingController();
  Set<PlaylistStatus> _selectedStatuses = {};
  Set<String> _selectedTags = {};
  Timer? _debounce;
  Timer? _autoRefreshTimer;
  bool _isAutoRefreshEnabled = false;
  int _refreshInterval = 30; // seconds

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener(_fetchPage);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _pagingController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _toggleAutoRefresh(bool value) {
    setState(() {
      _isAutoRefreshEnabled = value;
      if (value) {
        _startAutoRefresh();
      } else {
        _autoRefreshTimer?.cancel();
      }
    });
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(Duration(seconds: _refreshInterval), (timer) {
      if (mounted) {
        _pagingController.refresh();
      }
    });
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _pagingController.refresh();
    });
  }

  Future<void> _fetchPage(String? pageKey) async {
    try {
      final playlistService = ref.read(playlistServiceProvider);
      final result = await playlistService.getPlaylists(
        limit: _pageSize,
        startAfter: pageKey,
        searchQuery: _searchController.text,
        statusFilter: _selectedStatuses,
        tagFilter: _selectedTags,
      );

      final isLastPage = result.items.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(result.items);
      } else {
        _pagingController.appendPage(
          result.items,
          result.lastDocumentId,
        );
      }
    } catch (e) {
      _pagingController.error = e;
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Filtrar Playlists'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: PlaylistStatus.values.map((status) {
                    return FilterChip(
                      label: Text(_getStatusLabel(status)),
                      selected: _selectedStatuses.contains(status),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedStatuses.add(status);
                          } else {
                            _selectedStatuses.remove(status);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Tags:', style: TextStyle(fontWeight: FontWeight.bold)),
                FutureBuilder<Set<String>>(
                  future: ref.read(playlistServiceProvider).getAllTags(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }
                    return Wrap(
                      spacing: 8,
                      children: snapshot.data!.map((tag) {
                        return FilterChip(
                          label: Text(tag),
                          selected: _selectedTags.contains(tag),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedTags.add(tag);
                              } else {
                                _selectedTags.remove(tag);
                              }
                            });
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedStatuses.clear();
                  _selectedTags.clear();
                });
              },
              child: const Text('Limpar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _pagingController.refresh();
              },
              child: const Text('Aplicar'),
            ),
          ],
        ),
      ),
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const LoginScreen();
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Tiwee Admin'),
            actions: [
              IconButton(
                icon: Icon(_isAutoRefreshEnabled ? Icons.refresh : Icons.sync_disabled),
                onPressed: () => _toggleAutoRefresh(!_isAutoRefreshEnabled),
                tooltip: _isAutoRefreshEnabled ? 'Disable auto-refresh' : 'Enable auto-refresh',
              ),
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterDialog,
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  ref.read(authServiceProvider).signOut();
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Buscar playlists',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _pagingController.refresh();
                          },
                        )
                      : null,
                  ),
                ),
              ),
              if (_selectedStatuses.isNotEmpty || _selectedTags.isNotEmpty)
                Container(
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ..._selectedStatuses.map((status) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text(_getStatusLabel(status)),
                          onDeleted: () {
                            setState(() {
                              _selectedStatuses.remove(status);
                              _pagingController.refresh();
                            });
                          },
                        ),
                      )),
                      ..._selectedTags.map((tag) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text(tag),
                          onDeleted: () {
                            setState(() {
                              _selectedTags.remove(tag);
                              _pagingController.refresh();
                            });
                          },
                        ),
                      )),
                    ],
                  ),
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => Future.sync(() => _pagingController.refresh()),
                  child: PagedListView<String?, Playlist>(
                    pagingController: _pagingController,
                    builderDelegate: PagedChildBuilderDelegate<Playlist>(
                      itemBuilder: (context, playlist, index) => _buildPlaylistCard(context, playlist),
                      noItemsFoundIndicatorBuilder: (context) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Nenhuma playlist encontrada',
                              style: TextStyle(fontSize: 18),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _addPlaylist(context),
                              icon: const Icon(Icons.add),
                              label: const Text('Adicionar Playlist'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _addPlaylist(context),
            icon: const Icon(Icons.add),
            label: const Text('Nova Playlist'),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Text('Erro: $error'),
        ),
      ),
    );
  }

  Widget _buildPlaylistCard(BuildContext context, Playlist playlist) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlaylistDetailsScreen(playlist: playlist),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(
                playlist.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: Text(playlist.url),
              trailing: PopupMenuButton<String>(
                onSelected: (value) => _handlePlaylistAction(context, playlist, value),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'validate',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle),
                        SizedBox(width: 8),
                        Text('Validar'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    enabled: !playlist.isDefault,
                    value: 'default',
                    child: Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: playlist.isDefault ? Colors.grey : null,
                        ),
                        const SizedBox(width: 8),
                        const Text('Definir como padrão'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Excluir', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildStatusChip(playlist.status),
                      if (playlist.channelCount > 0)
                        Chip(
                          label: Text('${playlist.channelCount} canais'),
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          labelStyle: const TextStyle(color: Colors.blue),
                        ),
                      if (playlist.isDefault)
                        const Chip(
                          label: Text('Padrão'),
                          backgroundColor: Colors.blue,
                          labelStyle: TextStyle(color: Colors.white),
                        ),
                      ...playlist.tags.map((tag) => Chip(
                        label: Text(tag),
                        backgroundColor: Colors.grey.withOpacity(0.1),
                      )),
                    ],
                  ),
                  if (playlist.lastChecked != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Última verificação: ${_formatDateTime(playlist.lastChecked!)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return 'há ${difference.inDays} ${difference.inDays == 1 ? 'dia' : 'dias'}';
    } else if (difference.inHours > 0) {
      return 'há ${difference.inHours} ${difference.inHours == 1 ? 'hora' : 'horas'}';
    } else if (difference.inMinutes > 0) {
      return 'há ${difference.inMinutes} ${difference.inMinutes == 1 ? 'minuto' : 'minutos'}';
    } else {
      return 'agora';
    }
  }

  Widget _buildStatusChip(PlaylistStatus status) {
    Color color;
    String label;

    switch (status) {
      case PlaylistStatus.active:
        color = Colors.green;
        label = 'Ativa';
        break;
      case PlaylistStatus.offline:
        color = Colors.red;
        label = 'Offline';
        break;
      case PlaylistStatus.slow:
        color = Colors.orange;
        label = 'Lenta';
        break;
      case PlaylistStatus.error:
        color = Colors.red;
        label = 'Erro';
        break;
      case PlaylistStatus.unknown:
        color = Colors.grey;
        label = 'Desconhecido';
        break;
    }

    return Chip(
      label: Text(label),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(color: color),
    );
  }

  void _addPlaylist(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PlaylistFormScreen(),
      ),
    );
  }

  Future<void> _handlePlaylistAction(
    BuildContext context,
    Playlist playlist,
    String action,
  ) async {
    final playlistService = ref.read(playlistServiceProvider);

    switch (action) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlaylistFormScreen(playlist: playlist),
          ),
        );
        break;

      case 'validate':
        await _validatePlaylist(context, ref, playlist);
        break;

      case 'default':
        if (!playlist.isDefault) {
          try {
            await playlistService.setDefaultPlaylist(playlist.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Playlist definida como padrão')),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erro ao definir playlist como padrão: $e')),
              );
            }
          }
        }
        break;

      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar exclusão'),
            content: Text('Deseja realmente excluir a playlist "${playlist.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Excluir'),
              ),
            ],
          ),
        );

        if (confirmed == true && context.mounted) {
          try {
            await playlistService.deletePlaylist(playlist.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Playlist excluída com sucesso')),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erro ao excluir playlist: $e')),
              );
            }
          }
        }
        break;
    }
  }

  Future<void> _validatePlaylist(BuildContext context, WidgetRef ref, Playlist playlist) async {
    final playlistService = ref.read(playlistServiceProvider);

    try {
      // Show progress dialog
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Validando playlist...'),
              ],
            ),
          ),
        );
      }

      // Validate playlist
      final response = await Future.delayed(
        const Duration(seconds: 2),
        () => true, // Simulate validation
      );

      // Update status
      if (response) {
        await playlistService.updatePlaylistStatus(
          playlist.id,
          PlaylistStatus.active,
          responseTime: 0.5,
          channelCount: 100,
          categoryCount: {'Filmes': 30, 'Séries': 40, 'Esportes': 30},
        );
      } else {
        await playlistService.updatePlaylistStatus(
          playlist.id,
          PlaylistStatus.error,
          error: 'Falha ao validar playlist',
        );
      }

      // Close dialog and show result
      if (context.mounted) {
        Navigator.pop(context); // Close progress dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response 
                ? 'Playlist validada com sucesso' 
                : 'Erro ao validar playlist'
            ),
            backgroundColor: response ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close dialog and show error
      if (context.mounted) {
        Navigator.pop(context); // Close progress dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao validar playlist: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 