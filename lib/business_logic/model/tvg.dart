// To parse this JSON data, do
//
//     final tvgObj = tvgObjFromJson(jsonString);

import 'dart:convert';

TvgObj tvgObjFromJson(String str) => TvgObj.fromJson(json.decode(str));

String tvgObjToJson(TvgObj data) => json.encode(data.toJson());

class TvgObj {
  TvgObj({
    this.id,
    this.name,
    this.url,
    this.logo,
  });

  String ?id;
  String ?name;
  String ?url;
  String ?logo;

  factory TvgObj.fromJson(Map<String, dynamic> json) => TvgObj(
    id: json["id"]??"",
    name: json["name"]??"",
    url: json["url"]??"",
    logo: json["logo"] ?? "https://via.placeholder.com/150?text=No+Logo",
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "url": url,
    "logo": logo,
  };
}
