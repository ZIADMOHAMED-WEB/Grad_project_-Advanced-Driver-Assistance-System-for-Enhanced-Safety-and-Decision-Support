import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'widgets/responsive_background.dart';

class SettingsScreen extends StatefulWidget {
  static const String routeName = '/settings';

  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _cameraAccessGranted = false; // Added for camera access switch
  // Camera Settings
  String? _selectedCamera = 'front';
  final List<String> _cameras = ['front', 'rear'];
  int? _frameRateLimit = 30;
  final List<int> _frameRates = [15, 30, 60];
  String? _resolution = '720p';
  final List<String> _resolutions = ['480p', '720p', '1080p'];

  // Alert Settings
  bool _enableSoundAlert = true;
  double _alertVolume = 0.7;
  final TextEditingController _alertFrequencyController =
      TextEditingController(text: '10');
  bool _vibrationFeedback = true;

  // User Info Settings - Basic Information
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String? _selectedGender;
  final List<String> _genders = [
    'Male',
    'Female',
    'Other',
    'Prefer not to say'
  ];
  File? _profileImage;

  // User Info Settings - Driving Profile
  final TextEditingController _driverIdController = TextEditingController();
  String? _drivingExperience;
  final List<String> _experiences = ['Beginner', 'Intermediate', 'Expert'];
  String? _preferredDrivingMode;
  final List<String> _drivingModes = ['Normal', 'Drowsy-Prone', 'Night Driver'];

  // User Info Settings - Contact Info
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _emergencyContactNameController =
      TextEditingController();
  final TextEditingController _emergencyContactNumberController =
      TextEditingController();

  // User Info Settings - Preferences
  final TextEditingController _shortBioController = TextEditingController();

  // User Info Settings - Password Update
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController =
      TextEditingController();
  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmNewPasswordVisible = false;

