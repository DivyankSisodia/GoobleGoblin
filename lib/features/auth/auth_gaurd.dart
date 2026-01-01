import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        color: Colors.black,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 40,),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Text('Welcome Master\nDivyank', style: TextStyle(color: const Color.fromARGB(255, 168, 168, 168), fontSize: 40, fontFamily: GoogleFonts.montserrat().fontFamily),),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text("I'm alfred to\nserve you!!", style: TextStyle(color: const Color.fromARGB(255, 147, 147, 147), fontSize: 36, fontFamily: GoogleFonts.montserrat().fontFamily),),
            ),
            // ElevatedButton(onPressed: () {}, child: const Text('Login')),
          ],
        ),
      ),
    );
  }
}