import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../extensions/extension_util/context_extensions.dart';
import '../extensions/extension_util/widget_extensions.dart';
import '../extensions/text_styles.dart';
import '../extensions/app_button.dart';
import '../utils/app_colors.dart';
import '../models/competition_feedback_model.dart';
import '../network/rest_api.dart';
import '../main.dart';

class CompetitionFeedbackScreen extends StatefulWidget {
  @override
  _CompetitionFeedbackScreenState createState() => _CompetitionFeedbackScreenState();
}

class _CompetitionFeedbackScreenState extends State<CompetitionFeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Données du formulaire
  DateTime? _competitionDate;
  String? _competitionName;
  bool _isSubmitting = false;

  // Questions 1-2 (réponses 1 ou 2)
  int? _situationResponse; // 1 = Défi, 2 = Menace
  int? _victoryResponse; // 1 = Recherche victoire, 2 = Évitement défaite

  // Questions avec notes /10
  double _difficultyLevel = 5.0;
  double _motivation = 5.0;
  double _focus = 5.0;
  double _negativeFocus = 5.0;
  double _mentalPresence = 5.0;
  double _physicalSensations = 5.0;
  double _emotionalStability = 5.0;
  double _stressTension = 5.0;
  double _decisionMaking = 5.0;
  double _competitionEntry = 5.0;
  double _maximumEffort = 5.0;
  double _automaticity = 5.0;
  double _idealSelfRating = 5.0;

  // Questions texte
  final _clearObjectiveController = TextEditingController();
  final _performanceCommentController = TextEditingController();

  @override
  void dispose() {
    _clearObjectiveController.dispose();
    _performanceCommentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  "Questionnaire Retour de Compétition",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            "Évaluez votre performance en compétition",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildCompetitionInfo() {
    return Card(
      margin: EdgeInsets.all(16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Informations de la compétition",
              style: boldTextStyle(size: 16),
            ),
            SizedBox(height: 16),

            // Nom de la compétition
            TextFormField(
              decoration: InputDecoration(
                labelText: "Nom de la compétition",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Icon(Icons.emoji_events),
              ),
              onSaved: (value) => _competitionName = value,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez saisir le nom de la compétition';
                }
                return null;
              },
            ),

            SizedBox(height: 16),

            // Date de la compétition
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now().subtract(Duration(days: 365)),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _competitionDate = date);
                }
              },
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.grey[600]),
                    SizedBox(width: 12),
                    Text(
                      _competitionDate != null
                          ? DateFormat('dd/MM/yyyy').format(_competitionDate!)
                          : "Sélectionner la date de compétition",
                      style: TextStyle(
                        color: _competitionDate != null ? Colors.black : Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBinaryQuestion(String title, String option1, String option2, int? currentValue, Function(int) onChanged) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: boldTextStyle(size: 14)),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<int>(
                    title: Text(option1, style: TextStyle(fontSize: 13)),
                    value: 1,
                    groupValue: currentValue,
                    onChanged: (value) => onChanged(value!),
                    dense: true,
                  ),
                ),
                Expanded(
                  child: RadioListTile<int>(
                    title: Text(option2, style: TextStyle(fontSize: 13)),
                    value: 2,
                    groupValue: currentValue,
                    onChanged: (value) => onChanged(value!),
                    dense: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderQuestion(String title, double value, Function(double) onChanged, {String? subtitle}) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: boldTextStyle(size: 14)),
            if (subtitle != null) ...[
              SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
            SizedBox(height: 8),
            Row(
              children: [
                Text("0", style: TextStyle(color: Colors.grey)),
                Expanded(
                  child: Slider(
                    value: value,
                    min: 0,
                    max: 10,
                    divisions: 10,
                    label: value.round().toString(),
                    activeColor: primaryColor,
                    onChanged: onChanged,
                  ),
                ),
                Text("10", style: TextStyle(color: Colors.grey)),
              ],
            ),
            Center(
              child: Text(
                "${value.round()}/10",
                style: boldTextStyle(size: 16, color: primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextQuestion(String title, TextEditingController controller, {bool required = false, int maxLines = 1}) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: boldTextStyle(size: 14)),
            SizedBox(height: 12),
            TextFormField(
              controller: controller,
              maxLines: maxLines,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: maxLines > 1 ? "Décrivez votre ressenti..." : "Votre réponse...",
              ),
              validator: required ? (value) {
                if (value == null || value.isEmpty) {
                  return 'Ce champ est obligatoire';
                }
                return null;
              } : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_isSubmitting) return; // Empêcher les soumissions multiples

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_competitionDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Veuillez sélectionner la date de compétition"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_situationResponse == null || _victoryResponse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Veuillez répondre à toutes les questions obligatoires"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    _formKey.currentState!.save();

    try {
      // Créer l'objet de requête avec le modèle
      final request = CompetitionFeedbackRequest(
        competitionName: _competitionName!,
        competitionDate: _competitionDate!,
        situationResponse: _situationResponse!,
        victoryResponse: _victoryResponse!,
        difficultyLevel: _difficultyLevel,
        motivation: _motivation,
        focus: _focus,
        negativeFocus: _negativeFocus,
        mentalPresence: _mentalPresence,
        clearObjective: _clearObjectiveController.text,
        physicalSensations: _physicalSensations,
        emotionalStability: _emotionalStability,
        stressTension: _stressTension,
        decisionMaking: _decisionMaking,
        competitionEntry: _competitionEntry,
        maximumEffort: _maximumEffort,
        automaticity: _automaticity,
        idealSelfRating: _idealSelfRating,
        performanceComment: _performanceCommentController.text.isNotEmpty
            ? _performanceCommentController.text
            : null,
      );

      print("Données du questionnaire structurées: ${request.toJson()}");

      // Vérifier que l'utilisateur est connecté
      if (!userStore.isLoggedIn) {
        throw Exception("Vous devez être connecté pour enregistrer un questionnaire");
      }

      // Envoyer à l'API Laravel
      final response = await submitCompetitionFeedbackApi(request);

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.green,
          ),
        );

        // Retourner à l'accueil (supprimer toutes les routes jusqu'à l'accueil)
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        throw Exception(response.message);
      }

    } catch (e) {
      print("Erreur lors de l'enregistrement: $e");

      String errorMessage = "Erreur lors de l'enregistrement";

      // Personnaliser le message d'erreur selon le type d'erreur
      if (e.toString().contains("Connection")) {
        errorMessage = "Erreur de connexion. Vérifiez votre connexion internet.";
      } else if (e.toString().contains("timeout")) {
        errorMessage = "Délai d'attente dépassé. Veuillez réessayer.";
      } else if (e.toString().contains("401")) {
        errorMessage = "Session expirée. Veuillez vous reconnecter.";
      } else if (e.toString().contains("403")) {
        errorMessage = "Accès refusé. Vérifiez vos permissions.";
      } else if (e.toString().contains("422")) {
        errorMessage = "Données invalides. Vérifiez vos réponses.";
      } else if (e.toString().contains("500")) {
        errorMessage = "Erreur serveur. Veuillez réessayer plus tard.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    _buildCompetitionInfo(),

                    // Questions binaires
                    _buildBinaryQuestion(
                      "Situation de Défi ou Menace ?",
                      "Défi (1)",
                      "Menace (2)",
                      _situationResponse,
                      (value) => setState(() => _situationResponse = value),
                    ),

                    _buildBinaryQuestion(
                      "Recherche de victoire vs évitement de défaite",
                      "Recherche de victoire (1)",
                      "Évitement de défaite (2)",
                      _victoryResponse,
                      (value) => setState(() => _victoryResponse = value),
                    ),

                    // Questions avec sliders
                    _buildSliderQuestion(
                      "Niveau de difficulté",
                      _difficultyLevel,
                      (value) => setState(() => _difficultyLevel = value),
                    ),

                    _buildSliderQuestion(
                      "Motivation à y aller",
                      _motivation,
                      (value) => setState(() => _motivation = value),
                    ),

                    _buildSliderQuestion(
                      "Focus",
                      _focus,
                      (value) => setState(() => _focus = value),
                      subtitle: "À quel point j'étais concentré sur ce qui pouvait me faire gagner",
                    ),

                    _buildSliderQuestion(
                      "Focus négatif",
                      _negativeFocus,
                      (value) => setState(() => _negativeFocus = value),
                      subtitle: "À quel point j'étais focus sur ce qui n'est pas utile (coach, temps, public, etc)",
                    ),

                    _buildSliderQuestion(
                      "Présence mentale",
                      _mentalPresence,
                      (value) => setState(() => _mentalPresence = value),
                      subtitle: "À quel point j'étais en pleine conscience et dans l'instant présent",
                    ),

                    _buildTextQuestion(
                      "Objectif clair",
                      _clearObjectiveController,
                      required: true,
                    ),

                    _buildSliderQuestion(
                      "Sensations physiques",
                      _physicalSensations,
                      (value) => setState(() => _physicalSensations = value),
                      subtitle: "À quel point je me sentais bien physiquement",
                    ),

                    _buildSliderQuestion(
                      "Stabilité émotionnelle",
                      _emotionalStability,
                      (value) => setState(() => _emotionalStability = value),
                    ),

                    _buildSliderQuestion(
                      "Stress-Tension",
                      _stressTension,
                      (value) => setState(() => _stressTension = value),
                    ),

                    _buildSliderQuestion(
                      "Pertinence des décisions prises",
                      _decisionMaking,
                      (value) => setState(() => _decisionMaking = value),
                      subtitle: "0 = que des mauvaises décisions, 10 = que des bonnes",
                    ),

                    _buildSliderQuestion(
                      "Entrée rapide dans la compétition",
                      _competitionEntry,
                      (value) => setState(() => _competitionEntry = value),
                      subtitle: "À quel point je suis entré vite dans ma compétition",
                    ),

                    _buildSliderQuestion(
                      "Sensation d'avoir donné mon maximum",
                      _maximumEffort,
                      (value) => setState(() => _maximumEffort = value),
                    ),

                    _buildSliderQuestion(
                      "Automaticité technique et tactique",
                      _automaticity,
                      (value) => setState(() => _automaticity = value),
                      subtitle: "Technique et tactique qui sort naturellement ou besoin de réfléchir",
                    ),

                    _buildSliderQuestion(
                      "Note par rapport à mon moi idéal",
                      _idealSelfRating,
                      (value) => setState(() => _idealSelfRating = value),
                    ),

                    _buildTextQuestion(
                      "Commentaire sur ma performance (Facultatif)",
                      _performanceCommentController,
                      maxLines: 4,
                    ),

                    // Bouton de soumission
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.all(16),
                      child: AppButton(
                        text: _isSubmitting
                            ? "Enregistrement en cours..."
                            : "Enregistrer le questionnaire",
                        onTap: _isSubmitting ? null : _submitForm,
                        color: _isSubmitting ? Colors.grey : primaryColor,
                        child: _isSubmitting
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    "Enregistrement en cours...",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    ),

                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}