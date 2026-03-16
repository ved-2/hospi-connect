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
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
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
    const red = Color(0xFFE53935);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: red,
        foregroundColor: Colors.white,
        title: const Text('Patient Details',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFF1565C0).withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Color(0xFF1565C0), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Enter patient details to find the best matched hospital based on condition & resource availability.',
                      style: TextStyle(
                          color: Color(0xFF1565C0), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _sectionTitle('Patient Information'),
            const SizedBox(height: 12),
            _card(
              child: Column(
                children: [
                  _textField(
                    controller: _nameCtrl,
                    label: 'Patient Name *',
                    hint: 'Full name',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 14),
                  _textField(
                    controller: _ageCtrl,
                    label: 'Age *',
                    hint: 'e.g. 45',
                    icon: Icons.cake_outlined,
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            _sectionTitle('Condition & Severity'),
            const SizedBox(height: 12),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Condition / Disease *',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF555555))),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCondition,
                    hint: const Text('Choose condition'),
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
                    const SizedBox(height: 16),
                    _resourceChips(
                        DiseaseMapper.getRequirements(_selectedCondition!)),
                  ],

                  const SizedBox(height: 18),
                  const Text('Severity *',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF555555))),
                  const SizedBox(height: 8),
                  Row(
                    children: _severities.map((s) {
                      final selected = s == _severity;
                      final color = s == 'Critical'
                          ? const Color(0xFFE53935)
                          : s == 'Moderate'
                              ? const Color(0xFFFF8F00)
                              : const Color(0xFF2E7D32);
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _severity = s),
                          child: Container(
                            margin:
                                const EdgeInsets.symmetric(horizontal: 3),
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selected
                                  ? color
                                  : color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: color.withOpacity(0.5)),
                            ),
                            child: Center(
                              child: Text(s,
                                  style: TextStyle(
                                      color:
                                          selected ? Colors.white : color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            _sectionTitle('Pickup Location'),
            const SizedBox(height: 12),
            _card(
              child: _textField(
                controller: _locationCtrl,
                label: 'Current Location *',
                hint: 'Area / landmark',
                icon: Icons.location_on_outlined,
              ),
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _findHospitals,
                icon: const Icon(Icons.search_rounded, size: 24),
                label: const Text('FIND BEST HOSPITAL',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A1A2E)));

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
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
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF555555))),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: _inputDeco(hint, icon),
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey, size: 20),
        filled: true,
        fillColor: const Color(0xFFF5F6FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFFE53935), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      );

  Widget _resourceChips(ResourceRequirement req) {
    final chips = <_Chip>[];
    if (req.needsICU)
      chips.add(_Chip('ICU Bed', const Color(0xFFE53935)));
    if (req.needsVentilator)
      chips.add(_Chip('Ventilator', const Color(0xFF6A1B9A)));
    if (req.needsOxygenBed)
      chips.add(_Chip('Oxygen Bed', const Color(0xFF1565C0)));
    if (req.needsEmergencyOT)
      chips.add(_Chip('Emergency OT', const Color(0xFFE65100)));
    chips.add(_Chip(req.specialDept, const Color(0xFF2E7D32)));

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: chips
          .map((c) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: c.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: c.color.withOpacity(0.4)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check_circle, size: 13, color: c.color),
                  const SizedBox(width: 5),
                  Text(c.label,
                      style: TextStyle(
                          color: c.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600))
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
