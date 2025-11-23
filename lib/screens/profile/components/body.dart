import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../../constants.dart';
import '../user_profile_screen.dart';
import '../../../services/user_service.dart';
import '../../auth/sign_in_screen.dart';

class Body extends StatefulWidget {
  const Body({super.key});

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: defaultPadding),
              Text("Account Settings",
                  style: Theme.of(context).textTheme.headlineMedium),
              Text(
                "Update your settings like notifications, payments, profile edit etc.",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ProfileMenuCard(
                svgSrc: "assets/icons/profile.svg",
                title: "Profile Information",
                subTitle: "View your account information",
                press: () {
                  // Navigate to the user profile screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UserProfileScreen()),
                  );
                },
              ),
              ProfileMenuCard(
                svgSrc: "assets/icons/lock.svg",
                title: "Change Password",
                subTitle: "Change your password",
                press: () {},
              ),
              ProfileMenuCard(
                svgSrc: "assets/icons/card.svg",
                title: "Payment Methods",
                subTitle: "Add your credit & debit cards",
                press: () {},
              ),
              ProfileMenuCard(
                svgSrc: "assets/icons/marker.svg",
                title: "Locations",
                subTitle: "Add or remove your delivery locations",
                press: () {},
              ),
              ProfileMenuCard(
                svgSrc: "assets/icons/fb.svg",
                title: "Add Social Account",
                subTitle: "Add Facebook, Twitter etc ",
                press: () {},
              ),
              ProfileMenuCard(
                svgSrc: "assets/icons/share.svg",
                title: "Refer to Friends",
                subTitle: "Get \$10 for reffering friends",
                press: () {},
              ),
              const SizedBox(height: 16), // Add some spacing before the logout button
              // Logout button
              Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton(
                  onPressed: () async {
                    // Clear user data and navigate to login screen
                    await UserService.instance.clearUserData();
                    // Schedule navigation after the frame is rendered
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const SignInScreen()),
                        (route) => false,
                      );
                    });
                  },
                  child: const Text(
                    "Logout",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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

class ProfileMenuCard extends StatelessWidget {
  const ProfileMenuCard({
    super.key,
    this.title,
    this.subTitle,
    this.svgSrc,
    this.press,
  });

  final String? title, subTitle, svgSrc;
  final VoidCallback? press;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: defaultPadding / 2),
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        onTap: press,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              SvgPicture.asset(
                svgSrc!,
                height: 24,
                width: 24,
                colorFilter: ColorFilter.mode(
                  titleColor.withOpacity(0.64),
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title!,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subTitle!,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 14,
                        color: titleColor.withOpacity(0.54),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_outlined,
                size: 20,
              )
            ],
          ),
        ),
      ),
    );
  }
}
