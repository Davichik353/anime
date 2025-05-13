import 'dart:convert';
import 'package:anime/home/skeleton_loader.dart';
import 'package:anime/movie_screen.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'anime.dart';

class NewReleasesScreen extends StatefulWidget {
  const NewReleasesScreen({super.key});

  @override
  NewReleasesScreenState createState() => NewReleasesScreenState();
}

class NewReleasesScreenState extends State<NewReleasesScreen> {
  List<Anime> animeList = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  String? error;
  final ScrollController _scrollController = ScrollController();
  double _lastOffset = 0;
  int _currentPage = 1;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    initializeNotifications();
    fetchNewReleases();
    _scrollController.addListener(() {
      setState(() {
        _lastOffset = _scrollController.offset;
      });
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent * 0.8 &&
          !isLoadingMore) {
        fetchMoreReleases();
      }
    });
  }

  void initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _notificationsPlugin.initialize(initializationSettings);
  }

  void showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'new_releases',
          'Новые релизы',
          importance: Importance.max,
          priority: Priority.high,
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await _notificationsPlugin.show(0, title, body, platformChannelSpecifics);
  }

  Future<void> fetchNewReleases() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.anilibria.tv/v3/title/updates?limit=25&page=1'),
      );
      print('AniLibria updates запрос: ${response.request?.url}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> updates = data['list'];
        setState(() {
          animeList =
              updates.map((json) => Anime.fromAniLibriaJson(json)).toList();
          isLoading = false;
        });
        if (animeList.isNotEmpty) {
          showNotification(
            'Новый релиз!',
            'Вышел новый эпизод: ${animeList.first.title}',
          );
        }
      } else {
        throw Exception('Не удалось загрузить новые релизы');
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> fetchMoreReleases() async {
    if (isLoadingMore) return;
    setState(() {
      isLoadingMore = true;
    });
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.anilibria.tv/v3/title/updates?limit=25&page=${_currentPage + 1}',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> updates = data['list'];
        setState(() {
          _currentPage++;
          animeList.addAll(
            updates.map((json) => Anime.fromAniLibriaJson(json)).toList(),
          );
          isLoadingMore = false;
        });
      } else {
        throw Exception('Не удалось загрузить дополнительные релизы');
      }
    } catch (e) {
      setState(() {
        isLoadingMore = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(title: const Text('Новые релизы')),
      body:
          isLoading
              ? GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.6,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 10,
                itemBuilder:
                    (context, index) => const SkeletonLoader(
                      width: double.infinity,
                      height: 300,
                    ),
              )
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
                      onPressed: fetchNewReleases,
                      child: const Text('Попробовать снова'),
                    ),
                  ],
                ),
              )
              : GridView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.6,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: animeList.length + (isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == animeList.length) {
                    return const SkeletonLoader(
                      width: double.infinity,
                      height: 300,
                    );
                  }
                  final anime = animeList[index];
                  final parallaxOffset = (_lastOffset - index * 100).clamp(
                    -50.0,
                    50.0,
                  );
                  return Hero(
                    tag: 'poster_${anime.id}',
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => MovieScreen(animeId: anime.id),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                child: Transform.translate(
                                  offset: Offset(0, parallaxOffset),
                                  child: CachedNetworkImage(
                                    imageUrl: anime.imageUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    placeholder:
                                        (context, url) => const SkeletonLoader(
                                          width: double.infinity,
                                          height: double.infinity,
                                        ),
                                    errorWidget:
                                        (context, url, error) =>
                                            const Icon(Icons.error),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    anime.title,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Релиз: ${anime.releaseDate ?? 'Неизвестно'}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge!
                                        .copyWith(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(duration: 500.ms),
                  );
                },
              ),
    );
  }
}
