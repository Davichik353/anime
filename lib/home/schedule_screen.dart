import 'package:anime/home/skeleton_loader.dart';
import 'package:anime/model/anime.dart';
import 'package:anime/movie_screen.dart';
import 'package:anime/servis/api_serves.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ScheduleScreenState createState() => ScheduleScreenState();
}

class ScheduleScreenState extends State<ScheduleScreen> {
  final ApiService apiService = ApiService();
  List<Map<String, dynamic>> schedule = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchSchedule();
  }

  Future<void> fetchSchedule() async {
    try {
      final data = await apiService.fetchSchedule();
      setState(() {
        schedule = data;
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
      backgroundColor: Theme.of(context).colorScheme.background,
      body:
          isLoading
              ? ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: 7,
                itemBuilder:
                    (context, index) => const SkeletonLoader(
                      width: double.infinity,
                      height: 60,
                      margin: EdgeInsets.symmetric(vertical: 4),
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
                      onPressed: fetchSchedule,
                      child: const Text('Попробовать снова'),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: schedule.length,
                itemBuilder: (context, index) {
                  final day = schedule[index];
                  final List<dynamic> titles = day['list'] ?? [];
                  return ExpansionTile(
                    title: Text(
                      day['day'] == 0
                          ? 'Понедельник'
                          : day['day'] == 1
                          ? 'Вторник'
                          : day['day'] == 2
                          ? 'Среда'
                          : day['day'] == 3
                          ? 'Четверг'
                          : day['day'] == 4
                          ? 'Пятница'
                          : day['day'] == 5
                          ? 'Суббота'
                          : 'Воскресенье',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    children:
                        titles.map((title) {
                          final anime = Anime.fromAniLibriaJson(title);
                          return ListTile(
                            leading: CachedNetworkImage(
                              imageUrl: anime.imageUrl,
                              width: 50,
                              height: 70,
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) => const SkeletonLoader(
                                    width: 50,
                                    height: 70,
                                  ),
                              errorWidget:
                                  (context, url, error) =>
                                      const Icon(Icons.error),
                            ),
                            title: Text(anime.title),
                            subtitle: Text(
                              'Статус: ${anime.status == 'ongoing'
                                  ? 'Идёт'
                                  : anime.status == 'completed'
                                  ? 'Завершено'
                                  : 'Неизвестно'}',
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          MovieScreen(animeId: anime.id),
                                ),
                              );
                            },
                          ).animate().fadeIn(
                            duration: 500.ms,
                            delay: (index * 100).ms,
                          );
                        }).toList(),
                  ).animate().fadeIn(duration: 500.ms);
                },
              ),
    );
  }
}
