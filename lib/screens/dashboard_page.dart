
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/theme/app_theme.dart';
import '../core/favorites_store.dart';
import '../core/itinerary_store.dart';
import '../data/lipa_places.dart';
import 'explore_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int selectedIndex = 0;
  String selectedExploreCategory = 'All';
  bool isLoadingTrip = true;

  DateTime get tripStartDate => ItineraryStore.tripStartDate.value;
  int get tripDays => ItineraryStore.tripDays.value;

  final List<String> pageTitles = [
    'Discover Lipa',
    'Explore Places',
    'Your Favorites',
    'My Trip Planner',
    'My Profile',
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await loadDashboardData();
    });
  }

  Future<void> loadDashboardData() async {
    await FavoritesStore.load();
    await ItineraryStore.load();
    await ItineraryStore.loadTripPlan();

    if (!mounted) return;

    setState(() {
      isLoadingTrip = false;
    });
  }

  void changeTab(int index) {
    if (index < 0 || index >= pageTitles.length) return;

    setState(() {
      selectedIndex = index;
    });
  }

  void openExploreCategory(String category) {
    setState(() {
      selectedExploreCategory = category;
      selectedIndex = 1;
    });
  }

  Future<void> chooseTripDate() async {
    final today = DateTime.now();
    final currentDate = tripStartDate.isBefore(
      DateTime(today.year, today.month, today.day),
    )
        ? today
        : tripStartDate;

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: DateTime(today.year + 2, today.month, today.day),
      helpText: 'Choose your trip start date',
    );

    if (selectedDate == null || !mounted) return;

    setState(() {
      ItineraryStore.tripStartDate.value = selectedDate;
    });

    await saveTripSettings();
  }

  Future<void> changeTripDuration(int days) async {
    setState(() {
      ItineraryStore.tripDays.value = days;
    });

    await saveTripSettings();
  }

  Future<void> saveTripSettings() async {
    await ItineraryStore.saveTripPlan(
      startDate: tripStartDate,
      days: tripDays,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Trip plan settings saved.'),
      ),
    );
  }

  String formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to log out: $e')),
      );
    }
  }

  List<Widget> get pages {
    return [
      _buildHome(),
      ExplorePage(
        key: ValueKey(selectedExploreCategory),
        initialCategory: selectedExploreCategory,
      ),
      _buildFavorites(),
      _buildPlanner(),
      _buildProfile(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          pageTitles[selectedIndex],
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: SafeArea(
        child: IndexedStack(
          index: selectedIndex,
          children: pages,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: changeTab,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.sage,
        elevation: 0,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Planner',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HOME PAGE
  // ============================================================

  Widget _buildHome() {
    final featuredPlaces = LipaPlaces.places
        .where(
          (place) => place['category'] == 'Tourist Destinations',
        )
        .take(5)
        .toList();

    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim().split(' ').first
        : 'Explorer';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // WELCOME HEADER
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'YOUR LOCAL TRAVEL GUIDE',
                      style: TextStyle(
                        color: AppColors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.8,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Hello, $displayName!',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Your next Lipa adventure starts here.',
                      style: TextStyle(
                        color: AppColors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 49,
                height: 49,
                decoration: BoxDecoration(
                  color: AppColors.sage,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.travel_explore,
                  color: AppColors.forest,
                  size: 27,
                ),
              ),
            ],
          ),

          const SizedBox(height: 23),

          // HERO BANNER
          _buildHeroBanner(),

          const SizedBox(height: 22),

          // SEARCH SHORTCUT
          InkWell(
            onTap: () => openExploreCategory('All'),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search,
                    color: AppColors.forest,
                    size: 23,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Where would you like to go?',
                      style: TextStyle(
                        color: AppColors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 15,
                    color: AppColors.green,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 29),

          // CATEGORIES
          _buildHomeSectionHeader(
            title: 'Explore by category',
            subtitle: 'Find something that interests you',
          ),

          const SizedBox(height: 15),

          SizedBox(
            height: 116,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildHomeCategoryCard(
                  title: 'Destinations',
                  icon: Icons.location_city,
                  color: const Color(0xFFE7EBDD),
                  onTap: () => openExploreCategory(
                    'Tourist Destinations',
                  ),
                ),
                _buildHomeCategoryCard(
                  title: 'Local Food',
                  icon: Icons.restaurant,
                  color: const Color(0xFFF4E8D7),
                  onTap: () => openExploreCategory(
                    'Food & Restaurants',
                  ),
                ),
                _buildHomeCategoryCard(
                  title: 'Activities',
                  icon: Icons.directions_walk,
                  color: const Color(0xFFE4EBE9),
                  onTap: () => openExploreCategory('Activities'),
                ),
                _buildHomeCategoryCard(
                  title: 'All Places',
                  icon: Icons.explore,
                  color: const Color(0xFFECE7F2),
                  onTap: () => openExploreCategory('All'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // FEATURED DESTINATIONS
          _buildHomeSectionHeader(
            title: 'Discover Lipa',
            subtitle: 'Places worth adding to your journey',
            actionText: 'See all',
            onAction: () => openExploreCategory('All'),
          ),

          const SizedBox(height: 15),

          if (featuredPlaces.isEmpty)
            const Text(
              'No featured destinations available yet.',
              style: TextStyle(color: AppColors.grey),
            )
          else
            SizedBox(
              height: 245,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: featuredPlaces.length,
                itemBuilder: (context, index) {
                  return _buildHomeDestinationCard(
                    featuredPlaces[index],
                  );
                },
              ),
            ),

          const SizedBox(height: 29),

          // TRIP PLANNER SUMMARY
          _buildHomeSectionHeader(
            title: 'Your travel plans',
            subtitle: 'Keep your Lipa trip organized',
          ),

          const SizedBox(height: 14),

          ValueListenableBuilder<List<Map<String, dynamic>>>(
            valueListenable: ItineraryStore.itinerary,
            builder: (context, places, child) {
              return _buildTripSummary(places.length);
            },
          ),

          const SizedBox(height: 22),

          // FAVORITES SUMMARY
          ValueListenableBuilder<List<Map<String, dynamic>>>(
            valueListenable: FavoritesStore.favorites,
            builder: (context, favorites, child) {
              return _buildFavoritesSummary(favorites.length);
            },
          ),

          const SizedBox(height: 25),

          // FOOTER
          Center(
            child: Column(
              children: [
                const Icon(
                  Icons.eco_outlined,
                  color: AppColors.green,
                  size: 25,
                ),
                const SizedBox(height: 7),
                const Text(
                  'EXPLORE LIPA',
                  style: TextStyle(
                    color: AppColors.forest,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Discover the heart of Batangas.',
                  style: TextStyle(
                    color: AppColors.grey.withValues(alpha: 0.9),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // HERO BANNER
  Widget _buildHeroBanner() {
    return Container(
      height: 285,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.forest,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/casa_de_segunda.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF56765C),
                      Color(0xFF183A2B),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.landscape_outlined,
                  color: Colors.white24,
                  size: 110,
                ),
              );
            },
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.12),
                  Colors.black.withValues(alpha: 0.78),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(23),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Text(
                    'WELCOME TO LIPA CITY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Discover the\nBeauty of Lipa',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 31,
                    fontWeight: FontWeight.bold,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 9),
                const Text(
                  'Explore heritage, taste local flavors, and find experiences worth remembering.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 17),
                ElevatedButton(
                  onPressed: () => openExploreCategory('All'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.forest,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 19,
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Start exploring',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // SECTION HEADER
  Widget _buildHomeSectionHeader({
    required String title,
    required String subtitle,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.forest,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (actionText != null && onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionText,
              style: const TextStyle(
                color: AppColors.green,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  // CATEGORY CARD
  Widget _buildHomeCategoryCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 112,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                color: AppColors.forest,
                size: 29,
              ),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.forest,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // FEATURED DESTINATION CARD
  Widget _buildHomeDestinationCard(
    Map<String, dynamic> place,
  ) {
    final name = place['name']?.toString() ?? 'Destination';
    final location = place['location']?.toString() ?? 'Lipa City';
    final imagePath = place['image']?.toString() ?? '';

    return GestureDetector(
      onTap: () => openExploreCategory('Tourist Destinations'),
      child: Container(
        width: 205,
        margin: const EdgeInsets.only(right: 13),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imagePath.isNotEmpty)
                    Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _homeImageFallback();
                      },
                    )
                  else
                    _homeImageFallback(),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'FEATURED',
                        style: TextStyle(
                          color: AppColors.forest,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.forest,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.green,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.grey,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _homeImageFallback() {
    return Container(
      color: AppColors.sage,
      child: const Center(
        child: Icon(
          Icons.landscape_outlined,
          size: 48,
          color: AppColors.forest,
        ),
      ),
    );
  }

  // TRIP SUMMARY
  Widget _buildTripSummary(int totalPlaces) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: AppColors.forest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.map_outlined,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'My Lipa Itinerary',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white70,
                size: 15,
              ),
            ],
          ),
          const SizedBox(height: 17),
          Text(
            '$totalPlaces ${totalPlaces == 1 ? 'destination' : 'destinations'} saved',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '$tripDays ${tripDays == 1 ? 'day' : 'days'} planned • ${formatDate(tripStartDate)}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 17),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => changeTab(3),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.forest,
                backgroundColor: Colors.white,
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Open my trip planner',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // FAVORITES SUMMARY
  Widget _buildFavoritesSummary(int totalFavorites) {
    return InkWell(
      onTap: () => changeTab(2),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8E8E8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.favorite,
                color: Colors.redAccent,
                size: 23,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your saved favorites',
                    style: TextStyle(
                      color: AppColors.forest,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalFavorites ${totalFavorites == 1 ? 'place' : 'places'} saved for later',
                    style: const TextStyle(
                      color: AppColors.grey,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 15,
              color: AppColors.green,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FAVORITES PAGE
  // ============================================================

  Widget _buildFavorites() {
    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: FavoritesStore.favorites,
      builder: (context, savedPlaces, child) {
        if (savedPlaces.isEmpty) {
          return _buildEmptyState(
            icon: Icons.favorite_border,
            title: 'No Favorites Yet',
            message:
                'Save places you want to visit by tapping the heart button on their photos.',
            buttonText: 'Explore Places',
            onPressed: () => openExploreCategory('All'),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              '${savedPlaces.length} saved ${savedPlaces.length == 1 ? 'place' : 'places'}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 15),
            ...savedPlaces.map((place) {
              final name = place['name']?.toString() ?? 'Unknown place';

              return _buildPlaceCard(
                place: place,
                trailing: IconButton(
                  tooltip: 'Remove from favorites',
                  onPressed: () {
                    FavoritesStore.remove(name);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$name removed from favorites'),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.favorite,
                    color: Colors.redAccent,
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  // ============================================================
  // TRIP PLANNER
  // ============================================================

  Widget _buildPlanner() {
    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: ItineraryStore.itinerary,
      builder: (context, savedPlaces, child) {
        final totalPlaces = savedPlaces.length;

        if (isLoadingTrip) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.forest,
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Plan Your Lipa Trip',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Create your own schedule and organize the places you want to visit around Lipa City.',
                style: TextStyle(
                  color: AppColors.grey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),

              _plannerSection(
                title: '1. When are you visiting?',
                child: InkWell(
                  onTap: chooseTripDate,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: AppColors.forest,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Trip start date',
                                style: TextStyle(
                                  color: AppColors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatDate(tripStartDate),
                                style: const TextStyle(
                                  color: AppColors.forest,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.edit_calendar,
                          color: AppColors.green,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              _plannerSection(
                title: '2. How long is your trip?',
                child: DropdownButtonFormField<int>(
                  key: ValueKey(tripDays),
                  initialValue: tripDays,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.border,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.border,
                      ),
                    ),
                  ),
                  items: List.generate(5, (index) {
                    final days = index + 1;

                    return DropdownMenuItem(
                      value: days,
                      child: Text(
                        '$days ${days == 1 ? 'day' : 'days'}',
                      ),
                    );
                  }),
                  onChanged: (value) {
                    if (value != null) {
                      changeTripDuration(value);
                    }
                  },
                ),
              ),

              const SizedBox(height: 18),

              _plannerSection(
                title: '3. Your destinations',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          color: AppColors.forest,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$totalPlaces ${totalPlaces == 1 ? 'place' : 'places'} added',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.forest,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => openExploreCategory('All'),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add places'),
                        ),
                      ],
                    ),
                    if (savedPlaces.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.map_outlined,
                              color: AppColors.green,
                              size: 42,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Your itinerary is empty',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.forest,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Browse Explore and add destinations to start building your trip.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.grey,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => openExploreCategory('All'),
                                icon: const Icon(Icons.explore),
                                label: const Text(
                                  'Browse Lipa Destinations',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              if (savedPlaces.isNotEmpty) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Your Daily Itinerary',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Text(
                      '$tripDays ${tripDays == 1 ? 'day' : 'days'}',
                      style: const TextStyle(
                        color: AppColors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your selected destinations are divided across your chosen trip days.',
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),

                ...List.generate(tripDays, (dayIndex) {
                  final dayPlaces = <Map<String, dynamic>>[];

                  for (int i = 0; i < savedPlaces.length; i++) {
                    if (i % tripDays == dayIndex) {
                      dayPlaces.add(savedPlaces[i]);
                    }
                  }

                  final dayDate = tripStartDate.add(
                    Duration(days: dayIndex),
                  );

                  return _buildDayCard(
                    dayNumber: dayIndex + 1,
                    date: dayDate,
                    places: dayPlaces,
                  );
                }),

                const SizedBox(height: 12),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.sage,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        color: AppColors.forest,
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Tip: Add destinations in the order you want to visit them. You can change your trip duration anytime.',
                          style: TextStyle(
                            color: AppColors.forest,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _plannerSection({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.forest,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }

  Widget _buildDayCard({
    required int dayNumber,
    required DateTime date,
    required List<Map<String, dynamic>> places,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.sage,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(17),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: AppColors.forest,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$dayNumber',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Day $dayNumber',
                        style: const TextStyle(
                          color: AppColors.forest,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        formatDate(date),
                        style: const TextStyle(
                          color: AppColors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.event_available,
                  color: AppColors.forest,
                ),
              ],
            ),
          ),
          if (places.isEmpty)
            const Padding(
              padding: EdgeInsets.all(18),
              child: Text(
                'No destinations assigned to this day yet.',
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 13,
                ),
              ),
            )
          else
            ...List.generate(places.length, (index) {
              final place = places[index];
              final name =
                  place['name']?.toString() ?? 'Unknown place';
              final category =
                  place['category']?.toString() ?? 'Destination';

              return Padding(
                padding: const EdgeInsets.fromLTRB(15, 13, 10, 13),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            color: AppColors.sage,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: AppColors.forest,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        if (index != places.length - 1)
                          Container(
                            width: 2,
                            height: 35,
                            color: AppColors.border,
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: AppColors.forest,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            category,
                            style: const TextStyle(
                              color: AppColors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove destination',
                      onPressed: () async {
                        final messenger =
                            ScaffoldMessenger.of(context);

                        await ItineraryStore.remove(name);

                        if (!mounted) return;

                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              '$name removed from itinerary',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                        size: 21,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ============================================================
  // SHARED PLACE CARD
  // ============================================================

  Widget _buildPlaceCard({
    required Map<String, dynamic> place,
    required Widget trailing,
  }) {
    final name = place['name']?.toString() ?? 'Unknown place';
    final category = place['category']?.toString() ?? 'Destination';
    final location = place['location']?.toString() ?? 'Lipa City';
    final imagePath = place['image']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            height: 165,
            child: imagePath.isNotEmpty
                ? Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _imagePlaceholder();
                    },
                  )
                : _imagePlaceholder(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 13, 10, 13),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category,
                        style: const TextStyle(
                          color: AppColors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 15,
                            color: AppColors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              style: const TextStyle(
                                color: AppColors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                trailing,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: AppColors.sage,
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 45,
          color: AppColors.forest,
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: AppColors.sage,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 45,
                color: AppColors.forest,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.grey,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onPressed,
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PROFILE PAGE
  // ============================================================

  Widget _buildProfile() {
    final user = FirebaseAuth.instance.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: AppColors.sage,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              color: AppColors.forest,
              size: 55,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            user?.displayName?.isNotEmpty == true
                ? user!.displayName!
                : 'Explore Lipa User',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            user?.email ?? 'No email available',
            style: const TextStyle(color: AppColors.grey),
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _buildProfileOption(
                  icon: Icons.person_outline,
                  title: 'Account Information',
                  subtitle: 'View your account details',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'You are signed in to Explore Lipa.',
                        ),
                      ),
                    );
                  },
                ),
                const Divider(height: 25),
                _buildProfileOption(
                  icon: Icons.logout,
                  title: 'Log Out',
                  subtitle: 'Sign out of your account',
                  onTap: logout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: AppColors.forest,
        size: 26,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.charcoal,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppColors.grey,
          fontSize: 12,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 15,
        color: AppColors.grey,
      ),
      onTap: onTap,
    );
  }
}
