import 'package:flutter/material.dart';
import '../data/lesson_service.dart';
import '../domain/lesson_model.dart';
import 'package:flutter/services.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:collection/collection.dart';

class EduPathScreen extends StatefulWidget {
  const EduPathScreen({Key? key}) : super(key: key);

  @override
  State<EduPathScreen> createState() => _EduPathScreenState();
}

class _EduPathScreenState extends State<EduPathScreen> {
  static const int totalSteps = 10;
  static const Color appBarBlue = Color(0xFF7FBBBF);
  late Future<List<LessonModel>> _lessonsFuture;
  final LessonService _lessonService = LessonService();
  final SwiperController _swiperController = SwiperController();
  int _currentLessonIndex = 0;
  List<int> _quizAnswers = [];
  bool _isQuizSubmitted = false;
  bool _showFlashcard = false;
  int _selectedStep = 1;
  LessonModel? _selectedLessonDetail;
  bool _isLoadingLessonDetail = false;
  List<QuizQuestion>? _currentQuizQuestions;

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
    _lessonsFuture = _lessonService.fetchLessonsWithProgress();
  }

  void _openFlashcard(int step) async {
    final lessons = await _lessonsFuture;
    final lesson = lessons.firstWhereOrNull((l) => l.orderNumber == step);
    if (lesson == null) return;
    if (step != 1 && !lesson.isUnlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This lesson is locked. Please complete previous lessons.')),
      );
      return;
    }
    setState(() {
      _isLoadingLessonDetail = true;
      _showFlashcard = true;
      _selectedStep = step;
      _currentLessonIndex = step - 1;
      _quizAnswers = [];
      _isQuizSubmitted = false;
      _selectedLessonDetail = null;
    });
    // Detaylı dersi çek
    final detail = await _lessonService.fetchLessonDetail(lesson.id);
    // Eğer ders tamamlandıysa ve quiz varsa quiz sorularını çek
    List<QuizQuestion>? quizQuestions;
    if (detail.isCompleted && detail.hasQuiz) {
      quizQuestions = await _lessonService.fetchLessonQuiz(detail.id);
    }
    setState(() {
      _selectedLessonDetail = detail;
      _isLoadingLessonDetail = false;
      _currentQuizQuestions = quizQuestions;
    });
  }

  void _closeFlashcard() {
    setState(() {
      _showFlashcard = false;
      _selectedLessonDetail = null;
    });
  }

  void _markLessonAsCompleted() async {
    final lessons = await _lessonsFuture;
    final currentLesson = lessons.firstWhere((l) => l.orderNumber == _selectedStep);
    // Quiz kontrolünü kaldırıyoruz, önce dersi tamamla
    final success = await _lessonService.markLessonAsCompleted(currentLesson.id);
    if (success) {
      setState(() {
        _isLoadingLessonDetail = true;
      });
      final newLessons = await _lessonService.fetchLessonsWithProgress();
      // Eğer dersin quiz'i varsa, quiz sorularını çek ve modalda göster
      List<QuizQuestion>? quizQuestions;
      if (currentLesson.hasQuiz) {
        quizQuestions = await _lessonService.fetchLessonQuiz(currentLesson.id);
      }
      setState(() {
        _lessonsFuture = Future.value(newLessons);
        _showFlashcard = currentLesson.hasQuiz; // Quiz varsa modal açık kalsın
        _selectedLessonDetail = newLessons.firstWhere((l) => l.orderNumber == _selectedStep);
        _isLoadingLessonDetail = false;
        _currentQuizQuestions = quizQuestions;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lesson completed successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lesson could not be completed. Please try again.')),
      );
    }
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
          FutureBuilder<List<LessonModel>>(
            future: _lessonsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
              }
              
              final lessons = snapshot.data ?? [];
              return Stack(
                children: [
                  ...List.generate(totalSteps, (i) {
                    final step = i + 1;
                    final lesson = lessons.firstWhere(
                      (l) => l.orderNumber == step,
                      orElse: () => LessonModel(
                        id: 0,
                        title: '',
                        content: '',
                        orderNumber: step,
                        isUnlocked: step == 1,
                        isCompleted: false,
                        hasQuiz: false,
                      ),
                    );
                    final isUnlocked = step == 1 ? true : lesson.isUnlocked;
                    final isCompleted = lesson.isCompleted;
                    final hasQuiz = lesson.hasQuiz;
                    final pos = nodePositions[i];
                    return Positioned(
                      left: pos.dx * width - 32,
                      top: pos.dy * height - 32,
                      child: GestureDetector(
                        onTap: (lesson.id != 0 && isUnlocked) ? () => _openFlashcard(step) : null,
                        child: NodeWidget(
                          isActive: isUnlocked,
                          isCompleted: isCompleted,
                          hasQuiz: hasQuiz,
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
          if (_showFlashcard)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeFlashcard,
                child: Container(
                  color: Colors.black.withOpacity(0.35),
                  child: Center(
                    child: GestureDetector(
                      onTap: () {},
                      child: SizedBox(
                        width: width * 0.92,
                        height: height * 0.75,
                        child: _isLoadingLessonDetail
                            ? const Center(child: CircularProgressIndicator())
                            : _selectedLessonDetail == null
                                ? const Center(child: Text('Ders bulunamadı.'))
                                : (_selectedLessonDetail!.isCompleted && _selectedLessonDetail!.hasQuiz && _currentQuizQuestions != null)
                                    ? QuizWidget(questions: _currentQuizQuestions!)
                                    : Card(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                        elevation: 8,
                                        color: Colors.white.withOpacity(0.97),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            children: [
                                              Expanded(
                                                child: SingleChildScrollView(
                                                  padding: const EdgeInsets.all(16.0),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        _selectedLessonDetail!.title,
                                                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                                      ),
                                                      const SizedBox(height: 16),
                                                      Text(
                                                        _selectedLessonDetail!.content,
                                                        style: const TextStyle(fontSize: 16, height: 1.5),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              if (!_selectedLessonDetail!.isCompleted)
                                                Padding(
                                                  padding: const EdgeInsets.all(16.0),
                                                  child: ElevatedButton(
                                                    onPressed: _markLessonAsCompleted,
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: appBarBlue,
                                                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                                    ),
                                                    child: const Text('Complete Lesson', style: TextStyle(fontSize: 16)),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
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
}

class NodeWidget extends StatelessWidget {
  final bool isActive;
  final bool isCompleted;
  final bool hasQuiz;
  
  const NodeWidget({
    Key? key,
    required this.isActive,
    required this.isCompleted,
    required this.hasQuiz,
  }) : super(key: key);

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
            ? (isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 32)
                : hasQuiz
                    ? const Icon(Icons.quiz, color: Colors.white, size: 32)
                    : const Icon(Icons.description, color: Colors.white, size: 32))
            : const Icon(Icons.lock, color: Colors.white, size: 30),
      ),
    );
  }
}

class QuizWidget extends StatelessWidget {
  final List<QuizQuestion> questions;
  const QuizWidget({Key? key, required this.questions}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 8,
      color: Colors.white.withOpacity(0.97),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: questions.length,
          itemBuilder: (context, index) {
            final q = questions[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Soru ${index + 1}: ${q.question}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...q.options.map((o) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text('- ${o.text}'),
                )),
                const Divider(),
              ],
            );
          },
        ),
      ),
    );
  }
} 