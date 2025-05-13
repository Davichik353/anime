import 'dart:convert';
import 'package:anime/model/anime.dart';
import 'package:http/http.dart' as http;
import 'package:graphql/client.dart';

class ApiService {
  final GraphQLClient _aniListClient = GraphQLClient(
    link: HttpLink('https://graphql.anilist.co'),
    cache: GraphQLCache(),
  );

  Future<List<Anime>> fetchAnimeList({
    int page = 1,
    String? query,
    String? genre,
    int? year,
    String? status,
    String? sort,
  }) async {
    const String aniListQuery = '''
      query (\$page: Int) {
        Page(page: \$page, perPage: 25) {
          media(type: ANIME) {
            id
            title { romaji }
            coverImage { large }
          }
        }
      }
    ''';
    final QueryOptions options = QueryOptions(
      document: gql(aniListQuery),
      variables: {'page': page},
    );
    final result = await _aniListClient.query(options);
    if (result.hasException) {
      throw Exception('Ошибка AniList: ${result.exception.toString()}');
    }
    final aniListData =
        (result.data?['Page']?['media'] as List<dynamic>?) ?? [];

    final List<Anime> animeList = [];
    for (var aniListItem in aniListData) {
      try {
        final uri = Uri.parse(
          'https://api.anilibria.tv/v3/title/search/advanced?search=${Uri.encodeComponent(aniListItem['title']['romaji'])}&limit=1${genre != null ? '&genres=$genre' : ''}${year != null ? '&season_year=$year' : ''}${status != null ? '&status=$status' : ''}${sort != null ? '&sort=$sort' : ''}',
        );
        final aniLibriaResponse = await http.get(uri);
        print('AniLibria запрос: ${aniLibriaResponse.request?.url}');
        print('AniLibria статус: ${aniLibriaResponse.statusCode}');
        if (aniLibriaResponse.statusCode == 200) {
          final aniLibriaData = json.decode(aniLibriaResponse.body);
          final titleData =
              aniLibriaData['list']?.isNotEmpty == true
                  ? aniLibriaData['list'][0]
                  : null;
          if (titleData != null) {
            animeList.add(
              Anime(
                id: aniListItem['id'].toString(),
                title:
                    titleData['names']?['ru'] ?? aniListItem['title']['romaji'],
                description: titleData['description'] ?? 'Нет описания',
                imageUrl: aniListItem['coverImage']['large'] ?? '',
                rating: titleData['score']?.toString() ?? 'N/A',
                genres:
                    (titleData['genres'] as List<dynamic>?)
                        ?.map((g) => g.toString())
                        .toList() ??
                    [],
                releaseDate: titleData['season']?['year']?.toString() ?? null,
                streamingUrl:
                    (titleData['player']?['playlist'] as List<dynamic>?)
                                ?.isNotEmpty ==
                            true
                        ? titleData['player']['playlist'][0]['hd'] ??
                            titleData['player']['playlist'][0]['sd']
                        : null,
                torrentUrl:
                    titleData['torrents']?['list']?.isNotEmpty == true
                        ? titleData['torrents']['list'][0]['url']
                        : null,
                status: titleData['status'] ?? null,
                schedule: titleData['schedule'],
                episodes:
                    (titleData['player']?['playlist'] as List<dynamic>?)
                        ?.map(
                          (e) => {
                            'episode': e['episode'],
                            'sd': e['sd'],
                            'hd': e['hd'],
                          },
                        )
                        .toList(),
              ),
            );
          } else {
            animeList.add(Anime.fromAniListJson(aniListItem));
          }
        } else {
          animeList.add(Anime.fromAniListJson(aniListItem));
        }
      } catch (e) {
        print('Ошибка AniLibria: $e');
        animeList.add(Anime.fromAniListJson(aniListItem));
      }
    }
    return animeList;
  }

  Future<Anime?> fetchRandomAnime() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.anilibria.tv/v3/title/random'),
      );
      print('AniLibria random запрос: ${response.request?.url}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Anime.fromAniLibriaJson(data);
      }
      return null;
    } catch (e) {
      print('Ошибка random AniLibria: $e');
      return null;
    }
  }

  Future<List<int>> fetchYears() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.anilibria.tv/v3/years'),
      );
      print('AniLibria years запрос: ${response.request?.url}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final years = List<int>.from(data);
        return years.where((year) => year >= 1980).toList();
      }
      return List<int>.generate(DateTime.now().year - 1979, (i) => 1980 + i);
    } catch (e) {
      print('Ошибка years AniLibria: $e');
      return List<int>.generate(DateTime.now().year - 1979, (i) => 1980 + i);
    }
  }

  Future<List<Map<String, dynamic>>> fetchSchedule() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.anilibria.tv/v3/schedule'),
      );
      print('AniLibria schedule запрос: ${response.request?.url}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      print('Ошибка schedule AniLibria: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchNews() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.anilibria.tv/v3/rss?type=news'),
      );
      print('AniLibria news запрос: ${response.request?.url}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['items']);
      }
      return [];
    } catch (e) {
      print('Ошибка news AniLibria: $e');
      return [];
    }
  }

  Future<Anime> fetchAnimeDetails(String id) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.anilibria.tv/v3/title?id=$id'),
      );
      print('AniLibria details запрос: ${response.request?.url}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Anime.fromAniLibriaJson(data);
      } else {
        throw Exception('Не удалось загрузить детали аниме');
      }
    } catch (e) {
      print('Ошибка details AniLibria: $e');
      throw Exception('Ошибка загрузки деталей: $e');
    }
  }

  Future<List<Anime>> fetchPopularAnime() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.anilibria.tv/v3/title/search?sort=popularity&limit=10',
        ),
      );
      print('AniLibria popular запрос: ${response.request?.url}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> titles = data['list'];
        return titles.map((json) => Anime.fromAniLibriaJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Ошибка popular AniLibria: $e');
      return [];
    }
  }
}
