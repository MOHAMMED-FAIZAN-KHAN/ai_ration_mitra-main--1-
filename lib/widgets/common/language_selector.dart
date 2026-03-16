import 'package:flutter/material.dart';

class LanguageSelector extends StatelessWidget {
  final List<String> languages;
  final String selectedLanguage;
  final Function(String) onChanged;
  const LanguageSelector({super.key, required this.languages, required this.selectedLanguage, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Select Language / भाषा सुनें', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: languages.map((lang) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(lang), selected: selectedLanguage == lang, onSelected: (selected) => onChanged(lang)))).toList()),
      ),
    ]);
  }
}