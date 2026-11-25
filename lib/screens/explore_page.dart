
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/app_theme.dart';
import '../core/favorites_store.dart';
import '../core/itinerary_store.dart';
import '../data/lipa_places.dart';

class ExplorePage extends StatefulWidget {
  final String initialCategory;

  const ExplorePage({
    super.key,
    this.initialCategory = 'All',
  });

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  late String selectedCategory;

  String searchQuery = '';

  final TextEditingController searchController =
      TextEditingController();

  final Set<String> addingPlaces = {};

  final List<String> categories = [
    'All',
    'Tourist Destinations',
    'Food & Restaurants',
    'Activities',
  ];

  final List<Map<String, dynamic>> places = LipaPlaces.places;

  @override
  void initState() {
    super.initState();

    selectedCategory = categories.contains(widget.initialCategory)
        ? widget.initialCategory
        : 'All';
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // FILTER DESTINATIONS

  List<Map<String, dynamic>> get filteredPlaces {
    return places.where((place) {
      final categoryMatches = selectedCategory == 'All' ||
          place['category'] == selectedCategory;

      final query = searchQuery.toLowerCase().trim();

      final searchMatches = query.isEmpty ||
          place['name']
              .toString()
              .toLowerCase()
              .contains(query) ||
          place['description']
              .toString()
              .toLowerCase()
              .contains(query);

      return categoryMatches && searchMatches;
    }).toList();
  }

  // PLACE IMAGE

  Widget _buildPlaceImage(
    Map<String, dynamic> place, {
    double height = 125,
  }) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Image.asset(
        place['image'].toString(),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: AppColors.sage,
            alignment: Alignment.center,
            child: Icon(
              place['icon'] is IconData
                  ? place['icon'] as IconData
                  : Icons.place,
              size: 48,
              color: AppColors.forest,
            ),
          );
        },
      ),
    );
  }

  // FAVORITES

  void _toggleFavorite(Map<String, dynamic> place) {
    final name = place['name'].toString();

    final wasFavorite = FavoritesStore.isFavorite(name);

    FavoritesStore.toggle(place);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasFavorite
              ? '$name removed from Favorites.'
              : '$name added to Favorites.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildFavoriteButton(Map<String, dynamic> place) {
    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: FavoritesStore.favorites,
      builder: (context, favorites, child) {
        final saved = favorites.any(
          (item) => item['name'] == place['name'],
        );

        return Material(
          color: Colors.white,
          shape: const CircleBorder(),
          child: IconButton(
            tooltip: saved
                ? 'Remove from Favorites'
                : 'Add to Favorites',
            onPressed: () => _toggleFavorite(place),
            icon: Icon(
              saved ? Icons.favorite : Icons.favorite_border,
              color: saved ? Colors.red : AppColors.forest,
            ),
          ),
        );
      },
    );
  }

  // ADD DESTINATION TO ITINERARY

  Future<void> _addToItinerary(
    Map<String, dynamic> place,
  ) async {
    final name = place['name'].toString();

    if (addingPlaces.contains(name)) return;

    if (ItineraryStore.contains(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$name is already in your itinerary.'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      addingPlaces.add(name);
    });

    bool success = false;

    try {
      success = await ItineraryStore.add(place);
    } catch (e) {
      debugPrint('EXPLORE ADD ERROR: $e');
    }

    if (!mounted) return;

    setState(() {
      addingPlaces.remove(name);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '$name added to My Itinerary!'
              : 'Could not save $name. Check your Firebase permissions.',
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ADD BUTTON

  Widget _buildAddButton(Map<String, dynamic> place) {
    final name = place['name'].toString();

    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: ItineraryStore.itinerary,
      builder: (context, itinerary, child) {
        final alreadyAdded = itinerary.any(
          (item) => item['name'] == name,
        );

        final isAdding = addingPlaces.contains(name);

        return SizedBox(
          height: 38,
          child: ElevatedButton.icon(
            onPressed: alreadyAdded || isAdding
                ? null
                : () => _addToItinerary(place),
            icon: isAdding
                ? const SizedBox(
                    height: 14,
                    width: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    alreadyAdded ? Icons.check : Icons.add,
                    size: 17,
                  ),
            label: Text(
              isAdding
                  ? 'Saving...'
                  : alreadyAdded
                      ? 'Added'
                      : 'Add to Itinerary',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.forest,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.sage,
              disabledForegroundColor: AppColors.forest,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        );
      },
    );
  }

  // OPEN DESTINATION IN GOOGLE MAPS

  Future<void> _openMap(Map<String, dynamic> place) async {
    final name = place['name'].toString();
    final location = place['location'].toString();

    final query = '$name, $location';

    final mapUrl = Uri.https(
      'www.google.com',
      '/maps/search/',
      {
        'api': '1',
        'query': query,
      },
    );

    try {
      final opened = await launchUrl(
        mapUrl,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Google Maps.'),
          ),
        );
      }
    } catch (e) {
      debugPrint('MAP ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open the map.'),
        ),
      );
    }
  }

  // PLACE DETAILS

  void _showPlaceDetails(Map<String, dynamic> place) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _buildPlaceImage(
                      place,
                      height: 200,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          place['name'].toString(),
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium,
                        ),
                      ),
                      _buildFavoriteButton(place),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    place['category'].toString(),
                    style: const TextStyle(
                      color: AppColors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    place['description'].toString(),
                    style: const TextStyle(height: 1.5),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: AppColors.grey,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Location: ${place['location']}',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // VIEW ON MAP BUTTON

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _openMap(place),
                      icon: const Icon(Icons.map_outlined),
                      label: const Text(
                        'View on Map & Directions',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.forest,
                        side: const BorderSide(
                          color: AppColors.forest,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  SizedBox(
                    width: double.infinity,
                    child: _buildAddButton(place),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                      },
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // DESTINATION CARD

  Widget _buildPlaceCard(Map<String, dynamic> place) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IMAGE AND FAVORITE BUTTON

          Stack(
            children: [
              GestureDetector(
                onTap: () => _showPlaceDetails(place),
                child: _buildPlaceImage(place),
              ),

              Positioned(
                top: 8,
                right: 8,
                child: _buildFavoriteButton(place),
              ),
            ],
          ),

          // DESTINATION INFORMATION

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place['category'].toString(),
                    style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  GestureDetector(
                    onTap: () => _showPlaceDetails(place),
                    child: Text(
                      place['name'].toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.forest,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const Spacer(),

                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.grey,
                      ),

                      const SizedBox(width: 4),

                      Expanded(
                        child: Text(
                          place['location'].toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 9),

                  SizedBox(
                    width: double.infinity,
                    child: _buildAddButton(place),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // MAIN EXPLORE PAGE

  @override
  Widget build(BuildContext context) {
    final results = filteredPlaces;

    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Explore Lipa',
              style: Theme.of(context).textTheme.headlineMedium,
            ),

            const SizedBox(height: 8),

            Text(
              'Discover destinations, local food, and activities around the city.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            const SizedBox(height: 20),

            // SEARCH

            TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search places, food, or activities...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          searchController.clear();
                          setState(() {
                            searchQuery = '';
                          });
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
            ),

            const SizedBox(height: 18),

            // CATEGORY FILTERS

            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final selected = category == selectedCategory;

                  return ChoiceChip(
                    label: Text(category),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        selectedCategory = category;
                      });
                    },
                    selectedColor: AppColors.forest,
                    backgroundColor: Colors.white,
                    side: BorderSide.none,
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      color: selected
                          ? Colors.white
                          : AppColors.charcoal,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 22),

            // RESULTS HEADER

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    selectedCategory == 'All'
                        ? 'Discover places'
                        : selectedCategory,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text('${results.length} results'),
              ],
            ),

            const SizedBox(height: 14),

            // EMPTY RESULTS

            if (results.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: Text(
                    'No results found. Try another search.',
                  ),
                ),
              )

            // DESTINATION GRID

            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns =
                      constraints.maxWidth >= 650 ? 2 : 1;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    itemCount: results.length,
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      mainAxisExtent: 285,
                    ),
                    itemBuilder: (context, index) {
                      return _buildPlaceCard(results[index]);
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
