import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiwee/business_logic/model/channel.dart';
import 'package:tiwee/business_logic/provider/channel_provider.dart';
import 'package:tiwee/business_logic/model/country.dart';

final countryProvider = Provider<AsyncValue<Map<String, List<ChannelObj>>>>((ref) {
  final channelsAsync = ref.watch(channelProvider);
  return channelsAsync.when(
    data: (channels) {
      Map<String, List<ChannelObj>> channelsByCountry = {};
      channels.forEach((_, channelList) {
        for (var channel in channelList) {
          for (var country in channel.countries) {
            if (!channelsByCountry.containsKey(country.name)) {
              channelsByCountry[country.name] = [];
            }
            channelsByCountry[country.name]!.add(channel);
          }
        }
      });
      return AsyncValue.data(channelsByCountry);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

class CountryProvider {
  final List<ChannelObj> channels;
  
  CountryProvider({required this.channels});

  List<ChannelObj> getChannelsByCountry(String countryCode) {
    return channels.where((channel) => 
      channel.countries.any((country) => country.code.toLowerCase() == countryCode.toLowerCase())
    ).toList();
  }

  List<Country> get countries {
    final Set<Country> uniqueCountries = {};
    for (var channel in channels) {
      uniqueCountries.addAll(channel.countries);
    }
    return uniqueCountries.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }
}

final countryNotifierProvider = StateNotifierProvider<CountryNotifier, CountryState>((ref) {
  return CountryNotifier();
});

class CountryState {
  final List<Country> countries;

  CountryState({required this.countries});

  CountryState copyWith({List<Country>? countries}) {
    return CountryState(countries: countries ?? this.countries);
  }
}

class CountryNotifier extends StateNotifier<CountryState> {
  CountryNotifier() : super(CountryState(countries: []));

  void setCountries(List<Country> countries) {
    state = state.copyWith(countries: countries);
  }

  List<Country> get countries => state.countries;
}
