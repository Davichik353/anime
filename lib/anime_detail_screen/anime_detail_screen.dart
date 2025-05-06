import 'package:anime/model/anime.dart';
import 'package:anime/servis/api_serves.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AnimeDetailScreen extends StatefulWidget {
  final String animeId;

  AnimeDetailScreen({required this.animeId});

  @override
  _AnimeDetailScreenState createState() => _AnimeDetailScreenState();
}

class _AnimeDetailScreenState extends State<AnimeDetailScreen> {
  final ApiService apiService = ApiService();
  Anime? anime;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchAnimeDetails();
  }

  Future<void> fetchAnimeDetails() async {
    try {
      final details = await apiService.fetchAnimeDetails(widget.animeId);
      setState(() {
        anime = details;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(anime?.title ?? 'Загрузка...')),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : error != null
              ? Center(child: Text('Ошибка: $error'))
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CachedNetworkImage(
                      imageUrl: anime!.imageUrl,
                      height: 300,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => CircularProgressIndicator(),
                      errorWidget: (context, url, error) => Icon(Icons.error),
                    ),
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            anime!.title,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          SizedBox(height: 8),
                          Text('Рейтинг: ${anime!.rating}'),
                          SizedBox(height: 8),
                          Text('Жанры: ${anime!.genres.join(', ')}'),
                          SizedBox(height: 16),
                          Text(
                            anime!.description,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
