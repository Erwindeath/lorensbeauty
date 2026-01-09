import 'package:date_picker_timeline/date_picker_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider para la fecha seleccionada en el booking
final selectedBookingDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

class CustomDatePicker extends ConsumerStatefulWidget {
  const CustomDatePicker({
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<CustomDatePicker> createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends ConsumerState<CustomDatePicker> {
  DateTime newdate = DateTime.now();
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final datePickerHeight = screenHeight > 700 ? 90.0 : 80.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Row(
            children: [
              const Icon(
                Icons.arrow_back_ios,
                color: Colors.white60,
                size: 18,
              ),
              const Spacer(),
              Text(
                "${setMonth(newdate.month)}, ${newdate.year}",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white60,
                size: 18,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: DatePicker(
            DateTime.now(),
            daysCount: 30,
            deactivatedColor: Colors.white,
            initialSelectedDate: DateTime.now(),
            selectionColor: Colors.white,
            selectedTextColor: const Color(0xff721c80),
            dateTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            dayTextStyle: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            monthTextStyle: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
            onDateChange: (date) {
              setState(() {
                newdate = date;
              });
              // Actualizar el provider
              ref.read(selectedBookingDateProvider.notifier).state = date;
            },
            height: datePickerHeight,
            width: 58,
          ),
        ),
      ],
    );
  }

  String setMonth(monthNo) {
    switch (monthNo) {
      case 1:
        return "Jan";
      case 2:
        return "Feb";
      case 3:
        return "Mar";
      case 4:
        return "Apr";
      case 5:
        return "May";
      case 6:
        return "June";
      case 7:
        return "Jul";
      case 8:
        return "Aug";
      case 9:
        return "Sep";
      case 10:
        return "Oct";
      case 11:
        return "Nov";
      case 12:
        return "Dec";

      default:
        return "";
    }
  }
}
