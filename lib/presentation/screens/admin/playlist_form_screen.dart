import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiwee/business_logic/model/playlist.dart';
import 'package:tiwee/business_logic/provider/playlist_provider.dart';
import 'package:tiwee/business_logic/services/playlist_service.dart';

class PlaylistFormScreen extends ConsumerStatefulWidget {
  final Playlist? playlist;
  const PlaylistFormScreen({super.key, this.playlist});

  @override
  ConsumerState<PlaylistFormScreen> createState() => _PlaylistFormScreenState();
}

class _PlaylistFormScreenState extends ConsumerState<PlaylistFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _tagsController = TextEditingController();
  bool _isDefault = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.playlist != null) {
      _nameController.text = widget.playlist!.name;
      _urlController.text = widget.playlist!.url;
      _tagsController.text = widget.playlist!.tags.join(', ');
      _isDefault = widget.playlist!.isDefault;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _savePlaylist() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final tags = _tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();

    try {
      final playlistService = ref.read(playlistServiceProvider);
      
      if (widget.playlist == null) {
        // Create new playlist
        final playlist = Playlist(
          id: '', // ID will be assigned by Firestore
          name: _nameController.text.trim(),
          url: _urlController.text.trim(),
          tags: tags,
          isDefault: _isDefault,
          status: PlaylistStatus.unknown,
          channelCount: 0,
          categoryCount: const {},
          responseTime: 0.0,
          lastChecked: DateTime.now(),
          error: null,
          metadata: const {},
        );
        
        final id = await playlistService.createPlaylist(playlist);
        if (_isDefault) {
          await playlistService.setDefaultPlaylist(id);
        }
      } else {
        // Update existing playlist
        final updatedPlaylist = widget.playlist!.copyWith(
          name: _nameController.text.trim(),
          url: _urlController.text.trim(),
          tags: tags,
          isDefault: _isDefault,
        );
        
        await playlistService.updatePlaylist(updatedPlaylist);
        if (_isDefault) {
          await playlistService.setDefaultPlaylist(updatedPlaylist.id);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Playlist salva com sucesso')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar playlist: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlist == null ? 'Nova Playlist' : 'Editar Playlist'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty 
                  ? 'Informe um nome' 
                  : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'URL da Playlist',
                  border: OutlineInputBorder(),
                  hintText: 'https://exemplo.com/playlist.m3u',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe a URL';
                  }
                  try {
                    final uri = Uri.parse(value);
                    if (!uri.isAbsolute) {
                      return 'URL inválida';
                    }
                    return null;
                  } catch (e) {
                    return 'URL inválida';
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (separadas por vírgula)',
                  border: OutlineInputBorder(),
                  hintText: 'filmes, séries, esportes',
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Definir como playlist padrão'),
                subtitle: const Text(
                  'Esta playlist será usada como fonte principal de canais',
                ),
                value: _isDefault,
                onChanged: (value) => setState(() => _isDefault = value),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loading ? null : _savePlaylist,
                icon: _loading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
                label: Text(_loading ? 'Salvando...' : 'Salvar Playlist'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 