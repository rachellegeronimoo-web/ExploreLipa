
import 'package:flutter/material.dart';

import '../core/itinerary_store.dart';
import '../core/theme/app_theme.dart';

class TripPlannerPage extends StatefulWidget {
  final VoidCallback onBrowse;

  const TripPlannerPage({
    super.key,
    required this.onBrowse,
  });

  @override
  State<TripPlannerPage> createState() => _TripPlannerPageState();
}

class _TripPlannerPageState extends State<TripPlannerPage> {
  int selectedDay = 1;
  bool saving = false;

  static const List<String> expenseCategories = [
    'Transportation',
    'Food',
    'Accommodation',
    'Entrance Fees',
    'Shopping',
    'Other',
  ];

  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _money(double amount) {
    return '₱${amount.toStringAsFixed(2)}';
  }

  // =========================================================
  // TRIP SETTINGS
  // =========================================================

  Future<void> _chooseStartDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: ItineraryStore.tripStartDate.value,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 3),
      helpText: 'Choose your trip start date',
    );

    if (picked == null || !mounted) return;

    setState(() => saving = true);

    final success = await ItineraryStore.saveTripDetails(
      startDate: picked,
      days: ItineraryStore.dayCount.value,
    );

    if (!mounted) return;

    setState(() => saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Trip date saved!' : 'Unable to save trip date.',
        ),
      ),
    );
  }

  Future<void> _addDay() async {
    final currentDays = ItineraryStore.dayCount.value;

    if (currentDays >= 14) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can plan up to 14 days.'),
        ),
      );
      return;
    }

    setState(() => saving = true);

    final success = await ItineraryStore.saveTripDetails(
      startDate: ItineraryStore.tripStartDate.value,
      days: currentDays + 1,
    );

    if (!mounted) return;

    setState(() {
      saving = false;
      if (success) selectedDay = currentDays + 1;
    });

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to add another day.'),
        ),
      );
    }
  }

  // =========================================================
  // TIME HELPERS
  // =========================================================

  TimeOfDay _parseTime(String value) {
    try {
      final parts = value.trim().split(' ');
      final timeParts = parts[0].split(':');

      int hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      if (parts.length > 1) {
        if (parts[1].toUpperCase() == 'PM' && hour != 12) {
          hour += 12;
        } else if (parts[1].toUpperCase() == 'AM' && hour == 12) {
          hour = 0;
        }
      }

      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  int _timeInMinutes(String value) {
    final time = _parseTime(value);
    return time.hour * 60 + time.minute;
  }

  // =========================================================
  // EDIT DESTINATION SCHEDULE
  // =========================================================

  Future<void> _editSchedule(Map<String, dynamic> place) async {
    int chosenDay = (place['day'] as num?)?.toInt() ?? 1;
    final currentTime = place['visitTime']?.toString() ?? '09:00 AM';
    TimeOfDay chosenTime = _parseTime(currentTime);

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Schedule Destination'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place['name']?.toString() ?? 'Destination',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  const Text('Visit on which day?'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: chosenDay,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(
                      ItineraryStore.dayCount.value,
                      (index) {
                        final day = index + 1;
                        return DropdownMenuItem(
                          value: day,
                          child: Text('Day $day'),
                        );
                      },
                    ),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => chosenDay = value);
                      }
                    },
                  ),
                  const SizedBox(height: 18),
                  const Text('Visit time'),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: chosenTime,
                      );

                      if (picked != null) {
                        setDialogState(() => chosenTime = picked);
                      }
                    },
                    icon: const Icon(Icons.access_time),
                    label: Text(chosenTime.format(context)),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Save Schedule'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true || !mounted) return;

    final name = place['name']?.toString() ?? '';

    final success = await ItineraryStore.updateSchedule(
      name: name,
      day: chosenDay,
      visitTime: chosenTime.format(context),
    );

    if (!mounted) return;

    setState(() => selectedDay = chosenDay);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Schedule updated!' : 'Unable to update schedule.',
        ),
      ),
    );
  }

  Future<void> _removePlace(String name) async {
    await ItineraryStore.remove(name);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$name removed from your trip.')),
    );
  }

  // =========================================================
  // EXPENSES
  // =========================================================

  Future<void> _showExpenseDialog({
    Map<String, dynamic>? expense,
  }) async {
    final isEditing = expense != null;

    final titleController = TextEditingController(
      text: expense?['title']?.toString() ?? '',
    );

    final amountController = TextEditingController(
      text: expense?['amount']?.toString() ?? '',
    );

    final notesController = TextEditingController(
      text: expense?['notes']?.toString() ?? '',
    );

    String category = expense?['category']?.toString() ?? 'Food';

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Expense' : 'Add Expense'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Expense name',
                        hintText: 'Example: Lunch',
                        prefixIcon: Icon(Icons.receipt_long),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: expenseCategories.contains(category)
                          ? category
                          : 'Other',
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: expenseCategories.map((item) {
                        return DropdownMenuItem(
                          value: item,
                          child: Text(item),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => category = value);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixText: '₱ ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final amount =
                        double.tryParse(amountController.text.trim());

                    if (titleController.text.trim().isEmpty ||
                        amount == null ||
                        amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Enter a name and a valid amount.'),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(dialogContext, true);
                  },
                  child: Text(isEditing ? 'Save Changes' : 'Add Expense'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      final amount = double.tryParse(amountController.text.trim()) ?? 0;

      bool success;

      if (isEditing) {
        success = await ItineraryStore.updateExpense(
          id: expense['id'].toString(),
          title: titleController.text,
          category: category,
          amount: amount,
          notes: notesController.text,
        );
      } else {
        success = await ItineraryStore.addExpense(
          title: titleController.text,
          category: category,
          amount: amount,
          notes: notesController.text,
        );
      }

      if (!mounted) {
        titleController.dispose();
        amountController.dispose();
        notesController.dispose();
        return;
      }

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? (isEditing ? 'Expense updated!' : 'Expense added!')
                : 'Unable to save expense.',
          ),
        ),
      );
    }

    titleController.dispose();
    amountController.dispose();
    notesController.dispose();
  }

  Future<void> _deleteExpense(String id) async {
    final success = await ItineraryStore.removeExpense(id);

    if (!mounted) return;

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Expense deleted.' : 'Unable to delete expense.',
        ),
      ),
    );
  }

  IconData _expenseIcon(String category) {
    switch (category) {
      case 'Transportation':
        return Icons.directions_car_outlined;
      case 'Food':
        return Icons.restaurant_outlined;
      case 'Accommodation':
        return Icons.hotel_outlined;
      case 'Entrance Fees':
        return Icons.confirmation_number_outlined;
      case 'Shopping':
        return Icons.shopping_bag_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  // =========================================================
  // CHECKLIST
  // =========================================================

  Future<void> _addChecklistItem() async {
    final controller = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Checklist Item'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Example: Prepare travel essentials',
              labelText: 'Task name',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                Navigator.pop(dialogContext, true);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Add Task'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final success =
          await ItineraryStore.addChecklistItem(controller.text);

      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Checklist item added!' : 'Unable to add item.',
          ),
        ),
      );
    }

    controller.dispose();
  }

  Future<void> _toggleChecklist(String id, bool isDone) async {
    final success = await ItineraryStore.toggleChecklistItem(
      id: id,
      isDone: isDone,
    );

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update checklist.')),
      );
    }
  }

  Future<void> _deleteChecklistItem(String id) async {
    final success = await ItineraryStore.removeChecklistItem(id);

    if (!mounted) return;

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Checklist item removed.' : 'Unable to remove item.',
        ),
      ),
    );
  }

  // =========================================================
  // SECTION TITLE
  // =========================================================

  Widget _sectionTitle(
    String title,
    String subtitle, {
    Widget? action,
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
                style: Theme.of(context).textTheme.titleLarge,
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
        ?action,
      ],
    );
  }

  // =========================================================
  // OVERVIEW
  // =========================================================

  Widget _buildOverview() {
    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: ItineraryStore.itinerary,
      builder: (context, places, child) {
        return ValueListenableBuilder<int>(
          valueListenable: ItineraryStore.dayCount,
          builder: (context, days, child) {
            return ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: ItineraryStore.checklist,
              builder: (context, tasks, child) {
                final completed =
                    tasks.where((item) => item['isDone'] == true).length;

                final progress =
                    tasks.isEmpty ? 0.0 : completed / tasks.length;

                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.forest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.explore_outlined,
                            color: Colors.white,
                          ),
                          SizedBox(width: 9),
                          Text(
                            'YOUR TRIP OVERVIEW',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 19),
                      Row(
                        children: [
                          _overviewStat(
                            places.length.toString(),
                            'Destinations',
                            Icons.place_outlined,
                          ),
                          _overviewStat(
                            days.toString(),
                            days == 1 ? 'Trip day' : 'Trip days',
                            Icons.calendar_month_outlined,
                          ),
                          _overviewStat(
                            '$completed/${tasks.length}',
                            'Tasks done',
                            Icons.check_circle_outline,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Preparation progress',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Text(
                            '${(progress * 100).round()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation(
                            Color(0xFFD8E6D7),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _overviewStat(String value, String label, IconData icon) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TRIP DETAILS
  // =========================================================

  Widget _buildTripDetails() {
    return ValueListenableBuilder<DateTime>(
      valueListenable: ItineraryStore.tripStartDate,
      builder: (context, startDate, child) {
        return ValueListenableBuilder<int>(
          valueListenable: ItineraryStore.dayCount,
          builder: (context, days, child) {
            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_month,
                        color: AppColors.forest,
                      ),
                      const SizedBox(width: 9),
                      Text(
                        'Trip Details',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 17),
                  const Text(
                    'Starting date',
                    style: TextStyle(
                      color: AppColors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 7),
                  InkWell(
                    onTap: saving ? null : _chooseStartDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.event,
                            color: AppColors.forest,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _formatDate(startDate),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(Icons.edit_outlined),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 17),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Duration of your trip',
                          style: TextStyle(
                            color: AppColors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text(
                        '$days ${days == 1 ? 'day' : 'days'}',
                        style: const TextStyle(
                          color: AppColors.forest,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...List.generate(days, (index) {
                        final day = index + 1;

                        return ChoiceChip(
                          label: Text('Day $day'),
                          selected: selectedDay == day,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => selectedDay = day);
                            }
                          },
                          selectedColor: AppColors.sage,
                          labelStyle: TextStyle(
                            color: selectedDay == day
                                ? AppColors.forest
                                : AppColors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }),
                      ActionChip(
                        avatar: const Icon(Icons.add, size: 17),
                        label: const Text('Add day'),
                        onPressed: saving ? null : _addDay,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================
  // DESTINATION CARD
  // =========================================================

  Widget _buildPlaceCard(Map<String, dynamic> place) {
    final name = place['name']?.toString() ?? 'Unknown place';
    final category = place['category']?.toString() ?? 'Destination';
    final location = place['location']?.toString() ?? 'Lipa City';
    final imagePath = place['image']?.toString() ?? '';
    final visitTime = place['visitTime']?.toString() ?? '09:00 AM';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 145,
            width: double.infinity,
            child: imagePath.isNotEmpty
                ? Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.sage,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          size: 40,
                          color: AppColors.forest,
                        ),
                      );
                    },
                  )
                : Container(
                    color: AppColors.sage,
                    child: const Icon(
                      Icons.place,
                      size: 40,
                      color: AppColors.forest,
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 13, 8, 13),
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
                      Text(
                        location,
                        style: const TextStyle(
                          color: AppColors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.sage,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 15,
                              color: AppColors.forest,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              visitTime,
                              style: const TextStyle(
                                color: AppColors.forest,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editSchedule(place);
                    } else if (value == 'remove') {
                      _removePlace(name);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined),
                          SizedBox(width: 9),
                          Text('Edit schedule'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.redAccent),
                          SizedBox(width: 9),
                          Text('Remove destination'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // BUDGET SECTION
  // =========================================================

  Widget _buildBudgetSection() {
    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: ItineraryStore.expenses,
      builder: (context, expenses, child) {
        final total = ItineraryStore.totalBudget;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trip Expenses',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Keep track of your planned spending.',
                          style: TextStyle(
                            color: AppColors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filled(
                    onPressed: () => _showExpenseDialog(),
                    icon: const Icon(Icons.add),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.forest,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.sage,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL PLANNED EXPENSES',
                      style: TextStyle(
                        color: AppColors.forest,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _money(total),
                      style: const TextStyle(
                        color: AppColors.forest,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${expenses.length} ${expenses.length == 1 ? 'expense' : 'expenses'} recorded',
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (expenses.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(
                    child: Text(
                      'No expenses added yet.',
                      style: TextStyle(color: AppColors.grey),
                    ),
                  ),
                )
              else
                ...expenses.map((expense) {
                  final id = expense['id']?.toString() ?? '';
                  final title = expense['title']?.toString() ?? 'Expense';
                  final category =
                      expense['category']?.toString() ?? 'Other';

                  final amountValue = expense['amount'];
                  final amount = amountValue is num
                      ? amountValue.toDouble()
                      : 0.0;

                  return Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: AppColors.sage,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _expenseIcon(category),
                            color: AppColors.forest,
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                category,
                                style: const TextStyle(
                                  color: AppColors.grey,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _money(amount),
                          style: const TextStyle(
                            color: AppColors.forest,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showExpenseDialog(expense: expense);
                            } else if (value == 'delete') {
                              _deleteExpense(id);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  // =========================================================
  // CHECKLIST SECTION
  // =========================================================

  Widget _buildChecklistSection() {
    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: ItineraryStore.checklist,
      builder: (context, items, child) {
        final completed =
            items.where((item) => item['isDone'] == true).length;

        final progress = items.isEmpty ? 0.0 : completed / items.length;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Travel Checklist',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Prepare everything before your trip.',
                          style: TextStyle(
                            color: AppColors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filled(
                    onPressed: _addChecklistItem,
                    icon: const Icon(Icons.add),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.forest,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 7,
                        backgroundColor: AppColors.sage,
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.forest,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$completed/${items.length}',
                    style: const TextStyle(
                      color: AppColors.forest,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'Your checklist is empty. Add your first task!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.grey),
                    ),
                  ),
                )
              else
                ...items.map((item) {
                  final id = item['id']?.toString() ?? '';
                  final title =
                      item['title']?.toString() ?? 'Untitled task';
                  final isDone = item['isDone'] == true;

                  return Container(
                    margin: const EdgeInsets.only(top: 7),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: CheckboxListTile(
                      value: isDone,
                      onChanged: (value) {
                        _toggleChecklist(id, value ?? false);
                      },
                      activeColor: AppColors.forest,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          decoration:
                              isDone ? TextDecoration.lineThrough : null,
                          color: isDone ? AppColors.grey : null,
                        ),
                      ),
                      secondary: IconButton(
                        tooltip: 'Remove task',
                        onPressed: () => _deleteChecklistItem(id),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.grey,
                        ),
                      ),
                      contentPadding: const EdgeInsets.only(
                        left: 5,
                        right: 8,
                      ),
                      dense: true,
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  // =========================================================
  // MAIN SCREEN
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: ItineraryStore.itinerary,
      builder: (context, places, child) {
        final days = ItineraryStore.dayCount.value;

        if (selectedDay > days) {
          selectedDay = days;
        }

        final dayPlaces = places.where((place) {
          final day = (place['day'] as num?)?.toInt() ?? 1;
          return day == selectedDay;
        }).toList();

        dayPlaces.sort((a, b) {
          return _timeInMinutes(
            a['visitTime']?.toString() ?? '09:00 AM',
          ).compareTo(
            _timeInMinutes(
              b['visitTime']?.toString() ?? '09:00 AM',
            ),
          );
        });

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Plan Your Trip',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 7),
              Text(
                'Organize your Lipa City adventure in one place.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),

              _buildOverview(),
              const SizedBox(height: 25),

              _buildTripDetails(),
              const SizedBox(height: 27),

              _sectionTitle(
                'Daily Itinerary',
                'Organize the destinations you want to visit.',
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Day $selectedDay Schedule',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    '${dayPlaces.length} ${dayPlaces.length == 1 ? 'place' : 'places'}',
                    style: const TextStyle(
                      color: AppColors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),

              if (dayPlaces.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.map_outlined,
                        size: 48,
                        color: AppColors.forest,
                      ),
                      const SizedBox(height: 13),
                      Text(
                        'Nothing planned for Day $selectedDay',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Add destinations from Explore and organize your visit here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.grey,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: widget.onBrowse,
                          icon: const Icon(Icons.add_location_alt),
                          label: const Text('Add Destinations'),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                ...dayPlaces.map(_buildPlaceCard),
                OutlinedButton.icon(
                  onPressed: widget.onBrowse,
                  icon: const Icon(Icons.add),
                  label: const Text('Add More Destinations'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],

              const SizedBox(height: 27),

              _sectionTitle(
                'Budget Tracker',
                'Monitor your planned travel expenses.',
              ),
              const SizedBox(height: 13),
              _buildBudgetSection(),

              const SizedBox(height: 27),

              _sectionTitle(
                'Before You Go',
                'Keep track of your travel preparations.',
              ),
              const SizedBox(height: 13),
              _buildChecklistSection(),

              const SizedBox(height: 22),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.sage,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: AppColors.forest,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Travel tip: Add your destinations first, then arrange your schedule, estimate your expenses, and check off your preparations.',
                        style: TextStyle(
                          color: AppColors.forest,
                          height: 1.5,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
