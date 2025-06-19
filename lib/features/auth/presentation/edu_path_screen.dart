import 'package:flutter/material.dart';
import '../data/lesson_service.dart';
import '../domain/lesson_model.dart';
import 'package:flutter/services.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:collection/collection.dart';
import 'package:lottie/lottie.dart';
import 'dart:ui';

class EduPathScreen extends StatefulWidget {
  const EduPathScreen({Key? key}) : super(key: key);

  @override
  State<EduPathScreen> createState() => _EduPathScreenState();
}

class _EduPathScreenState extends State<EduPathScreen> with TickerProviderStateMixin {
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

  // Bulut animasyon controller'ları
  late AnimationController _cloudController1;
  late AnimationController _cloudController2;
  late AnimationController _cloudController3;
  late AnimationController _cloudController4;

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
    
    // Bulut animasyonlarını başlat
    _cloudController1 = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..repeat();
    
    _cloudController2 = AnimationController(
      duration: const Duration(seconds: 18),
      vsync: this,
    )..repeat();
    
    _cloudController3 = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();
    
    _cloudController4 = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _cloudController1.dispose();
    _cloudController2.dispose();
    _cloudController3.dispose();
    _cloudController4.dispose();
    super.dispose();
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
      _currentQuizQuestions = null;
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

    // Eğer lesson zaten tamamlanmışsa kartı kapat
    if (currentLesson.isCompleted) {
      _closeFlashcard();
      return;
    }
    
    // 5. node için özel kontrol - quiz tamamlanmadan dersi tamamlama
    if (_selectedStep == 5 && currentLesson.hasQuiz) {
      // Quiz'i göster ama dersi henüz tamamlama
      final quizQuestions = await _lessonService.fetchLessonQuiz(currentLesson.id);
      setState(() {
        _currentQuizQuestions = quizQuestions;
        _showFlashcard = true;
        _selectedLessonDetail = currentLesson; // Quiz ekranı için gerekli
      });
      return;
    }
    
