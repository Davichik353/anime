import 'package:anime/model/anime.dart';
import 'package:anime/servis/api_serves.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chewie/chewie.dart';
import 'package:torrent_streamer/torrent_streamer.dart';
import 'package:video_player/video_player.dart';
//import 'package:flutter_torrent_streamer/flutter_torrent_streamer.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MovieScreen extends StatefulWidget {
  final String animeId;

  const MovieScreen({required this.animeId, super.key});

  @override
  MovieScreenState createState() => MovieScreenState();
}

class MovieScreenState extends State<MovieScreen> {
  final ApiService apiService = ApiService();
  Anime? anime;
  bool isLoading = true;
  String? error;
  bool isFavorite = false;
  String? selectedQuality = 'HD';
  int? selectedEpisode = 1;
  ChewieController? _chewieController;
  VideoPlayerController? _videoPlayerController;

  @override
  void initState() {
    super.initState();
    fetchAnimeDetails();
    checkFavorite();
    addToHistory();
  }

  Future<void> fetchAnimeDetails() async {
    try {
      final details = await apiService.fetchAnimeDetails(widget.animeId);
      setState(() {
        anime = details;
        isLoading = false;
        if (details.episodes?.isNotEmpty == true) {
          initializeVideoPlayer(
            details.episodes![0][selectedQuality!.toLowerCase()],
          );
        }
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  void initializeVideoPlayer(String url) {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _videoPlayerController = VideoPlayerController.network(url);
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController!,
      autoPlay: false,
      looping: false,
      aspectRatio: 16 / 9,
      allowFullScreen: true,
      fullScreenByDefault: false,
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Text(
            'Ошибка воспроизведения: $errorMessage',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        );
      },
    );
  }

  Future<void> checkFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList('favorites') ?? [];
    setState(() {
      isFavorite = favorites.contains(widget.animeId);
    });
  }

  Future<void> toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList('favorites') ?? [];
    if (isFavorite) {
      favorites.remove(widget.animeId);
    } else {
      favorites.add(widget.animeId);
    }
    await prefs.setStringList('favorites', favorites);
    setState(() {
      isFavorite = !isFavorite;
    });
  }

  Future<void> addToHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('history') ?? [];
    if (!history.contains(widget.animeId)) {
      history.add(widget.animeId);
      await prefs.setStringList('history', history);
    }
  }

  void downloadTorrent() async {
    if (anime?.torrentUrl != null) {
      try {
        await TorrentStreamer.start(anime!.torrentUrl!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Загрузка торрента начата')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка загрузки торрента: $e')));
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Торрент недоступен')));
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Ошибка: $error',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: fetchAnimeDetails,
                      child: const Text('Попробовать снова'),
                    ),
                  ],
                ),
              )
              : CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 400,
                    floating: false,
                    pinned: true,
                    actions: [
                      IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.white,
                        ),
                        onPressed: toggleFavorite,
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(
                        anime!.title,
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall!.copyWith(
                          color: Colors.white,
                          shadows: [
                            const Shadow(
                              blurRadius: 10,
                              color: Colors.black,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          Hero(
                            tag: 'poster_${anime!.id}',
                            child: CachedNetworkImage(
                              imageUrl: anime!.imageUrl,
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) =>
                                      const CircularProgressIndicator(),
                              errorWidget:
                                  (context, url, error) =>
                                      const Icon(Icons.error),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 500.ms),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_chewieController != null)
                            AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Chewie(controller: _chewieController!),
                            ).animate().slideY(begin: 0.2, duration: 500.ms)
                          else
                            const Text(
                              'Видео недоступно',
                            ).animate().fadeIn(duration: 500.ms),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButton<int>(
                                  value: selectedEpisode,
                                  hint: const Text('Эпизод'),
                                  isExpanded: true,
                                  items:
                                      anime?.episodes
                                          ?.map(
                                            (e) => DropdownMenuItem<int>(
                                              value: e['episode'] as int,
                                              child: Text(
                                                'Эпизод ${e['episode']}',
                                              ),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedEpisode = value;
                                      final episode = anime!.episodes!
                                          .firstWhere(
                                            (e) => e['episode'] == value,
                                          );
                                      initializeVideoPlayer(
                                        episode[selectedQuality!.toLowerCase()],
                                      );
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              DropdownButton<String>(
                                value: selectedQuality,
                                items:
                                    ['SD', 'HD']
                                        .map(
                                          (quality) => DropdownMenuItem<String>(
                                            value: quality,
                                            child: Text(quality),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedQuality = value;
                                    final episode = anime!.episodes!.firstWhere(
                                      (e) => e['episode'] == selectedEpisode,
                                    );
                                    initializeVideoPlayer(
                                      episode[value!.toLowerCase()],
                                    );
                                  });
                                },
                              ),
                            ],
                          ).animate().slideX(begin: 0.2, duration: 500.ms),
                          const SizedBox(height: 16),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Название: ',
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
                          ).animate().fadeIn(duration: 500.ms),
                          const SizedBox(height: 8),
                          Text(
                            'Рейтинг: ${anime!.rating}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
                          const SizedBox(height: 8),
                          Text(
                            'Жанры: ${anime!.genres.join(', ')}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
                          const SizedBox(height: 8),
                          Text(
                            'Статус: ${anime!.status == 'ongoing'
                                ? 'Идёт'
                                : anime!.status == 'completed'
                                ? 'Завершено'
                                : 'Неизвестно'}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ).animate().fadeIn(duration: 500.ms, delay: 300.ms),
                          const SizedBox(height: 8),
                          Text(
                            'Дата релиза: ${anime!.releaseDate ?? 'Неизвестно'}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ).animate().fadeIn(duration: 500.ms, delay: 400.ms),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: downloadTorrent,
                            icon: const Icon(Icons.download),
                            label: const Text('Скачать торрент'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                            ),
                          ).animate().slideY(begin: 0.2, duration: 500.ms),
                          const SizedBox(height: 16),
                          Text(
                            'Описание:',
                            style: Theme.of(context).textTheme.headlineSmall!
                                .copyWith(fontWeight: FontWeight.bold),
                          ).animate().fadeIn(duration: 500.ms),
                          const SizedBox(height: 8),
                          Text(
                            anime!.description,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
