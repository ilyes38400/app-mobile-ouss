import 'package:flutter/material.dart';
import '../main.dart';
import '../network/rest_api.dart';

Future<void> showAddWeightDialog(
    BuildContext context, VoidCallback onSaved) async {
  final ctrl = TextEditingController();

  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Ajouter une pesée"),
      content: TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
        decoration: const InputDecoration(hintText: "Ex : 73.4"),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler")),
        ElevatedButton(
          onPressed: () async {
            final w = double.tryParse(ctrl.text.replaceAll(',', '.'));
            if (w == null) return;

            final confirm = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text("Confirmer le poids"),
                content: Text("Confirmez-vous que votre poids est bien de ${w.toStringAsFixed(1)} kg ?"),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Modifier")),
                  ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Confirmer")),
                ],
              ),
            );

            if (confirm != true) return;

            await addUserWeightApi(w); // ← Appel API

            await userStore.setWeight(w.toString());

            Navigator.pop(context);
            onSaved();
          },
          child: const Text("Enregistrer"),
        ),
      ],
    ),
  );
}
