import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../domain/lesson_model.dart';
import '../../../core/network/http_interceptor.dart';

class QuizAnswerResponse {
  final bool correct;
  final String explanation;

  QuizAnswerResponse({required this.correct, required this.explanation});

  factory QuizAnswerResponse.fromJson(Map<String, dynamic> json) {
    return QuizAnswerResponse(
      correct: json['correct'] == true,
      explanation: json['explanation'] as String? ?? '',
    );
  }
}

class LessonService {
  static const _baseUrl = 'http://10.0.2.2:8080';
  static const _lessonEndpoint = '/api/lessons';
  static const _quizEndpoint = '/api/quiz';

  Future<List<LessonModel>> fetchLessons() async {
    final response = await HttpInterceptor.get(
      Uri.parse('$_baseUrl$_lessonEndpoint'),
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => LessonModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load lessons');
    }
  }

  Future<LessonModel> fetchLessonById(int lessonId) async {
    final response = await HttpInterceptor.get(
      Uri.parse('$_baseUrl$_lessonEndpoint/$lessonId'),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return LessonModel.fromJson(data);
    } else {
      throw Exception('Failed to load lesson');
    }
  }

  Future<List<QuizQuestion>> fetchLessonQuiz(int lessonId) async {
    final response = await HttpInterceptor.get(
      Uri.parse('$_baseUrl$_lessonEndpoint/$lessonId/quiz'),
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => QuizQuestion.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load quiz');
    }
  }

  Future<bool> submitQuizAnswers(int lessonId, List<int> answers) async {
    // Her bir quiz sorusu için cevabı gönder
    for (int i = 0; i < answers.length; i++) {
      final response = await HttpInterceptor.post(
        Uri.parse('$_baseUrl$_quizEndpoint/answer'),
        body: jsonEncode({
          'quizId': lessonId,
          'selectedOptionId': answers[i],
        }),
      );
      
      if (response.statusCode != 200) {
        return false;
      }
      
      final data = jsonDecode(response.body);
      if (!data['correct']) {
        return false;
      }
    }
    
    return true;
  }

  Future<QuizAnswerResponse> submitQuizAnswersSingle(int quizId, int selectedOptionId) async {
    final response = await HttpInterceptor.post(
      Uri.parse('$_baseUrl$_quizEndpoint/answer'),
      body: jsonEncode({
        'quizId': quizId,
        'selectedOptionId': selectedOptionId,
      }),
    );
    
    if (response.statusCode != 200) {
      return QuizAnswerResponse(correct: false, explanation: 'Bir hata oluştu.');
    }
    final data = jsonDecode(response.body);
    return QuizAnswerResponse.fromJson(data);
  }

  Future<bool> markLessonAsCompleted(int lessonId) async {
    final response = await HttpInterceptor.post(
      Uri.parse('$_baseUrl$_lessonEndpoint/edupath/$lessonId/complete'),
    );

    return response.statusCode == 200;
  }

  Future<LessonModel> fetchLessonDetail(int lessonId) async {
    final response = await HttpInterceptor.get(
      Uri.parse('$_baseUrl$_lessonEndpoint/$lessonId'),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return LessonModel.fromJson(data);
    } else {
      throw Exception('Failed to load lesson detail');
    }
  }

  Future<List<LessonModel>> fetchLessonsWithProgress() async {
    final response = await HttpInterceptor.get(
      Uri.parse('$_baseUrl$_lessonEndpoint/edupath/progress'),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final lessons = data['lessons'] as List;
      return lessons.map((e) => LessonModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load lessons with progress');
    }
  }
} 