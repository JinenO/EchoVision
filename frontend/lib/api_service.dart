import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // Use 10.0.2.2 if using Android Emulator, or your local IP for real device
  // Change it from 10.0.2.2 to 127.0.0.1
  static const String baseUrl = "http://127.0.0.1:8000";

  // --- NEW: A place to hold your token while the app is open ---
  static String? currentToken;
  
  static Future<bool> register({
    required String email,
    required String password,
    required String username,
    required String gender,
    String? birthday,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/users/register"), // Ensure this matches your prefix
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
        "username": username,
        "gender": gender,
        "birthday": birthday,
      }),
    );

    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<bool> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(
              "$baseUrl/users/verify",
            ), // Points to your FastAPI verify endpoint
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"email": email, "code": code}),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print("API Verification Error: $e");
      return false;
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/users/login"),
            // Notice we do NOT use application/json here
            headers: {"Content-Type": "application/x-www-form-urlencoded"},
            // Notice we do NOT use jsonEncode here, and the key MUST be 'username'
            body: {"username": email, "password": password},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {"success": true, "token": data["access_token"]};
      } else if (response.statusCode == 403) {
        // HTTP 403 means the email is unverified based on your backend logic
        return {"success": false, "error": "unverified"};
      } else {
        // HTTP 401 means wrong email/password
        return {"success": false, "error": "invalid"};
      }
    } catch (e) {
      print("Login API Error: $e");
      return {"success": false, "error": "network"};
    }
  }

  // --- NEW: Fetch the Profile Data ---
  static Future<Map<String, dynamic>?> getUserProfile() async {
    if (currentToken == null) return null; // Can't fetch without a token!

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/users/me"), // Your backend endpoint
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $currentToken", // Presenting the token to the Security Guard
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("Failed to fetch profile: ${response.body}");
        return null;
      }
    } catch (e) {
      print("API Fetch Error: $e");
      return null;
    }
  }

  // --- NEW: Update Text Data ---
  static Future<bool> updateProfile({
    String? username,
    String? birthday,
    String? gender,
  }) async {
    if (currentToken == null) return false;
    try {
      final response = await http
          .put(
            Uri.parse("$baseUrl/users/me"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $currentToken",
            },
            body: jsonEncode({
              "username": username,
              "birthday": birthday,
              "gender": gender,
            }),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print("Update Profile Error: $e");
      return false;
    }
  }

  // --- NEW: Upload Image File (Accepts Original too) ---
  static Future<bool> uploadProfilePicture(
    File croppedImage, [
    File? originalImage,
  ]) async {
    if (currentToken == null) return false;
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/users/me/upload-profile-picture"),
      );
      request.headers.addAll({"Authorization": "Bearer $currentToken"});

      // 1. Attach the small cropped file
      request.files.add(
        await http.MultipartFile.fromPath('file', croppedImage.path),
      );

      // 2. Attach the MASSIVE original file (if it exists)
      if (originalImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'original_file',
            originalImage.path,
          ),
        );
      }

      var streamedResponse = await request.send();
      return streamedResponse.statusCode == 200;
    } catch (e) {
      print("Upload Image Error: $e");
      return false;
    }
  }

  // --- Request Password Reset Code ---
  static Future<bool> requestPasswordReset(String email) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/users/forgot-password"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"email": email}),
          )
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      print("Forgot Password Error: $e");
      return false;
    }
  }

  // --- Submit Code and New Password ---
  static Future<bool> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/users/reset-password"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "email": email,
              "code": code,
              "new_password": newPassword,
            }),
          )
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      print("Reset Password Error: $e");
      return false;
    }
  }

  // --- NEW: Logged-in Change Password ---
  static Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    if (currentToken == null) return false;
    try {
      final response = await http
          .put(
            Uri.parse("$baseUrl/users/me/password"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $currentToken",
            },
            body: jsonEncode({
              "current_password": currentPassword,
              "new_password": newPassword,
            }),
          )
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      print("Change Password Error: $e");
      return false;
    }
  }

  // --- NEW: Verify Code BEFORE Resetting ---
  static Future<bool> verifyResetCode(String email, String code) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/users/verify-reset-code"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"email": email, "code": code}),
          )
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      print("Verify Code Error: $e");
      return false;
    }
  }

  // --- NEW: Check Current Password Before Unlocking ---
  static Future<bool> verifyCurrentPassword(String currentPassword) async {
    if (currentToken == null) return false;
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/users/me/verify-password"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $currentToken",
            },
            body: jsonEncode({"current_password": currentPassword}),
          )
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      print("Verify Current Password Error: $e");
      return false;
    }
  }
}
