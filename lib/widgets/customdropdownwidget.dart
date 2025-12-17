import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';


class CustomDropdownSearch extends StatefulWidget {
  final String label;
  final bool isRequired;
  final List<String> items;
  final String? selectedItem;
  final ValueChanged<String?>? onChanged;
  final bool isCompact;
  final bool isReadOnly;
  final bool autoFocus;

  const CustomDropdownSearch({
    super.key,
    required this.label,
    this.isRequired = false,
    required this.items,
    this.selectedItem,
    required this.onChanged,
    this.isCompact = false,
    this.isReadOnly = false,
    this.autoFocus = false,
  });

  @override
  State<CustomDropdownSearch> createState() => _CustomDropdownSearchState();
}

class _CustomDropdownSearchState extends State<CustomDropdownSearch> {
  final TextEditingController _searchController = TextEditingController();

  void _handleEnterKeySelection(String searchText) {
    if (searchText.isEmpty) return;

    // Filter items based on search text
    final filteredItems = widget.items.where((item) =>
        item.toLowerCase().contains(searchText.toLowerCase())).toList();

    if (filteredItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No matching item found for "$searchText"')),
      );
      return;
    }

    // Select the first matching item
    _selectItem(filteredItems.first);
  }

  void _selectItem(String item) {
    if (widget.onChanged != null) {
      if (widget.isRequired && item.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("This field is required")),
        );
      } else {
        widget.onChanged!(item);
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    OutlineInputBorder _border({Color color = const Color(0xFFD1D5DB)}) {
      return OutlineInputBorder(
        borderSide: BorderSide(color: color, width: 1.4),
        borderRadius: BorderRadius.circular(6),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if(widget.label != '')
          Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: RichText(
              text: TextSpan(
                text: widget.label,
                style: TextStyle(
                  color: widget.isReadOnly ? const Color(0xFF111827) : const Color(0xFF374151),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                children: widget.isRequired
                    ? const [
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: Colors.red),
                  )
                ]
                    : [],
              ),
            ),
          ),
        DropdownSearch<String>(
          items: (filter, loadProps) => widget.items,
          selectedItem: widget.selectedItem,
          enabled: !widget.isReadOnly,
          onChanged: widget.isReadOnly ? null : (value) {
            if (widget.isRequired && (value == null || value.isEmpty)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("This field is required")),
              );
            }
            widget.onChanged?.call(value);
          },
          // dropdownButtonProps: DropdownButtonProps(
          //   icon: Icon(
          //     Icons.arrow_drop_down,
          //     color: isReadOnly ? const Color(0xFF111827) : const Color(0xFF374151),
          //   ),
          // ),
          decoratorProps: DropDownDecoratorProps(
            baseStyle: TextStyle(
              fontSize: 14,
              color: widget.isReadOnly ? const Color(0xFF111827) : Colors.black, // Dark text for readonly
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: widget.isReadOnly ? const Color(0xFFF3F4F6) : const Color(0xFFF3F4F6),
              border: _border(),
              enabledBorder: _border(),
              focusedBorder: _border(),
              disabledBorder: _border(color: const Color(0xFFD1D5DB)),
              isDense: widget.isCompact,
              contentPadding: widget.isCompact
                  ? const EdgeInsets.symmetric(horizontal: 14, vertical: 13)
                  : const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              hintStyle: TextStyle(
                color: widget.isReadOnly ? const Color(0xFF6B7280) : const Color(0xFF6B7280),
              ),
            ),
          ),
          popupProps: PopupProps.menu(
            showSearchBox: true,
            searchFieldProps: TextFieldProps(
              controller: _searchController,
              autofocus: widget.autoFocus, // Auto-focus when dropdown opens
              decoration: InputDecoration(
                hintText: 'Search...',
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    // This will be handled by the dropdown search internally
                  },
                ),
              ),
              onSubmitted: _handleEnterKeySelection,
            ),
            menuProps: MenuProps(
              borderRadius: BorderRadius.circular(12),
              elevation: 6,
              color: Colors.white,
              backgroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}


class CustomDropdownSearchonlybox extends StatelessWidget {
  final String? label;
  final bool isRequired;
  final List<String> items;
  final String? selectedItem;
  final ValueChanged<String?>? onChanged;
  final bool isCompact;
  final bool isReadOnly;

