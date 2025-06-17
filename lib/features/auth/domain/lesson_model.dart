class LessonModel {
  final int id;
  final String title;
  final String content;
  final int orderNumber;
  final bool isUnlocked;
  final bool isCompleted;
  final bool hasQuiz;
  final List<QuizQuestion>? questions;

  LessonModel({
    required this.id,
    required this.title,
    required this.content,
    required this.orderNumber,
    this.isUnlocked = false,
    this.isCompleted = false,
    this.hasQuiz = false,
    this.questions,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      orderNumber: json['orderNumber'] as int? ?? 0,
      isUnlocked: json['isUnlocked'] as bool? ?? json['unlocked'] as bool? ?? false,
      isCompleted: json['isCompleted'] as bool? ?? json['completed'] as bool? ?? false,
      hasQuiz: json['hasQuiz'] as bool? ?? false,
      questions: json['questions'] != null
          ? (json['questions'] as List)
              .map((q) => QuizQuestion.fromJson(q))
              .toList()
          : null,
    );
  }
}

class QuizQuestion {
  final int id;
  final String question;
  final List<QuizOption> options;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] as int? ?? 0,
      question: json['question'] as String? ?? '',
      options: (json['options'] as List?)?.map((o) => QuizOption.fromJson(o)).toList() ?? [],
    );
  }
}

class QuizOption {
  final int id;
  final String text;

  QuizOption({
    required this.id,
    required this.text,
  });

  factory QuizOption.fromJson(Map<String, dynamic> json) {
    return QuizOption(
      id: json['id'] as int? ?? 0,
      text: json['text'] as String? ?? '',
    );
  }
} 