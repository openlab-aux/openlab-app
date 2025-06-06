import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

class ICalCalendarWidget extends StatefulWidget {
  final String icalUrl;

  const ICalCalendarWidget({Key? key, required this.icalUrl}) : super(key: key);

  @override
  State<ICalCalendarWidget> createState() => _ICalCalendarWidgetState();
}

class _ICalCalendarWidgetState extends State<ICalCalendarWidget> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<ICalEvent>> _events = {};
  List<ICalEvent> _allEvents = [];
  bool _isLoading = false;
  String _errorMessage = '';
  CalendarView _currentView = CalendarView.monthly;
  final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadICalData();
  }

  Future<void> _loadICalData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(Uri.parse(widget.icalUrl));
      if (response.statusCode == 200) {
        final icalData = response.body;
        final calendar = ICalendar.fromString(icalData);

        _allEvents.clear();
        _events.clear();

        for (final event in calendar.data) {
          final icalEvent = ICalEvent(
            uid: event['uid']?.toString() ?? '',
            summary: event['summary']?.toString() ?? 'No title',
            description: event['description']?.toString() ?? '',
            start:
                event['dtstart'] != null
                    ? DateTime.tryParse(event['dtstart'].toString()) ??
                        DateTime.now()
                    : DateTime.now(),
            end:
                event['dtend'] != null
                    ? DateTime.tryParse(event['dtend'].toString()) ??
                        DateTime.now()
                    : DateTime.now(),
            location: event['location']?.toString() ?? '',
          );

          _allEvents.add(icalEvent);

          final eventDate = DateTime(
            icalEvent.start.year,
            icalEvent.start.month,
            icalEvent.start.day,
          );

          if (_events[eventDate] != null) {
            _events[eventDate]!.add(icalEvent);
          } else {
            _events[eventDate] = [icalEvent];
          }
        }

        setState(() {});
      } else {
        throw Exception('Failed to load iCal data: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading calendar: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<ICalEvent> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  Future<void> _syncToDevice() async {
    try {
      var permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
      if (permissionsGranted.isSuccess && !permissionsGranted.data!) {
        permissionsGranted = await _deviceCalendarPlugin.requestPermissions();
        if (!permissionsGranted.isSuccess || !permissionsGranted.data!) {
          _showSnackBar('Calendar permissions not granted');
          return;
        }
      }

      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      if (!calendarsResult.isSuccess || calendarsResult.data!.isEmpty) {
        _showSnackBar('No calendars found on device');
        return;
      }

      final calendar = calendarsResult.data!.first;
      int syncedCount = 0;

      for (final event in _allEvents) {
        final deviceEvent = Event(
          calendar.id,
          title: event.summary,
          description: event.description,
          start: tz.TZDateTime.from(event.start, tz.UTC),
          end: tz.TZDateTime.from(event.end, tz.UTC),
          location: event.location.isNotEmpty ? event.location : null,
        );

        final result = await _deviceCalendarPlugin.createOrUpdateEvent(
          deviceEvent,
        );
        if (result?.isSuccess == true) {
          syncedCount++;
        }
      }

      _showSnackBar('Synced $syncedCount events to device calendar');
    } catch (e) {
      _showSnackBar('Error syncing to device: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildCalendarView() {
    switch (_currentView) {
      case CalendarView.monthly:
        return _buildMonthlyView();
      case CalendarView.weekly:
        return _buildWeeklyView();
      case CalendarView.daily:
        return _buildDailyView();
      case CalendarView.list:
        return _buildListView();
    }
  }

  Widget _buildMonthlyView() {
    return Column(
      children: [
        TableCalendar<ICalEvent>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          eventLoader: _getEventsForDay,
          startingDayOfWeek: StartingDayOfWeek.monday,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          calendarStyle: const CalendarStyle(
            outsideDaysVisible: false,
            markerDecoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _buildEventsList(_getEventsForDay(_selectedDay!))),
      ],
    );
  }

  Widget _buildWeeklyView() {
    final weekStart = _selectedDay!.subtract(
      Duration(days: _selectedDay!.weekday - 1),
    );
    final weekDays = List.generate(
      7,
      (index) => weekStart.add(Duration(days: index)),
    );

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Week of ${DateFormat('MMM d, yyyy').format(weekStart)}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: weekDays.length,
            itemBuilder: (context, index) {
              final day = weekDays[index];
              final events = _getEventsForDay(day);
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ExpansionTile(
                  title: Text(
                    '${DateFormat('EEEE, MMM d').format(day)} (${events.length} events)',
                    style: TextStyle(
                      fontWeight:
                          isSameDay(day, DateTime.now())
                              ? FontWeight.bold
                              : FontWeight.normal,
                    ),
                  ),
                  children:
                      events.map((event) => _buildEventTile(event)).toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDailyView() {
    final events = _getEventsForDay(_selectedDay!);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedDay = _selectedDay!.subtract(
                      const Duration(days: 1),
                    );
                  });
                },
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                DateFormat('EEEE, MMMM d, yyyy').format(_selectedDay!),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedDay = _selectedDay!.add(const Duration(days: 1));
                  });
                },
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        Expanded(child: _buildEventsList(events)),
      ],
    );
  }

  Widget _buildListView() {
    final sortedEvents = List<ICalEvent>.from(_allEvents)
      ..sort((a, b) => a.start.compareTo(b.start));

    return ListView.builder(
      itemCount: sortedEvents.length,
      itemBuilder: (context, index) {
        final event = sortedEvents[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            title: Text(event.summary),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('MMM d, yyyy - HH:mm').format(event.start)),
                if (event.location.isNotEmpty) Text('📍 ${event.location}'),
                if (event.description.isNotEmpty)
                  Text(
                    event.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildEventsList(List<ICalEvent> events) {
    if (events.isEmpty) {
      return const Center(child: Text('No events for this day'));
    }

    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) => _buildEventTile(events[index]),
    );
  }

  Widget _buildEventTile(ICalEvent event) {
    return ListTile(
      title: Text(event.summary),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${DateFormat('HH:mm').format(event.start)} - ${DateFormat('HH:mm').format(event.end)}',
          ),
          if (event.location.isNotEmpty) Text('📍 ${event.location}'),
          if (event.description.isNotEmpty)
            Text(
              event.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      isThreeLine: event.description.isNotEmpty,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('iCal Calendar'),
        actions: [
          IconButton(onPressed: _loadICalData, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: _syncToDevice, icon: const Icon(Icons.sync)),
        ],
      ),
      body: Column(
        children: [
          // View selector
          Container(
            padding: const EdgeInsets.all(8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    CalendarView.values.map((view) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(view.name.toUpperCase()),
                          selected: _currentView == view,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _currentView = view;
                              });
                            }
                          },
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),
          // Content
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage.isNotEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_errorMessage),
                          ElevatedButton(
                            onPressed: _loadICalData,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                    : _buildCalendarView(),
          ),
        ],
      ),
    );
  }
}

enum CalendarView { monthly, weekly, daily, list }

class ICalEvent {
  final String uid;
  final String summary;
  final String description;
  final DateTime start;
  final DateTime end;
  final String location;

  ICalEvent({
    required this.uid,
    required this.summary,
    required this.description,
    required this.start,
    required this.end,
    required this.location,
  });
}

// Usage example:
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iCal Calendar Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ICalCalendarWidget(
        icalUrl:
            'https://example.com/calendar.ics', // Replace with your iCal URL
      ),
    );
  }
}