  const CustomDropdownSearchonlybox({
    super.key,
    this.label,
    this.isRequired = false,
    required this.items,
    this.selectedItem,
    required this.onChanged,
    this.isCompact = false,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder _border({Color color = const Color(0xFFE5E7EB)}) {
      return OutlineInputBorder(
        borderSide: BorderSide(color: color, width: 1),
        borderRadius: BorderRadius.circular(6),
      );
    }

    return SizedBox(
      height: 40,
      child: DropdownSearch<String>(
        items: (filter, loadProps) => items,
        selectedItem: selectedItem,
        enabled: !isReadOnly,
        onChanged: isReadOnly ? null : (value) {
          if (isRequired && (value == null || value.isEmpty)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("This field is required")),
            );
          }
          onChanged?.call(value);
        },
        // dropdownButtonProps: DropdownButtonProps(
        //   icon: Icon(
        //     Icons.arrow_drop_down,
        //     color: isReadOnly ? const Color(0xFF111827) : const Color(0xFF374151),
        //     size: 20,
        //   ),
        // ),
        suffixProps: DropdownSuffixProps(
            dropdownButtonProps: DropdownButtonProps(
                padding: EdgeInsets.only(left:0,top:4,bottom:4,right:1),
                constraints: BoxConstraints()
            )
        ),
        decoratorProps: DropDownDecoratorProps(
          baseStyle: TextStyle(
            fontSize: 13,
            color: isReadOnly ? const Color(0xFF111827) : Colors.black, // Dark text for readonly
          ),
          decoration: InputDecoration(
              constraints: BoxConstraints(),
              isDense: true,
              hintText: label ?? "Select",
              hintStyle: TextStyle(
                color: isReadOnly ? const Color(0xFF6B7280) : const Color(0xFF6B7280),
                fontSize: 13,
              ),
              filled: true,
              fillColor: isReadOnly ? const Color(0xFFF3F4F6) : Colors.white, // Fixed background color
              border: _border(),
              enabledBorder: _border(),
              focusedBorder: _border(color: Colors.blue),
              disabledBorder: _border(color: const Color(0xFFE5E7EB)),
              suffixIconConstraints: BoxConstraints(
                minWidth: 3,
              )
          ),
        ),
        popupProps: PopupProps.menu(
          fit: FlexFit.loose,
          constraints : const BoxConstraints(minWidth: 350),
          showSearchBox: true,
          searchFieldProps: TextFieldProps(
            decoration: InputDecoration(
              hintText: 'Search...',
              hintStyle: TextStyle(fontSize: 13),
              fillColor: Colors.white,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          menuProps: MenuProps(
            borderRadius: BorderRadius.circular(8),
            elevation: 6,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// import 'package:dropdown_search/dropdown_search.dart';
// import 'package:flutter/material.dart';
//
// class CustomDropdownSearch extends StatelessWidget {
//   final String label;
//   final bool isRequired;
//   final List<String> items;
//   final String? selectedItem;
//   final ValueChanged<String?> onChanged;
//   final bool isCompact;
//
//   const CustomDropdownSearch({
//     super.key,
//     required this.label,
//     this.isRequired = false,
//     required this.items,
//     this.selectedItem,
//     required this.onChanged,
//     this.isCompact = false,
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
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         if(label != '')
//         Padding(
//           padding: const EdgeInsets.only(bottom: 6.0),
//           child: RichText(
//             text: TextSpan(
//               text: label,
//               style: const TextStyle(
//                 color: Color(0xFF374151),
//                 fontSize: 14,
//                 fontWeight: FontWeight.w500,
//               ),
//               children: isRequired
//                   ? const [
//                 TextSpan(
//                   text: ' *',
//                   style: TextStyle(color: Colors.red),
//                 )
//               ]
//                   : [],
//             ),
//           ),
//         ),
//         DropdownSearch<String>(
//           items: (filter, loadProps) => items,
//           selectedItem: selectedItem,
//
//           onChanged: (value) {
//             if (isRequired && (value == null || value.isEmpty)) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text("This field is required")),
//               );
//             }
//             onChanged(value);
//           },
//           decoratorProps: DropDownDecoratorProps(
//             decoration: InputDecoration(
//               // contentPadding:
//               // const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
//               filled: true,
//               fillColor: Color(0xffF3F4F6),
//               border: _border(),
//               enabledBorder:  _border(),
//               focusedBorder:  _border(),
//
//               isDense: isCompact,
//               contentPadding: isCompact
//                   ? const EdgeInsets.symmetric(horizontal: 14, vertical: 13)
//                   : const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
//
//             ),
//           ),
//           popupProps: PopupProps.menu(
//
//             showSearchBox: true,
//             searchFieldProps: TextFieldProps(
//               decoration: InputDecoration(
//                 hintText: 'Search...',
//                 contentPadding:
//                 const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//             ),
//             menuProps: MenuProps(
//               borderRadius: BorderRadius.circular(12),
//               elevation: 6,
//               color:  Colors.white,
//               backgroundColor: Colors.white,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
// class CustomDropdownSearchonlybox extends StatelessWidget {
//   final String? label;
//   final bool isRequired;
//   final List<String> items;
//   final String? selectedItem;
//   final ValueChanged<String?> onChanged;
//   final bool isCompact;
//
//   const CustomDropdownSearchonlybox({
//     super.key,
//     this.label,
//     this.isRequired = false,
//     required this.items,
//     this.selectedItem,
//     required this.onChanged,
//     this.isCompact = false,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     OutlineInputBorder _border({Color color = const Color(0xFFE5E7EB)}) {
//       return OutlineInputBorder(
//         borderSide: BorderSide(color: color, width: 1),
//         borderRadius: BorderRadius.circular(6),
//       );
//     }
//
//     return SizedBox(
//       height: 40,
//       child: DropdownSearch<String>(
//         items: (filter, loadProps) => items,
//         selectedItem: selectedItem,
//         onChanged: (value) {
//           if (isRequired && (value == null || value.isEmpty)) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text("This field is required")),
//             );
//           }
//           onChanged(value);
//         },
//         suffixProps: DropdownSuffixProps(
//             dropdownButtonProps: DropdownButtonProps(
//               // iconOpened: Icon(Icons.arrow_drop_up, size: 12),
//               // iconClosed: Icon(Icons.arrow_drop_down, size: 12),
//                 padding:EdgeInsets.only(left:0,top:4,bottom: 4,right:1),
//                 constraints:BoxConstraints(
//                   //maxHeight: 0,
//                   // maxWidth: 0,
//                   //minHeight: 0,
//                   // minWidth: 0
//                 )
//               // splashRadius:0.1,
//               // isVisible: false,
//               // alignment: AlignmentGeometry.directional(start, y),
//               // visualDensity: VisualDensity(
//               //   vertical: 0.1,
//               // )
//             )
//         ),
//         decoratorProps: DropDownDecoratorProps(
//           baseStyle: TextStyle(fontSize: 13),
//           // textAlign: TextAlign.center,
//           decoration: InputDecoration(
//               constraints: BoxConstraints(
//                 // minHeight: 36,
//                 //minWidth: 150
//                 // 👈 match your SizedBox height
//               ),
//               isDense: true, // compact
//               // contentPadding: const EdgeInsets.symmetric(
//               //   horizontal: 2,
//               //   //vertical: 11,
//               // ),
//               hintText: label ?? "Select",
//               filled: true,
//               fillColor: Colors.white,
//               border: _border(),
//               enabledBorder: _border(),
//               focusedBorder: _border(color: Colors.blue),
//               suffixIconConstraints:BoxConstraints(
//                 minWidth: 3,
//                 //minHeight: 16,
//                 // maxWidth: 0,
//                 // maxHeight: 0
//               )
//           ),
//         ),
//
//
//
//
//         popupProps: PopupProps.menu(
//           fit:FlexFit.loose,
//           constraints : const BoxConstraints(minWidth: 350),
//           showSearchBox: true,
//           searchFieldProps: TextFieldProps(
//             decoration: InputDecoration(
//               hintText: 'Search...',
//               hintStyle: TextStyle(fontSize: 13),
//               fillColor: Colors.white,
//
//               isDense: true,
//               // contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(6),
//               ),
//             ),
//           ),
//
//           menuProps: MenuProps(
//             borderRadius: BorderRadius.circular(8),
//             elevation: 6,
//             color: Colors.white,
//           ),
//         ),
//       ),
//     );
//   }
// }
//
