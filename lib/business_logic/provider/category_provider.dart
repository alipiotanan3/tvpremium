import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiwee/business_logic/model/channel.dart';
import 'package:tiwee/business_logic/provider/channel_provider.dart';
import 'package:tiwee/business_logic/provider/country_code.dart';
import 'package:tiwee/core/consts.dart';

import 'channel_card_provider.dart';

final categoryProvider = Provider<AsyncValue<Map<String, List<ChannelObj>>>>((ref) {
  final channelsAsync = ref.watch(channelProvider);
  return channelsAsync.when(
    data: (channels) {
      Map<String, List<ChannelObj>> categorizedChannels = {};
      channels.forEach((category, channelList) {
        categorizedChannels[category] = channelList;
      });
      return AsyncValue.data(categorizedChannels);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

class CategoryProvider {
  final List<ChannelObj> channels;
  
  CategoryProvider({required this.channels});

  List<ChannelObj> getChannelsByCategory(String category) {
    return channels.where((channel) => 
      channel.categories.any((cat) => cat.name.toLowerCase() == category.toLowerCase())
    ).toList();
  }

  List<String> get categories {
    final Set<String> uniqueCategories = {};
    for (var channel in channels) {
      for (var category in channel.categories) {
        uniqueCategories.add(category.name);
      }
    }
    return uniqueCategories.toList()..sort();
              }
}

final categoryNotifierProvider = StateNotifierProvider<CategoryNotifier, CategoryState>((ref) {
  return CategoryNotifier();
});

class CategoryState {
  final List<ChannelObj> channels;
  final List<ChannelObj> favoriteChannels;
  final Map<String, List<ChannelObj>> channelsByCategory;

  CategoryState({
    required this.channels,
    required this.favoriteChannels,
    required this.channelsByCategory,
  });

  CategoryState copyWith({
    List<ChannelObj>? channels,
    List<ChannelObj>? favoriteChannels,
    Map<String, List<ChannelObj>>? channelsByCategory,
  }) {
    return CategoryState(
      channels: channels ?? this.channels,
      favoriteChannels: favoriteChannels ?? this.favoriteChannels,
      channelsByCategory: channelsByCategory ?? this.channelsByCategory,
    );
  }
}

class CategoryNotifier extends StateNotifier<CategoryState> {
  CategoryNotifier()
      : super(CategoryState(
          channels: [],
          favoriteChannels: [],
          channelsByCategory: {},
        ));

  void setChannels(List<ChannelObj> channels) {
    final channelsByCategory = <String, List<ChannelObj>>{};
    for (final channel in channels) {
      for (final category in channel.categories) {
        channelsByCategory.putIfAbsent(category.name, () => []).add(channel);
      }
    }
    state = state.copyWith(
      channels: channels,
      channelsByCategory: channelsByCategory,
    );
  }

  void toggleFavorite(ChannelObj channel) {
    final favorites = List<ChannelObj>.from(state.favoriteChannels);
    if (favorites.contains(channel)) {
      favorites.remove(channel);
    } else {
      favorites.add(channel);
    }
    state = state.copyWith(favoriteChannels: favorites);
  }

  List<ChannelObj> getChannelsByCountry(String countryCode) {
    return state.channels.where((channel) => 
      channel.countries.any((country) => country.code == countryCode)
    ).toList();
  }

  List<ChannelObj> getChannelsByCategory(String categoryName) {
    return state.channelsByCategory[categoryName] ?? [];
  }
}
