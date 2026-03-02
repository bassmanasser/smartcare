import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/doctor.dart';
import '../../utils/constants.dart';

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
        backgroundColor: PETROL_DARK,
      ),
      body: Column(
        children: [
          // 1. تقويم اختيار اليوم
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
              selectedDecoration: BoxDecoration(color: PETROL, shape: BoxShape.circle),
              todayDecoration: BoxDecoration(color: Colors.lightBlueAccent, shape: BoxShape.circle),
            ),
          ),

          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text("اختر الوقت المتاح:", 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: PETROL_DARK)),
            ),
          ),

          // 2. شبكة المواعيد المتاحة
          Expanded(
            child: widget.doctor.availableSlots.isEmpty 
              ? const Center(child: Text("لا توجد مواعيد متاحة حالياً لهذا الطبيب"))
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, 
                    childAspectRatio: 2.5, 
                    crossAxisSpacing: 10, 
                    mainAxisSpacing: 10,
                  ),
                  itemCount: widget.doctor.availableSlots.length,
                  itemBuilder: (context, index) {
                    String slot = widget.doctor.availableSlots[index];
                    bool isSelected = _selectedSlot == slot;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedSlot = slot),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? PETROL : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isSelected ? PETROL_DARK : Colors.transparent),
                        ),
                        alignment: Alignment.center,
                        child: Text(slot, 
                          style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.w500)),
                      ),
                    );
                  },
                ),
          ),

          // 3. عرض سعر الكشف وتأكيد الحجز
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("رسوم الكشف:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text("${widget.doctor.consultationFee} ج.م", 
                      style: const TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55),
                    backgroundColor: PETROL_DARK,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: (_selectedDay != null && _selectedSlot != null) ? () {
                    // هنا يتم إضافة منطق الحجز الفعلي في قاعدة البيانات
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("تم طلب الحجز يوم ${_selectedDay!.day}/${_selectedDay!.month} الساعة $_selectedSlot"))
                    );
                  } : null,
                  child: const Text("تأكيد موعد الحجز", 
                    style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}