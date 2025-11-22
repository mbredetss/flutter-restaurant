import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:lottie/lottie.dart';
import '../../entry_point.dart';
import '../../components/buttons/secondery_button.dart';
import '../../components/welcome_text.dart';
import '../../constants.dart';
import '../../services/user_service.dart';
import '../../services/location_service.dart';

class FindRestaurantsScreen extends StatefulWidget {
  const FindRestaurantsScreen({super.key});

  @override
  State<FindRestaurantsScreen> createState() => _FindRestaurantsScreenState();
}

class _FindRestaurantsScreenState extends State<FindRestaurantsScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Find Restaurants"),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const WelcomeText(
                    title: "Find restaurants near you ",
                    text:
                        "Allow access to your location to find restaurants near you.",
                  ),

                  // Getting Current Location
                  SeconderyButton(
                    press: () async {
                      setState(() {
                        _isLoading = true;
                      });

                      try {
                        // Use location service to handle GPS status and get current position
                        Position? position = await LocationService().handleLocationCheck(context);

                        // If position is null, it means user opened settings or refused
                        if (position == null) {
                          setState(() {
                            _isLoading = false;
                          });
                          return;
                        }

                        // Convert coordinates to address
                        List<Placemark> placemarks = await placemarkFromCoordinates(
                          position.latitude,
                          position.longitude,
                        );

                        if (placemarks.isNotEmpty) {
                          String fullAddress = placemarks[0].thoroughfare != null
                              ? '${placemarks[0].thoroughfare}, ${placemarks[0].locality}'
                              : placemarks[0].locality ?? placemarks[0].name ?? 'Unknown Location';

                          // Update user location in service
                          await UserService.instance.updateUserLocation(fullAddress);

                          // Navigate to entry point
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EntryPoint(),
                            ),
                            (_) => true,
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Could not determine your location.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } catch (e) {
                        String errorMessage = e.toString();
                        if (e is String) {
                          errorMessage = e;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(errorMessage),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } finally {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          "assets/icons/location.svg",
                          height: 24,
                          colorFilter: const ColorFilter.mode(
                            primaryColor,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Use current location",
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(color: primaryColor),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: defaultPadding),

                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.7),
              child: Center(
                child: Lottie.asset(
                  'assets/animations/Food.json',
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
