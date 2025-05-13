import 'package:anime/home/schedule_screen.dart';
import 'package:anime/home/skeleton_loader.dart';
import 'package:anime/model/anime.dart';
import 'package:anime/movie_screen.dart';
import 'package:anime/servis/api_serves.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final ApiService apiService = ApiService();
  List<Anime> animeList = [];
  List<Anime> filteredAnimeList = [];
  List<Anime> popularAnime = [];
  List<Map<String, dynamic>> newsList = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  String? error;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  double _lastOffset = 0;
  int _currentPage = 1;
  String? _selectedGenre;
  int? _selectedYear;
  String? _selectedStatus;
  String? _selectedSort;
  List<int> _years = [];
  TabController? _tabController;

  final List<String> _genres = [
    'Все',
    'Экшен',
    'Приключения',
    'Комедия',
    'Драма',
    'Фэнтези',
    'Ужасы',
    'Меха',
    'Романтика',
    'Научная фантастика',
  ];

  final List<String> _statuses = ['Все', 'ongoing', 'completed'];

  final List<String> _sortOptions = [
    'По популярности',
    'По дате',
    'По рейтингу',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchAnime();
    fetchYears();
    fetchNews();
    fetchPopularAnime();
    _scrollController.addListener(() {
      setState(() {
        _lastOffset = _scrollController.offset;
      });
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent * 0.8 &&
          !isLoadingMore) {
        fetchMoreAnime();
      }
    });
    _searchController.addListener(() {
      filterAnime();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> fetchAnime({
    String? genre,
    int? year,
    String? status,
    String? sort,
  }) async {
    try {
      final list = await apiService.fetchAnimeList(
        page: 1,
        genre: genre,
        year: year,
        status: status,
        sort:
            sort == 'По популярности'
                ? 'popularity'
                : sort == 'По дате'
                ? 'updated'
                : 'score',
      );
      setState(() {
        animeList = list;
        filteredAnimeList = list;
        isLoading = false;
        _currentPage = 1;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> fetchYears() async {
    try {
      final years = await apiService.fetchYears();
      setState(() {
        _years = years;
      });
    } catch (e) {
      print('Ошибка загрузки годов: $e');
    }
  }

  Future<void> fetchNews() async {
    try {
      final news = await apiService.fetchNews();
      setState(() {
        newsList = news;
      });
    } catch (e) {
      print('Ошибка загрузки новостей: $e');
    }
  }

  Future<void> fetchPopularAnime() async {
    try {
      final popular = await apiService.fetchPopularAnime();
      setState(() {
        popularAnime = popular;
      });
    } catch (e) {
      print('Ошибка загрузки популярных аниме: $e');
    }
  }

  Future<void> fetchMoreAnime() async {
    if (isLoadingMore) return;
    setState(() {
      isLoadingMore = true;
    });
    try {
      final list = await apiService.fetchAnimeList(
        page: _currentPage + 1,
        genre: _selectedGenre,
        year: _selectedYear,
        status: _selectedStatus,
        sort:
            _selectedSort == 'По популярности'
                ? 'popularity'
                : _selectedSort == 'По дате'
                ? 'updated'
                : 'score',
      );
      setState(() {
        _currentPage++;
        animeList.addAll(list);
        filteredAnimeList = animeList;
        isLoadingMore = false;
        if (_searchController.text.isNotEmpty) {
          filterAnime();
        }
      });
    } catch (e) {
      setState(() {
        isLoadingMore = false;
      });
    }
  }

  void filterAnime() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredAnimeList =
          animeList
              .where((anime) => anime.title.toLowerCase().contains(query))
              .toList();
    });
  }

  void filterByCriteria() {
    fetchAnime(
      genre: _selectedGenre == 'Все' ? null : _selectedGenre,
      year: _selectedYear,
      status: _selectedStatus == 'Все' ? null : _selectedStatus,
      sort: _selectedSort,
    );
  }

  void goToRandomAnime() async {
    setState(() {
      isLoading = true;
    });
    try {
      final randomAnime = await apiService.fetchRandomAnime();
      if (randomAnime != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MovieScreen(animeId: randomAnime.id),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки случайного аниме: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'AniLibria ',
                style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              TextSpan(
                text: 'Аниме',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle),
            onPressed: goToRandomAnime,
            tooltip: 'Случайное аниме',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Популярное'),
            Tab(text: 'Расписание'),
            Tab(text: 'Новости'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Поиск аниме...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                ).animate().fadeIn(duration: 500.ms),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedGenre ?? 'Все',
                        isExpanded: true,
                        items:
                            _genres
                                .map(
                                  (genre) => DropdownMenuItem(
                                    value: genre,
                                    child: Text(genre),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedGenre = value;
                          });
                          filterByCriteria();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<int>(
                        value: _selectedYear,
                        hint: const Text('Год'),
                        isExpanded: true,
                        items:
                            _years
                                .map(
                                  (year) => DropdownMenuItem(
                                    value: year,
                                    child: Text(year.toString()),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedYear = value;
                          });
                          filterByCriteria();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedStatus ?? 'Все',
                        isExpanded: true,
                        items:
                            _statuses
                                .map(
                                  (status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(
                                      status == 'ongoing'
                                          ? 'Идёт'
                                          : status == 'completed'
                                          ? 'Завершено'
                                          : 'Все',
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value;
                          });
                          filterByCriteria();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedSort ?? 'По популярности',
                        isExpanded: true,
                        items:
                            _sortOptions
                                .map(
                                  (sort) => DropdownMenuItem(
                                    value: sort,
                                    child: Text(sort),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSort = value;
                          });
                          filterByCriteria();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Популярное сейчас',
                  style: Theme.of(context).textTheme.headlineSmall,
                ).animate().fadeIn(duration: 500.ms),
              ),
              SizedBox(
                height: 200,
                child:
                    popularAnime.isEmpty
                        ? ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: 5,
                          itemBuilder:
                              (context, index) => const SkeletonLoader(
                                width: 120,
                                height: 180,
                                margin: EdgeInsets.symmetric(horizontal: 8),
                              ),
                        )
                        : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: popularAnime.length,
                          itemBuilder: (context, index) {
                            final anime = popularAnime[index];
                            return GestureDetector(
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
                              child: Container(
                                width: 120,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: anime.imageUrl,
                                    fit: BoxFit.cover,
                                    placeholder:
                                        (context, url) => const SkeletonLoader(
                                          width: 120,
                                          height: 180,
                                        ),
                                    errorWidget:
                                        (context, url, error) =>
                                            const Icon(Icons.error),
                                  ),
                                ),
                              ).animate().scale(duration: 300.ms),
                            );
                          },
                        ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Жанры',
                  style: Theme.of(context).textTheme.headlineSmall,
                ).animate().fadeIn(duration: 500.ms),
              ),
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _genres.length,
                  itemBuilder: (context, index) {
                    final genre = _genres[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: FilterChip(
                        label: Text(genre),
                        selected: _selectedGenre == genre,
                        onSelected: (selected) {
                          setState(() {
                            _selectedGenre = selected ? genre : null;
                          });
                          filterByCriteria();
                        },
                      ).animate().fadeIn(
                        duration: 500.ms,
                        delay: (index * 100).ms,
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                child:
                    isLoading
                        ? GridView.builder(
                          padding: const EdgeInsets.all(8),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
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
                                onPressed:
                                    () => fetchAnime(
                                      genre: _selectedGenre,
                                      year: _selectedYear,
                                      status: _selectedStatus,
                                      sort: _selectedSort,
                                    ),
                                child: const Text('Попробовать снова'),
                              ),
                            ],
                          ),
                        )
                        : GridView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(8),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.6,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                          itemCount:
                              filteredAnimeList.length +
                              (isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == filteredAnimeList.length) {
                              return const SkeletonLoader(
                                width: double.infinity,
                                height: 300,
                              );
                            }
                            final anime = filteredAnimeList[index];
                            final parallaxOffset = (_lastOffset - index * 100)
                                .clamp(-50.0, 50.0);
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
                                            (context) =>
                                                MovieScreen(animeId: anime.id),
                                      ),
                                    );
                                  },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(12),
                                              ),
                                          child: Transform.translate(
                                            offset: Offset(0, parallaxOffset),
                                            child: CachedNetworkImage(
                                              imageUrl: anime.imageUrl,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              placeholder:
                                                  (context, url) =>
                                                      const SkeletonLoader(
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              anime.title,
                                              style:
                                                  Theme.of(
                                                    context,
                                                  ).textTheme.titleMedium,
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
              ),
            ],
          ),
          const ScheduleScreen(),
          ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: newsList.length,
            itemBuilder: (context, index) {
              final news = newsList[index];
              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(news['title'] ?? 'Без заголовка'),
                  subtitle: Text(
                    news['description'] ?? 'Нет описания',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {},
                ).animate().fadeIn(duration: 500.ms, delay: (index * 100).ms),
              );
            },
          ),
        ],
      ),
    );
  }
}
