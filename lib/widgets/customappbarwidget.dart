// import 'package:flutter/material.dart';
//
// class CustomAppBarWidget extends StatelessWidget implements PreferredSizeWidget {
//   final String title;
//   final String subtitleDate;
//   final String initials;
//
//   const CustomAppBarWidget({
//     Key? key,
//     required this.title,
//     required this.subtitleDate,
//     required this.initials,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return AppBar(
//       elevation: 0,
//       backgroundColor: Colors.white,
//       surfaceTintColor: Colors.white,
//       automaticallyImplyLeading: false,
//       title: Text(
//         title,
//         style: const TextStyle(
//           color: Colors.black,
//           fontSize: 20,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//       actions: [
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Text('Today', style: TextStyle(color: Colors.grey)),
//               Text(
//                 subtitleDate,
//                 style: const TextStyle(
//                   color: Colors.black,
//                   fontWeight: FontWeight.bold,
//                 ),
//               )
//             ],
//           ),
//         ),
//         CircleAvatar(
//           backgroundColor: Colors.deepPurple,
//           child: Text(initials, style: const TextStyle(color: Colors.white)),
//         ),
//         const SizedBox(width: 16),
//       ],
//     );
//   }
//
//   @override
//   Size get preferredSize => const Size.fromHeight(kToolbarHeight);
// }

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomAppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitleDate; // Now optional
  final String? initials; // Now optional
  final bool showBackButton;

  const CustomAppBarWidget({
    Key? key,
    required this.title,
    this.subtitleDate,
    this.initials,
    this.showBackButton = false,
  }) : super(key: key);

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  @override
  Widget build(BuildContext context) {
    final bool displayBackButton = showBackButton || _isMobile(context);

    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      automaticallyImplyLeading: false,
      leading: displayBackButton
          ? IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
        onPressed: () => context.pop(),
        tooltip: 'Back',
      )
          : null,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        if (subtitleDate != null) // Only show if provided
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Today', style: TextStyle(color: Colors.grey)),
                Text(
                  subtitleDate!,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                )
              ],
            ),
          ),
        // if (initials != null) // Only show if provided
        //   CircleAvatar(
        //     backgroundColor: Colors.deepPurple,
        //     child: Text(initials!, style: const TextStyle(color: Colors.white)),
        //   ),
        const SizedBox(width: 16),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
