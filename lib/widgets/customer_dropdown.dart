// import 'package:dropdown_search/dropdown_search.dart';
// import 'package:flutter/material.dart';
//
// class CustomerDropdownSearch<T> extends StatelessWidget {
//   final String label;
//   final bool isRequired;
//   final List<T> items;
//   final T? selectedItem;
//   final ValueChanged<T?>? onChanged;
//   final bool isCompact;
//   final bool isReadOnly;
//   final String Function(T)? itemAsString;
//   final bool Function(T, String)? filterFn;
//   final Widget Function(BuildContext, T, bool)? popupItemBuilder;
//
//   const CustomerDropdownSearch({
//     super.key,
//     required this.label,
//     this.isRequired = false,
//     required this.items,
//     this.selectedItem,
//     required this.onChanged,
//     this.isCompact = false,
//     this.isReadOnly = false,
//     this.itemAsString,
//     this.filterFn,
//     this.popupItemBuilder,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     OutlineInputBorder _border({Color color = const Color(0xFFD1D5DB)}) {
//       return OutlineInputBorder(
//         borderSide: BorderSide(color: color, width: 1.4),
//         borderRadius: BorderRadius.circular(6),
//       );
//     }
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         if(label != '')
//           Padding(
//             padding: const EdgeInsets.only(bottom: 6.0),
//             child: RichText(
//               text: TextSpan(
//                 text: label,
//                 style: TextStyle(
//                   color: isReadOnly ? const Color(0xFF111827) : const Color(0xFF374151),
//                   fontSize: 14,
//                   fontWeight: FontWeight.w500,
//                 ),
//                 children: isRequired
//                     ? const [
//                   TextSpan(
//                     text: ' *',
//                     style: TextStyle(color: Colors.red),
//                   )
//                 ]
//                     : [],
//               ),
//             ),
//           ),
//         DropdownSearch<T>(
//           asyncItems: (String filter) => Future.value(items),
//           selectedItem: selectedItem,
//           enabled: !isReadOnly,
//           onChanged: isReadOnly ? null : (value) {
//             if (isRequired && value == null) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text("This field is required")),
//               );
//             }
//             onChanged?.call(value);
//           },
//           itemAsString: itemAsString,
//           filterFn: filterFn,
//           popupProps: PopupProps.menu(
//             showSearchBox: true,
//             searchFieldProps: TextFieldProps(
//               decoration: InputDecoration(
//                 hintText: 'Search by name or phone...',
//                 contentPadding:
//                 const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//             ),
//             itemBuilder: popupItemBuilder,
//             menuProps: MenuProps(
//               borderRadius: BorderRadius.circular(12),
//               elevation: 6,
//               color: Colors.white,
//             ),
//           ),
//           dropdownDecoratorProps: DropDownDecoratorProps(
//             baseStyle: TextStyle(
//               fontSize: 14,
//               color: isReadOnly ? const Color(0xFF111827) : Colors.black,
//             ),
//             decoration: InputDecoration(
//               filled: true,
//               fillColor: isReadOnly ? const Color(0xFFF3F4F6) : const Color(0xFFF3F4F6),
//               border: _border(),
//               enabledBorder: _border(),
//               focusedBorder: _border(),
//               disabledBorder: _border(color: const Color(0xFFD1D5DB)),
//               isDense: isCompact,
//               contentPadding: isCompact
//                   ? const EdgeInsets.symmetric(horizontal: 14, vertical: 13)
//                   : const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
//               hintStyle: TextStyle(
//                 color: isReadOnly ? const Color(0xFF6B7280) : const Color(0xFF6B7280),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }