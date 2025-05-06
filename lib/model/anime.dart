class Anime {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final List<String> genres;
  final double rating;

  Anime({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.genres,
    required this.rating,
  });

  factory Anime.fromJson(Map<String, dynamic> json) {
    return Anime(
      id: json['mal_id']?.toString() ?? '0',
      title: json['title'] ?? 'Без названия',
      description: json['synopsis'] ?? 'Описание отсутствует',
      imageUrl: json['images']?['jpg']?['image_url'] ?? '',
      genres:
          (json['genres'] as List<dynamic>?)
              ?.map((g) => g['name'].toString())
              .toList() ??
          [],
      rating: (json['score'] ?? 0.0).toDouble(),
    );
  }
}
