import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../widgets/deliveryBottomNavBar.dart';
import '../../widgets/input.dart';
import '../../widgets/title.dart';
import '../../../routes.dart';
import '../../../colors.dart';

class DeliveryDriverProfile extends StatefulWidget {
  const DeliveryDriverProfile({super.key});

  @override
  _DeliveryDriverProfileState createState() => _DeliveryDriverProfileState();
}

class _DeliveryDriverProfileState extends State<DeliveryDriverProfile> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  User? _currentUser;
  Map<dynamic, dynamic>? _userData;
  late DatabaseReference _dbRef;

  @override
  void initState() {
    super.initState();
    _dbRef = FirebaseDatabase.instance.ref();
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  @override
  void dispose() {
    _dbRef.onDisconnect();
    super.dispose();
  }

  Future<void> _fetchData() async {
    await _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (_currentUser != null) {
      final snapshot = await _dbRef.child('drivers/${_currentUser!.uid}').get();
      if (snapshot.exists) {
        _userData = snapshot.value as Map<dynamic, dynamic>;
        _nameController.text = _userData?['name'] ?? '';
        _emailController.text = _userData?['email'] ?? '';
        _mobileNumberController.text = _userData?['contact'] ?? '';
      }
    }
  }

  void _editProfile() {
    // Navigate to edit profile page
    Navigator.pushNamed(context, Routes.deliveryDriverEditProfile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _fetchData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const TitleBar(title: 'Profile'),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Stack(
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 50,
                                    child: Icon(
                                      Icons.person,
                                      size: 50,
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                ],
                              ),
                              Positioned(
                                top: 0,
                                right: 70,
                                child: IconButton(
                                  icon: const Icon(Icons.edit, color: AppColors.secondary),
                                  onPressed: _editProfile,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          Input(
                            controller: _nameController,
                            labelText: 'Name',
                            placeholder: 'John Doe',
                            editable: false, // Make it non-editable
                          ),
                          const SizedBox(height: 15),
                          Input(
                            controller: _emailController,
                            labelText: 'Email',
                            placeholder: 'john.doe@gmail.com',
                            editable: false, // Make it non-editable
                          ),
                          const SizedBox(height: 15),
                          Input(
                            controller: _mobileNumberController,
                            labelText: 'Mobile Number',
                            placeholder: '0124567890',
                            editable: false, // Make it non-editable
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
      bottomNavigationBar: const DeliveryBottomNavBar(initialIndex: 2),
    );
  }
}
