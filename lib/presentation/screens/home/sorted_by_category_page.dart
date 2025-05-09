import 'package:flutter/material.dart';
import 'package:tiwee/business_logic/model/channel.dart';
import 'package:tiwee/presentation/screens/home/player.dart';
import 'package:tiwee/presentation/widgets/custom_carousel.dart';

class SortedByCategoryPage extends StatefulWidget {
  final List<ChannelObj> channels;
  final String title;

  const SortedByCategoryPage({
    super.key,
    required this.channels,
    required this.title,
  });

  @override
  State<SortedByCategoryPage> createState() => _SortedByCategoryPageState();
}

class _SortedByCategoryPageState extends State<SortedByCategoryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
          body: widget.channels.isEmpty
          ? const Center(
              child: Text('No channels available'),
            )
          : CustomCarousel(
              items: widget.channels,
              itemBuilder: (context, channel, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Player(
                          url: channel.url,
                          fallbackUrl: channel.fallbackUrl,
                          name: channel.name,
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
                              channel.tvg.logo ?? "https://via.placeholder.com/150?text=No+Logo",
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.tv,
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
                                channel.name,
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
                                channel.languages.first.name,
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
    );
  }
}
