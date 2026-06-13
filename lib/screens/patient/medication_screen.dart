import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../utils/constants.dart';
import '../../utils/localization.dart';

class MedicationScreen extends StatefulWidget {
  final String patientId;
  const MedicationScreen({super.key, required this.patientId});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();

  String _statusFilter = 'all';
  String _routeFilter = 'all';
  String _doctorFilter = 'all';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  CollectionReference<Map<String, dynamic>> _medsRef() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(widget.patientId)
        .collection('medications');
  }

  DocumentReference<Map<String, dynamic>> _patientRef() {
    return FirebaseFirestore.instance.collection('users').doc(widget.patientId);
  }

  AppLocalizations get _lang => AppLocalizations.of(context);

  TimeOfDay? _mapToTime(dynamic x) {
    if (x is Map) {
      final h = x['h'];
      final m = x['m'];
      if (h is int && m is int) return TimeOfDay(hour: h, minute: m);
    }
    return null;
  }

  DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  List<TimeOfDay> _readTimes(Map<String, dynamic> d) {
    final rawTimes = d['times'];
    final times = <TimeOfDay>[];
    if (rawTimes is List) {
      for (final raw in rawTimes) {
        final parsed = _mapToTime(raw);
        if (parsed != null) times.add(parsed);
      }
    }

    final legacy = _mapToTime(d['reminderTime']);
    if (times.isEmpty && legacy != null) times.add(legacy);
    return times;
  }

  MedicationRecord _docToMedication(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data();
    final active = d['active'] != false;
    final explicitStatus = (d['status'] ?? '').toString().trim().toLowerCase();
    final status = explicitStatus.isNotEmpty
        ? explicitStatus
        : active
        ? 'active'
        : 'stopped';

    return MedicationRecord(
      id: doc.id,
      patientId: (d['patientId'] ?? widget.patientId).toString(),
      name: (d['name'] ?? '').toString(),
      dosage: (d['dosage'] ?? '').toString(),
      frequency: (d['frequency'] ?? '').toString(),
      route: (d['route'] ?? 'oral').toString(),
      status: status,
      active: active,
      prn: d['prn'] == true,
      reminderEnabled: d['reminderEnabled'] != false,
      times: _readTimes(d),
      lastTakenAt: _toDate(d['lastTakenAt']),
      startDate: _toDate(d['startDate']),
      endDate: _toDate(d['endDate']),
      prescribedBy: (d['prescribedBy'] ?? '').toString(),
      indication: (d['indication'] ?? '').toString(),
      instructions: (d['instructions'] ?? '').toString(),
      notes: (d['notes'] ?? '').toString(),
      warning: (d['warning'] ?? '').toString(),
      storageLocation: (d['storageLocation'] ?? '').toString(),
      pickupLocation: (d['pickupLocation'] ?? '').toString(),
      patientHasMedication: d['patientHasMedication'] == true,
      refillRequestedAt: _toDate(d['refillRequestedAt']),
      history: (d['history'] is List)
          ? List<Map<String, dynamic>>.from(
              (d['history'] as List).whereType<Map>().map(
                (e) => Map<String, dynamic>.from(e),
              ),
            )
          : const [],
    );
  }

  Future<void> _markTaken(MedicationRecord med) async {
    await _medsRef().doc(med.id).update({
      'lastTakenAt': FieldValue.serverTimestamp(),
      'status': 'active',
      'history': FieldValue.arrayUnion([
        {
          'action': 'taken',
          'at': Timestamp.now(),
          'summary': '${med.dosage} marked as taken',
        },
      ]),
    });
  }

  Future<void> _stopMedication(MedicationRecord med) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t('stop_medication')),
        content: TextField(
          controller: reasonCtrl,
          decoration: InputDecoration(
            labelText: _t('stop_reason'),
            border: const OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_t('stop')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await _medsRef().doc(med.id).update({
      'active': false,
      'status': 'stopped',
      'stoppedAt': FieldValue.serverTimestamp(),
      'stopReason': reasonCtrl.text.trim(),
      'history': FieldValue.arrayUnion([
        {
          'action': 'stopped',
          'at': Timestamp.now(),
          'summary': reasonCtrl.text.trim().isEmpty
              ? 'Medication stopped'
              : reasonCtrl.text.trim(),
        },
      ]),
    });
  }

  Future<void> _requestRefill(MedicationRecord med) async {
    await _medsRef().doc(med.id).update({
      'refillRequestedAt': FieldValue.serverTimestamp(),
      'history': FieldValue.arrayUnion([
        {
          'action': 'refill',
          'at': Timestamp.now(),
          'summary': 'Refill requested',
        },
      ]),
    });
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_t('refill_requested'))));
  }

  Future<void> _openMedicationForm([MedicationRecord? med]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => MedicationFormSheet(
        initial: med,
        patientId: widget.patientId,
        medsRef: _medsRef(),
      ),
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(med == null ? 'medication_added' : 'medication_updated'),
          ),
        ),
      );
    }
  }

  String _t(String key) => _lang.translate(key);

  String _dateText(DateTime? date) {
    if (date == null) return _t('not_set');
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  String _timeText(DateTime? date) {
    if (date == null) return _t('not_set');
    final t = TimeOfDay.fromDateTime(date);
    return t.format(context);
  }

  String _medStatus(MedicationRecord med) {
    if (med.status == 'stopped' || !med.active) return 'stopped';
    if (med.status == 'completed') return 'completed';
    if (med.status == 'missed') return 'missed';
    if (_isMissed(med)) return 'missed';
    return 'active';
  }

  bool _isMissed(MedicationRecord med) {
    if (!med.active || med.prn || med.times.isEmpty) return false;
    final now = DateTime.now();
    final lastDose = _lastScheduledDoseToday(med);
    if (lastDose == null || now.difference(lastDose).inMinutes < 60) {
      return false;
    }
    final lastTaken = med.lastTakenAt;
    return lastTaken == null || lastTaken.isBefore(lastDose);
  }

  DateTime? _lastScheduledDoseToday(MedicationRecord med) {
    final now = DateTime.now();
    final doses =
        med.times
            .map(
              (t) => DateTime(now.year, now.month, now.day, t.hour, t.minute),
            )
            .where((d) => !d.isAfter(now))
            .toList()
          ..sort();
    return doses.isEmpty ? null : doses.last;
  }

  DateTime? _nextDose(MedicationRecord med) {
    if (!med.active || med.prn || med.times.isEmpty) return null;
    final now = DateTime.now();
    final today =
        med.times
            .map(
              (t) => DateTime(now.year, now.month, now.day, t.hour, t.minute),
            )
            .where((d) => d.isAfter(now))
            .toList()
          ..sort();
    if (today.isNotEmpty) return today.first;
    final t = med.times.toList()
      ..sort(
        (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute),
      );
    return DateTime(
      now.year,
      now.month,
      now.day + 1,
      t.first.hour,
      t.first.minute,
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'missed':
        return Colors.red.shade700;
      case 'completed':
      case 'taken':
        return Colors.green.shade700;
      case 'stopped':
        return Colors.grey.shade600;
      case 'upcoming':
        return accentYellow;
      default:
        return petrol;
    }
  }

  List<MedicationRecord> _filteredMeds(List<MedicationRecord> meds) {
    return meds.where((med) {
      final status = _medStatus(med);
      final matchesStatus = switch (_statusFilter) {
        'all' => true,
        'prn' => med.prn,
        'upcoming' => _nextDose(med) != null,
        _ => status == _statusFilter,
      };
      final matchesRoute = _routeFilter == 'all' || med.route == _routeFilter;
      final matchesDoctor =
          _doctorFilter == 'all' || med.prescribedBy == _doctorFilter;
      final haystack =
          '${med.name} ${med.dosage} ${med.frequency} ${med.prescribedBy} ${med.route}'
              .toLowerCase();
      return matchesStatus &&
          matchesRoute &&
          matchesDoctor &&
          (_query.isEmpty || haystack.contains(_query));
    }).toList()..sort((a, b) {
      final nextA = _nextDose(a);
      final nextB = _nextDose(b);
      if (nextA != null && nextB != null) return nextA.compareTo(nextB);
      if (nextA != null) return -1;
      if (nextB != null) return 1;
      return a.name.compareTo(b.name);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        title: Text(_t('medication_reminders')),
        backgroundColor: petrolDark,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: _t('current')),
            Tab(text: _t('schedule')),
            Tab(text: _t('history')),
            Tab(text: _t('alerts')),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openMedicationForm(),
        backgroundColor: petrol,
        icon: const Icon(Icons.add),
        label: Text(_t('add_medication')),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _medsRef().snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final meds = snap.data?.docs.map(_docToMedication).toList() ?? [];
          if (meds.isEmpty) {
            return _EmptyMedicationState(onAdd: () => _openMedicationForm());
          }

          final doctors =
              meds
                  .map((m) => m.prescribedBy)
                  .where((d) => d.trim().isNotEmpty)
                  .toSet()
                  .toList()
                ..sort();
          final routes = meds.map((m) => m.route).toSet().toList()..sort();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildCurrentTab(meds, doctors, routes),
              _buildScheduleTab(meds),
              _buildHistoryTab(meds),
              _buildAlertsTab(meds),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCurrentTab(
    List<MedicationRecord> meds,
    List<String> doctors,
    List<String> routes,
  ) {
    final filtered = _filteredMeds(meds);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: _t('search_medications'),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _filterChip('all', _t('all')),
            _filterChip('active', _t('active_medications')),
            _filterChip('stopped', _t('stopped_discontinued')),
            _filterChip('prn', _t('prn_medications')),
            _filterChip('upcoming', _t('upcoming_doses')),
            _filterChip('missed', _t('missed')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DropdownFilter(
                value: _routeFilter,
                label: _t('route'),
                items: ['all', ...routes],
                textFor: (v) => v == 'all' ? _t('all_routes') : _routeLabel(v),
                onChanged: (v) => setState(() => _routeFilter = v ?? 'all'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DropdownFilter(
                value: _doctorFilter,
                label: _t('doctor'),
                items: ['all', ...doctors],
                textFor: (v) => v == 'all' ? _t('all_doctors') : v,
                onChanged: (v) => setState(() => _doctorFilter = v ?? 'all'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 64),
            child: Center(child: Text(_t('no_matching_medications'))),
          )
        else
          ...filtered.map(_buildMedicationCard),
      ],
    );
  }

  Widget _filterChip(String value, String label) {
    return FilterChip(
      label: Text(label),
      selected: _statusFilter == value,
      onSelected: (_) => setState(() => _statusFilter = value),
      selectedColor: petrol.withValues(alpha: 0.16),
      checkmarkColor: petrol,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _buildMedicationCard(MedicationRecord med) {
    final status = _medStatus(med);
    final next = _nextDose(med);
    final color = _statusColor(status);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showDetails(med),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.12),
                    child: Icon(Icons.medication_liquid, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          med.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${med.dosage} • ${med.frequency} • ${_routeLabel(med.route)}',
                        ),
                      ],
                    ),
                  ),
                  _StatusPill(label: _statusLabel(status), color: color),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: Icons.history,
                    label: '${_t('last_dose')}: ${_timeText(med.lastTakenAt)}',
                  ),
                  _InfoChip(
                    icon: Icons.schedule,
                    label:
                        '${_t('next_dose')}: ${next == null ? _t('not_set') : _timeText(next)}',
                  ),
                  if (med.storageLocation.isNotEmpty)
                    _InfoChip(
                      icon: Icons.inventory_2_outlined,
                      label: '${_t('stored_at')}: ${med.storageLocation}',
                    ),
                  if (med.prn)
                    _InfoChip(icon: Icons.bolt_outlined, label: _t('prn')),
                ],
              ),
              const Divider(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ActionButton(
                    icon: Icons.check_circle_outline,
                    label: _t('mark_taken'),
                    onPressed: med.active ? () => _markTaken(med) : null,
                  ),
                  _ActionButton(
                    icon: Icons.edit_outlined,
                    label: _t('edit'),
                    onPressed: () => _openMedicationForm(med),
                  ),
                  _ActionButton(
                    icon: Icons.pause_circle_outline,
                    label: _t('stop'),
                    onPressed: med.active ? () => _stopMedication(med) : null,
                  ),
                  _ActionButton(
                    icon: Icons.local_pharmacy_outlined,
                    label: _t('refill_request'),
                    onPressed: () => _requestRefill(med),
                  ),
                  _ActionButton(
                    icon: Icons.history,
                    label: _t('view_history'),
                    onPressed: () => _tabController.animateTo(2),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleTab(List<MedicationRecord> meds) {
    final items = <DoseScheduleItem>[];
    final now = DateTime.now();
    for (final med in meds.where((m) => m.active && !m.prn)) {
      for (final time in med.times) {
        final doseAt = DateTime(
          now.year,
          now.month,
          now.day,
          time.hour,
          time.minute,
        );
        items.add(DoseScheduleItem(med: med, doseAt: doseAt));
      }
    }
    items.sort((a, b) => a.doseAt.compareTo(b.doseAt));

    if (items.isEmpty) {
      return Center(child: Text(_t('no_scheduled_doses')));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Text(
          _t('today_schedule'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        ...items.map((item) {
          final isPast = item.doseAt.isBefore(now);
          final isSoon = !isPast && item.doseAt.difference(now).inMinutes <= 90;
          final color = isPast
              ? Colors.green.shade700
              : isSoon
              ? accentYellow
              : petrol;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              leading: Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _timeText(item.doseAt),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
              ),
              title: Text(item.med.name),
              subtitle: Text(
                '${item.med.dosage} • ${_routeLabel(item.med.route)}',
              ),
              trailing: _StatusPill(
                label: isPast
                    ? _t('taken_or_due')
                    : isSoon
                    ? _t('soon')
                    : _t('upcoming'),
                color: color,
              ),
              onTap: () => _showDetails(item.med),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildHistoryTab(List<MedicationRecord> meds) {
    final entries = <MedicationHistoryEntry>[];
    for (final med in meds) {
      if (med.lastTakenAt != null) {
        entries.add(
          MedicationHistoryEntry(
            medName: med.name,
            at: med.lastTakenAt!,
            summary: _t('marked_as_taken'),
          ),
        );
      }
      for (final h in med.history) {
        final at = _toDate(h['at']) ?? DateTime.now();
        entries.add(
          MedicationHistoryEntry(
            medName: med.name,
            at: at,
            summary: (h['summary'] ?? h['action'] ?? _t('updated')).toString(),
          ),
        );
      }
    }
    entries.sort((a, b) => b.at.compareTo(a.at));

    if (entries.isEmpty) {
      return Center(child: Text(_t('no_medication_history')));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            leading: const Icon(Icons.manage_history, color: petrol),
            title: Text(entry.medName),
            subtitle: Text(entry.summary),
            trailing: Text('${_dateText(entry.at)}\n${_timeText(entry.at)}'),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildAlertsTab(List<MedicationRecord> meds) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _patientRef().snapshots(),
      builder: (context, patientSnap) {
        final patientData = patientSnap.data?.data() ?? {};
        final allergies = _readAllergies(patientData);
        final alerts = _buildMedicationAlerts(meds, allergies);

        if (alerts.isEmpty) {
          return Center(child: Text(_t('no_medication_alerts')));
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          itemCount: alerts.length,
          itemBuilder: (context, index) {
            final alert = alerts[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: alert.color.withValues(alpha: 0.12),
                  child: Icon(alert.icon, color: alert.color),
                ),
                title: Text(alert.title),
                subtitle: Text(alert.message),
              ),
            );
          },
        );
      },
    );
  }

  List<String> _readAllergies(Map<String, dynamic> data) {
    final raw = data['allergies'];
    if (raw is List) {
      return raw
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      return raw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }

  List<MedicationAlert> _buildMedicationAlerts(
    List<MedicationRecord> meds,
    List<String> allergies,
  ) {
    final alerts = <MedicationAlert>[];
    final active = meds.where((m) => m.active).toList();
    final names = <String, int>{};
    for (final med in active) {
      names.update(
        med.name.toLowerCase(),
        (value) => value + 1,
        ifAbsent: () => 1,
      );

      if (med.warning.trim().isNotEmpty) {
        alerts.add(
          MedicationAlert(
            title: '${_t('warning')}: ${med.name}',
            message: med.warning,
            color: Colors.red.shade700,
            icon: Icons.warning_amber_rounded,
          ),
        );
      }

      for (final allergy in allergies) {
        if (allergy.trim().isEmpty) continue;
        if (med.name.toLowerCase().contains(allergy.toLowerCase())) {
          alerts.add(
            MedicationAlert(
              title: _t('allergy_alert'),
              message: '${med.name} ${_t('matches_allergy')} $allergy',
              color: Colors.red.shade700,
              icon: Icons.health_and_safety_outlined,
            ),
          );
        }
      }
    }

    for (final entry in names.entries.where((e) => e.value > 1)) {
      alerts.add(
        MedicationAlert(
          title: _t('possible_duplicate'),
          message: '${entry.key} ${_t('appears_more_than_once')}',
          color: accentOrange,
          icon: Icons.compare_arrows,
        ),
      );
    }

    return alerts;
  }

  void _showDetails(MedicationRecord med) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.82,
        minChildSize: 0.45,
        maxChildSize: 0.96,
        expand: false,
        builder: (context, scrollController) {
          final status = _medStatus(med);
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      med.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _StatusPill(
                    label: _statusLabel(status),
                    color: _statusColor(status),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${med.dosage} • ${med.frequency} • ${_routeLabel(med.route)}',
              ),
              const SizedBox(height: 18),
              _DetailRow(_t('indication'), med.indication),
              _DetailRow(_t('instructions'), med.instructions),
              _DetailRow(_t('start_date'), _dateText(med.startDate)),
              _DetailRow(_t('end_date'), _dateText(med.endDate)),
              _DetailRow(_t('prescribed_by'), med.prescribedBy),
              _DetailRow(_t('stored_at'), med.storageLocation),
              _DetailRow(_t('pickup_location'), med.pickupLocation),
              _DetailRow(
                _t('patient_has_medication'),
                med.patientHasMedication ? _t('yes') : _t('no'),
              ),
              _DetailRow(_t('notes'), med.notes),
              if (med.warning.trim().isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(med.warning)),
                    ],
                  ),
                ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ActionButton(
                    icon: Icons.check_circle_outline,
                    label: _t('mark_taken'),
                    onPressed: med.active ? () => _markTaken(med) : null,
                  ),
                  _ActionButton(
                    icon: Icons.edit_outlined,
                    label: _t('edit'),
                    onPressed: () {
                      Navigator.pop(context);
                      _openMedicationForm(med);
                    },
                  ),
                  _ActionButton(
                    icon: Icons.pause_circle_outline,
                    label: _t('stop'),
                    onPressed: med.active ? () => _stopMedication(med) : null,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  String _routeLabel(String route) {
    switch (route) {
      case 'injection':
        return _t('injection');
      case 'topical':
        return _t('topical');
      case 'inhaler':
        return _t('inhaler');
      case 'drops':
        return _t('drops');
      default:
        return _t('oral');
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'missed':
        return _t('missed');
      case 'completed':
        return _t('completed');
      case 'stopped':
        return _t('stopped');
      default:
        return _t('active');
    }
  }
}

class MedicationFormSheet extends StatefulWidget {
  final MedicationRecord? initial;
  final String patientId;
  final CollectionReference<Map<String, dynamic>> medsRef;

  const MedicationFormSheet({
    super.key,
    required this.initial,
    required this.patientId,
    required this.medsRef,
  });

  @override
  State<MedicationFormSheet> createState() => _MedicationFormSheetState();
}

class _MedicationFormSheetState extends State<MedicationFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _dosageCtrl;
  late final TextEditingController _frequencyCtrl;
  late final TextEditingController _indicationCtrl;
  late final TextEditingController _instructionsCtrl;
  late final TextEditingController _prescribedByCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _warningCtrl;
  late final TextEditingController _storageCtrl;
  late final TextEditingController _pickupCtrl;

  String _route = 'oral';
  String _status = 'active';
  bool _prn = false;
  bool _patientHasMedication = true;
  bool _saving = false;
  List<TimeOfDay> _times = [const TimeOfDay(hour: 8, minute: 0)];
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    final med = widget.initial;
    _nameCtrl = TextEditingController(text: med?.name ?? '');
    _dosageCtrl = TextEditingController(text: med?.dosage ?? '');
    _frequencyCtrl = TextEditingController(
      text: med?.frequency ?? 'Once daily',
    );
    _indicationCtrl = TextEditingController(text: med?.indication ?? '');
    _instructionsCtrl = TextEditingController(text: med?.instructions ?? '');
    _prescribedByCtrl = TextEditingController(text: med?.prescribedBy ?? '');
    _notesCtrl = TextEditingController(text: med?.notes ?? '');
    _warningCtrl = TextEditingController(text: med?.warning ?? '');
    _storageCtrl = TextEditingController(text: med?.storageLocation ?? '');
    _pickupCtrl = TextEditingController(text: med?.pickupLocation ?? '');
    _route = med?.route ?? 'oral';
    _status = med?.status ?? 'active';
    _prn = med?.prn ?? false;
    _patientHasMedication = med?.patientHasMedication ?? true;
    _times = med != null && med.times.isNotEmpty
        ? med.times.toList()
        : [const TimeOfDay(hour: 8, minute: 0)];
    _startDate = med?.startDate;
    _endDate = med?.endDate;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    _frequencyCtrl.dispose();
    _indicationCtrl.dispose();
    _instructionsCtrl.dispose();
    _prescribedByCtrl.dispose();
    _notesCtrl.dispose();
    _warningCtrl.dispose();
    _storageCtrl.dispose();
    _pickupCtrl.dispose();
    super.dispose();
  }

  AppLocalizations get _lang => AppLocalizations.of(context);
  String _t(String key) => _lang.translate(key);
  Map<String, dynamic> _timeToMap(TimeOfDay t) => {'h': t.hour, 'm': t.minute};

  Future<void> _pickTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _times[index],
    );
    if (picked != null) setState(() => _times[index] = picked);
  }

  Future<void> _pickDate(bool start) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: start ? (_startDate ?? now) : (_endDate ?? now),
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  String _dateText(DateTime? date) {
    if (date == null) return _t('not_set');
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final data = {
      'patientId': widget.patientId,
      'name': _nameCtrl.text.trim(),
      'dosage': _dosageCtrl.text.trim(),
      'frequency': _frequencyCtrl.text.trim(),
      'route': _route,
      'status': _status,
      'active': _status != 'stopped',
      'prn': _prn,
      'reminderEnabled': !_prn,
      'times': _prn ? [] : _times.map(_timeToMap).toList(),
      'startDate': _startDate == null ? null : Timestamp.fromDate(_startDate!),
      'endDate': _endDate == null ? null : Timestamp.fromDate(_endDate!),
      'indication': _indicationCtrl.text.trim(),
      'instructions': _instructionsCtrl.text.trim(),
      'prescribedBy': _prescribedByCtrl.text.trim(),
      'notes': _notesCtrl.text.trim(),
      'warning': _warningCtrl.text.trim(),
      'storageLocation': _storageCtrl.text.trim(),
      'pickupLocation': _pickupCtrl.text.trim(),
      'patientHasMedication': _patientHasMedication,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      if (widget.initial == null) {
        await widget.medsRef.add({
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
          'history': [
            {
              'action': 'created',
              'at': Timestamp.now(),
              'summary': 'Medication created',
            },
          ],
        });
      } else {
        await widget.medsRef.doc(widget.initial!.id).update({
          ...data,
          'history': FieldValue.arrayUnion([
            {
              'action': 'updated',
              'at': Timestamp.now(),
              'summary': 'Medication updated',
            },
          ]),
        });
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_t('failed_to_save_medication')}: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.96,
        expand: false,
        builder: (context, scrollController) => Form(
          key: _formKey,
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                widget.initial == null
                    ? _t('add_medication')
                    : _t('edit_medication'),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              _field(_nameCtrl, _t('medication_name'), required: true),
              _field(_dosageCtrl, _t('dosage'), required: true),
              _field(_frequencyCtrl, _t('frequency'), required: true),
              DropdownButtonFormField<String>(
                initialValue: _route,
                decoration: InputDecoration(
                  labelText: _t('route'),
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: 'oral', child: Text(_t('oral'))),
                  DropdownMenuItem(
                    value: 'injection',
                    child: Text(_t('injection')),
                  ),
                  DropdownMenuItem(
                    value: 'topical',
                    child: Text(_t('topical')),
                  ),
                  DropdownMenuItem(
                    value: 'inhaler',
                    child: Text(_t('inhaler')),
                  ),
                  DropdownMenuItem(value: 'drops', child: Text(_t('drops'))),
                ],
                onChanged: (v) => setState(() => _route = v ?? 'oral'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: InputDecoration(
                  labelText: _t('status'),
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: 'active', child: Text(_t('active'))),
                  DropdownMenuItem(
                    value: 'completed',
                    child: Text(_t('completed')),
                  ),
                  DropdownMenuItem(
                    value: 'stopped',
                    child: Text(_t('stopped')),
                  ),
                ],
                onChanged: (v) => setState(() => _status = v ?? 'active'),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_t('prn_medication')),
                value: _prn,
                onChanged: (v) => setState(() => _prn = v),
              ),
              if (!_prn) ...[
                Row(
                  children: [
                    Expanded(child: Text(_t('dose_times'))),
                    IconButton(
                      tooltip: _t('add_time'),
                      onPressed: () => setState(
                        () => _times.add(const TimeOfDay(hour: 8, minute: 0)),
                      ),
                      icon: const Icon(Icons.add_alarm),
                    ),
                  ],
                ),
                ...List.generate(_times.length, (i) {
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      title: Text('${_t('time')} ${i + 1}'),
                      subtitle: Text(_times[i].format(context)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: _t('edit'),
                            icon: const Icon(Icons.access_time),
                            onPressed: () => _pickTime(i),
                          ),
                          if (_times.length > 1)
                            IconButton(
                              tooltip: _t('delete'),
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () =>
                                  setState(() => _times.removeAt(i)),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(true),
                      icon: const Icon(Icons.event),
                      label: Text(
                        '${_t('start_date')}: ${_dateText(_startDate)}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(false),
                      icon: const Icon(Icons.event_available),
                      label: Text('${_t('end_date')}: ${_dateText(_endDate)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _field(_indicationCtrl, _t('indication')),
              _field(_instructionsCtrl, _t('instructions'), maxLines: 2),
              _field(_prescribedByCtrl, _t('prescribed_by')),
              _field(_storageCtrl, _t('stored_at_hint')),
              _field(_pickupCtrl, _t('pickup_location')),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_t('patient_has_medication')),
                value: _patientHasMedication,
                onChanged: (v) => setState(() => _patientHasMedication = v),
              ),
              _field(
                _warningCtrl,
                _t('contraindications_allergy_warning'),
                maxLines: 2,
              ),
              _field(_notesCtrl, _t('notes'), maxLines: 2),
              const SizedBox(height: 16),
              SizedBox(
                height: 50,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: petrol),
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_t('save')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? _t('required') : null
            : null,
      ),
    );
  }
}

class MedicationRecord {
  final String id;
  final String patientId;
  final String name;
  final String dosage;
  final String frequency;
  final String route;
  final String status;
  final bool active;
  final bool prn;
  final bool reminderEnabled;
  final List<TimeOfDay> times;
  final DateTime? lastTakenAt;
  final DateTime? startDate;
  final DateTime? endDate;
  final String prescribedBy;
  final String indication;
  final String instructions;
  final String notes;
  final String warning;
  final String storageLocation;
  final String pickupLocation;
  final bool patientHasMedication;
  final DateTime? refillRequestedAt;
  final List<Map<String, dynamic>> history;

  const MedicationRecord({
    required this.id,
    required this.patientId,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.route,
    required this.status,
    required this.active,
    required this.prn,
    required this.reminderEnabled,
    required this.times,
    required this.lastTakenAt,
    required this.startDate,
    required this.endDate,
    required this.prescribedBy,
    required this.indication,
    required this.instructions,
    required this.notes,
    required this.warning,
    required this.storageLocation,
    required this.pickupLocation,
    required this.patientHasMedication,
    required this.refillRequestedAt,
    required this.history,
  });
}

class DoseScheduleItem {
  final MedicationRecord med;
  final DateTime doseAt;
  const DoseScheduleItem({required this.med, required this.doseAt});
}

class MedicationHistoryEntry {
  final String medName;
  final DateTime at;
  final String summary;
  const MedicationHistoryEntry({
    required this.medName,
    required this.at,
    required this.summary,
  });
}

class MedicationAlert {
  final String title;
  final String message;
  final Color color;
  final IconData icon;
  const MedicationAlert({
    required this.title,
    required this.message,
    required this.color,
    required this.icon,
  });
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Flexible(child: Text(label, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _DropdownFilter extends StatelessWidget {
  final String value;
  final String label;
  final List<String> items;
  final String Function(String value) textFor;
  final ValueChanged<String?> onChanged;

  const _DropdownFilter({
    required this.value,
    required this.label,
    required this.items,
    required this.textFor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem(value: item, child: Text(textFor(item))),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(value.trim().isEmpty ? lang.translate('not_set') : value),
        ],
      ),
    );
  }
}

class _EmptyMedicationState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyMedicationState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.medication_outlined, size: 64, color: petrol),
            const SizedBox(height: 12),
            Text(
              lang.translate('no_medications_added_yet'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: petrol),
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(lang.translate('add_medication')),
            ),
          ],
        ),
      ),
    );
  }
}
