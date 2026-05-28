import 'package:flutter/material.dart';
import '../../../core/models/pro_profile.dart';
import '../../../core/utils/pro_module_helper.dart';

class ProviderCalendarScreen extends StatelessWidget {
  final String businessName;
  final List<ProModule> modules;

  const ProviderCalendarScreen({
    super.key,
    required this.businessName,
    required this.modules,
  });

  @override
  Widget build(BuildContext context) {
    final labels = modules.map(ProModuleHelper.getModuleName).join(' • ');
    return Scaffold(
      appBar: AppBar(
        title: Text('$businessName Schedule'),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    labels,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (index) {
                    final date = DateTime.now().add(Duration(days: index - 2));
                    final isSelected = index == 2;
                    final weekdays = [
                      'Sun',
                      'Mon',
                      'Tue',
                      'Wed',
                      'Thu',
                      'Fri',
                      'Sat',
                    ];
                    return Column(
                      children: [
                        Text(
                          weekdays[date.weekday - 1],
                          style: TextStyle(
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${date.day}',
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTimeSlot(
            context,
            '09:00 AM',
            true,
            'Deep Cleaning - 123 Main St',
            '2 Hours',
            Colors.blue,
          ),
          _buildTimeSlot(
            context,
            '11:00 AM',
            false,
            '',
            '',
            Colors.transparent,
          ),
          _buildTimeSlot(
            context,
            '01:00 PM',
            true,
            'AC Repair - Apartment 4B',
            '1.5 Hours',
            Colors.orange,
          ),
          _buildTimeSlot(
            context,
            '02:30 PM',
            true,
            'Plumbing - Villa 22',
            '1 Hour',
            Colors.green,
          ),
          _buildTimeSlot(
            context,
            '03:30 PM',
            false,
            '',
            '',
            Colors.transparent,
          ),
          _buildTimeSlot(
            context,
            '04:00 PM',
            false,
            '',
            '',
            Colors.transparent,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.block),
        label: const Text('Block Time'),
      ),
    );
  }

  Widget _buildTimeSlot(
    BuildContext context,
    String time,
    bool isBooked,
    String title,
    String duration,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              time,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 4, right: 12),
            decoration: BoxDecoration(
              color: isBooked ? color : Colors.grey.shade300,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
          Expanded(
            child: isBooked
                ? Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: color.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.timer, size: 14, color: color),
                            const SizedBox(width: 4),
                            Text(duration, style: TextStyle(color: color)),
                          ],
                        ),
                      ],
                    ),
                  )
                : const Divider(height: 20),
          ),
        ],
      ),
    );
  }
}
