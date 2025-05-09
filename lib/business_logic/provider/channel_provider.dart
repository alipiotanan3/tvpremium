import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiwee/business_logic/model/channel.dart';
import 'package:tiwee/business_logic/model/m3u_channel.dart';
import 'package:tiwee/business_logic/services/m3u_service.dart';
import 'package:tiwee/core/consts.dart';

final m3uServiceProvider = Provider((ref) => M3UService());

final channelProvider = StateNotifierProvider<ChannelNotifier, AsyncValue<Map<String, List<ChannelObj>>>>((ref) {
  final m3uService = ref.watch(m3uServiceProvider);
  return ChannelNotifier(m3uService);
});

class ChannelNotifier extends StateNotifier<AsyncValue<Map<String, List<ChannelObj>>>> {
  final M3UService _m3uService;
  static const int maxRetries = 3;
  
  ChannelNotifier(this._m3uService) : super(const AsyncValue.loading()) {
    loadChannels();
  }

  Future<void> loadChannels([int retryCount = 0]) async {
    if (retryCount >= maxRetries) {
      state = AsyncValue.error(
        'Falha ao carregar canais após $maxRetries tentativas',
        StackTrace.current
      );
      return;
    }

    try {
      state = const AsyncValue.loading();
      print('Tentativa ${retryCount + 1} de $maxRetries para carregar canais');
      
      // Get M3U content
      final m3uContent = await _m3uService.getM3UList(AppConstants.defaultM3uUrl);
      
      if (m3uContent.trim().isEmpty) {
        throw Exception('Lista M3U está vazia');
      }
      
      // Parse M3U content
      final m3uChannels = _m3uService.parseM3U(m3uContent);
      
      if (m3uChannels.isEmpty) {
        throw Exception('Nenhum canal encontrado na lista M3U');
      }
      
      print('Total de canais encontrados: ${m3uChannels.length}');
      
      // Organize channels
      final organizedM3UChannels = _m3uService.organizeChannels(m3uChannels);
      
      // Convert M3UChannel to ChannelObj
      final Map<String, List<ChannelObj>> categorizedChannels = {};
      
      organizedM3UChannels.forEach((category, channels) {
        if (channels.isNotEmpty) {
          print('Categoria $category: ${channels.length} canais');
          categorizedChannels[category] = channels.map((m3uChannel) => ChannelObj(
            name: m3uChannel.name,
            logo: m3uChannel.logo,
            url: m3uChannel.url,
            categories: [Category(name: m3uChannel.category, slug: m3uChannel.category.toLowerCase())],
            countries: [],
            languages: [],
            tvg: Tvg(
              id: m3uChannel.tvgId,
              name: m3uChannel.tvgName,
              logo: m3uChannel.tvgLogo,
            ),
          )).toList();
        }
      });
      
      if (categorizedChannels.isEmpty) {
        throw Exception('Nenhum canal foi categorizado corretamente');
      }

      state = AsyncValue.data(categorizedChannels);
    } catch (e, stack) {
      print('Erro ao carregar canais (tentativa ${retryCount + 1}): $e');
      
      if (e.toString().contains('SocketException') || 
          e.toString().contains('TimeoutException') ||
          e.toString().contains('HttpException')) {
        // Network related errors - retry
        await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
        return loadChannels(retryCount + 1);
      }
      
      state = AsyncValue.error(e, stack);
    }
  }

  void refreshChannels() {
    loadChannels();
  }
}
