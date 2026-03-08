import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'widgets.dart';
import 'change_password_page.dart';
import 'api_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();

  String? _selectedGender;
  final List<String> _genderOptions = [
    "Male",
    "Female",
    "Other",
    "Prefer not to say",
  ];

  String _currentEmail = "";
  String _networkProfilePic = "default_avatar.png";
  DateTime? _selectedDate;
  bool _isLoading = true;

  File? _imageFile; // The small, cropped square
  File? _originalImageFile; // NEW: The massive, uncropped original

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    final data = await ApiService.getUserProfile();

    if (data != null && mounted) {
      setState(() {
        _usernameController.text = data["username"] ?? "";
        _currentEmail = data["email"] ?? "";
        _networkProfilePic = data["profile_picture"] ?? "default_avatar.png";

        if (_genderOptions.contains(data["gender"])) {
          _selectedGender = data["gender"];
        }

        if (data["birthday"] != null) {
          try {
            _selectedDate = DateTime.parse(data["birthday"].toString());
            _birthdayController.text = DateFormat(
              'dd/MM/yyyy',
            ).format(_selectedDate!);
          } catch (e) {
            print("Date Parse Error: $e");
          }
        }
        _isLoading = false;
      });
    }
  }

  void _showFullImage() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withOpacity(0.9),
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: _imageFile != null
                      ? Image.file(_imageFile!, fit: BoxFit.contain)
                      : _networkProfilePic == "default_avatar.png"
                      ? Image.asset(
                          'assets/images/profile.png',
                          fit: BoxFit.contain,
                        )
                      : Image.network(
                          _networkProfilePic,
                          fit: BoxFit.contain,
                          errorBuilder: (c, e, s) => Image.asset(
                            'assets/images/profile.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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
                leading: const Icon(Icons.crop, color: Color(0xFF2C3E50)),
                title: Text(
                  'Adjust Crop Area',
                  style: GoogleFonts.patrickHand(fontSize: 20),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _cropCurrentPicture();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Color(0xFF2C3E50),
                ),
                title: Text(
                  'Choose New from Library',
                  style: GoogleFonts.patrickHand(fontSize: 20),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickAndCropImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF2C3E50)),
                title: Text(
                  'Take New Photo',
                  style: GoogleFonts.patrickHand(fontSize: 20),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickAndCropImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --- DOWNLOAD ORIGINAL IMAGE LOGIC ---
  Future<void> _cropCurrentPicture() async {
    String? pathToCrop;

    if (_originalImageFile != null) {
      // They just picked a new file and want to adjust it again
      pathToCrop = _originalImageFile!.path;
    } else if (_networkProfilePic != "default_avatar.png") {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      try {
        // MAGIC TRICK: Guess the original URL by adding "_original" before the .png/.jpg
        int dotIndex = _networkProfilePic.lastIndexOf('.');
        String originalUrl =
            _networkProfilePic.substring(0, dotIndex) +
            "_original" +
            _networkProfilePic.substring(dotIndex);

        // Download the original image
        final response = await http.get(Uri.parse(originalUrl));

        if (response.statusCode == 200) {
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/temp_original_crop.png');
          file.writeAsBytesSync(response.bodyBytes);

          _originalImageFile = file; // Save it so we can re-upload it
          pathToCrop = file.path;
        } else {
          // Fallback just in case the backend doesn't have the original yet
          final fallbackResponse = await http.get(
            Uri.parse(_networkProfilePic),
          );
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/temp_fallback_crop.png');
          file.writeAsBytesSync(fallbackResponse.bodyBytes);
          pathToCrop = file.path;
        }

        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text("Failed to load original picture."),
          ),
        );
        return;
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("Cannot crop the default cartoon avatar!"),
        ),
      );
      return;
    }

    if (pathToCrop != null) {
      _openCropper(pathToCrop);
    }
  }

  // --- PICK NEW IMAGE LOGIC ---
  Future<void> _pickAndCropImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      // Save the uncropped original so we can upload it later!
      _originalImageFile = File(pickedFile.path);
      _openCropper(pickedFile.path);
    }
  }

  Future<void> _openCropper(String filePath) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: filePath,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Position Profile Picture',
          toolbarColor: const Color(0xFF2C3E50),
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          hideBottomControls: false,
        ),
        IOSUiSettings(
          title: 'Position Profile Picture',
          aspectRatioLockEnabled: true,
        ),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        _imageFile = File(croppedFile.path); // Save the tiny cropped square
      });
    }
  }

  Future<void> _selectDateWidget(BuildContext context) async {
    DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
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
        _selectedDate = picked;
        _birthdayController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  void _handleSave() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    bool textSuccess = true;
    bool imageSuccess = true;

    String? formattedDate;
    if (_selectedDate != null) {
      formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    }

    textSuccess = await ApiService.updateProfile(
      username: _usernameController.text.trim(),
      birthday: formattedDate,
      gender: _selectedGender,
    );

    if (_imageFile != null) {
      // Pass BOTH the tiny cropped image AND the massive original image to the API
      imageSuccess = await ApiService.uploadProfilePicture(
        _imageFile!,
        _originalImageFile,
      );
    }

    if (mounted) Navigator.pop(context);

    if (textSuccess && imageSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            "Profile Updated!",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("Failed to update profile."),
        ),
      );
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- 1. PROFILE PICTURE ---
                    Center(
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: _showFullImage,
                            child: Container(
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
                                child: _imageFile != null
                                    ? Image.file(
                                        _imageFile!,
                                        fit: BoxFit.cover,
                                        width: 120,
                                        height: 120,
                                      )
                                    : _networkProfilePic == "default_avatar.png"
                                    ? Transform.scale(
                                        scale: 1.3,
                                        child: Image.asset(
                                          'assets/images/profile.png',
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Image.network(
                                        _networkProfilePic,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => Image.asset(
                                          'assets/images/profile.png',
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                              ),
                            ),
                          ),

                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => _showPickerOptions(context),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF5BC0EB),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
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
                      onTap: () => _selectDateWidget(context),
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
                          onChanged: (String? newValue) =>
                              setState(() => _selectedGender = newValue!),
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

                    // --- 5. SECURITY ---
                    const _Label("Security"),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChangePasswordPage(),
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
                        onTap: _handleSave,
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
