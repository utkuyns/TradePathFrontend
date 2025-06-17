import 'package:flutter/material.dart';
import '../data/lesson_service.dart';
import '../domain/lesson_model.dart';
import 'package:flutter/services.dart';
import 'package:card_swiper/card_swiper.dart';

class EduPathScreen extends StatefulWidget {
  const EduPathScreen({Key? key}) : super(key: key);

  @override
  State<EduPathScreen> createState() => _EduPathScreenState();
}

class _EduPathScreenState extends State<EduPathScreen> {
  static const int totalSteps = 10;
  int unlockedStep = 1;
  static const Color appBarBlue = Color(0xFF7FBBBF);
  late Future<List<LessonModel>> _lessonsFuture;
  final LessonService _lessonService = LessonService();
  final SwiperController _swiperController = SwiperController();
  int _currentLessonIndex = 0;
  List<int> _quizAnswers = [];
  bool _isQuizSubmitted = false;
  bool _showFlashcard = false;
  int _selectedStep = 1;

  // Node positions based on user-provided pixel coordinates (image size: 1080x1440), each moved 200px up on y-axis
  static const List<Offset> nodePositions = [
    Offset(582/1080, (1174-200)/1440), // 1
    Offset(400/1080, (1100-200)/1440), // 2
    Offset(610/1080, (1006-175)/1440), // 3 
    Offset(310/1080, (1006-200)/1440), // 4
    Offset(850/1080, (994-270)/1440),  // 5
    Offset(624/1080, (871-200)/1440),  // 6
    Offset(840/1080, (800-200)/1440),  // 7 
    Offset(800/1080, (670-170)/1440),  // 8
    Offset(425/1080, (670-225)/1440),  // 9
    Offset(710/1080, (598-200)/1440),  // 10
  ];

  @override
  void initState() {
    super.initState();
    _lessonsFuture = _lessonService.fetchLessons();
  }

  void _openFlashcard(int step) {
    setState(() {
      _showFlashcard = true;
      _selectedStep = step;
      _currentLessonIndex = (step - 1) * 3; // örnek: her adımda 3 lesson var varsayımı
      _quizAnswers = [];
      _isQuizSubmitted = false;
    });
  }

  void _closeFlashcard() {
    setState(() {
      _showFlashcard = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double width = screenSize.width;
    final double height = screenSize.height;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: appBarBlue,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(38),
        child: AppBar(
          backgroundColor: appBarBlue,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('EduPath', style: TextStyle(color: Colors.black, fontSize: 19, fontWeight: FontWeight.w600)),
          centerTitle: true,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          toolbarHeight: 38,
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/edupathmap.webp',
              fit: BoxFit.cover,
            ),
          ),
          ...List.generate(totalSteps, (i) {
            final step = i + 1;
            final isActive = step == 1 || step <= unlockedStep;
            final pos = nodePositions[i];
            return Positioned(
              left: pos.dx * width - 32,
              top: pos.dy * height - 32,
              child: GestureDetector(
                onTap: isActive ? () => _openFlashcard(step) : null,
                child: NodeWidget(
                  isActive: isActive,
                  isFirst: step == 1,
                ),
              ),
            );
          }),
          if (_showFlashcard)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeFlashcard,
                child: Container(
                  color: Colors.black.withOpacity(0.35),
                  child: Center(
                    child: GestureDetector(
                      onTap: () {}, // kartın kendisine tıklanınca kapanmasın diye
                      child: SizedBox(
                        width: width * 0.92,
                        height: height * 0.75,
                        child: FutureBuilder<List<LessonModel>>(
                          future: _lessonsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError) {
                              return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
                            }
                            final lessons = snapshot.data ?? [];
                            // Her step için 3 lesson örneği, istersen burayı backend'e göre ayarlayabilirsin
                            final start = (_selectedStep - 1) * 3;
                            final end = (_selectedStep) * 3;
                            final stepLessons = lessons.length >= end
                                ? lessons.sublist(start, end)
                                : lessons.sublist(start);
                            if (stepLessons.isEmpty) {
                              return const Center(child: Text('Ders bulunamadı.'));
                            }
                            return Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              elevation: 8,
                              color: Colors.white.withOpacity(0.97),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Swiper(
                                  controller: _swiperController,
                                  itemCount: stepLessons.length,
                                  itemBuilder: (context, index) {
                                    final lesson = stepLessons[index];
                                    if (lesson.isQuiz) {
                                      return _buildQuizCard(lesson, ScrollController());
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            lesson.title,
                                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 16),
                                          Expanded(
                                            child: SingleChildScrollView(
                                              child: Builder(
                                                builder: (context) {
                                                  print('Lesson: \\${lesson.title} | Content: \\${lesson.content}');
                                                  return Text(
                                                    (lesson.content != null && lesson.content.trim().isNotEmpty)
                                                        ? lesson.content
                                                        : 'İçerik bulunamadı.',
                                                    style: const TextStyle(fontSize: 16, height: 1.5),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  onIndexChanged: (index) {
                                    setState(() {
                                      _currentLessonIndex = index;
                                      _quizAnswers = [];
                                      _isQuizSubmitted = false;
                                    });
                                  },
                                  loop: false,
                                  pagination: const SwiperPagination(),
                                  control: const SwiperControl(),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuizCard(LessonModel lesson, ScrollController scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lesson.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          ...lesson.questions!.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${index + 1}. ${question.question}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                ...question.options.asMap().entries.map((option) {
                  final optionIndex = option.key;
                  final optionData = option.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: RadioListTile<int>(
                      title: Text(optionData.text),
                      value: optionData.id,
                      groupValue: _quizAnswers.length > index ? _quizAnswers[index] : null,
                      onChanged: _isQuizSubmitted ? null : (value) {
                        if (value != null) {
                          setState(() {
                            if (_quizAnswers.length <= index) {
                              _quizAnswers.add(value);
                            } else {
                              _quizAnswers[index] = value;
                            }
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
                const SizedBox(height: 24),
              ],
            );
          }).toList(),
          if (!_isQuizSubmitted && _quizAnswers.length == lesson.questions!.length)
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  final success = await _lessonService.submitQuizAnswers(lesson.id, _quizAnswers);
                  setState(() {
                    _isQuizSubmitted = true;
                  });
                  if (success) {
                    setState(() {
                      unlockedStep++;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Quiz başarıyla tamamlandı! Sonraki ders açıldı.')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bazı cevaplar yanlış. Lütfen tekrar deneyin.')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: appBarBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('Quiz\'i Tamamla', style: TextStyle(fontSize: 16)),
              ),
            ),
        ],
      ),
    );
  }
}

class NodeWidget extends StatelessWidget {
  final bool isActive;
  final bool isFirst;
  const NodeWidget({Key? key, required this.isActive, required this.isFirst}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color gold = const Color(0xFFF9C846);
    final Color darkGreen = const Color(0xFF3A5A2A);
    final Color gray = Colors.grey[500]!;
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: isActive ? gold : gray.withOpacity(0.7),
        shape: BoxShape.circle,
        border: Border.all(color: isActive ? darkGreen : gray, width: 4),
        boxShadow: [
          BoxShadow(
            color: isActive ? gold.withOpacity(0.35) : gray.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: isActive
            ? (isFirst
                ? const Icon(Icons.description, color: Colors.white, size: 32)
                : const Icon(Icons.check, color: Colors.white, size: 32))
            : const Icon(Icons.lock, color: Colors.white, size: 30),
      ),
    );
  }
} 