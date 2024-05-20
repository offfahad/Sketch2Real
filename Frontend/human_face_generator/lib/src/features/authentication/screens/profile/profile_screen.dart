import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:human_face_generator/src/constants/colors.dart';
import 'package:human_face_generator/src/constants/image_strings.dart';
import 'package:human_face_generator/src/constants/sizes.dart';
import 'package:human_face_generator/src/constants/text_strings.dart';
import 'package:human_face_generator/src/features/authentication/models/user_model.dart';
import 'package:human_face_generator/src/features/authentication/screens/forget_password/forget_password_mail/forget_password_mail.dart';
import 'package:human_face_generator/src/features/authentication/screens/profile/profile_menu_widget.dart';
import 'package:human_face_generator/src/features/authentication/screens/profile/update_profile_screen.dart';
import 'package:human_face_generator/src/features/authentication/controllers/profile_controller.dart';
import 'package:human_face_generator/src/features/liveSketching/screens/drawing_layout_responsive.dart';
import 'package:human_face_generator/src/features/withoutLive/models/drawing_point_without_live.dart';
import 'package:human_face_generator/src/features/withoutLive/screens/drawing_screen_without_live.dart';
import 'package:human_face_generator/src/repository/authentication_repository/authentication_repository.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProfileController());
    var isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: screenWidth >= 800
          ? AppBar(
              centerTitle: true,
              backgroundColor: tPrimaryColor,
              leading: IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(
                    LineAwesomeIcons.angle_left,
                    color: tWhiteColor,
                  )),
              title: Text(
                tProfile,
                style: GoogleFonts.poppins(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                  color: tWhiteColor,
                ),
              ),
              actions: [
                IconButton(
                    onPressed: () {},
                    icon: Icon(
                        isDark ? LineAwesomeIcons.sun : LineAwesomeIcons.moon))
              ],
            )
          : null,
      body: Center(
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(tDefaultSize),
          child: Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: Column(
              children: [
                /// -- IMAGE
                if (screenWidth <= 800)
                const SizedBox(height: 150,),
                FutureBuilder(
                  future: controller.getUserData(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (snapshot.hasData) {
                        UserModel userData = snapshot.data as UserModel;
                        final email = userData.email;
                        final fullname = userData.fullName;
                        final profileUrl = userData.profileImage;
                        return Column(
                          children: [
                            SizedBox(
                                width: 120,
                                height: 120,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(100),
                                  child: Image.network(
                                    profileUrl,
                                    fit: BoxFit.fill,
                                  ),
                                )),
                            const SizedBox(
                              height: 20,
                            ),
                            Text(fullname,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium),
                            Text(email,
                                style:
                                    Theme.of(context).textTheme.bodyMedium),
                          ],
                        );
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text(snapshot.error.toString()),
                        );
                      } else {
                        return const Center(
                          child:
                              Text('Too Slow Internet Connection Try Again.'),
                        );
                      }
                    } else {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: tPrimaryColor,
                        ),
                      );
                    }
                  },
                ),
      
                const SizedBox(height: 20),
      
                /// -- BUTTON
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () =>
                        Get.to(() => const UpdateProfileScreen()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tPrimaryColor,
                      side: BorderSide.none,
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      tEditProfile,
                      style: TextStyle(color: tWhiteColor),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Divider(),
                const SizedBox(height: 10),
      
                /// -- MENU
                // ProfileMenuWidget(
                //     title: "Settings",
                //     icon: LineAwesomeIcons.cog,
                //     onPress: () {}),
                // ProfileMenuWidget(
                //     title: "Billing Details",
                //     icon: LineAwesomeIcons.wallet,
                //     onPress: () {}),
                if (screenWidth >= 800)
                  ProfileMenuWidget(
                      title: "Drawing Practice Mode",
                      icon: Icons.draw,
                      onPress: () {
                        Get.to(() => const DrawingScreenWithoutLive());
                      }),
                if (screenWidth >= 800) const SizedBox(height: 10),
                if (screenWidth >= 800)
                  ProfileMenuWidget(
                    title: "Sketch To Real Mode",
                    icon: LineAwesomeIcons.pen_square,
                    onPress: () {
                      Get.to(() => const DrawingResponsiveLayout());
                    },
                  ),
                if (screenWidth >= 800) const Divider(),
                const SizedBox(height: 10),
                ProfileMenuWidget(
                    title: "Reset Password",
                    icon: Icons.password,
                    onPress: () {
                      Get.to(() => const ForgetPasswordMailScreen());
                    }),
      
                const SizedBox(height: 10),
                ProfileMenuWidget(
                  title: "Logout",
                  icon: LineAwesomeIcons.alternate_sign_out,
                  textColor: Colors.red,
                  endIcon: false,
                  onPress: () async {
                    await _showLogoutDialog();
                  },
                ),
      
                const Divider(),
                const SizedBox(height: 10),
                Text(
                  'Developed By @offfahad',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showLogoutDialog() async {
    await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('LOGOUT'),
            content: const Text('Are you sure, you want to Logout?'),
            actions: [
              OutlinedButton(
                onPressed: () => Get.back(),
                child: const Text("No"),
              ),
              ElevatedButton(
                onPressed: () => AuthenticationRepository.instance.logout(),
                style: ElevatedButton.styleFrom(
                    backgroundColor: tPrimaryColor, side: BorderSide.none),
                child: const Text("Yes"),
              ),
            ],
          );
        });
  }
}
