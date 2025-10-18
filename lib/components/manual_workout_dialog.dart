import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../main.dart';
import '../network/rest_api.dart';
import '../models/workout_type_response.dart';
import '../extensions/text_styles.dart';
import '../utils/app_colors.dart';

class ManualWorkoutDialog extends StatefulWidget {
  final DateTime selectedDate;

  const ManualWorkoutDialog({
    Key? key,
    required this.selectedDate,
  }) : super(key: key);

  @override
  _ManualWorkoutDialogState createState() => _ManualWorkoutDialogState();
}

class _ManualWorkoutDialogState extends State<ManualWorkoutDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  
  List<WorkoutTypeModel> _workoutTypes = [];
  WorkoutTypeModel? _selectedWorkoutType;
  String _selectedIntensity = 'modere';
  int _durationMinutes = 30;
  bool _isLoading = false;
  bool _isLoadingTypes = true;

  final List<String> _intensityOptions = ['faible', 'modere', 'intense', 'tres_intense'];
  final List<int> _durationOptions = [15, 30, 45, 60, 90, 120];

  @override
  void initState() {
    super.initState();
    _loadWorkoutTypes();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkoutTypes() async {
    try {
      final response = await getWorkoutTypeListApi();
      setState(() {
        _workoutTypes = response.data ?? [];
        _isLoadingTypes = false;
        if (_workoutTypes.isNotEmpty) {
          _selectedWorkoutType = _workoutTypes.first;
        }
      });
    } catch (e) {
      setState(() => _isLoadingTypes = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des types d\'entraînement'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveManualWorkout() async {
    if (!_formKey.currentState!.validate() || _selectedWorkoutType == null) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await storeManualWorkoutLogApi(
        date: widget.selectedDate,
        workoutTypeId: _selectedWorkoutType!.id!,
        intensityLevel: _selectedIntensity,
        durationMinutes: _durationMinutes,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      // Notifier que les logs doivent être rafraîchis
      userStore.shouldReloadWorkoutLogs = true;

      Navigator.of(context).pop(true);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Entraînement ajouté avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'ajout de l\'entraînement'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre
            Row(
              children: [
                Icon(Icons.fitness_center, color: primaryColor),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ajouter un entraînement',
                    style: boldTextStyle(size: 18),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Date: ${DateFormat('d MMMM yyyy', 'fr_FR').format(widget.selectedDate)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 24),

            if (_isLoadingTypes)
              Center(child: CircularProgressIndicator())
            else
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type d'entraînement
                    Text('Type d\'entraînement *', style: boldTextStyle(size: 14)),
                    SizedBox(height: 8),
                    DropdownButtonFormField<WorkoutTypeModel>(
                      value: _selectedWorkoutType,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _workoutTypes.map((type) {
                        return DropdownMenuItem<WorkoutTypeModel>(
                          value: type,
                          child: Text(type.title ?? ''),
                        );
                      }).toList(),
                      onChanged: (WorkoutTypeModel? value) {
                        setState(() => _selectedWorkoutType = value);
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Veuillez sélectionner un type d\'entraînement';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Intensité
                    Text('Niveau d\'intensité *', style: boldTextStyle(size: 14)),
                    SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedIntensity,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _intensityOptions.map((intensity) {
                        return DropdownMenuItem<String>(
                          value: intensity,
                          child: Text(intensity.getDisplayLabel()),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        if (value != null) {
                          setState(() => _selectedIntensity = value);
                        }
                      },
                    ),
                    SizedBox(height: 16),

                    // Durée
                    Text('Durée (minutes) *', style: boldTextStyle(size: 14)),
                    SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _durationMinutes,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _durationOptions.map((duration) {
                        return DropdownMenuItem<int>(
                          value: duration,
                          child: Text('$duration min'),
                        );
                      }).toList(),
                      onChanged: (int? value) {
                        if (value != null) {
                          setState(() => _durationMinutes = value);
                        }
                      },
                    ),
                    SizedBox(height: 16),

                    // Notes
                    Text('Notes (optionnel)', style: boldTextStyle(size: 14)),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: EdgeInsets.all(12),
                        hintText: 'Ajoutez des notes sur votre séance...',
                      ),
                    ),
                    SizedBox(height: 24),

                    // Boutons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                            child: Text(
                              'Annuler',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveManualWorkout,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    'Ajouter',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

extension IntensityLabels on String {
  String getDisplayLabel() {
    switch (this) {
      case 'faible':
        return 'Faible';
      case 'modere':
        return 'Modérée';
      case 'intense':
        return 'Intense';
      case 'tres_intense':
        return 'Très intense';
      default:
        return this;
    }
  }
}