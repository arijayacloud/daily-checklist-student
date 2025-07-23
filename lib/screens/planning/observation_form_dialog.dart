import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/laravel_api/models/observation_model.dart';
import '/laravel_api/models/child_model.dart';
import '/lib/theme/app_theme.dart';
import 'package:flutter/services.dart';

class ObservationFormDialog extends StatefulWidget {
  final List<ChildModel> children;
  final ObservationModel? initialObservation;
  final DateTime? initialDate;
  final Function({
    required String childId,
    required DateTime observationDate,
    required String? observationResult,
    required Map<String, bool> conclusions,
  }) onSubmit;

  const ObservationFormDialog({
    Key? key,
    required this.children,
    required this.onSubmit,
    this.initialObservation,
    this.initialDate,
  }) : super(key: key);

  @override
  State<ObservationFormDialog> createState() => _ObservationFormDialogState();
}

class _ObservationFormDialogState extends State<ObservationFormDialog> {
  late String? selectedChildId;
  late DateTime selectedDate;
  late TextEditingController observationResultController;
  late Map<String, bool> conclusions;

  @override
  void initState() {
    super.initState();
    selectedChildId = widget.initialObservation?.childId ?? widget.children.first.id;
    selectedDate = widget.initialObservation?.observationDate ?? widget.initialDate ?? DateTime.now();
    observationResultController = TextEditingController(text: widget.initialObservation?.observationResult ?? '');
    conclusions = {
      'presentasi_ulang': widget.initialObservation?.presentasiUlang ?? false,
      'extension': widget.initialObservation?.extension ?? false,
      'bahasa': widget.initialObservation?.bahasa ?? false,
      'presentasi_langsung': widget.initialObservation?.presentasiLangsung ?? false,
    };
  }

  @override
  void dispose() {
    observationResultController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialObservation != null;
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit ? 'Edit Observasi' : 'Tambah Observasi',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          value: selectedChildId,
                          decoration: const InputDecoration(
                            labelText: 'Pilih Anak',
                            border: OutlineInputBorder(),
                          ),
                          items: widget.children.map((child) {
                            return DropdownMenuItem(
                              value: child.id,
                              child: Text(child.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedChildId = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() {
                                selectedDate = date;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Tanggal Observasi',
                              border: OutlineInputBorder(),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(selectedDate),
                                ),
                                const Icon(Icons.calendar_today, size: 18, color: AppTheme.primary),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: observationResultController,
                          decoration: const InputDecoration(
                            labelText: 'Hasil Observasi (Opsional)',
                            border: OutlineInputBorder(),
                            hintText: 'Catatan hasil observasi...',
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Kesimpulan',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._buildConclusionCheckboxes(),
                        const SizedBox(height: 80), // For sticky button space
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  width: double.infinity,
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (selectedChildId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Pilih anak terlebih dahulu'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            widget.onSubmit(
                              childId: selectedChildId!,
                              observationDate: selectedDate,
                              observationResult: observationResultController.text.isNotEmpty
                                  ? observationResultController.text
                                  : null,
                              conclusions: conclusions,
                            );
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(isEdit ? 'Simpan Perubahan' : 'Simpan'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildConclusionCheckboxes() {
    return [
      _buildCheckbox('Presentasi Ulang', 'presentasi_ulang'),
      _buildCheckbox('Extension', 'extension'),
      _buildCheckbox('Bahasa', 'bahasa'),
      _buildCheckbox('Presentasi Lanjutan', 'presentasi_langsung'),
    ];
  }

  Widget _buildCheckbox(String label, String key) {
    return CheckboxListTile(
      title: Text(label),
      value: conclusions[key]!,
      onChanged: (value) {
        setState(() {
          conclusions[key] = value ?? false;
        });
      },
      contentPadding: EdgeInsets.zero,
    );
  }
}
