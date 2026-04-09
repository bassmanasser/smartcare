import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HospitalProfileScreen extends StatefulWidget {
  const HospitalProfileScreen({super.key});

  @override
  State<HospitalProfileScreen> createState() => _HospitalProfileScreenState();
}

class _HospitalProfileScreenState extends State<HospitalProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _loading = true;
  bool _saving = false;

  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _hospitalData;
  String _institutionId = '';

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _hospitalNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _hospitalNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final userDoc = await _firestore.collection('users').doc(uid).get();
      final userData = userDoc.data() ?? {};
      final institutionId = (userData['institutionId'] ?? '').toString();

      Map<String, dynamic>? hospitalData;
      if (institutionId.isNotEmpty) {
        final hospitalDoc =
            await _firestore.collection('institutions').doc(institutionId).get();
        hospitalData = hospitalDoc.data() ?? {};
      }

      _userData = userData;
      _hospitalData = hospitalData;
      _institutionId = institutionId;

      _hospitalNameController.text = _readValue([
        hospitalData?['name'],
        hospitalData?['hospitalName'],
        userData['institutionName'],
      ]);

      _emailController.text = _readValue([
        hospitalData?['email'],
        userData['email'],
        _auth.currentUser?.email,
      ]);

      _phoneController.text = _readValue([
        hospitalData?['phone'],
        hospitalData?['hospitalPhone'],
        userData['phone'],
      ]);

      _cityController.text = _readValue([
        hospitalData?['city'],
        hospitalData?['hospitalCity'],
      ]);

      _addressController.text = _readValue([
        hospitalData?['address'],
        hospitalData?['hospitalAddress'],
      ]);

      _descriptionController.text = _readValue([
        hospitalData?['description'],
        hospitalData?['about'],
      ]);

      if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load hospital profile: $e')),
      );
    }
  }

  String _readValue(List<dynamic> values) {
    for (final value in values) {
      final text = (value ?? '').toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  Future<int> _countByRole(String role) async {
    if (_institutionId.isEmpty) return 0;

    final snapshot = await _firestore
        .collection('users')
        .where('institutionId', isEqualTo: _institutionId)
        .where('role', isEqualTo: role)
        .get();

    return snapshot.docs.length;
  }

  Future<int> _countPendingStaff() async {
    if (_institutionId.isEmpty) return 0;

    final snapshot = await _firestore
        .collection('staff_requests')
        .where('institutionId', isEqualTo: _institutionId)
        .where('status', isEqualTo: 'pending')
        .get();

    return snapshot.docs.length;
  }

  Future<int> _countPatientsToday() async {
    if (_institutionId.isEmpty) return 0;

    final now = DateTime.now();
    final dayKey =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final snapshot = await _firestore
        .collection('users')
        .where('institutionId', isEqualTo: _institutionId)
        .where('role', isEqualTo: 'patient')
        .where('arrivalDayKey', isEqualTo: dayKey)
        .get();

    return snapshot.docs.length;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_institutionId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hospital ID found for this account')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final updateData = {
        'name': _hospitalNameController.text.trim(),
        'hospitalName': _hospitalNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'hospitalPhone': _phoneController.text.trim(),
        'city': _cityController.text.trim(),
        'hospitalCity': _cityController.text.trim(),
        'address': _addressController.text.trim(),
        'hospitalAddress': _addressController.text.trim(),
        'description': _descriptionController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('institutions')
          .doc(_institutionId)
          .set(updateData, SetOptions(merge: true));

      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        await _firestore.collection('users').doc(uid).set({
          'institutionId': _institutionId,
          'institutionName': _hospitalNameController.text.trim(),
          'hospitalCity': _cityController.text.trim(),
          'phone': _phoneController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (!mounted) return;
      setState(() => _saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hospital profile updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $e')),
      );
    }
  }

  String get _hospitalName =>
      _hospitalNameController.text.trim().isEmpty
          ? 'Hospital'
          : _hospitalNameController.text.trim();

  String get _city =>
      _cityController.text.trim().isEmpty ? 'Unknown city' : _cityController.text.trim();

  String get _adminName =>
      (_userData?['name'] ?? _userData?['fullName'] ?? 'Admin').toString();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hospital Profile'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadProfile,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withOpacity(0.95),
                    colorScheme.primaryContainer.withOpacity(0.90),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.local_hospital_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _hospitalName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _HeaderLine(
                          label: 'Hospital ID',
                          value: _institutionId.isEmpty ? '-' : _institutionId,
                        ),
                        _HeaderLine(label: 'City', value: _city),
                        _HeaderLine(label: 'Admin', value: _adminName),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const _SectionTitle(
              title: 'Hospital Overview',
              subtitle: 'Live summary of institution data',
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<int>>(
              future: Future.wait([
                _countByRole('doctor'),
                _countByRole('nurse'),
                _countPatientsToday(),
                _countPendingStaff(),
              ]),
              builder: (context, snapshot) {
                final values = snapshot.data ?? [0, 0, 0, 0];

                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _StatCard(
                      icon: Icons.badge_outlined,
                      title: 'Doctors',
                      value: values[0].toString(),
                    ),
                    _StatCard(
                      icon: Icons.local_hospital_outlined,
                      title: 'Nurses',
                      value: values[1].toString(),
                    ),
                    _StatCard(
                      icon: Icons.groups_outlined,
                      title: 'Patients Today',
                      value: values[2].toString(),
                    ),
                    _StatCard(
                      icon: Icons.approval_outlined,
                      title: 'Pending Staff',
                      value: values[3].toString(),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            const _SectionTitle(
              title: 'Edit Hospital Information',
              subtitle: 'Keep hospital identity and contact details updated',
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildField(
                        controller: _hospitalNameController,
                        label: 'Hospital Name',
                        icon: Icons.business_rounded,
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Please enter hospital name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _buildField(
                        controller: _emailController,
                        label: 'Hospital Email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),
                      _buildField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 14),
                      _buildField(
                        controller: _cityController,
                        label: 'City',
                        icon: Icons.location_city_outlined,
                      ),
                      const SizedBox(height: 14),
                      _buildField(
                        controller: _addressController,
                        label: 'Address',
                        icon: Icons.location_on_outlined,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 14),
                      _buildField(
                        controller: _descriptionController,
                        label: 'Description',
                        icon: Icons.description_outlined,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _saveProfile,
                          icon: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(_saving ? 'Saving...' : 'Save Changes'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const _SectionTitle(
              title: 'Institution Identity',
              subtitle: 'Read-only summary for quick review',
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _InfoRow(
                      label: 'Hospital Name',
                      value: _hospitalNameController.text.trim().isEmpty
                          ? '-'
                          : _hospitalNameController.text.trim(),
                    ),
                    _InfoRow(
                      label: 'Hospital ID',
                      value: _institutionId.isEmpty ? '-' : _institutionId,
                    ),
                    _InfoRow(
                      label: 'Admin Name',
                      value: _adminName,
                    ),
                    _InfoRow(
                      label: 'Email',
                      value: _emailController.text.trim().isEmpty
                          ? '-'
                          : _emailController.text.trim(),
                    ),
                    _InfoRow(
                      label: 'Phone',
                      value: _phoneController.text.trim().isEmpty
                          ? '-'
                          : _phoneController.text.trim(),
                    ),
                    _InfoRow(
                      label: 'City',
                      value: _cityController.text.trim().isEmpty
                          ? '-'
                          : _cityController.text.trim(),
                    ),
                    _InfoRow(
                      label: 'Address',
                      value: _addressController.text.trim().isEmpty
                          ? '-'
                          : _addressController.text.trim(),
                      isLast: true,
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

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class _HeaderLine extends StatelessWidget {
  final String label;
  final String value;

  const _HeaderLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: Colors.white.withOpacity(0.92),
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
        Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.72);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13.5,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: colorScheme.primary.withOpacity(0.10),
              ),
              child: Icon(icon, color: colorScheme.primary),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withOpacity(0.75),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.72),
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        if (!isLast) ...[
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}