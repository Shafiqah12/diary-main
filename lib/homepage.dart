import 'package:flutter/material.dart';
import 'sql_helper.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'setting_page.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode and kIsWeb
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'custom_app_bar.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:shake/shake.dart'; // NEW: For Motion Sensor
import 'package:table_calendar/table_calendar.dart'; // NEW: For Calendar

// Define a simple FloatingDecoration class for the background animation
class FloatingDecoration {
  final String imagePath;
  double top;
  double left;
  double opacity;
  double size;
  double speed;
  final Random random;
  final Size screenSize;

  FloatingDecoration({
    required this.imagePath,
    required this.random,
    required this.screenSize,
  }) :
    top = screenSize.height + random.nextDouble() * 100,
    left = random.nextDouble() * screenSize.width,
    opacity = random.nextDouble() * 0.4 + 0.2,
    size = random.nextDouble() * 40 + 20,
    speed = random.nextDouble() * 0.8 + 0.3;

  void move() {
    top -= speed;
    opacity -= 0.003;
    if (top < -size || opacity <= 0) {
      reset();
    }
  }

  void reset() {
    top = screenSize.height + random.nextDouble() * 100;
    left = random.nextDouble() * screenSize.width;
    opacity = random.nextDouble() * 0.4 + 0.2;
    size = random.nextDouble() * 40 + 20;
    speed = random.nextDouble() * 0.8 + 0.3;
  }
}


class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

