import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mighty_fitness/extensions/extension_util/string_extensions.dart';
import 'package:mighty_fitness/extensions/extension_util/widget_extensions.dart';
import 'package:mighty_fitness/extensions/shared_pref.dart';
import 'package:mighty_fitness/models/question_model.dart';
import 'package:mighty_fitness/utils/app_constants.dart';
import '../../main.dart';
import '../../extensions/loader_widget.dart';
import '../models/category_result.dart';
import '../models/register_request.dart';
import '../network/rest_api.dart';
import '../utils/app_common.dart';
import '../../screens/dashboard_screen.dart';

String _removeHtmlTags(String htmlText) {
  return htmlText
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .trim();
}

class SignUpStep5Component extends StatefulWidget {
  @override
  _SignUpStep5ComponentState createState() => _SignUpStep5ComponentState();
}

class _SignUpStep5ComponentState extends State<SignUpStep5Component> {
  bool _loading = false;
  bool _showIntro = true;
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
      _questions = await getQuestionnaireListByTypeApi('annuel');
    } catch (_) {}
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
    try {
      _results = await submitQuestionnaireApi({
        'user_email': userStore.email.validate(),
        'responses': responses,
      });
    } catch (e) {
      toast('Erreur lors de l’envoi du questionnaire');
    }
    setState(() => _loading = false);
  }

  Future<void> _saveData() async {
    UserProfile profile = UserProfile()
      ..age = userStore.age.toInt()
      ..heightUnit = userStore.heightUnit.validate()
      ..height = userStore.height.validate()
      ..weight = userStore.weight.validate()
      ..idealWeight = userStore.idealWeight.validate()
      ..weightUnit = userStore.weightUnit.validate();

    Map<String, dynamic> req = {
      'first_name': userStore.fName.validate(),
      'last_name': userStore.lName.validate(),
      'username': userStore.email.validate(),
      'email': userStore.email.validate(),
      'password': userStore.password.validate(),
      'user_type': LoginUser,
      'status': statusActive,
      'phone_number': userStore.phoneNo.validate(),
      'gender': userStore.gender.validate(),
      'user_profile': profile,
      'player_id': getStringAsync(PLAYER_ID).validate(),
      if (getBoolAsync(IS_OTP) == true) 'login_type': LoginTypeOTP,
    };

    appStore.setLoading(true);
    try {
      final value = await registerApi(req);
      userStore.setLogin(true);
      userStore.setToken(value.data!.apiToken.validate());
      await getUSerDetail(context, value.data!.id);
      DashboardScreen().launch(context, isNewTask: true);
    } catch (e) {
      toast(e.toString());
    } finally {
      appStore.setLoading(false);
    }
  }

  Widget _buildIntroScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz, size: 80, color: Theme.of(context).primaryColor),
            SizedBox(height: 32),
            Text(
              'Bilan personnalisé',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Répondez à quelques questions simples.\nCela prendra environ 2 minutes.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => setState(() => _showIntro = false),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Commencer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(bool allAnswered, int totalPages, List<QuestionModel> pageQuestions) {
    final isLastPage = _currentPage == totalPages - 1;

    final nextButton = ElevatedButton(
      onPressed: allAnswered
          ? () {
        if (!isLastPage) {
          setState(() => _currentPage++);
        } else {
          _submitAll();
        }
      }
          : null,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(isLastPage ? 'Voir résultats' : 'Suivant'),
    );

    final prevButton = OutlinedButton(
      onPressed: () => setState(() => _currentPage--),
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
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

  @override
  Widget build(BuildContext context) {
    if (_loading) return Loader().center();
    if (_showIntro) return _buildIntroScreen();
    if (_results != null) return _buildResults();

    int questionsPerPage = 5;
    int totalPages = (_questions.length / questionsPerPage).ceil();
    int start = _currentPage * questionsPerPage;
    int end = (_currentPage + 1) * questionsPerPage;
    final pageQuestions = _questions.sublist(start, end > _questions.length ? _questions.length : end);

    return Column(
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
    );
  }

  Widget _buildResults() {
    final labels = _results!.map((c) => c.category).toList();
    final data = _results!.map((c) => c.averageScore.floorToDouble()).toList();

    return ListView(
      padding: EdgeInsets.all(20),
      children: [
        Text(
          '🎯 Résultats personnalisés',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 24),

        // Résultats sous forme de cards avec barres horizontales
        Column(
          children: List.generate(_results!.length, (index) {
            final c = _results![index];
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
                      _removeHtmlTags(positive ? c.positiveResponse : c.negativeResponse),
                      style: TextStyle(fontSize: 15, color: Colors.black.withOpacity(0.8)),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),

        SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _saveData,
          icon: Icon(Icons.arrow_forward),
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          label: Text("Terminer l'inscription", style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}