    // Diğer node'lar için normal akış
    final success = await _lessonService.markLessonAsCompleted(currentLesson.id);
    if (success) {
      setState(() {
        _isLoadingLessonDetail = true;
      });
      final newLessons = await _lessonService.fetchLessonsWithProgress();
      List<QuizQuestion>? quizQuestions;
      bool showQuiz = false;
      // Her 5. dersten sonra ilgili quiz'i getir
      if (currentLesson.orderNumber % 5 == 0) {
        final quizId = (currentLesson.orderNumber ~/ 5); // ör: 10. ders -> 2. quiz
        quizQuestions = await _lessonService.fetchLessonQuiz(quizId);
        if (quizQuestions != null && quizQuestions.isNotEmpty) {
          showQuiz = true;
        }
      }
      setState(() {
        _lessonsFuture = Future.value(newLessons);
        _showFlashcard = showQuiz;
        _selectedLessonDetail = newLessons.firstWhere((l) => l.orderNumber == _selectedStep);
        _isLoadingLessonDetail = false;
        _currentQuizQuestions = quizQuestions;
      });
      if (!showQuiz) {
        _closeFlashcard(); // Quiz yoksa kartı kapat
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lesson completed successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lesson could not be completed. Please try again.')),
      );
    }
  }

  // 5. node için quiz tamamlandığında çağrılacak method
  void _completeLessonWithQuiz() async {
    final lessons = await _lessonsFuture;
    final currentLesson = lessons.firstWhere((l) => l.orderNumber == _selectedStep);
    
    final success = await _lessonService.markLessonAsCompleted(currentLesson.id);
    if (success) {
      setState(() {
        _isLoadingLessonDetail = true;
      });
      final newLessons = await _lessonService.fetchLessonsWithProgress();
      setState(() {
        _lessonsFuture = Future.value(newLessons);
        _showFlashcard = false; // Quiz tamamlandı, modalı kapat
        _selectedLessonDetail = newLessons.firstWhere((l) => l.orderNumber == _selectedStep);
        _isLoadingLessonDetail = false;
        _currentQuizQuestions = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lesson and quiz completed successfully!')),
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
          // Bulut Lottie animasyonları (gökyüzü alanı) -- GÜNEŞİN ALTINA ALINDI
          AnimatedBuilder(
            animation: _cloudController1,
            builder: (context, child) {
              final screenSize = MediaQuery.of(context).size;
              final x = lerpDouble(-80, screenSize.width + 80, _cloudController1.value)!;
              return Positioned(
                top: 24,
                left: x,
                child: SizedBox(
                  width: 90,
                  height: 60,
                  child: Lottie.asset('assets/animations/cloud.json', repeat: true),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _cloudController2,
            builder: (context, child) {
              final screenSize = MediaQuery.of(context).size;
              final x = lerpDouble(screenSize.width + 80, -80, _cloudController2.value)!;
              return Positioned(
                top: 38,
                left: x,
                child: SizedBox(
                  width: 70,
                  height: 45,
                  child: Lottie.asset('assets/animations/cloud.json', repeat: true),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _cloudController3,
            builder: (context, child) {
              final screenSize = MediaQuery.of(context).size;
              final x = lerpDouble(-60, screenSize.width + 60, _cloudController3.value)!;
              return Positioned(
                top: 18,
                left: x,
                child: SizedBox(
                  width: 60,
                  height: 38,
                  child: Lottie.asset('assets/animations/cloud.json', repeat: true),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _cloudController4,
            builder: (context, child) {
              final screenSize = MediaQuery.of(context).size;
              final x = lerpDouble(screenSize.width + 60, -60, _cloudController4.value)!;
              return Positioned(
                top: 52,
                left: x,
                child: SizedBox(
                  width: 80,
                  height: 50,
                  child: Lottie.asset('assets/animations/cloud.json', repeat: true),
                ),
              );
            },
          ),
          // EKSTRA BULUT 1 (ilk bulutla aynı koordinat)
          AnimatedBuilder(
            animation: _cloudController1,
            builder: (context, child) {
              final screenSize = MediaQuery.of(context).size;
              final x = lerpDouble(-100, screenSize.width + 100, (_cloudController1.value + 0.3) % 1.0)!;
              return Positioned(
                top: 24,
                left: x,
                child: SizedBox(
                  width: 60,
                  height: 38,
                  child: Lottie.asset('assets/animations/cloud.json', repeat: true),
                ),
              );
            },
          ),
          // EKSTRA BULUT 2 (ikinci bulutla aynı koordinat)
          AnimatedBuilder(
            animation: _cloudController2,
            builder: (context, child) {
              final screenSize = MediaQuery.of(context).size;
              final x = lerpDouble(screenSize.width + 120, -120, (_cloudController2.value + 0.5) % 1.0)!;
              return Positioned(
                top: 38,
                left: x,
                child: SizedBox(
                  width: 100,
                  height: 60,
                  child: Lottie.asset('assets/animations/cloud.json', repeat: true),
                ),
              );
            },
          ),
          Positioned(
            top: height * 0.06 - 8, // 8px yukarı
            left: width * 0.5 - 60 - 90 + 4, // 2px daha sağa, toplamda 4px sağa
            child: SizedBox(
              width: 100,
              height: 100,
              child: Lottie.asset(
                'assets/animations/newsun2.json',
                repeat: true,
                animate: true, // animasyonun oynamasını garantiye al
              ),
            ),
          ),
          // Tree Lottie animasyonu (güneşin 310px aşağısı)
          Positioned(
            top: (height * 0.06 - 8) + 310,
            left: width * 0.5 - 60 - 90 + 4,
            child: SizedBox(
              width: 120,
              height: 120,
              child: Lottie.asset(
                'assets/animations/tree.json',
                repeat: true,
                animate: true,
              ),
            ),
          ),
          // İkinci tree Lottie animasyonu (40px sağa kaydırılmış)
          Positioned(
            top: (height * 0.06 - 8) + 310,
            left: width * 0.5 - 60 - 90 + 4 + 40,
            child: SizedBox(
              width: 120,
              height: 120,
              child: Lottie.asset(
                'assets/animations/tree.json',
                repeat: true,
                animate: true,
              ),
            ),
          ),
          // Üçüncü tree Lottie animasyonu (1. node'un 35px sağı, 15px yukarıda)
          Positioned(
            top: nodePositions[0].dy * height - 32 - 15,
            left: (nodePositions[0].dx * width - 32) + 35,
            child: SizedBox(
              width: 120,
              height: 120,
              child: Lottie.asset(
                'assets/animations/tree.json',
                repeat: true,
                animate: true,
              ),
            ),
          ),
          // Dördüncü tree Lottie animasyonu (güneşin 120px aşağısı)
          Positioned(
            top: (height * 0.06 - 8) + 120,
            left: width * 0.5 - 60 - 90 + 4,
            child: SizedBox(
              width: 120,
              height: 120,
              child: Lottie.asset(
                'assets/animations/tree.json',
                repeat: true,
                animate: true,
              ),
            ),
          ),
          // Beşinci tree Lottie animasyonu (4. eklenenin 50px sağı)
          Positioned(
            top: (height * 0.06 - 8) + 120,
            left: width * 0.5 - 60 - 90 + 4 + 50,
            child: SizedBox(
              width: 120,
              height: 120,
              child: Lottie.asset(
                'assets/animations/tree.json',
                repeat: true,
                animate: true,
              ),
            ),
          ),
          // --- KARTLAR EN ÜSTE ALINDI ---
          FutureBuilder<List<LessonModel>>(
            future: _lessonsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Bir hata oluştu: {snapshot.error}'));
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
                      child: AnimatedScale(
                        scale: 1.0,
                        duration: Duration(milliseconds: 350),
                        curve: Curves.easeOutBack,
                        child: SizedBox(
                          width: width * 0.92,
                          height: height * 0.75,
                          child: _isLoadingLessonDetail
                              ? const Center(child: CircularProgressIndicator())
                              : _selectedLessonDetail == null
                                  ? const Center(child: Text('Lesson not found.'))
                                  : (_currentQuizQuestions != null && _showFlashcard)
                                      ? QuizWidget(
                                          questions: _currentQuizQuestions!,
                                          lessonId: _selectedLessonDetail!.id,
                                          onQuizSuccess: _selectedStep == 5 ? _completeLessonWithQuiz : _markLessonAsCompleted,
                                          onClose: _closeFlashcard,
                                        )
                                      : LessonCard(
                                          title: _selectedLessonDetail!.title,
                                          content: _selectedLessonDetail!.content,
                                          isCompleted: _selectedLessonDetail!.isCompleted,
                                          onComplete: _markLessonAsCompleted,
                                          onClose: _closeFlashcard,
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

class QuizWidget extends StatefulWidget {
  final List<QuizQuestion> questions;
  final int lessonId;
  final Function onQuizSuccess;
  final VoidCallback onClose;
  const QuizWidget({Key? key, required this.questions, required this.lessonId, required this.onQuizSuccess, required this.onClose}) : super(key: key);

  @override
  State<QuizWidget> createState() => _QuizWidgetState();
}

class _QuizWidgetState extends State<QuizWidget> with SingleTickerProviderStateMixin {
  int _currentQuestion = 0;
  int _correctCount = 0;
  bool _isLoading = false;
  bool _quizFinished = false;
  String? _errorMessage;
  String? _explanation;
  List<int> _selectedOptions = [];
  int? _lastAnsweredOption;
  bool? _lastAnswerCorrect;
  late AnimationController _cardAnimController;

  final LessonService _lessonService = LessonService();

  @override
  void initState() {
    super.initState();
    _cardAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      lowerBound: 0.95,
      upperBound: 1.0,
    )..forward();
  }

  @override
  void dispose() {
    _cardAnimController.dispose();
    super.dispose();
  }

  void _answer(int optionId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _explanation = null;
      _lastAnsweredOption = optionId;
      _lastAnswerCorrect = null;
    });
    try {
      final response = await _lessonService.submitQuizAnswersSingle(widget.questions[_currentQuestion].id, optionId);
      setState(() {
        _explanation = (response.explanation.isNotEmpty) ? response.explanation : null;
        _errorMessage = null;
        _lastAnswerCorrect = response.correct;
      });
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      if (response.correct) {
        _selectedOptions.add(optionId);
        if (_currentQuestion == widget.questions.length - 1) {
          setState(() {
            _quizFinished = true;
            _correctCount = widget.questions.length;
            _explanation = null;
            _errorMessage = null;
          });
          widget.onQuizSuccess();
          widget.onClose(); // Quiz bitince kartı kapat
        } else {
          setState(() {
            _currentQuestion++;
            _explanation = null;
            _errorMessage = null;
            _lastAnsweredOption = null;
            _lastAnswerCorrect = null;
          });
        }
      } else {
        // Yanlış şık seçildiyse, kısa bir süre sonra tekrar seçim yapılabilsin
        await Future.delayed(const Duration(milliseconds: 1000));
        if (!mounted) return;
        setState(() {
          _lastAnsweredOption = null;
          _lastAnswerCorrect = null;
        });
      }
    } catch (e) {
      setState(() {
        _explanation = null;
        _errorMessage = 'An error occurred: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.questions[_currentQuestion];
    return AnimatedScale(
      scale: _cardAnimController.value,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 12,
        color: Colors.white.withOpacity(0.98),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
          child: _quizFinished
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.emoji_events, color: Colors.amber, size: 72),
                      const SizedBox(height: 18),
                      const Text('Congratulations! You answered all questions correctly.', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Question ${_currentQuestion + 1} of ${widget.questions.length}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: Color(0xFF3A5A2A))),
                    const SizedBox(height: 18),
                    Text(q.question, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, height: 1.3)),
                    const SizedBox(height: 28),
                    ...q.options.map((o) {
                      final isSelected = _lastAnsweredOption == o.id;
                      final isCorrect = isSelected && _lastAnswerCorrect == true;
                      final isWrong = isSelected && _lastAnswerCorrect == false;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.symmetric(vertical: 7),
                        child: GestureDetector(
                          onTap: (_isLoading || (o.quizId != null && o.quizId != q.id) || _lastAnsweredOption != null) ? null : () => _answer(o.id),
                          child: AnimatedScale(
                            scale: isSelected ? 0.97 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                              decoration: BoxDecoration(
                                color: isCorrect
                                    ? Colors.green[400]
                                    : isWrong
                                        ? Colors.red[300]
                                        : Colors.blueGrey[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isCorrect
                                      ? Colors.green
                                      : isWrong
                                          ? Colors.red
                                          : Colors.blueGrey[200]!,
                                  width: 2.2,
                                ),
                                boxShadow: [
                                  if (isSelected)
                                    BoxShadow(
                                      color: isCorrect
                                          ? Colors.green.withOpacity(0.18)
                                          : isWrong
                                              ? Colors.red.withOpacity(0.18)
                                              : Colors.blueGrey.withOpacity(0.10),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                ],
                              ),
                              child: Text(
                                o.text,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                  color: isCorrect || isWrong ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    if (_isLoading) ...[
                      const SizedBox(height: 18),
                      const Center(child: CircularProgressIndicator()),
                    ],
                    if (_explanation != null) ...[
                      const SizedBox(height: 18),
                      Text(_explanation!, style: const TextStyle(color: Colors.blueGrey, fontSize: 16)),
                    ],
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 18),
                      Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 16)),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class LessonCard extends StatelessWidget {
  final String title;
  final String content;
  final bool isCompleted;
  final VoidCallback onComplete;
  final VoidCallback onClose;
  static const Color appBarBlue = Color(0xFF7FBBBF);

  const LessonCard({
    Key? key,
    required this.title,
    required this.content,
    required this.isCompleted,
    required this.onComplete,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 8,
      color: Colors.white.withOpacity(0.97),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 1),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 28, color: Color(0xFF222B45)),
                  onPressed: onClose,
                  tooltip: 'Close',
                ),
              ],
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 0.2),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  content,
                  style: const TextStyle(fontSize: 17, height: 1.6, color: Color(0xFF222B45)),
                ),
              ),
            ),
            if (!isCompleted)
              Padding(
                padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
                child: _AnimatedGradientButton(
                  onTap: onComplete,
                  text: 'Complete Lesson',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedGradientButton extends StatefulWidget {
  final VoidCallback onTap;
  final String text;
  const _AnimatedGradientButton({required this.onTap, required this.text});

  @override
  State<_AnimatedGradientButton> createState() => _AnimatedGradientButtonState();
}

class _AnimatedGradientButtonState extends State<_AnimatedGradientButton> with SingleTickerProviderStateMixin {
  double _scale = 1.0;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
    _controller.addListener(() {
      setState(() {
        _scale = _controller.value;
      });
    });
  }
//SON.

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.reverse();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.forward();
  }

  void _onTapCancel() {
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: Transform.scale(
        scale: _scale,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF43CEA2), Color(0xFF185A9D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
} 