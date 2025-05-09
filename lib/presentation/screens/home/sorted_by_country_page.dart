import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tiwee/business_logic/provider/category_provider.dart';
import 'package:tiwee/business_logic/provider/country_provider.dart';
import 'package:tiwee/presentation/screens/home/country_channels.dart';
import 'package:tiwee/presentation/widgets/main_appbar.dart';
import 'package:tiwee/presentation/widgets/sorted_by_category_widget/fav_all_card.dart';
import 'package:tiwee/presentation/widgets/custom_carousel.dart';

class SortedByCountryPage extends ConsumerWidget {
  const SortedByCountryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countryProvider = ref.watch(countryNotifierProvider);
    final categoryProvider = ref.watch(categoryNotifierProvider);

    return Scaffold(
      appBar: const MainAppBar(),
      body: Container(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FavAllCard(
                  text: 'Favorites',
                  icon: Icons.favorite,
                  count: categoryProvider.favoriteChannels.length,
                  onTap: () {
                    // Handle favorites tap
                  },
                ),
                FavAllCard(
                  text: 'All Channels',
                  icon: Icons.tv,
                  count: categoryProvider.channels.length,
                  onTap: () {
                    // Handle all channels tap
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: CustomCarousel(
                items: countryProvider.countries,
                itemBuilder: (context, country, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CountryChannels(
                            countryCode: country.code,
                            countryName: country.name,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey[900],
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(10),
                              ),
                              child: Image.network(
                                'https://flagcdn.com/w160/${country.code.toLowerCase()}.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    FontAwesomeIcons.flag,
                                    size: 50,
                                    color: Colors.grey,
                                  );
                                },
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Text(
                                  country.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${ref.read(categoryNotifierProvider.notifier).getChannelsByCountry(country.code).length} channels',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
