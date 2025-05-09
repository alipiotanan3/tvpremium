import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import '../model/m3u_channel.dart';

class M3UService {
  static const int _maxRetries = 3;
  static const Duration _connectTimeout = Duration(seconds: 15);
  static const Duration _readTimeout = Duration(seconds: 20);
  
  Future<String> getM3UList(String url) async {
    int retryCount = 0;
    Exception? lastException;
    final errors = <String>[];
    
    while (retryCount < _maxRetries) {
      try {
        print('=== CARREGANDO LISTA M3U (Tentativa ${retryCount + 1}/$_maxRetries) ===');
        print('URL: $url');
        print('Iniciando conexão...');
        
        final client = http.Client();
        try {
          final response = await client.get(
            Uri.parse(url),
            headers: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
              'Accept': '*/*',
              'Connection': 'keep-alive',
            },
          ).timeout(_connectTimeout);
          
          print('Conexão estabelecida, lendo dados...');
          final content = await response.timeout(_readTimeout).then((resp) => resp.body.trim());
          
          print('Resposta recebida:');
          print('Status code: ${response.statusCode}');
          print('Content-Type: ${response.headers['content-type']}');
          print('Content-Length: ${response.contentLength}');
          
          if (response.statusCode == 200) {
            if (content.isEmpty) {
              throw const FormatException('Lista M3U está vazia');
            }
            
            print('Verificando formato M3U...');
            if (!content.startsWith('#EXTM3U')) {
              final preview = content.substring(0, min(100, content.length));
              print('Conteúdo recebido não começa com #EXTM3U:');
              print(preview);
              throw FormatException('Arquivo não é uma lista M3U válida. Conteúdo recebido: $preview');
            }
            
            print('Lista M3U carregada com sucesso');
            print('Tamanho: ${content.length} bytes');
            print('Número de canais: ${content.split('#EXTINF').length - 1}');
            return content;
          } else {
            final errorMsg = 'Erro HTTP ${response.statusCode}: ${response.body}';
            print(errorMsg);
            errors.add(errorMsg);
            throw HttpException(errorMsg);
          }
        } on TimeoutException catch (e) {
          final timeoutMsg = 'Timeout durante ${e.duration?.inSeconds}s';
          print(timeoutMsg);
          errors.add(timeoutMsg);
          throw TimeoutException(timeoutMsg);
        } finally {
          client.close();
        }
      } on TimeoutException catch (e) {
        lastException = e;
        errors.add('Timeout na tentativa ${retryCount + 1}: ${e.message}');
        print('Timeout na tentativa ${retryCount + 1}');
      } on SocketException catch (e) {
        lastException = e;
        errors.add('Erro de conexão na tentativa ${retryCount + 1}: ${e.message}');
        print('Erro de conexão na tentativa ${retryCount + 1}: ${e.message}');
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        errors.add('Erro não esperado na tentativa ${retryCount + 1}: $e');
        print('Erro não esperado na tentativa ${retryCount + 1}: $e');
      }
      
      retryCount++;
      if (retryCount < _maxRetries) {
        final waitTime = Duration(seconds: pow(2, retryCount).toInt());
        print('Aguardando ${waitTime.inSeconds} segundos antes da próxima tentativa...');
        await Future.delayed(waitTime);
      }
    }
    
    final errorSummary = 'Falha ao carregar lista M3U após $_maxRetries tentativas:\n${errors.join('\n')}';
    print(errorSummary);
    throw lastException ?? Exception(errorSummary);
  }

  int min(int a, int b) => a < b ? a : b;

  List<M3UChannel> parseM3U(String m3uContent) {
    print('Iniciando parsing da lista M3U...');
    final List<M3UChannel> channels = [];
    final lines = m3uContent.split('\n');
    int totalLines = lines.length;
    int processedLines = 0;
    
    try {
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.startsWith('#EXTINF:')) {
          String? url;
          // Procura a próxima linha não vazia que não começa com #
          for (int j = i + 1; j < lines.length; j++) {
            final nextLine = lines[j].trim();
            if (nextLine.isNotEmpty && !nextLine.startsWith('#')) {
              url = nextLine;
              break;
            }
          }
          
          if (url != null) {
            try {
              final channel = M3UChannel.fromM3ULine(line, url);
              channels.add(channel);
              processedLines++;
              if (processedLines % 100 == 0) {
                print('Progresso: $processedLines/$totalLines linhas processadas');
              }
            } catch (e) {
              print('Erro ao processar canal: $e');
            }
          }
        }
      }
    } catch (e) {
      print('Erro durante o parsing: $e');
    }
    
    print('Parsing concluído');
    print('Total de canais encontrados: ${channels.length}');
    return channels;
  }

  Map<String, List<M3UChannel>> organizeChannels(List<M3UChannel> channels) {
    print('Organizando ${channels.length} canais por categoria...');
    final Map<String, List<M3UChannel>> organizedChannels = {
      'TV ao Vivo': [],
      'Filmes': [],
      'Séries': [],
      'Esportes': [],
      'Notícias': [],
      'Entretenimento': [],
      'Infantil': [],
      'Música': [],
      'Documentários': [],
      'Outros': [],
    };

    for (final channel in channels) {
      String category = 'Outros';
      
      if (channel.type == 'movie') {
        category = 'Filmes';
      } else if (channel.type == 'series') {
        category = 'Séries';
      } else {
        final groupTitle = channel.groupTitle?.toLowerCase() ?? '';
        
        switch (groupTitle) {
          case 'filmes':
          case 'movies':
          case 'cinema':
            category = 'Filmes';
            break;
          case 'séries':
          case 'series':
            category = 'Séries';
            break;
          case 'esportes':
          case 'sports':
            category = 'Esportes';
            break;
          case 'notícias':
          case 'news':
            category = 'Notícias';
            break;
          case 'entretenimento':
          case 'entertainment':
            category = 'Entretenimento';
            break;
          case 'infantil':
          case 'kids':
          case 'children':
            category = 'Infantil';
            break;
          case 'música':
          case 'music':
            category = 'Música';
            break;
          case 'documentários':
          case 'documentary':
            category = 'Documentários';
            break;
          default:
            if (channel.type == 'live') {
              category = 'TV ao Vivo';
            }
        }
      }
      
      organizedChannels[category]?.add(channel);
      
      if (channel.type == 'live') {
        organizedChannels['TV ao Vivo']?.add(channel);
      }
    }

    print('\nResumo de canais por categoria:');
    organizedChannels.forEach((category, channelList) {
      print('$category: ${channelList.length} canais');
    });

    return organizedChannels;
  }
} 