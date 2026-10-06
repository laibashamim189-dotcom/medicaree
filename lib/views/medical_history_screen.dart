import 'package:flutter/material.dart';
import '../models/medical_history_model.dart';
import '../view_models/medical_history_view_model.dart';

class MedicalHistoryScreen extends StatefulWidget {
  final String? patientId;
  const MedicalHistoryScreen({super.key, this.patientId});

  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  late MedicalHistoryViewModel _viewModel;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = MedicalHistoryViewModel();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectivePatientId = _viewModel.getEffectivePatientId(widget.patientId);

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FE),
          appBar: AppBar(
            title: _viewModel.isSearching
                ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: "Search name, date or time...",
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.white70),
              ),
              style: const TextStyle(color: Colors.white, fontSize: 18),
              onChanged: (value) {
                _viewModel.updateSearchQuery(value);
              },
            )
                : const Text("Medical History", style: TextStyle(color: Colors.white)),
            backgroundColor: const Color(0xFF1565C0),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: Icon(_viewModel.isSearching ? Icons.close : Icons.search),
                onPressed: () {
                  if (_viewModel.isSearching) {
                    _searchController.clear();
                    _viewModel.clearSearch();
                  } else {
                    _viewModel.toggleSearch();
                  }
                },
              ),
            ],
          ),
          body: effectivePatientId == null
              ? const Center(child: Text("User not identified"))
              : StreamBuilder<List<MedicalHistoryModel>>(
            stream: _viewModel.getHistoryStream(widget.patientId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                if (_viewModel.searchQuery.isNotEmpty) {
                  return const Center(child: Text("No matching records found."));
                }
                return const Center(child: Text("No history records found for this patient."));
              }

              final items = snapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final statusColor = item.statusColor;

                  return Dismissible(
                    key: Key(item.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: Colors.transparent,
                      child: const Icon(Icons.delete, color: Colors.grey),
                    ),
                    onDismissed: (_) async {
                      await _viewModel.deleteHistoryRecord(item.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("${item.title} deleted")),
                        );
                      }
                    },
                    child: Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: statusColor.withValues(alpha: 0.1),
                          child: Icon(
                            item.isSuccess ? Icons.check_circle_outline : Icons.cancel_outlined,
                            color: statusColor,
                          ),
                        ),
                        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          "${item.category}\n${item.date} at ${item.time}",
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            item.status,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