  // General Settings
  String? _selectedLanguage = 'en';
  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'ar', 'name': 'Arabic'},
    // Add more languages as needed
  ];

  // 1. Image picker logic
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  // 2. Password strength indicator
  String _password = '';
  String _confirmPassword = '';
  String _passwordStrength = '';
  Color _strengthColor = Colors.grey;
  void _updatePasswordStrength(String password) {
    setState(() {
      _password = password;
      if (password.length < 6) {
        _passwordStrength = 'Weak';
        _strengthColor = Colors.red;
      } else if (password.length < 10) {
        _passwordStrength = 'Medium';
        _strengthColor = Colors.orange;
      } else {
        _passwordStrength = 'Strong';
        _strengthColor = Colors.green;
      }
    });
  }

  // 3. Password match validation
  String? _passwordError;
  void _validatePasswords() {
    setState(() {
      if (_password != _confirmPassword) {
        _passwordError = 'Passwords do not match';
      } else {
        _passwordError = null;
      }
    });
  }

  // 4. Update profile logic
  void _updateProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Profile updated!')),
    );
  }

  // 5. Update password logic
  void _updatePassword() {
    _validatePasswords();
    if (_passwordError == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password updated!')),
      );
    }
  }

  // 6. Export settings logic
  void _exportSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Settings exported!')),
    );
  }

  // 7. Reset/Delete logic with confirmation dialog
  void _resetOrDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm'),
        content: Text('Are you sure you want to reset/delete your data?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Yes')),
        ],
      ),
    );
    if (!mounted) return;
    if (confirmed == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data reset/deleted!')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _checkCameraPermission();
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.status;
    if (mounted) {
      setState(() {
        _cameraAccessGranted = status.isGranted;
      });
    }
  }

  Future<void> _pickProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      if (mounted) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    }
  }

  Future<void> _handleCameraPermission(bool value) async {
    if (value) {
      final status = await Permission.camera.request();
      if (mounted) {
        setState(() {
          _cameraAccessGranted = status.isGranted;
        });
        if (status.isPermanentlyDenied) {
          openAppSettings();
        }
      }
    } else {
      // This can be tricky. Revoking permission is done in system settings.
      // We can guide the user there.
      openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final isTablet = size.width >= 600 && size.width < 1024;

    return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Settings',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.black,
          elevation: 0,
          automaticallyImplyLeading: false, // To prevent back button to login
        ),
        body: ResponsiveBackground(
          child: Center(
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile
                    ? 20.0
                    : isTablet
                        ? 40.0
                        : 60.0,
                vertical: 20.0,
              ),
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(
                      16.0), // This padding might be reviewed later
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      // User Profile Section
                      Text(
                        'User Profile',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 18 : 22,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: _pickProfileImage,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white24,
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : (_selectedImage != null
                                  ? FileImage(File(_selectedImage!.path))
                                  : null),
                          child:
                              (_profileImage == null && _selectedImage == null)
                                  ? const Icon(Icons.camera_alt,
                                      color: Colors.white70, size: 50)
                                  : null,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _pickProfileImage,
                        child: const Text('Change Profile Picture',
                            style: TextStyle(color: Color(0xFFECA660))),
                      ),
                      const SizedBox(height: 20),
                      Divider(height: 40, thickness: 1, color: Colors.white24),

                      // Camera Settings Section
                      Text(
                        'Camera Settings',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 18 : 22,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      // Select Camera
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Select Camera:',
                              style: TextStyle(color: Colors.white70)),
                          DropdownButton<String>(
                            value: _selectedCamera,
                            dropdownColor: Colors.grey[850],
                            iconEnabledColor: Colors.white70,
                            style: TextStyle(color: Colors.white),
                            items: _cameras.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value,
                                    style: TextStyle(color: Colors.white)),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedCamera = newValue;
                              });
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      // Frame Rate Limit
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Frame Rate Limit (FPS):',
                              style: TextStyle(color: Colors.white70)),
                          DropdownButton<int>(
                            value: _frameRateLimit,
                            dropdownColor: Colors.grey[850],
                            iconEnabledColor: Colors.white70,
                            style: TextStyle(color: Colors.white),
                            items: _frameRates.map((int value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text(value.toString(),
                                    style: TextStyle(color: Colors.white)),
                              );
                            }).toList(),
                            onChanged: (int? newValue) {
                              setState(() {
                                _frameRateLimit = newValue;
                              });
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      // Resolution
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Resolution:',
                              style: TextStyle(color: Colors.white70)),
                          DropdownButton<String>(
                            value: _resolution,
                            dropdownColor: Colors.grey[850],
                            iconEnabledColor: Colors.white70,
                            style: TextStyle(color: Colors.white),
                            items: _resolutions.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value,
                                    style: TextStyle(color: Colors.white)),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _resolution = newValue;
                              });
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      SwitchListTile(
                        title: const Text('Grant Camera Access',
                            style: TextStyle(color: Colors.white)),
                        value: _cameraAccessGranted,
                        activeColor: const Color(0xFFECA660),
                        activeTrackColor: const Color(0xFFECA660)
                            .withAlpha((255 * 0.5).round()),
                        inactiveThumbColor: Colors.grey[400],
                        inactiveTrackColor: Colors.white30,
                        onChanged: _handleCameraPermission,
                      ),
                      SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.photo_camera_outlined,
                              color: Colors.white),
                          label: Text('Open Camera',
                              style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFECA660),
                            padding: EdgeInsets.symmetric(
                                vertical: isMobile ? 12 : 15),
                            textStyle: TextStyle(fontSize: isMobile ? 14 : 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0)),
                          ),
                          onPressed: () {
                            Navigator.pushNamed(context, '/camera');
                          },
                        ),
                      ),
                      SizedBox(height: 20),
                      Divider(height: 40, thickness: 1, color: Colors.white24),

                      // Alert Settings Section
                      Text(
                        'Alert Settings',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 18 : 22,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      // Enable Sound Alert
                      SwitchListTile(
                        title: Text('Enable Sound Alert',
                            style: TextStyle(color: Colors.white)),
                        value: _enableSoundAlert,
                        activeColor: Color(0xFFECA660),
                        activeTrackColor:
                            Color(0xFFECA660).withAlpha((255 * 0.5).round()),
                        inactiveThumbColor: Colors.grey[400],
                        inactiveTrackColor: Colors.white30,
                        onChanged: (bool value) {
                          setState(() {
                            _enableSoundAlert = value;
                          });
                        },
                      ),
                      SizedBox(height: 10),
                      // Alert Volume
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Alert Volume:',
                              style: TextStyle(color: Colors.white70)),
                          Expanded(
                            child: Slider(
                              value: _alertVolume,
                              min: 0.0,
                              max: 1.0,
                              divisions: 10,
                              label:
                                  '${(_alertVolume * 100).toStringAsFixed(0)}%',
                              activeColor: Color(0xFFECA660),
                              inactiveColor: Colors.white30,
                              onChanged: (double value) {
                                setState(() {
                                  _alertVolume = value;
                                });
                              },
                            ),
                          ),
                          Text('${(_alertVolume * 100).toStringAsFixed(0)}%',
                              style: TextStyle(color: Colors.white)),
                        ],
                      ),
                      SizedBox(height: 10),
                      // Alert Frequency
                      TextField(
                        controller: _alertFrequencyController,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Alert Frequency (seconds)',
                          labelStyle: TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.white12,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 10),
                      // Vibration Feedback
                      SwitchListTile(
                        title: Text('Vibration Feedback'),
                        value: _vibrationFeedback,
                        onChanged: (bool value) {
                          setState(() {
                            _vibrationFeedback = value;
                          });
                        },
                      ),
                      Divider(height: 40, thickness: 1, color: Colors.white24),

                      // User Information Section - Basic Information
                      Text(
                        'Basic Information',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 18 : 22,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 15),
                      // Profile Picture Placeholder
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: isMobile ? 40 : 50,
                            backgroundColor: Colors.white24,
                            child: Icon(Icons.person,
                                size: isMobile ? 40 : 50,
                                color: Colors.white70),
                            // backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                          ),
                          SizedBox(width: 20),
                          ElevatedButton.icon(
                            icon: Icon(Icons.camera_alt, color: Colors.white),
                            label: Text('Upload Picture',
                                style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFECA660).withAlpha(204),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 10),
                              textStyle:
                                  TextStyle(fontSize: isMobile ? 12 : 14),
                            ),
                            onPressed: _pickImage,
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      // Full Name
                      TextField(
                        controller: _fullNameController,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          labelStyle: TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.white12,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon:
                              Icon(Icons.person_outline, color: Colors.white70),
                        ),
                      ),
                      SizedBox(height: 15),
                      // Age
                      TextField(
                        controller: _ageController,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Age',
                          labelStyle: TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.white12,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon:
                              Icon(Icons.cake_outlined, color: Colors.white70),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 15),
                      // Gender
                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        hint: Text('Select Gender',
                            style: TextStyle(color: Colors.white70)),
                        dropdownColor: Colors.grey[850],
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Gender',
                          labelStyle: TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.white12,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon:
                              Icon(Icons.wc_outlined, color: Colors.white70),
                        ),
                        items: _genders.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value,
                                style: TextStyle(color: Colors.white)),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedGender = newValue;
                          });
                        },
                      ),
                      SizedBox(height: 20),
                      Divider(height: 40, thickness: 1, color: Colors.white24),

                      // User Information Section - Driving Profile
                      Text(
                        'Driving Profile',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 18 : 22,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 15),
                      // Driver ID / License Number
                      TextField(
                        controller: _driverIdController,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Driver ID / License Number',
                          labelStyle: TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.white12,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon:
                              Icon(Icons.badge_outlined, color: Colors.white70),
                        ),
                      ),
                      SizedBox(height: 15),
                      // Driving Experience
                      DropdownButtonFormField<String>(
                        value: _drivingExperience,
                        hint: Text('Select Experience',
                            style: TextStyle(color: Colors.white70)),
                        dropdownColor: Colors.grey[850],
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Driving Experience',
                          labelStyle: TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.white12,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: Icon(Icons.school_outlined,
                              color: Colors.white70),
                        ),
                        items: _experiences.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value,
                                style: TextStyle(color: Colors.white)),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _drivingExperience = newValue;
                          });
                        },
                      ),
                      SizedBox(height: 15),
                      // Preferred Driving Mode
                      DropdownButtonFormField<String>(
                        value: _preferredDrivingMode,
                        hint: Text('Select Driving Mode',
                            style: TextStyle(color: Colors.white70)),
                        dropdownColor: Colors.grey[850],
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Preferred Driving Mode',
                          labelStyle: TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.white12,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: Icon(Icons.drive_eta_outlined,
                              color: Colors.white70),
                        ),
                        items: _drivingModes.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value,
                                style: TextStyle(color: Colors.white)),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _preferredDrivingMode = newValue;
                          });
                        },
                      ),
                      SizedBox(height: 20),
                      Divider(height: 40, thickness: 1, color: Colors.white24),

                      // User Information Section - Contact Info
                      Text(
                        'Contact Information (Optional)',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 18 : 22,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 15),
                      // Phone Number
                      TextField(
                        controller: _phoneNumberController,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          labelStyle: TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.white12,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon:
                              Icon(Icons.phone_outlined, color: Colors.white70),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      SizedBox(height: 15),
                      // Emergency Contact Name
                      TextField(
                        controller: _emergencyContactNameController,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Emergency Contact Name',
                          labelStyle: TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.white12,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: Icon(Icons.person_pin_circle_outlined,
                              color: Colors.white70),
                        ),
                      ),
                      SizedBox(height: 15),
                      // Emergency Contact Number
                      TextField(
                        controller: _emergencyContactNumberController,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Emergency Contact Number',
                          labelStyle: TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.white12,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: Icon(Icons.contact_phone_outlined,
                              color: Colors.white70),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      SizedBox(height: 20),
                      Divider(height: 40, thickness: 1, color: Colors.white24),

                      // User Information Section - Preferences
                      Text(
                        'Preferences',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 18 : 22,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 15),
                      // Short Bio or Notes
                      TextField(
                        controller: _shortBioController,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Short Bio / Notes',
                          labelStyle: TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.white12,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: Icon(Icons.note_alt_outlined,
                              color: Colors.white70),
                        ),
                        maxLines: 3,
                        textInputAction: TextInputAction.newline,
                      ),
                      SizedBox(height: 20),
                      Divider(height: 40, thickness: 1, color: Colors.white24),

                      // User Information Section - Password Update
                      Text(
                        'Update Password',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 18 : 22,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 15),
                      // Current Password
                      TextField(
                        controller: _currentPasswordController,
                        obscureText: !_isCurrentPasswordVisible,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Current Password',
                          labelStyle: TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.white12,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon:
                              Icon(Icons.lock_outline, color: Colors.white70),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isCurrentPasswordVisible
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() {
                                _isCurrentPasswordVisible =
                                    !_isCurrentPasswordVisible;
                              });
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 15),
                      // New Password
                      TextField(
                        controller: _newPasswordController,
                        obscureText: !_isNewPasswordVisible,
                        style: TextStyle(color: Colors.white),
                        onChanged: (val) {
                          _updatePasswordStrength(val);
                          _validatePasswords();
                        },
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          labelStyle: TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.white12,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon:
                              Icon(Icons.lock_outline, color: Colors.white70),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isNewPasswordVisible
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() {
                                _isNewPasswordVisible = !_isNewPasswordVisible;
                              });
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 15),
                      // Password strength indicator
                      if (_passwordStrength.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _strengthColor,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(_passwordStrength,
                                  style: TextStyle(color: _strengthColor)),
                            ],
                          ),
                        ),
                      // Confirm New Password
                      TextField(
                        controller: _confirmNewPasswordController,
                        obscureText: !_isConfirmNewPasswordVisible,
                        style: TextStyle(color: Colors.white),
                        onChanged: (val) {
                          _confirmPassword = val;
                          _validatePasswords();
                        },
                        decoration: InputDecoration(
                          labelText: 'Confirm New Password',
                          labelStyle: TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.white12,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon:
                              Icon(Icons.lock_outline, color: Colors.white70),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isConfirmNewPasswordVisible
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() {
                                _isConfirmNewPasswordVisible =
                                    !_isConfirmNewPasswordVisible;
                              });
                            },
                          ),
                          errorText: _passwordError,
                        ),
                      ),
                      SizedBox(height: 20),
                      Divider(height: 40, thickness: 1, color: Colors.white24),

                      // User Information Section - Actions
                      Text(
                        'Actions',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 18 : 22,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 20),
                      // Update Profile Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.save_alt_outlined,
                              color: Colors.white),
                          label: Text('Update Profile',
                              style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFECA660),
                            padding: EdgeInsets.symmetric(
                                vertical: isMobile ? 12 : 15),
                            textStyle: TextStyle(fontSize: isMobile ? 14 : 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0)),
                          ),
                          onPressed: _updateProfile,
                        ),
                      ),
                      SizedBox(height: 15),
                      // Update Password Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.password_outlined,
                              color: Colors.white),
                          label: Text('Update Password',
                              style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFECA660),
                            padding: EdgeInsets.symmetric(
                                vertical: isMobile ? 12 : 15),
                            textStyle: TextStyle(fontSize: isMobile ? 14 : 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0)),
                          ),
                          onPressed: _updatePassword,
                        ),
                      ),
                      SizedBox(height: 15),
                      // Export Settings Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.download_outlined,
                              color: Colors.white70),
                          label: Text('Export Settings as JSON',
                              style: TextStyle(color: Colors.white70)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey[700],
                            padding: EdgeInsets.symmetric(
                                vertical: isMobile ? 12 : 15),
                            textStyle: TextStyle(fontSize: isMobile ? 14 : 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0)),
                          ),
                          onPressed: _exportSettings,
                        ),
                      ),
                      SizedBox(height: 15),
                      // Reset Info / Delete Account Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.delete_forever_outlined,
                              color: Colors.white),
                          label: Text('Reset All Info / Delete Account',
                              style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent[700],
                            padding: EdgeInsets.symmetric(
                                vertical: isMobile ? 12 : 15),
                            textStyle: TextStyle(fontSize: isMobile ? 14 : 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0)),
                          ),
                          onPressed: _resetOrDelete,
                        ),
                      ),
                      SizedBox(height: 20),
                      Divider(height: 40, thickness: 1, color: Colors.white24),

                      // General Settings Section
                      Text(
                        'General Settings',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 18 : 22,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      // Language Selection
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Language:',
                              style: TextStyle(color: Colors.white70)),
                          DropdownButton<String>(
                            value: _selectedLanguage,
                            dropdownColor: Colors.grey[850],
                            iconEnabledColor: Colors.white70,
                            style: const TextStyle(color: Colors.white),
                            items: _languages.map((Map<String, String> lang) {
                              return DropdownMenuItem<String>(
                                value: lang['code'],
                                child: Text(lang['name']!,
                                    style:
                                        const TextStyle(color: Colors.white)),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedLanguage = newValue;
                                // Note: Full localization requires app-wide state management.
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Reset to Defaults Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white, // Ensure text is white
                          padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 20 : 30,
                              vertical: isMobile ? 12 : 15),
                          textStyle: TextStyle(fontSize: isMobile ? 14 : 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0)),
                        ),
                        onPressed: () {
                          setState(() {
                            // Reset Camera Settings
                            _selectedCamera = 'front';
                            _frameRateLimit = 30;
                            _resolution = '720p';
                            // Reset Alert Settings
                            _enableSoundAlert = true;
                            _alertVolume = 0.7;
                            _alertFrequencyController.text = '10';
                            _vibrationFeedback = true;
                            // Reset User Info - Basic Information
                            _fullNameController.clear();
                            _ageController.clear();
                            _selectedGender = null;
                            // _profileImageSet = false; // Or reset image path

                            // Reset User Info - Driving Profile
                            _driverIdController.clear();
                            _drivingExperience = null;
                            _preferredDrivingMode = null;

                            // Reset User Info - Contact Info
                            _phoneNumberController.clear();
                            _emergencyContactNameController.clear();
                            _emergencyContactNumberController.clear();

                            // Reset User Info - Preferences
                            _shortBioController.clear();

                            // Reset User Info - Password Update
                            _currentPasswordController.clear();
                            _newPasswordController.clear();
                            _confirmNewPasswordController.clear();
                            _isCurrentPasswordVisible = false;
                            _isNewPasswordVisible = false;
                            _isConfirmNewPasswordVisible = false;
                            // Reset General Settings
                            _selectedLanguage = 'en';

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'All settings have been reset to defaults.')),
                            );
                          });
                        }, // Correctly closes onPressed and adds a comma
                        child: const Text('Reset to Defaults'),
                      ), // Closes ElevatedButton, comma added assuming it's in a list
                      const SizedBox(
                          height: 20), // Add some spacing at the bottom
                    ],
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
