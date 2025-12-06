import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Custom Clipper for creating a wave-like shape at the bottom of the AppBar
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 20); // Start slightly above the bottom left corner
    
    // First quadratic bezier curve for the first wave segment
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 20);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy, firstEndPoint.dx, firstEndPoint.dy);

    // Second quadratic bezier curve for the second wave segment
    var secondControlPoint = Offset(size.width * 3 / 4, size.height - 40);
    var secondEndPoint = Offset(size.width, size.height - 20);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy, secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, 0); // Line to the top right corner
    path.close(); // Close the path to form a shape
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false; // No need to re-clip unless properties change
}

// Custom AppBar widget that uses the WaveClipper
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color backgroundColor;
  final List<Widget>? actions;
  final Widget? leading; // Added leading for potential back button or drawer icon
  final double height; // Custom height for the AppBar

  const CustomAppBar({
    Key? key,
    required this.title,
    required this.backgroundColor,
    this.actions,
    this.leading,
    this.height = kToolbarHeight + 40, // Default height: standard toolbar height + extra for the wave
  }) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(height); // Define the preferred size for the AppBar

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: WaveClipper(), // Apply the custom wave clipper
      child: Container(
        color: backgroundColor, // Background color of the AppBar
        child: AppBar(
          backgroundColor: Colors.transparent, // Make AppBar background transparent to show ClipPath's color
          elevation: 0, // No shadow under the AppBar
          title: Text(
            title,
            style: GoogleFonts.quicksand(
              fontWeight: FontWeight.bold,
              color: Colors.white, // Ensure title color is white for contrast
              fontSize: 20,
            ),
          ),
          leading: leading, // Pass leading widget
          actions: actions, // Pass action widgets
          // Make sure the automaticallyImplyLeading is false if leading is provided
          automaticallyImplyLeading: leading != null, 
        ),
      ),
    );
  }
}
