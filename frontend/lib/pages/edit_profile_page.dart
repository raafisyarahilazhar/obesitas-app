import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_colors.dart';

class EditProfilePage extends StatefulWidget {
  final int userId;

  const EditProfilePage({
    super.key,
    required this.userId,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await ApiService.getProfile(widget.userId);

      if (!mounted) return;

      _nameController.text = data['name']?.toString() ?? '';
      _ageController.text = data['age']?.toString() ?? '';
      _heightController.text = data['height_cm']?.toString() ?? '';
      _weightController.text = data['weight_kg']?.toString() ?? '';

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal memuat profil: ${e.toString()}',
          ),
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final data = {
        'name': _nameController.text.trim(),
        'age': int.parse(_ageController.text.trim()),
        'height_cm': double.parse(_heightController.text.trim()),
        'weight_kg': double.parse(_weightController.text.trim()),
      };

      await ApiService.updateProfile(
        widget.userId,
        data,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil diperbarui'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal memperbarui profil: ${e.toString()}',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon,
        color: AppColors.accent,
      ),
      suffixText: suffix,
      filled: true,
      fillColor: AppColors.card,
      labelStyle: const TextStyle(
        color: AppColors.textSub,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.border,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.accent,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.danger,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.danger,
          width: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPri,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profil',
          style: TextStyle(
            color: AppColors.textPri,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.accent,
              ),
            )
          : SafeArea(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    24,
                    12,
                    24,
                    32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: AppColors.heroBg,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Perbarui Profil Kesehatan',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Data ini digunakan untuk menghitung BMI dan target kalori harian.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      const Text(
                        'DATA PRIBADI',
                        style: TextStyle(
                          color: AppColors.textSub,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.3,
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration(
                          label: 'Nama',
                          icon: Icons.person_outline_rounded,
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Nama wajib diisi';
                          }

                          if (value.trim().length < 2) {
                            return 'Nama minimal 2 karakter';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration(
                          label: 'Usia',
                          icon: Icons.cake_outlined,
                          suffix: 'tahun',
                        ),
                        validator: (value) {
                          final age = int.tryParse(
                            value?.trim() ?? '',
                          );

                          if (age == null) {
                            return 'Usia harus berupa angka';
                          }

                          if (age <= 0 || age > 120) {
                            return 'Usia tidak valid';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 28),

                      const Text(
                        'DATA FISIK',
                        style: TextStyle(
                          color: AppColors.textSub,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.3,
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _heightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration(
                          label: 'Tinggi Badan',
                          icon: Icons.height_rounded,
                          suffix: 'cm',
                        ),
                        validator: (value) {
                          final height = double.tryParse(
                            value?.trim() ?? '',
                          );

                          if (height == null) {
                            return 'Tinggi harus berupa angka';
                          }

                          if (height < 50 || height > 250) {
                            return 'Tinggi tidak valid';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.done,
                        decoration: _inputDecoration(
                          label: 'Berat Badan',
                          icon: Icons.monitor_weight_outlined,
                          suffix: 'kg',
                        ),
                        validator: (value) {
                          final weight = double.tryParse(
                            value?.trim() ?? '',
                          );

                          if (weight == null) {
                            return 'Berat harus berupa angka';
                          }

                          if (weight <= 0 || weight > 500) {
                            return 'Berat tidak valid';
                          }

                          return null;
                        },
                        onFieldSubmitted: (_) => _saveProfile(),
                      ),

                      const SizedBox(height: 28),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.accentLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.accent.withOpacity(0.2),
                          ),
                        ),
                        child: const Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: AppColors.accent,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'BMI dan target kalori akan dihitung ulang secara otomatis setelah profil disimpan.',
                                style: TextStyle(
                                  color: AppColors.textPri,
                                  fontSize: 12,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isSaving
                              ? null
                              : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.black,
                            disabledBackgroundColor:
                                AppColors.accent.withOpacity(0.5),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(16),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.black,
                                  ),
                                )
                              : const Text(
                                  'Simpan Perubahan',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}