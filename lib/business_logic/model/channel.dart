// To parse this JSON data, do
//
//     final channelObj = channelObjFromJson(jsonString);

import 'dart:convert';

ChannelObj channelObjFromJson(String str) => ChannelObj.fromJson(json.decode(str));

String channelObjToJson(ChannelObj data) => json.encode(data.toJson());

class ChannelObj {
  ChannelObj({
    required this.name,
    required this.logo,
    required this.url,
    required this.categories,
    required this.countries,
    required this.languages,
    required this.tvg,
    this.groupTitle = '',
    this.type = 'live',
    this.id = '',
  });

  String name;
  String logo;
  String url;
  List<Category> categories;
  List<Country> countries;
  List<Country> languages;
  Tvg tvg;
  String groupTitle;
  String type;
  String id;

  factory ChannelObj.fromJson(Map<String, dynamic> json) => ChannelObj(
    name: json["name"] ?? "",
    logo: json["logo"] ?? "",
    url: json["url"] ?? "",
    categories: List<Category>.from(json["categories"]?.map((x) => Category.fromJson(x)) ?? []),
    countries: List<Country>.from(json["countries"]?.map((x) => Country.fromJson(x)) ?? []),
    languages: List<Country>.from(json["languages"]?.map((x) => Country.fromJson(x)) ?? []),
    tvg: Tvg.fromJson(json["tvg"] ?? {}),
    groupTitle: json["group_title"] ?? "",
    type: json["type"] ?? "live",
    id: json["id"] ?? "",
  );

  factory ChannelObj.fromM3U(String extinf, String url) {
    // Parse EXTINF line
    final nameMatch = RegExp('tvg-name="(.*?)"').firstMatch(extinf);
    final logoMatch = RegExp('tvg-logo="(.*?)"').firstMatch(extinf);
    final groupMatch = RegExp('group-title="(.*?)"').firstMatch(extinf);
    final idMatch = RegExp('tvg-id="(.*?)"').firstMatch(extinf);
    final typeMatch = RegExp('type="(.*?)"').firstMatch(extinf);
    
    // Get channel name from the end of EXTINF line
    final nameFromEnd = extinf.split(',').last.trim();
    
    // Determine type based on URL or type attribute
    String type = "live";
    if (typeMatch != null) {
      type = typeMatch.group(1)!.toLowerCase();
    } else if (url.toLowerCase().contains("/movie/") || 
              url.toLowerCase().contains("/vod/") ||
              url.toLowerCase().contains(".mp4")) {
      type = "vod";
    } else if (url.toLowerCase().contains("/series/")) {
      type = "series";
    }

    return ChannelObj(
      name: nameMatch?.group(1) ?? nameFromEnd,
      logo: logoMatch?.group(1) ?? "",
      url: url,
      categories: [Category(name: groupMatch?.group(1) ?? "Outros", slug: "outros")],
      countries: [],
      languages: [],
      tvg: Tvg(),
      groupTitle: groupMatch?.group(1) ?? "Outros",
      type: type,
      id: idMatch?.group(1) ?? "",
    );
  }

  Map<String, dynamic> toJson() => {
    "name": name,
    "logo": logo,
    "url": url,
    "categories": List<dynamic>.from(categories.map((x) => x.toJson())),
    "countries": List<dynamic>.from(countries.map((x) => x.toJson())),
    "languages": List<dynamic>.from(languages.map((x) => x.toJson())),
    "tvg": tvg.toJson(),
    "group_title": groupTitle,
    "type": type,
    "id": id,
  };
}

class Category {
  Category({
   required this.name,
   required this.slug,
  });

  String name;
  String slug;

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    name: json["name"],
    slug: json["slug"],
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "slug": slug,
  };
}

class Country {
  Country({
  required  this.name,
   required this.code,
  });

  String name;
  String code;

  factory Country.fromJson(Map<String, dynamic> json) => Country(
    name: json["name"],
    code: json["code"],
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "code": code,
  };
}

class Tvg {
  Tvg({
    this.id,
    this.name,
    this.url,
    this.logo,
  });

  String? id;
  String? name;
  String? url;
  String? logo;

  factory Tvg.fromJson(Map<String, dynamic> json) => Tvg(
    id: json["id"],
    name: json["name"],
    url: json["url"],
    logo: json["logo"] ?? "https://via.placeholder.com/150?text=No+Logo",
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "url": url,
    "logo": logo,
  };
}
