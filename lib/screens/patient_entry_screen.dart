import 'package:flutter/material.dart';
import '../models/models.dart';
import 'hospital_results_screen.dart';

class PatientEntryScreen extends StatefulWidget {
  const PatientEntryScreen({super.key});

  @override
  State<PatientEntryScreen> createState() => _PatientEntryScreenState();
}

class _PatientEntryScreenState extends State<PatientEntryScreen> {
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  String? _selectedCondition;
  String _severity = 'Critical';
  final _locationCtrl = TextEditingController(text: 'Pune City Centre');

  final List<String> _severities = ['Critical', 'Moderate', 'Mild'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  void _findHospitals() {
    if (_nameCtrl.text.trim().isEmpty ||
        _ageCtrl.text.trim().isEmpty ||
        _selectedCondition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('FILL ALL REQUIRED FIELDS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
          backgroundColor: const Color(0xFFFF3B30),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final patient = PatientCase(
      name: _nameCtrl.text.trim(),
      age: int.tryParse(_ageCtrl.text.trim()) ?? 0,
      condition: _selectedCondition!,
      severity: _severity,
      citizenLocation: _locationCtrl.text.trim(),
    );

    final req = DiseaseMapper.getRequirements(_selectedCondition!);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            HospitalResultsScreen(patient: patient, requirement: req),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryRed = Color(0xFFFF3B30);
    const bgColor = Color(0xFF0B0E14);
    const surfaceColor = Color(0xFF161B26);
    const inputColor = Color(0xFF1C2333);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: const Text('PATIENT INTAKE',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 14)),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: const Color(0xFF007AFF).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Color(0xFF007AFF), size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Enter patient details to find the best matched hospital based on condition & resource availability.',
                      style: TextStyle(
                          color: const Color(0xFF007AFF).withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            _sectionTitle('PATIENT INFORMATION'),
            const SizedBox(height: 16),
            _card(
              child: Column(
                children: [
                  _textField(
                    controller: _nameCtrl,
                    label: 'PATIENT NAME *',
                    hint: 'Full name',
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 18),
                  _textField(
                    controller: _ageCtrl,
                    label: 'AGE *',
                    hint: 'e.g. 45',
                    icon: Icons.cake_outlined,
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            _sectionTitle('CONDITION & SEVERITY'),
            const SizedBox(height: 16),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SELECT CONDITION *',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white24,
                          letterSpacing: 1)),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCondition,
                    hint: Text('Choose condition', style: TextStyle(color: Colors.white.withValues(alpha: 0.2))),
                    dropdownColor: inputColor,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: _inputDeco('', Icons.medical_information_outlined),
                    items: DiseaseMapper.allConditions
                        .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c,
                                style: const TextStyle(fontSize: 14))))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedCondition = v),
                    isExpanded: true,
                  ),

                  // Show resource needs
                  if (_selectedCondition != null) ...[
                    const SizedBox(height: 20),
                    _resourceChips(
                        DiseaseMapper.getRequirements(_selectedCondition!)),
                  ],

                  const SizedBox(height: 24),
                  const Text('SEVERITY LEVEL *',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white24,
                          letterSpacing: 1)),
                  const SizedBox(height: 10),
                  Row(
                    children: _severities.map((s) {
                      final selected = s == _severity;
                      final color = s == 'Critical'
                          ? primaryRed
                          : s == 'Moderate'
                              ? const Color(0xFFFFCC00)
                              : const Color(0xFF32D74B);
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _severity = s),
                          child: Container(
                            margin:
                                const EdgeInsets.symmetric(horizontal: 4),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: selected
                                  ? color
                                  : color.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: selected ? color : color.withValues(alpha: 0.3),
                                  width: selected ? 2 : 1),
                            ),
                            child: Center(
                              child: Text(s.toUpperCase(),
                                  style: TextStyle(
                                      color:
                                          selected ? Colors.white : color,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 11,
                                      letterSpacing: 0.5)),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            _sectionTitle('PICKUP LOCATION'),
            const SizedBox(height: 16),
            _card(
              child: _textField(
                controller: _locationCtrl,
                label: 'CURRENT LOCATION *',
                hint: 'Area / landmark',
                icon: Icons.location_on_outlined,
              ),
            ),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _findHospitals,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_rounded, size: 22),
                    SizedBox(width: 10),
                    Text('FIND BEST HOSPITAL',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: Colors.white38,
          letterSpacing: 2));

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF161B26),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: child,
      );

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Colors.white24,
                letterSpacing: 1)),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: _inputDeco(hint, icon),
          style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.15)),
        prefixIcon: Icon(icon, color: Colors.white24, size: 20),
        filled: true,
        fillColor: const Color(0xFF1C2333),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFFFF3B30), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      );

  Widget _resourceChips(ResourceRequirement req) {
    final chips = <_Chip>[];
    if (req.needsICU) {
      chips.add(_Chip('ICU Bed', const Color(0xFFFF3B30)));
    }
    if (req.needsVentilator) {
      chips.add(_Chip('Ventilator', const Color(0xFFAF52DE)));
    }
    if (req.needsOxygenBed) {
      chips.add(_Chip('Oxygen Bed', const Color(0xFF007AFF)));
    }
    if (req.needsEmergencyOT) {
      chips.add(_Chip('Emergency OT', const Color(0xFFFF9500)));
    }
    chips.add(_Chip(req.specialDept, const Color(0xFF32D74B)));

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips
          .map((c) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: c.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: c.color.withValues(alpha: 0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check_circle_rounded, size: 12, color: c.color),
                  const SizedBox(width: 6),
                  Text(c.label.toUpperCase(),
                      style: TextStyle(
                          color: c.color,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5))
                ]),
              ))
          .toList(),
    );
  }
}

class _Chip {
  final String label;
  final Color color;
  _Chip(this.label, this.color);
}
