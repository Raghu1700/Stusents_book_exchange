import 'package:flutter/material.dart';
import '../../model/course.dart';
import '../home/components/secondary_course_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterType = 'All'; // Options: All, Name, Class, Subject
  List<Course> _filteredBooks = [];

  @override
  void initState() {
    super.initState();
    _filteredBooks = [...availableBooks, ...recentlyAddedBooks];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateSearchResults(String query) {
    setState(() {
      _searchQuery = query;
      _filterBooks();
    });
  }

  void _changeFilterType(String filterType) {
    setState(() {
      _filterType = filterType;
      _filterBooks();
    });
  }

  void _filterBooks() {
    if (_searchQuery.isEmpty) {
      _filteredBooks = [...availableBooks, ...recentlyAddedBooks];
      return;
    }

    final query = _searchQuery.toLowerCase();
    _filteredBooks = [...availableBooks, ...recentlyAddedBooks].where((book) {
      if (_filterType == 'All') {
        return book.title.toLowerCase().contains(query) ||
            book.subject.toLowerCase().contains(query) ||
            book.bookClass.toLowerCase().contains(query);
      } else if (_filterType == 'Name') {
        return book.title.toLowerCase().contains(query);
      } else if (_filterType == 'Class') {
        return book.bookClass.toLowerCase().contains(query);
      } else if (_filterType == 'Subject') {
        return book.subject.toLowerCase().contains(query);
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              "Search Books",
              style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for books...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _updateSearchResults('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _updateSearchResults,
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Name'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Class'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Subject'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _filteredBooks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.search_off,
                            size: 80,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No books found',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try changing your search or filter',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredBooks.length,
                      itemBuilder: (context, index) {
                        final book = _filteredBooks[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: SecondaryCourseCard(
                            title: book.title,
                            iconSrc: book.iconSrc,
                            color: book.color,
                            subject: book.subject,
                            bookClass: book.bookClass,
                            price: book.price,
                            seller: book.seller,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _filterType == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _changeFilterType(label),
      backgroundColor: Colors.grey[200],
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
