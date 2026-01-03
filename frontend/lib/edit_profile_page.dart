import 'dart:io'; // <--- NEEDED FOR FILE HANDLING
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart'; // <--- THE NEW PACKAGE
import 'package:intl/intl.dart';
import 'widgets.dart';
import 'verification_page.dart';
import 'reset_password_page.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _usernameController = TextEditingController(
    text: "EchoUser",
  );
  final TextEditingController _birthdayController = TextEditingController(
    text: "20/07/2002",
  );
  String? _selectedGender = "Male";
  final List<String> _genderOptions = ["Male", "Female", "Prefer not to say"];

  // --- NEW IMAGE PICKER VARIABLES ---
  File? _imageFile; // Will hold the picked image file
  final ImagePicker _picker = ImagePicker();

  // --- FUNCTION 1: Show Camera/Gallery Options ---
  void _showPickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bc) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFF2C3E50), width: 2),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Color(0xFF2C3E50),
                ),
                title: Text(
                  'Photo Library',
                  style: GoogleFonts.patrickHand(fontSize: 20),
                ),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF2C3E50)),
                title: Text(
                  'Camera',
                  style: GoogleFonts.patrickHand(fontSize: 20),
                ),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --- FUNCTION 2: Actual Picking Logic ---
  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path); // Update state to show new image
      });
    }
  }

  // --- FUNCTION 3: Date Picker (Existing) ---
  Future<void> _selectDate(BuildContext context) async {
    DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2002, 7, 20),
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2C3E50),
              onPrimary: Colors.white,
              onSurface: Color(0xFF2C3E50),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _birthdayController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Edit Profile",
          style: GoogleFonts.patrickHand(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2C3E50),
          ),
        ),
        centerTitle: true,
        shape: const Border(
          bottom: BorderSide(color: Color(0xFF2C3E50), width: 2.0),
        ),
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. PROFILE PICTURE (CLICKABLE) ---
              Center(
                child: GestureDetector(
                  onTap: () => _showPickerOptions(context), // <--- Trigger Menu
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF2C3E50),
                            width: 3,
                          ),
                        ),
                        child: ClipOval(
                          // --- THE SWITCHING LOGIC ---
                          child: _imageFile == null
                              ? Transform.scale(
                                  // Show default asset
                                  scale: 1.3,
                                  child: Image.asset(
                                    'assets/images/profile.png',
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Image.file(
                                  // Show picked file
                                  _imageFile!,
                                  fit: BoxFit.cover,
                                  width: 120,
                                  height: 120,
                                ),
                        ),
                      ),
                      // Camera Icon Overlay
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5BC0EB),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // --- 2. USERNAME ---
              const _Label("Username"),
              SketchyTextField(
                hintText: "Username",
                controller: _usernameController,
              ),
              const SizedBox(height: 20),

              // --- 3. BIRTHDAY ---
              const _Label("Birthday"),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: SketchyTextField(
                    hintText: "DD/MM/YYYY",
                    controller: _birthdayController,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- 4. GENDER ---
              const _Label("Gender"),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: const Color(0xFF2C3E50),
                    width: 2.0,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      offset: Offset(2, 2),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedGender,
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Color(0xFF2C3E50),
                    ),
                    iconSize: 30,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    style: GoogleFonts.patrickHand(
                      fontSize: 20,
                      color: const Color(0xFF2C3E50),
                    ),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedGender = newValue!;
                      });
                    },
                    items: _genderOptions.map<DropdownMenuItem<String>>((
                      String value,
                    ) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 30),
              const Divider(color: Color(0xFF2C3E50), thickness: 1),
              const SizedBox(height: 10),

              // --- 5. CHANGE PASSWORD ---
              const _Label("Security"),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VerificationPage(
                        email: "echo@cat.com",
                        targetPage: ResetPasswordPage(),
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F7F1),
                    border: Border.all(
                      color: const Color(0xFF2C3E50),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Change Password",
                        style: TextStyle(
                          fontSize: 20,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                        color: Color(0xFF2C3E50),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // --- 6. SAVE BUTTON ---
              SizedBox(
                width: double.infinity,
                child: SketchyButton(
                  text: "Save Changes",
                  isPrimary: true,
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Colors.green,
                        content: Text(
                          "Profile Updated!",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        text,
        style: GoogleFonts.patrickHand(fontSize: 18, color: Colors.grey[600]),
      ),
    );
  }
}
