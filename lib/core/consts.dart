import 'package:flutter/material.dart';

const Color kBlackBg = Color(0xff1c1829);
const Color kWhiteBg = Color(0xff262436);
const Color kPurple = Color(0xff9c4af5);
const Color kGray = Color(0xff262433);
const Map<String, String> kCategoryType = {
  "Animação":
      "https://img.elo7.com.br/product/original/317F25D/adesivo-personalizado-para-parede-desenho-bob-esponja-series.jpg",
  "Automóveis":
      "https://images.unsplash.com/photo-1503376780353-7e6692767b70?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=2070&q=80",
  "Negócios":
      "https://images.unsplash.com/photo-1600880292203-757bb62b4baf?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=2070&q=80",
  "Clássicos":
      "https://images.unsplash.com/photo-1608144252993-f33f23e9df9a?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1502&q=80",
  "Comédia":
      "https://media.biobiochile.cl/wp-content/uploads/2021/04/happy_ending-e1618520426737.jpeg",
  "Culinária":
      "https://images.unsplash.com/photo-1466637574441-749b8f19452f?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1480&q=80",
  "Cultura":
      "https://images.unsplash.com/photo-1488861859915-4b5a5e57649f?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=2340&q=80",
  "Documentários":
      "https://images.unsplash.com/photo-1615309871801-6b065d20f50b?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=2069&q=80",
  "Educação":
      "https://images.unsplash.com/photo-1523050854058-8df90110c9f1?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=2340&q=80",
  "Entretenimento":
      "https://images.unsplash.com/photo-1603739903239-8b6e64c3b185?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=2071&q=80",
  "Geral":
      "https://images.unsplash.com/photo-1493612276216-ee3925520721?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1064&q=80",
  "Infantil":
      "https://images.unsplash.com/photo-1607453998774-d533f65dac99?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=987&q=80",
  "Legislativo":
      "https://images.unsplash.com/photo-1526615735835-530c611a3d8a?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=2071&q=80",
  "Estilo de Vida":
      "https://images.unsplash.com/photo-1529333166437-7750a6dd5a70?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=2069&q=80",
  "Local":
      "https://images.unsplash.com/photo-1482514194978-3ed8cc9d86c6?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=2070&q=80",
  "Filmes":
      "https://images.unsplash.com/photo-1594909122845-11baa439b7bf?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=2070&q=80",
  "Música":
      "https://images.unsplash.com/photo-1511379938547-c1f69419868d?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=2070&q=80",
  "Notícias":
      "https://images.unsplash.com/photo-1495020689067-958852a7765e?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=2069&q=80",
  "Ar Livre":
      "https://images.unsplash.com/photo-1526772662000-3f88f10405ff?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1974&q=80",
  "Relaxamento":
      "https://images.unsplash.com/photo-1512552288940-3a300922a275?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=2071&q=80",
  "Ciência":
      "https://images.unsplash.com/photo-1582719471384-894fbb16e074?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=987&q=80",
  "Séries":
      "https://images.unsplash.com/photo-1522869635100-9f4c5e86aa37?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=2070&q=80",
  "Loja":
      "https://images.unsplash.com/photo-1483985988355-763728e1935b?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=2070&q=80",
  "Esportes":
      "https://images.unsplash.com/photo-1517649763962-0c623066013b?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=2070&q=80",
  "Viagens":
      "https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=2021&q=80",
  "Clima":
      "https://images.unsplash.com/photo-1592210454359-9043f067919b?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=2070&q=80",
  "Outros":
      "https://images.unsplash.com/photo-1504275107627-0c2ba7a43dba?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1974&q=80",
};

const String kEmptyAnimation = 'assets/animation/empty.json';
const String kLoading = 'assets/animation/loading.json';
const String kNotFound = 'assets/animation/not_found.json';
const String kTvLoading = 'assets/animation/tv_loading.json';

final List<String> kLanguages = [
  "Russian",
  "Hindi",
  "Pashto",
  "Spanish",
  "German",
  "Ukrainian",
  "Hungarian",
  "Georgian",
  "Persian",
  "Arabic",
  "Wolof",
  "English",
  "Tamil",
  "Catalan",
  "French",
  "Greek",
  "Polish",
  "Armenian",
  "Albanian",
  "Kazakh",
  "Marathi",
  "Italian",
  "Turkish",
  "Urdu",
  "Bulgarian",
  "Portuguese",
  "Punjabi",
  "Romanian",
  "Bengali",
  "Amharic",
  "Serbian",
  "Kurdish",
  "Swedish",
  "Vietnamese",
  "Bosnian",
  "Finnish",
  "Thai",
  "Turkmen",
  "Azerbaijani",
  "Malayalam",
  "Japanese",
  "Korean",
  "Hebrew",
  "Malay",
  "Dutch",
  "Nepali",
  "Uzbek",
  "Bhojpuri",
  "Khmer",
  "Belarusian",
  "Indonesian",
  "Chinese",
  "Slovak",
  "Tagalog",
  "Luxembourgish",
  "Sinhala",
  "Swahili",
  "Czech",
  "Kannada",
  "Estonian",
  "Norwegian",
  "Bokmål",
  "Slovenian",
  "Somali",
  "Croatian",
  "Norwegian",
  "Danish",
  "Assyrian",
  "Neo - Aramaic",
  "Kinyarwanda",
  "Greenlandic",
  "Faroese",
  "Lao",
  "Latvian",
  "Lithuanian",
  "Maori",
  "Chichewa",
  "Icelandic",
  "Macedonian",
  "Maltese",
  "Panjabi",
  "Akan",
  "Telugu",
  "Galician",
  "Dhivehi",
  "Kyrgyz",
  "Bashkir",
  "Min Nan Chinese"
];

class AppConstants {
  static String defaultM3uUrl = 'https://iptv-org.github.io/iptv/index.m3u';
  static bool autoRetry = true;
  static int maxRetries = 3;
  static int connectionTimeout = 15;
  static int readTimeout = 20;
  
  static void updateM3uUrl(String newUrl) {
    defaultM3uUrl = newUrl;
  }

  static void updateNetworkSettings({
    bool? autoRetry,
    int? maxRetries,
    int? connectionTimeout,
    int? readTimeout,
  }) {
    if (autoRetry != null) AppConstants.autoRetry = autoRetry;
    if (maxRetries != null) AppConstants.maxRetries = maxRetries;
    if (connectionTimeout != null) AppConstants.connectionTimeout = connectionTimeout;
    if (readTimeout != null) AppConstants.readTimeout = readTimeout;
  }
}

// Category Icons
const Map<String, IconData> categoryIcons = {
  'TV ao Vivo': Icons.live_tv,
  'Filmes': Icons.movie,
  'Séries': Icons.tv,
  'Esportes': Icons.sports,
  'Notícias': Icons.newspaper,
  'Entretenimento': Icons.theater_comedy,
  'Infantil': Icons.child_care,
  'Música': Icons.music_note,
  'Documentários': Icons.camera,
  'Outros': Icons.more_horiz,
};
