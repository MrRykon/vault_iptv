import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../core/api/api_service.dart';
import '../settings/admin_settings_screen.dart';
import '../settings/vault_settings_screen.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;

  const ProfileScreen({Key? key, required this.initialData}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  late TextEditingController _nameController;
  bool _isLoading = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData['display_name'] ?? '');
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
       setState(() { _selectedImage = File(picked.path); });
       
       setState(() => _isLoading = true);
       String? err = await _apiService.uploadAvatar(_selectedImage!);
       setState(() => _isLoading = false);
       
       if (err == null) {
          if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avatar Upload Complete. Server updated natively.')));
       } else {
          if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hardware Push Failed: $err')));
       }
    }
  }

  void _saveProfile() async {
    setState(() => _isLoading = true);
    // Since we now upload images linearly, editProfile only needs display name overrides natively!
    bool success = await _apiService.editProfile(_nameController.text.trim(), null);
    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile Visuals Overwritten Successfully')));
      Navigator.pop(context);
    }
  }

  void _showChangePasswordDialog() {
    final passwordCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white12)),
          title: const Text('Change Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: TextField(
             controller: passwordCtrl,
             style: const TextStyle(color: Colors.white),
             decoration: const InputDecoration(
                labelText: 'New Secret Password', 
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
             ),
             obscureText: true,
          ),
          actions: [
            TextButton(child: const Text('Cancel', style: TextStyle(color: Colors.grey)), onPressed: () => Navigator.pop(context)),
            ElevatedButton(
               style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
               child: const Text('SECURE NOW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
               onPressed: () async {
                  bool ok = await _apiService.selfChangePassword(passwordCtrl.text);
                  Navigator.pop(context);
                  if (ok && mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vault Access Keys Mutated')));
                  }
               }
            )
          ]
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    String avatarUrl = widget.initialData['avatar_url'] ?? '';
    bool hasAvatar = avatarUrl.isNotEmpty || _selectedImage != null;
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Identity Sandbox', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
             Center(
               child: Stack(
                 alignment: Alignment.bottomRight,
                 children: [
                   Container(
                     decoration: BoxDecoration(
                       shape: BoxShape.circle,
                       border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.5), width: 3),
                       boxShadow: [
                         BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.2), blurRadius: 20, spreadRadius: 5)
                       ]
                     ),
                     child: CircleAvatar(
                       radius: 60,
                       backgroundColor: const Color(0xFF2C2C2E),
                       backgroundImage: _selectedImage != null 
                            ? FileImage(_selectedImage!) as ImageProvider 
                            : (hasAvatar ? NetworkImage(avatarUrl) : null),
                       child: hasAvatar ? null : const Icon(Icons.person, size: 70, color: Colors.white38),
                     ),
                   ),
                   GestureDetector(
                     onTap: _pickAvatar,
                     child: Container(
                       padding: const EdgeInsets.all(8),
                       decoration: const BoxDecoration(
                         color: Colors.amber,
                         shape: BoxShape.circle,
                       ),
                       child: const Icon(Icons.camera_alt, color: Colors.black, size: 24),
                     ),
                   )
                 ],
               ),
             ),
             const SizedBox(height: 40),
             
             Container(
               padding: const EdgeInsets.all(20),
               decoration: BoxDecoration(
                 color: const Color(0xFF1C1C1E),
                 borderRadius: BorderRadius.circular(16),
                 border: Border.all(color: Colors.white10)
               ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.stretch,
                 children: [
                   TextField(
                     controller: _nameController,
                     style: const TextStyle(color: Colors.white),
                     decoration: const InputDecoration(labelText: 'Display Name', prefixIcon: Icon(Icons.badge, color: Colors.grey), labelStyle: TextStyle(color: Colors.grey), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12))),
                   ),
                 ],
               )
             ),
             
             const SizedBox(height: 30),
             
             Container(
               padding: const EdgeInsets.all(20),
               decoration: BoxDecoration(
                 gradient: LinearGradient(colors: [Colors.grey[900]!, Colors.grey[850]!]),
                 borderRadius: BorderRadius.circular(16),
               ),
               child: Column(
                 children: [
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       const Text('Account Structure:', style: TextStyle(color: Colors.grey)),
                       Text(widget.initialData['account_status'].toString().toUpperCase(), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, letterSpacing: 1)),
                     ],
                   ),
                   const Divider(color: Colors.white10, height: 30),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       const Text('Authorization Level:', style: TextStyle(color: Colors.grey)),
                       Text(widget.initialData['profile_type'].toString().toUpperCase(), style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, letterSpacing: 1)),
                     ],
                   ),
                 ]
               ),
             ),
             
             const SizedBox(height: 30),
             
             Row(
               children: [
                 Expanded(
                   child: OutlinedButton.icon(
                     icon: const Icon(Icons.lock_reset, color: Colors.white),
                     label: const Text('CHANGE PASSWORD', style: TextStyle(color: Colors.white)),
                     onPressed: _showChangePasswordDialog,
                     style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(vertical: 16)),
                   ),
                 ),
                 const SizedBox(width: 16),
                 Expanded(
                   child: OutlinedButton.icon(
                     icon: const Icon(Icons.settings, color: Colors.white),
                     label: const Text('SETTINGS', style: TextStyle(color: Colors.white)),
                     onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VaultSettingsScreen())),
                     style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(vertical: 16)),
                   ),
                 ),
               ],
             ),
             
             if (widget.initialData['admin_status'] == true) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                   icon: const Icon(Icons.admin_panel_settings),
                   label: const Text('ADMIN DASHBOARD', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
                   onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminSettingsScreen())),
                   style: ElevatedButton.styleFrom(
                     backgroundColor: Colors.amber,
                     foregroundColor: Colors.black,
                     minimumSize: const Size(double.infinity, 50),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                   ),
                ),
             ],
             
             const SizedBox(height: 30),
             ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text('SAVE IDENTITY OVERRIDES', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2))
             ),
             const SizedBox(height: 16),
             OutlinedButton.icon(
                icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
                label: const Text('DISCONNECT', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 2)),
                style: OutlinedButton.styleFrom(
                   minimumSize: const Size(double.infinity, 55),
                   side: const BorderSide(color: Colors.redAccent, width: 2),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                ),
                onPressed: () async {
                   await _apiService.logout();
                   if (!mounted) return;
                   Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
                }
             ),
             const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
