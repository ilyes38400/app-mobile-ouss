import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mighty_fitness/extensions/extension_util/string_extensions.dart';
import 'package:mighty_fitness/extensions/extension_util/widget_extensions.dart';
import 'package:mighty_fitness/extensions/loader_widget.dart';
import 'package:mighty_fitness/models/question_model.dart';
import 'package:mighty_fitness/network/rest_api.dart';
import 'package:mighty_fitness/utils/app_common.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../models/category_result.dart';

class WeeklyQuestionnaireScreen extends StatefulWidget {
  @override
  _WeeklyQuestionnaireScreenState createState() => _WeeklyQuestionnaireScreenState();
}

class _WeeklyQuestionnaireScreenState extends State<WeeklyQuestionnaireScreen> {
  bool _loading = false;
  List<QuestionModel> _questions = [];
  Map<int, int> _scores = {};
  List<CategoryResult>? _results;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    setState(() => _loading = true);
    try {
      _questions = await getQuestionnaireListByTypeApi('hebdo');
    } catch (e) {
      toast('Erreur lors du chargement des questions.');
    }
    setState(() => _loading = false);
  }

  void _onAnswer(int questionId, int score) => setState(() => _scores[questionId] = score);

  Future<void> _submitAll() async {
    final responses = <String, dynamic>{};
    for (var q in _questions) {
      responses[q.id.toString()] = {
        'score': _scores[q.id],
        'category_id': q.categoryId,
      };
    }

    setState(() => _loading = true);
    print(json.encode({
      'user_email': userStore.email.validate(),
      'responses': responses,
    }));
    try {
      _results = await submitQuestionnaireApi({
        'user_email': userStore.email.validate(),
        'responses': responses,
      });
    } catch (e) {
      toast('Erreur lors de l\'envoi du questionnaire');
    }
    setState(() => _loading = false);

    final prefs = await SharedPreferences.getInstance();
    final key = 'last_weekly_questionnaire_${userStore.email.validate()}';
    await prefs.setString(key, DateTime.now().toIso8601String());

  }

  Widget _buildQuestion(QuestionModel q) => Container(
    margin: EdgeInsets.only(bottom: 28),
    padding: EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: Text(
            q.question,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        SizedBox(height: 18),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: List.generate(5, (i) {
            int score = i + 1;
            bool selected = _scores[q.id] == score;
            return InkWell(
              onTap: () => _onAnswer(q.id, score),
              borderRadius: BorderRadius.circular(30),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: selected ? Theme.of(context).primaryColor : Colors.grey.shade100,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? Theme.of(context).primaryColor : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  score.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: selected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    ),
  );

  Widget _buildNavigationButtons(bool allAnswered, int totalPages, List<QuestionModel> pageQuestions) {
    final isLastPage = _currentPage == totalPages - 1;

    final nextButton = ElevatedButton(
      onPressed: allAnswered
          ? () async {
        if (!isLastPage) {
          setState(() => _currentPage++);
        } else {
          _submitAll();


        }
      }
          : null,
      child: Text(isLastPage ? 'Voir résultats' : 'Suivant'),
    );

    final prevButton = OutlinedButton(
      onPressed: () => setState(() => _currentPage--),
      child: Text('Précédent'),
    );

    if (_currentPage == 0) {
      return Center(child: nextButton);
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [prevButton, nextButton],
      );
    }
  }

  Widget _buildResults() {
    if (_results == null || _results!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text("Résultats")),
        body: Center(
          child: Text("Aucun résultat à afficher."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Résultats hebdo")),
      body: ListView(
        padding: EdgeInsets.all(20),
        children: [
          Text('🎯 Résultats hebdomadaires', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          SizedBox(height: 24),
          Column(
            children: _results!.map((c) {
              final score = c.averageScore;
              final positive = score >= 3;
              final color = positive ? Colors.green : Colors.red;

              return Card(
                elevation: 3,
                margin: EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              c.category,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            score.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: score / 5,
                          minHeight: 10,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        positive ? c.positiveResponse : c.negativeResponse,
                        style: TextStyle(fontSize: 15, color: Colors.black.withOpacity(0.8)),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.check),
            label: Text("Terminé"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Loader().center();
    if (_results != null) return _buildResults();

    int questionsPerPage = 5;
    int totalPages = (_questions.length / questionsPerPage).ceil();
    int start = _currentPage * questionsPerPage;
    int end = (_currentPage + 1) * questionsPerPage;
    final pageQuestions = _questions.sublist(start, end > _questions.length ? _questions.length : end);

    return Scaffold(
      appBar: AppBar(
        title: Text("Questionnaire Hebdo"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: totalPages > 0 ? (_currentPage + 1) / totalPages : 0.0,
                minHeight: 8,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(20),
              children: [
                ...pageQuestions.map((q) => _buildQuestion(q)).toList(),
                SizedBox(height: 16),
                _buildNavigationButtons(
                  pageQuestions.every((q) => _scores.containsKey(q.id)),
                  totalPages,
                  pageQuestions,
                ).paddingSymmetric(vertical: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}