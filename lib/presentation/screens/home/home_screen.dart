import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiwee/business_logic/provider/channel_provider.dart';
import 'package:tiwee/presentation/screens/settings/settings_screen.dart';
import 'package:tiwee/presentation/widgets/channel_list.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelsAsync = ref.watch(channelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tiwee'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: channelsAsync.when(
        data: (channels) {
          if (channels.isEmpty) {
            return const Center(
              child: Text('Nenhum canal encontrado'),
            );
          }

          return DefaultTabController(
            length: channels.length,
            child: Column(
              children: [
                TabBar(
                  isScrollable: true,
                  tabs: channels.keys.map((category) {
                    return Tab(
                      child: Row(
                        children: [
                          Icon(categoryIcons[category] ?? Icons.live_tv),
                          const SizedBox(width: 8),
                          Text(category),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                Expanded(
                  child: TabBarView(
                    children: channels.values.map((categoryChannels) {
                      return ChannelList(channels: categoryChannels);
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Erro ao carregar canais:\n${error.toString()}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(channelProvider.notifier).refreshChannels();
                },
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 