// FIX: Changed SingleTickerProviderStateMixin to TickerProviderStateMixin
class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _diaries = [];
  List<Map<String, dynamic>> _filteredDiaries = [];
  bool _isLoading = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  final ScrollController _emotionScrollController = ScrollController();

  late AnimationController _floatingDecorationsController;
  final List<FloatingDecoration> _decorations = [];
  final Random _random = Random();

  // --- NEW: Dashboard & Nav State ---
  int _currentIndex = 0; // 0: Diary, 1: Calendar, 2: Dashboard
  late ShakeDetector _shakeDetector;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final List<String> _backgroundDecorationImages = [
    'assets/images/love.png',
    'assets/images/care.png',
    'assets/images/wink.png',
    'assets/images/happy.png',
    'assets/images/polite.png',
    'assets/images/happy.gif',
  ];

  // Make AudioPlayer nullable and conditionally initialize
  AudioPlayer? _audioPlayer;

  late AnimationController _fabPulseController;
  late Animation<double> _fabPulseAnimation;


  final Map<String, Color> _emotionColors = {
    'assets/images/happy.gif': Colors.pink.shade100,
    'assets/images/happy.png': Colors.amber.shade200,
    'assets/images/angry.png': Colors.red.shade200,
    'assets/images/care.png': Colors.lightGreen.shade200,
    'assets/images/goffy.png': Colors.purple.shade200,
    'assets/images/love.png': Colors.pink.shade200,
    'assets/images/party.png': Colors.orange.shade200,
    'assets/images/polite.png': Colors.blue.shade200,
    'assets/images/sad.png': Colors.grey.shade400,
    'assets/images/scared.png': Colors.deepPurple.shade200,
    'assets/images/sick.png': Colors.brown.shade200,
    'assets/images/smart.png': Colors.teal.shade200,
    'assets/images/stress.png': Colors.indigo.shade200,
    'assets/images/wink.png': Colors.cyan.shade200,
  };


  void _refreshDiaries() async {
    final data = await SQLHelper.getDiaries();
    setState(() {
      _diaries = data;
      _applySearchFilter();
      _isLoading = false;
    });
  }

  void _applySearchFilter() {
    if (_searchController.text.isEmpty) {
      _filteredDiaries = List.from(_diaries);
    } else {
      final query = _searchController.text.toLowerCase();
      _filteredDiaries = _diaries.where((diary) {
        return (diary['feeling']?.toLowerCase().contains(query) ?? false) ||
               (diary['description']?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
    _filteredDiaries.sort((a, b) {
      final dateTimeA = DateTime.tryParse(a['createdAt']) ?? DateTime(0);
      final dateTimeB = DateTime.tryParse(b['createdAt']) ?? DateTime(0);
      return dateTimeB.compareTo(dateTimeA);
    });
  }

  // Play a subtle sound effect (conditionally on non-web platforms)
  Future<void> _playSound() async {
    if (!kIsWeb && _audioPlayer != null) { // Only play if not web and player is initialized
      await _audioPlayer!.play(AssetSource('sounds/chime.mp3'), volume: 0.5);
    } else if (kDebugMode && kIsWeb) {
      print('Sound playback skipped on web platform.');
    }
  }

  // Trigger subtle haptic feedback (conditionally on non-web platforms)
  void _triggerHapticFeedback() {
    if (!kIsWeb) { // Haptic feedback is typically not available on web
      HapticFeedback.lightImpact();
    } else if (kDebugMode && kIsWeb) {
      print('Haptic feedback skipped on web platform.');
    }
  }


  @override
  void initState() {
    super.initState();
    _refreshDiaries();

    // MOTION SENSOR: Initialize Shake Detection
    _shakeDetector = ShakeDetector.autoStart(
      onPhoneShake: () {
        _triggerHapticFeedback();
        _showForm(null); // Automatically opens "Add Entry" sheet
      },
      shakeThresholdGravity: 1.5,
    );

    _searchController.addListener(() {
      setState(() {
        _applySearchFilter();
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initFloatingDecorations();
    });

    _floatingDecorationsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..addListener(() {
        setState(() {
          for (var decoration in _decorations) {
            decoration.move();
          }
        });
      })
      ..repeat();

    // FIX: Conditionally initialize AudioPlayer based on platform
    if (!kIsWeb) {
      _audioPlayer = AudioPlayer();
      // It's good practice to pre-load the sound if it's small and used frequently
      _audioPlayer!.setSourceAsset('sounds/chime.mp3'); // Ensure this sound file exists in assets/sounds/
    }


    _fabPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _fabPulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _fabPulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _initFloatingDecorations() {
    final screenSize = MediaQuery.of(context).size;
    for (int i = 0; i < 25; i++) {
      _decorations.add(FloatingDecoration(
        imagePath: _backgroundDecorationImages[_random.nextInt(_backgroundDecorationImages.length)],
        random: _random,
        screenSize: screenSize,
      ));
    }
    setState(() {});
  }

  @override
  void dispose() {
    _shakeDetector.stopListening();
    _floatingDecorationsController.dispose();
    _emotionScrollController.dispose();
    _feelingController.dispose();
    _descriptionController.dispose();
    _dateTimeController.dispose();
    _searchController.dispose();
    // FIX: Conditionally dispose AudioPlayer
    if (_audioPlayer != null) {
      _audioPlayer!.dispose();
    }
    _fabPulseController.dispose();
    super.dispose();
  }

  // --- STREAK LOGIC ---
  int _calculateStreak() {
    if (_diaries.isEmpty) return 0;
    final dates = _diaries
        .map((e) => DateTime.parse(e['createdAt']).toIso8601String().split('T')[0])
        .toSet().toList()..sort((a, b) => b.compareTo(a));

    int streak = 0;
    DateTime checkDate = DateTime.now();
    for (String dateStr in dates) {
      if (dateStr == DateFormat('yyyy-MM-dd').format(checkDate)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (DateTime.parse(dateStr).isBefore(DateTime(checkDate.year, checkDate.month, checkDate.day))) {
        break;
      }
    }
    return streak;
  }

  // --- VIEW BUILDERS ---

  Widget _buildCalendarView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() { _selectedDay = selectedDay; _focusedDay = focusedDay; });
            },
            onFormatChanged: (format) => setState(() => _calendarFormat = format),
            eventLoader: (day) {
              return _diaries.where((e) => isSameDay(DateTime.parse(e['createdAt']), day)).toList();
            },
          ),
          const Divider(),
          if (_selectedDay != null) ...[
             Text("Entries for ${DateFormat.yMMMd().format(_selectedDay!)}", 
                  style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
             // Add mini list here if needed
          ]
        ],
      ),
    );
  }

  Widget _buildDashboardView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // STREAK CARD
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            color: Colors.orange.shade50,
            child: ListTile(
              leading: const Icon(Icons.local_fire_department, color: Colors.orange, size: 40),
              title: Text('Current Streak', style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
              trailing: Text('${_calculateStreak()} Days', 
                style: GoogleFonts.quicksand(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
            ),
          ),
          const SizedBox(height: 24),
          Text("Diary Summary", style: GoogleFonts.quicksand(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              children: [
                _buildStatTile("Total Entries", "${_diaries.length}", Icons.book),
                _buildStatTile("Current Goal", "Write Daily", Icons.star),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(String title, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal),
      title: Text(title, style: GoogleFonts.quicksand()),
      trailing: Text(value, style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
    );
  }

  final TextEditingController _feelingController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateTimeController = TextEditingController();
  DateTime _selectedDateTime = DateTime.now();

  final List<String> _emotionImages = [
    'assets/images/happy.gif',
    'assets/images/happy.png',
    'assets/images/angry.png',
    'assets/images/care.png',
    'assets/images/goffy.png',
    'assets/images/love.png',
    'assets/images/party.png',
    'assets/images/polite.png',
    'assets/images/sad.png',
    'assets/images/scared.png',
    'assets/images/sick.png',
    'assets/images/smart.png',
    'assets/images/stress.png',
    'assets/images/wink.png',
  ];

  String? _selectedEmotionImage;

  void _showForm(int? id) async {
    _playSound();
    _triggerHapticFeedback();

    if (id != null) {
      final existingDiary =
          _diaries.firstWhere((element) => element['id'] == id);
      _feelingController.text = existingDiary['feeling'];
      _descriptionController.text = existingDiary['description'];
      _selectedDateTime = DateTime.tryParse(existingDiary['createdAt']) ?? DateTime.now();
      _selectedEmotionImage = existingDiary['emotionImage'];
    } else {
      _feelingController.text = '';
      _descriptionController.text = '';
      _selectedDateTime = DateTime.now();
      _selectedEmotionImage = null;
    }

    _updateDateTimeController();

    if (kDebugMode) {
      print('Total emotion images in list: ${_emotionImages.length}');
      for (var img in _emotionImages) {
        print('Emotion image path: $img');
      }
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            final themeProvider = Provider.of<ThemeProvider>(context);

            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _feelingController,
                    decoration: InputDecoration(
                      hintText: 'Feeling (e.g., Happy, Sad, Grateful)',
                      hintStyle: GoogleFonts.quicksand(),
                    ),
                    style: GoogleFonts.quicksand(),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _descriptionController,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      hintText: 'Describe your day...',
                      hintStyle: GoogleFonts.quicksand(),
                    ),
                    style: GoogleFonts.quicksand(),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _dateTimeController,
                    readOnly: true,
                    onTap: () async {
                      await _pickDateTime(context);
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: 'Select Date and Time',
                      hintStyle: GoogleFonts.quicksand(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    style: GoogleFonts.quicksand(),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Select your emotion:',
                    style: GoogleFonts.quicksand(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Scrollbar(
                    controller: _emotionScrollController,
                    thumbVisibility: true,
                    child: SizedBox(
                      height: 80,
                      child: ListView.builder(
                        controller: _emotionScrollController,
                        scrollDirection: Axis.horizontal,
                        itemCount: _emotionImages.length,
                        itemBuilder: (context, index) {
                          final imagePath = _emotionImages[index];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedEmotionImage = imagePath;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _selectedEmotionImage == imagePath
                                      ? themeProvider.appBarColor
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Image.asset(
                                imagePath,
                                height: 50,
                                width: 50,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  if (kDebugMode) {
                                    print('Error loading image: $imagePath');
                                  }
                                  return const Icon(Icons.error, color: Colors.red, size: 50);
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (id == null) {
                        await _addDiary();
                      } else {
                        await _updateDiary(id);
                      }
                      _playSound();
                      _triggerHapticFeedback();

                      _feelingController.text = '';
                      _descriptionController.text = '';
                      _dateTimeController.text = '';
                      _selectedDateTime = DateTime.now();
                      _selectedEmotionImage = null;
                      if (!mounted) return;
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeProvider.appBarColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      elevation: 5,
                      minimumSize: const Size(double.infinity, 45),
                    ),
                    child: Text(
                      id == null ? 'Create New Entry' : 'Update Entry',
                      style: GoogleFonts.quicksand(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
  

  void _updateDateTimeController() {
    _dateTimeController.text = DateFormat('yyyy-MM-dd HH:mm').format(_selectedDateTime);
  }

  Future<void> _pickDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      if (!mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );
      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          _updateDateTimeController();
        });
      }
    }
  }

  Future<void> _addDiary() async {
    await SQLHelper.createDiary(
        _feelingController.text, _descriptionController.text, _selectedDateTime.toIso8601String(), _selectedEmotionImage);
    _refreshDiaries();
  }

  Future<void> _updateDiary(int id) async {
    await SQLHelper.updateDiary(
        id, _feelingController.text, _descriptionController.text, _selectedDateTime.toIso8601String(), _selectedEmotionImage);
    _refreshDiaries();
  }

  void _deleteDiary(int id) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Confirm Deletion',
            style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete this diary entry?',
            style: GoogleFonts.quicksand(),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.quicksand(color: Colors.blueGrey),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Delete',
                style: GoogleFonts.quicksand(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await SQLHelper.deleteDiary(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Successfully deleted a diary entry!',
          style: GoogleFonts.quicksand(),
        ),
      ));
      _refreshDiaries();
      _playSound();
      _triggerHapticFeedback();
    }
  }
  
@override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    // --- STEP 1: DEFINE THE CONTENT FOR EACH TAB ---
    Widget activeTabContent;

    if (_currentIndex == 0) {
      // TAB 0: YOUR ORIGINAL DIARY LIST INTERFACE
      activeTabContent = _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredDiaries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/images/happy.png', height: 150, width: 150),
                      const SizedBox(height: 24),
                      Text(
                        _isSearching ? 'No results found!' : 'Your journey begins here!',
                        style: GoogleFonts.quicksand(
                          fontSize: 22,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30.0),
                        child: Text(
                          _isSearching
                              ? 'Try a different search term or add a new entry.'
                              : 'Tap the cute "+" button below to add your first entry!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.quicksand(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _filteredDiaries.length,
                  itemBuilder: (context, index) {
                    final diaryEntry = _filteredDiaries[index];
                    final String? emotionImagePath = diaryEntry['emotionImage'];
                    final Color cardBorderColor = _emotionColors[emotionImagePath] ?? Colors.transparent;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(color: cardBorderColor, width: 2),
                      ),
                      child: Stack(
                        children: [
                          // Your original stars/hearts decorations inside the card
                          Positioned(
                            top: -10, right: -10,
                            child: Transform.rotate(angle: 0.5, child: Icon(Icons.star, size: 50, color: Colors.yellow.withOpacity(0.2))),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (emotionImagePath != null && emotionImagePath.isNotEmpty)
                                      Image.asset(emotionImagePath, height: 45, width: 45),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        diaryEntry['feeling'],
                                        style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 22, color: themeProvider.appBarColor),
                                      ),
                                    ),
                                    IconButton(icon: const Icon(Icons.edit, color: Colors.blueGrey), onPressed: () => _showForm(diaryEntry['id'])),
                                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteDiary(diaryEntry['id'])),
                                  ],
                                ),
                                Text(diaryEntry['description'], style: GoogleFonts.quicksand(color: Colors.black87, fontSize: 16)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
    } else if (_currentIndex == 1) {
      // TAB 1: THE NEW CALENDAR VIEW
      activeTabContent = _buildCalendarView(); 
    } else {
      // TAB 2: THE NEW DASHBOARD/STATS VIEW
      activeTabContent = _buildDashboardView();
    }

    // --- STEP 2: THE MAIN SCAFFOLD STRUCTURE ---
    return Scaffold(
      appBar: CustomAppBar(
        title: _isSearching ? 'Search Diary' : "Shafiqah's Diary",
        backgroundColor: themeProvider.appBarColor,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) _searchController.clear();
                _applySearchFilter();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage())),
          ),
        ],
        leading: _isSearching
            ? Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(hintText: 'Search entries...', border: InputBorder.none),
                  style: GoogleFonts.quicksand(color: Colors.white, fontSize: 18),
                ),
              )
            : null,
        height: kToolbarHeight + 40,
      ),
      body: Stack(
        children: [
          // 1. KEEP YOUR BACKGROUND ANIMATIONS AS THE BOTTOM LAYER
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                 if (_decorations.isEmpty || _decorations[0].screenSize != constraints.biggest) {

                  _decorations.clear();

                  for (int i = 0; i < 25; i++) {

                    _decorations.add(FloatingDecoration(

                      imagePath: _backgroundDecorationImages[_random.nextInt(_backgroundDecorationImages.length)],

                      random: _random,

                      screenSize: constraints.biggest,

                    ));

                  }

                }
                return Stack(
                  children: _decorations.map((decoration) {
                    return Positioned(
                      top: decoration.top, left: decoration.left,
                      child: Opacity(
                        opacity: decoration.opacity,
                        child: Image.asset(decoration.imagePath, width: decoration.size),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          
          // 2. SHOW THE ACTIVE TAB CONTENT ON TOP
          activeTabContent,
        ],
      ),

      // --- STEP 3: ADD THE BOTTOM NAVIGATION BAR ---
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: themeProvider.appBarColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Diary'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Calendar'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Stats'),
        ],
      ),

      // Only show FAB when on the Diary tab
      floatingActionButton: _currentIndex == 0 
        ? ScaleTransition(
            scale: _fabPulseAnimation,
            child: FloatingActionButton(
              onPressed: () => _showForm(null),
              backgroundColor: themeProvider.appBarColor,
              child: Icon(Icons.add_rounded, size: 35, color: Colors.white,),
            ),
          )
        : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }}