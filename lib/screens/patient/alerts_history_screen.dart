import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../utils/constants.dart';
import '../../models/alert_item.dart';

class AlertsHistoryScreen extends StatefulWidget {
  final String patientId;
  const AlertsHistoryScreen({super.key, required this.patientId});

  @override
  State<AlertsHistoryScreen> createState() => _AlertsHistoryScreenState();
}

class _AlertsHistoryScreenState extends State<AlertsHistoryScreen> {
  
  @override
  void initState() {
    super.initState();
    // جلب التنبيهات عند فتح الصفحة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppState>(context, listen: false).fetchAlerts(widget.patientId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Alerts History"),
        backgroundColor: PETROL_DARK,
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          final alerts = appState.alerts;

          if (alerts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No alerts recorded yet", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final alert = alerts[index];
              return _buildAlertCard(alert);
            },
          );
        },
      ),
    );
  }

  Widget _buildAlertCard(AlertItem alert) {
    Color color;
    IconData icon;

    switch (alert.severity.toLowerCase()) {
      case 'critical':
        color = Colors.red;
        icon = Icons.warning;
        break;
      case 'high':
        color = Colors.orange;
        icon = Icons.priority_high;
        break;
      default:
        color = Colors.blue;
        icon = Icons.info_outline;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: color, width: 5)),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color),
          ),
          title: Text(
            alert.type,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 5),
              Text(alert.message),
              const SizedBox(height: 5),
              Text(
                _formatDate(alert.timestamp),
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return "${dt.day}/${dt.month}  ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }
}