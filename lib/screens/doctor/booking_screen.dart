import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/doctor.dart';

class BookingScreen extends StatefulWidget {
  final Doctor doctor;
  const BookingScreen({super.key, required this.doctor});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String? _selectedSlot;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('حجز موعد - د. ${widget.doctor.name}'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 30)),
            focusedDay: _focusedDay,
            calendarFormat: CalendarFormat.month,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarStyle: const CalendarStyle(
              selectedDecoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
              todayDecoration: BoxDecoration(color: Colors.lightBlue, shape: BoxShape.circle),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("اختر الوقت المتاح:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: widget.doctor.availableSlots.isEmpty 
              ? const Center(child: Text("لا توجد مواعيد متاحة حالياً"))
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, childAspectRatio: 2.5, crossAxisSpacing: 10, mainAxisSpacing: 10,
                  ),
                  itemCount: widget.doctor.availableSlots.length,
                  itemBuilder: (context, index) {
                    String slot = widget.doctor.availableSlots[index];
                    bool isSelected = _selectedSlot == slot;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedSlot = slot),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isSelected ? Colors.blueAccent : Colors.transparent),
                        ),
                        alignment: Alignment.center,
                        child: Text(slot, style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
                      ),
                    );
                  },
                ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 55),
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: (_selectedDay != null && _selectedSlot != null) ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("تم طلب الحجز يوم ${_selectedDay!.day} الساعة $_selectedSlot"))
                );
              } : null,
              child: const Text("تأكيد موعد الحجز", style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }
}