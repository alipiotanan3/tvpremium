import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:tiwee/business_logic/provider/country_provider.dart';
import 'package:tiwee/core/consts.dart';
import 'package:tiwee/presentation/screens/home/player.dart';
import 'package:tiwee/presentation/widgets/main_appbar.dart';
import 'package:tiwee/presentation/widgets/tv_card.dart';
import 'package:tiwee/business_logic/provider/category_provider.dart';
import 'package:tiwee/presentation/screens/home/sorted_by_category_page.dart';

//
// final clickedStarProvider = StateProvider<bool>((ref) {
//   bool value = false;
//   void toggle(){
//     value =!value;
//   }
//   return value;
// });



class CountryChannels extends ConsumerWidget {
  final String countryCode;
  final String countryName;

  const CountryChannels({
    super.key,
    required this.countryCode,
    required this.countryName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryNotifier = ref.watch(categoryNotifierProvider.notifier);
    final channels = categoryNotifier.getChannelsByCountry(countryCode);

    return Scaffold(
      appBar: AppBar(
        title: Text(countryName),
      ),
      body: channels.isEmpty
          ? const Center(
              child: Text('No channels available for this country'),
            )
          : ListView.builder(
              itemCount: channels.length,
              itemBuilder: (context, index) {
                final channel = channels[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(
                      channel.tvg.logo ?? "https://via.placeholder.com/150?text=No+Logo"
                    ),
                    onBackgroundImageError: (_, __) => const Icon(Icons.tv),
                  ),
                  title: Text(channel.name),
                  subtitle: Text(channel.languages.first.name),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SortedByCategoryPage(
                          channels: [channel],
                          title: channel.name,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}



