import 'package:flutter/material.dart';
import 'package:tiwee/business_logic/model/channel.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChannelList extends StatelessWidget {
  final List<ChannelObj> channels;

  const ChannelList({
    super.key,
    required this.channels,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: channels.length,
      itemBuilder: (context, index) {
        final channel = channels[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: channel.tvg.logo ?? channel.logo,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                placeholder: (context, url) => const CircularProgressIndicator(),
                errorWidget: (context, url, error) => const Icon(Icons.tv),
              ),
            ),
            title: Text(channel.name),
            subtitle: Text(
              channel.categories.isNotEmpty 
                ? channel.categories.first.name 
                : 'No category',
            ),
            onTap: () {
              // TODO: Implement channel playback
              print('Playing channel: ${channel.name}');
            },
          ),
        );
      },
    );
  }
} 