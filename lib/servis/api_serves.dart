import 'package:anime/model/anime.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'https://api.jikan.moe/v4';

  Future<List<Anime>> fetchAnimeList() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/anime?limit=20'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> animeData = data['data'];
        return animeData.map((json) => Anime.fromJson(json)).toList();
      } else {
        throw Exception(
          'Ошибка загрузки: статус ${response.statusCode}, ответ: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Не удалось загрузить данные: $e');
    }
  }

  Future<Anime> fetchAnimeDetails(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/anime/$id'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Anime.fromJson(data['data']);
      } else {
        throw Exception(
          'Ошибка загрузки деталей: статус ${response.statusCode}, ответ: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Не удалось загрузить детали аниме: $e');
    }
  }
}
