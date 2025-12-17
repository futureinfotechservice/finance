
import 'package:cached_network_image/cached_network_image.dart';
// import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/loginscreenwidget.dart';
import '../services/login_apiservice.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool obscurePassword = true;
  String? logourlvalue ;

  String? companynamevalue;
  String? companyidvalue;


  Future<void> loadlogo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyname = prefs.getString('companyname') ?? '';
    final logourl = prefs.getString('logourl') ?? '';
    final companyid = prefs.getString('companyid') ?? '';
    final username = prefs.getString('username') ?? '';
    final password = prefs.getString('password') ?? '';
    final email = prefs.getString('email') ?? '';



if(companyid != ''){
    if (kIsWeb) {
      ApiService().login(
          context,
          username.toString(),
          password.toString(),
          email.toString(),
          '',
          '1');
      print("Unsupported platform");
    } else if (defaultTargetPlatform ==
        TargetPlatform.android) {
      // final deviceInfo = DeviceInfoPlugin();
      // AndroidDeviceInfo androidInfo =
      //     await deviceInfo.androidInfo;
      // print(
      //     "Android Device ID: ${androidInfo.androidId}");
      ApiService().login(
          context,
          username.toString(),
          password.toString(),
          email.toString(),
          // "${androidInfo.androidId}",
          "",
          "0");
    } else if (defaultTargetPlatform ==
        TargetPlatform.iOS) {
      // final deviceInfo = DeviceInfoPlugin();
      // IosDeviceInfo iosInfo =
      //     await deviceInfo.iosInfo;
      // print(
      //     "iOS UUID: ${iosInfo.identifierForVendor}");
      ApiService().login(
          context,
          username.toString(),
          password.toString(),
          email.toString(),
          // "${iosInfo.identifierForVendor}",
          "",
          "0");
    }}
    setState(() {
      logourlvalue = logourl.toString();
      companynamevalue = companyname.toString();
      companyidvalue = companyid.toString();
    });


  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadlogo();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final cardWidth = screenWidth < 600 ? screenWidth * 0.9 : 500.0;

    return Scaffold(
      backgroundColor: Color(0xffF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Future Info Tech Logo
              Align(
                alignment: Alignment.topLeft,
                child: Image.asset(
                  'assets/Homelogos/fItlogo.png', // Add to assets
                  height: 60,
                ),
              ),
              const SizedBox(height: 10),

          CircleAvatar(
            radius: 80,
            backgroundColor: Colors.transparent,
            child: ClipOval(
              child: Image.network(
                "https://futureinfotechservices.in/financeapi/getlogo.php?companyid="+companyidvalue.toString(),
                fit: BoxFit.cover,
                width: 160,
                height: 160,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/Homelogos/fItlogo.png',
                    fit: BoxFit.cover,
                    width: 160,
                    height: 160,
                  );
                },
              ),
            ),
          ),


              const SizedBox(height: 10),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [Colors.orange, Colors.red],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(
                    Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                child: Text(
                  (companynamevalue != null && companynamevalue!.isNotEmpty)
                      ? companynamevalue!.toUpperCase().toString():'FUTURE INFOTECH',
                  style: GoogleFonts.poppins(
                    fontSize: 22.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Required for ShaderMask to work
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: cardWidth),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 15,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Login',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Login to access your account',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Email Field
                      CustomInputField(
                        controller: emailController,
                        hintText: "Enter your email",
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email,
                        onChanged: (val) => print("Email: $val"),
                      ),
                      const SizedBox(height: 15),
                      CustomInputField(
                        controller: usernameController,
                        hintText: "User Name",
                        keyboardType: TextInputType.name,
                        prefixIcon: Icons.person,
                        onChanged: (val) => print("Email: $val"),
                      ),
                      const SizedBox(height: 15),
                      CustomInputField(
                        controller: passwordController,
                        hintText: "Password",
                        isPassword: true,
                        prefixIcon: Icons.lock,
                        onSubmitted: (val) => print("Submitted password: $val"),
                      ),
                      const SizedBox(height: 25),
                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF3869EB).withOpacity(0.8),
                            // Blue with 70% opacity
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          onPressed: () async {
                            if (emailController.text != "" &&
                                usernameController.text != "" &&
                                passwordController.text != "") {
                              if (kIsWeb) {
                                ApiService().login(
                                 context,
                                    usernameController.text.toString(),
                                    passwordController.text.toString(),
                                    emailController.text.toString(),
                                    '',
                                    '1');
                                print("Unsupported platform");
                              } else if (defaultTargetPlatform ==
                                  TargetPlatform.android) {
                                // final deviceInfo = DeviceInfoPlugin();
                                // AndroidDeviceInfo androidInfo =
                                //     await deviceInfo.androidInfo;
                                // print(
                                //     "Android Device ID: ${androidInfo.androidId}");
                                ApiService().login(
                                  context,
                                    usernameController.text.toString(),
                                    passwordController.text.toString(),
                                    emailController.text.toString(),
                                    // "${androidInfo.androidId}",
                                    "",
                                    "0");
                              } else if (defaultTargetPlatform ==
                                  TargetPlatform.iOS) {
                                // final deviceInfo = DeviceInfoPlugin();
                                // IosDeviceInfo iosInfo =
                                //     await deviceInfo.iosInfo;
                                // print(
                                //     "iOS UUID: ${iosInfo.identifierForVendor}");
                                ApiService().login(
                                  context,
                                    usernameController.text.toString(),
                                    passwordController.text.toString(),
                                    emailController.text.toString(),
                                    // "${iosInfo.identifierForVendor}",
                                    "",
                                    "0");
                              }
                              // Add login logic here
                            }
                          },
                          child: Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



