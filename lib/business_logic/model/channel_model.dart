class ChannelModel {
  ChannelModel(
      {required this.name,
      required this.iconAddress,
      required this.channelCount});

  String name;
  String iconAddress;
  int channelCount;

  ChannelModel copyWith({
    String? name,
    String? iconAddress,
    int? channelCount,
  }) {
    return ChannelModel(
      name: name ?? this.name,
      iconAddress: iconAddress ?? this.iconAddress,
      channelCount: channelCount ?? this.channelCount,
    );
  }
}

