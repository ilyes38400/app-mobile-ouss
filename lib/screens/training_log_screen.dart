import 'package:flutter/material.dart';
import '../extensions/extension_util/context_extensions.dart';
import '../extensions/extension_util/widget_extensions.dart';
import '../extensions/text_styles.dart';
import '../extensions/app_button.dart';
import '../utils/app_colors.dart';
import '../models/training_log_model.dart';
import '../network/rest_api.dart';
import '../main.dart';

class TrainingLogScreen extends StatefulWidget {
  @override
  _TrainingLogScreenState createState() => _TrainingLogScreenState();
}

class _TrainingLogScreenState extends State<TrainingLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Données du formulaire
  final _disciplineController = TextEditingController();
  String? _selectedDominance;
  String? _selectedDuration;
  bool _isSubmitting = false;

  // Scores avec sliders
  double _intensity = 5.0;
  double _ifp = 5.0;
  double _engagement = 5.0;
  double _focus = 5.0;
  double _stress = 5.0;

  // Commentaire et productivité
  final _commentController = TextEditingController();
  bool _productive = true;

  @override
  void dispose() {
    _disciplineController.dispose();
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF388E3C), Color(0xFF2E7D32)],
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
                  "Carnet d'Entraînement",
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
            "Enregistrez votre séance d'entraînement",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo() {
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
              "Informations de base",
              style: boldTextStyle(size: 16),
            ),
            SizedBox(height: 16),

            // Discipline (champ libre)
            TextFormField(
              controller: _disciplineController,
              decoration: InputDecoration(
                labelText: "Discipline",
                hintText: "Ex: Football, Tennis, Basketball...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Icon(Icons.sports),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez saisir la discipline';
                }
                return null;
              },
            ),

            SizedBox(height: 16),

            // Dominante (liste de choix)
            DropdownButtonFormField<String>(
              value: _selectedDominance,
              decoration: InputDecoration(
                labelText: "Dominante",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Icon(Icons.category),
              ),
              items: TrainingLogOptions.dominances.map((dominance) {
                return DropdownMenuItem(
                  value: dominance,
                  child: Text(TrainingLogOptions.getDominanceLabel(dominance)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedDominance = value);
              },
              validator: (value) {
                if (value == null) {
                  return 'Veuillez sélectionner une dominante';
                }
                return null;
              },
            ),

            SizedBox(height: 16),

            // Temps (liste de choix)
            DropdownButtonFormField<String>(
              value: _selectedDuration,
              decoration: InputDecoration(
                labelText: "Durée",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Icon(Icons.timer),
              ),
              items: TrainingLogOptions.durations.map((duration) {
                return DropdownMenuItem(
                  value: duration,
                  child: Text(TrainingLogOptions.getDurationLabel(duration)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedDuration = value);
              },
              validator: (value) {
                if (value == null) {
                  return 'Veuillez sélectionner une durée';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderCard(String title, double value, Function(double) onChanged, {String? subtitle}) {
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

  Widget _buildAdditionalInfo() {
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
              "Informations complémentaires",
              style: boldTextStyle(size: 16),
            ),
            SizedBox(height: 16),

            // Commentaire
            TextFormField(
              controller: _commentController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: "Commentaire (optionnel)",
                hintText: "Décrivez votre séance, vos sensations...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                alignLabelWithHint: true,
              ),
            ),

            SizedBox(height: 16),

            // Productif (oui/non)
            Text("Séance productive ?", style: boldTextStyle(size: 14)),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: Text("Oui", style: TextStyle(fontSize: 14)),
                    value: true,
                    groupValue: _productive,
                    onChanged: (value) => setState(() => _productive = value!),
                    dense: true,
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: Text("Non", style: TextStyle(fontSize: 14)),
                    value: false,
                    groupValue: _productive,
                    onChanged: (value) => setState(() => _productive = value!),
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

  Future<void> _submitForm() async {
    if (_isSubmitting) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final request = TrainingLogRequest(
        discipline: _disciplineController.text,
        dominance: _selectedDominance!,
        duration: _selectedDuration!,
        intensity: _intensity,
        ifp: _ifp,
        engagement: _engagement,
        focus: _focus,
        stress: _stress,
        comment: _commentController.text.isNotEmpty ? _commentController.text : null,
        productive: _productive,
      );

      print("Données du carnet d'entraînement: ${request.toJson()}");

      // Vérifier que l'utilisateur est connecté
      if (!userStore.isLoggedIn) {
        throw Exception("Vous devez être connecté pour enregistrer un carnet d'entraînement");
      }

      // Envoyer à l'API Laravel
      final response = await submitTrainingLogApi(request);

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.green,
          ),
        );

        // Retourner à l'accueil
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        throw Exception(response.message);
      }

    } catch (e) {
      print("Erreur lors de l'enregistrement: $e");

      String errorMessage = "Erreur lors de l'enregistrement";

      if (e.toString().contains("Connection")) {
        errorMessage = "Erreur de connexion. Vérifiez votre connexion internet.";
      } else if (e.toString().contains("timeout")) {
        errorMessage = "Délai d'attente dépassé. Veuillez réessayer.";
      } else if (e.toString().contains("401")) {
        errorMessage = "Session expirée. Veuillez vous reconnecter.";
      } else if (e.toString().contains("403")) {
        errorMessage = "Accès refusé. Vérifiez vos permissions.";
      } else if (e.toString().contains("422")) {
        errorMessage = "Données invalides. Vérifiez vos informations.";
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
                    _buildBasicInfo(),

                    // Sliders pour les scores
                    _buildSliderCard(
                      "Intensité",
                      _intensity,
                      (value) => setState(() => _intensity = value),
                      subtitle: "Niveau d'intensité de votre entraînement",
                    ),

                    _buildSliderCard(
                      "IFP (Indice de Fatigue Physique)",
                      _ifp,
                      (value) => setState(() => _ifp = value),
                      subtitle: "Votre niveau de fatigue physique après la séance",
                    ),

                    _buildSliderCard(
                      "Engagement",
                      _engagement,
                      (value) => setState(() => _engagement = value),
                      subtitle: "Votre niveau d'engagement pendant la séance",
                    ),

                    _buildSliderCard(
                      "Focus",
                      _focus,
                      (value) => setState(() => _focus = value),
                      subtitle: "Votre niveau de concentration",
                    ),

                    _buildSliderCard(
                      "Stress",
                      _stress,
                      (value) => setState(() => _stress = value),
                      subtitle: "Votre niveau de stress pendant la séance",
                    ),

                    _buildAdditionalInfo(),

                    // Bouton de soumission
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.all(16),
                      child: AppButton(
                        text: _isSubmitting
                            ? "Enregistrement en cours..."
                            : "Enregistrer la séance",
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