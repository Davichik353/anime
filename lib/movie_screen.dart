import 'package:anime/model/anime.dart';
import 'package:anime/servis/api_serves.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MovieScreen extends StatefulWidget {
  final String animeId;

  MovieScreen({required this.animeId});

  @override
  _MovieScreenState createState() => _MovieScreenState();
}

class _MovieScreenState extends State<MovieScreen> {
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
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            text: anime?.title ?? 'Загрузка...',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
      ),
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
                      height: 400,
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
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Title: ',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall!
                                      .copyWith(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(
                                  text: anime!.title,
                                  style:
                                      Theme.of(context).textTheme.headlineSmall,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Рейтинг: ${anime!.rating}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Жанры: ${anime!.genres.join(', ')}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
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
