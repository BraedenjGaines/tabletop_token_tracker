import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/library_filters.dart';
import '../state/library_state.dart';
import 'custom_token_screen.dart';
import 'widgets/library_filter_sheet.dart';
import 'widgets/library_tab.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  LibraryFilters _filters = const LibraryFilters();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Card Library'),
          actions: [
            IconButton(
              tooltip: 'Manage Custom Content',
              icon: const Icon(Icons.edit_note),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CustomTokenScreen()),
                );
              },
            ),
          ],
        ),
        body: Consumer<LibraryState>(
          builder: (context, library, _) {
            if (library.loadFailed) {
              return _buildError(library);
            }
            if (!library.isLoaded) {
              return const Center(child: CircularProgressIndicator());
            }

            return LibraryTab(
              cards: library.cards,
              filters: _filters,
              onEditFilters: () => _openFilterSheet(library),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openFilterSheet(LibraryState library) async {
    final result = await LibraryFilterSheet.open(
      context: context,
      initial: _filters,
      allCards: library.cards,
      allSets: library.sets,
      classNames: library.classNames,
    );
    if (result != null && mounted) {
      setState(() => _filters = result);
    }
  }

  Widget _buildError(LibraryState library) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Could not load card library.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              library.loadError ?? 'Unknown error',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => library.loadFromAssets(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}