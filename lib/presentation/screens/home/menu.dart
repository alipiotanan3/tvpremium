import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:tiwee/business_logic/provider/category_provider.dart';
import 'package:tiwee/business_logic/provider/channel_card_provider.dart';
import 'package:tiwee/core/consts.dart';
import 'package:tiwee/business_logic/provider/channel_provider.dart';
import 'package:tiwee/presentation/widgets/channel_list.dart';
import 'package:tiwee/presentation/widgets/loading_widget.dart';

import 'package:tiwee/presentation/screens/home/sorted_by_category_page.dart';
import 'package:tiwee/presentation/screens/home/sorted_by_country_page.dart';
import 'package:tiwee/presentation/widgets/home_page_widget/big_card_channel.dart';
import 'package:tiwee/presentation/widgets/main_appbar.dart';
import 'package:tiwee/presentation/screens/home/player.dart';

class Menu extends ConsumerWidget {
  const Menu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelsAsync = ref.watch(channelProvider);

    return Scaffold(
      body: Column(
        children: [
          MainAppbar(
            havSettingBtn: true,
            widget: const Text(
              'Tiwee IPTV',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: channelsAsync.when(
              data: (categorizedChannels) {
                if (categorizedChannels.isEmpty) {
                  return const Center(
                    child: Text('No channels available'),
                  );
                }
                return ListView.builder(
                  itemCount: categorizedChannels.length,
                  itemBuilder: (context, index) {
                    final category = categorizedChannels.keys.elementAt(index);
                    final channels = categorizedChannels[category]!;
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(
                                categoryIcons[category] ?? Icons.category,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                category,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${channels.length} channels',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: channels.length,
                            itemBuilder: (context, channelIndex) {
                              final channel = channels[channelIndex];
                              return Card(
                                margin: const EdgeInsets.all(8.0),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => Player(url: channel.url),
                                      ),
                                    );
                                  },
                                  child: SizedBox(
                                    width: 150,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (channel.logo.isNotEmpty)
                                          Expanded(
                                            child: Image.network(
                                              channel.logo,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return const Center(
                                                  child: Icon(Icons.tv),
                                                );
                                              },
                                            ),
                                          ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            channel.name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
              loading: () => const LoadingWidget(),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Error loading channels'),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(channelProvider.notifier).refreshChannels();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
