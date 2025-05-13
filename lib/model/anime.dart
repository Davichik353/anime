class Anime {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String rating;
  final List<String> genres;
  final String? releaseDate;
  final String? streamingUrl;
  final String? torrentUrl;
  final String? status;
  final Map<String, dynamic>? schedule;
  final List<Map<String, dynamic>>? episodes;

  Anime({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.rating,
    required this.genres,
    this.releaseDate,
    this.streamingUrl,
    this.torrentUrl,
    this.status,
    this.schedule,
    this.episodes,
  });

  factory Anime.fromAniListJson(Map<String, dynamic> json) {
    return Anime(
      id: json['id'].toString(),
      title: json['title']?['romaji'] ?? 'Без названия',
      description: '',
      imageUrl: json['coverImage']?['large'] ?? '',
      rating: 'N/A',
      genres: [],
      releaseDate: null,
      streamingUrl: null,
      torrentUrl: null,
      status: null,
      schedule: null,
      episodes: null,
    );
  }

  factory Anime.fromAniLibriaJson(Map<String, dynamic> json) {
    return Anime(
      id: json['id'].toString(),
      title: json['names']?['ru'] ?? json['names']?['en'] ?? 'Без названия',
      description: json['description'] ?? 'Нет описания',
      imageUrl: '',
      rating: json['score']?.toString() ?? 'N/A',
      genres:
          (json['genres'] as List<dynamic>?)
              ?.map((g) => g.toString())
              .toList() ??
          [],
      releaseDate: json['season']?['year']?.toString() ?? null,
      streamingUrl:
          (json['player']?['playlist'] as List<dynamic>?)?.isNotEmpty == true
              ? json['player']['playlist'][0]['hd'] ??
                  json['player']['playlist'][0]['sd']
              : null,
      torrentUrl:
          json['torrents']?['list']?.isNotEmpty == true
              ? json['torrents']['list'][0]['url']
              : null,
      status: json['status']?['string']?.toString(),
      schedule: json['schedule'],
      episodes:
          (json['player']?['playlist'] as List<dynamic>?)
              ?.map(
                (e) => {'episode': e['episode'], 'sd': e['sd'], 'hd': e['hd']},
              )
              .toList(),
    );
  }
}
