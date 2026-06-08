import 'package:flutter/material.dart';
import '../../core/api/api_service.dart';
import 'dart:ui';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({Key? key}) : super(key: key);

  @override
  _AdminSettingsScreenState createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  void _fetchUsers() async {
    setState(() => _isLoading = true);
    final data = await _apiService.getUsers();
    if(data != null) {
      if(mounted) setState(() { users = data; _isLoading = false; });
    }
  }

  void _showCreateUserDialog() {
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    String profileType = 'standard';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1C1C1E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white12)),
              title: const Text('Synthesize New User', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: usernameCtrl, decoration: const InputDecoration(labelText: 'Core Custom Login ID', labelStyle: TextStyle(color: Colors.grey)), style: const TextStyle(color: Colors.white)),
                  TextField(controller: passwordCtrl, decoration: const InputDecoration(labelText: 'Vault Password String', labelStyle: TextStyle(color: Colors.grey)), style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 20),
                  DropdownButton<String>(
                    value: profileType,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF333333),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    items: const [
                      DropdownMenuItem(value: 'standard', child: Text('Standard Authority')),
                      DropdownMenuItem(value: 'kids', child: Text('Kids (Walled Garden)')),
                    ],
                    onChanged: (val) {
                      setModalState(() => profileType = val!);
                    },
                  )
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
                  onPressed: () async {
                    bool ok = await _apiService.createUser(usernameCtrl.text, passwordCtrl.text, profileType);
                    Navigator.pop(context);
                    if (ok) _fetchUsers();
                  },
                  child: const Text('INITIALIZE', style: TextStyle(fontWeight: FontWeight.bold)),
                )
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
           SliverAppBar(
              expandedHeight: 180.0,
              floating: false,
              pinned: true,
              backgroundColor: Colors.black,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text('VAULT SENTINEL', style: TextStyle(letterSpacing: 4, fontWeight: FontWeight.bold, color: Colors.amber)),
                background: Stack(
                   fit: StackFit.expand,
                   children: [
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.deepPurple, Colors.black],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter
                          )
                        )
                      ),
                      Positioned(
                         right: -50,
                         top: -50,
                         child: Icon(Icons.admin_panel_settings, size: 250, color: Colors.white.withOpacity(0.05)),
                      )
                   ]
                ),
              ),
           ),
           if (_isLoading)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Colors.amber)))
           else
              SliverPadding(
                 padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                 sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                       (context, index) {
                          final u = users[index];
                          return Padding(
                             padding: const EdgeInsets.only(bottom: 16.0),
                             child: VaultAdminUserCard(
                                userMap: u,
                                apiService: _apiService,
                                onActionComplete: _fetchUsers,
                             ),
                          );
                       },
                       childCount: users.length,
                    )
                 )
              )
        ]
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'spawnUserBtn',
            onPressed: _showCreateUserDialog,
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
            icon: const Icon(Icons.add_moderator),
            label: const Text('SPAWN USER', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'sendNoteBtn',
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const GlobalNotificationSenderScreen()));
            },
            backgroundColor: Colors.cyanAccent,
            foregroundColor: Colors.black,
            icon: const Icon(Icons.campaign),
            label: const Text('BROADCAST NOTIFICATION', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
          )
        ]
      )
    );
  }
}

class GlobalNotificationSenderScreen extends StatefulWidget {
   const GlobalNotificationSenderScreen({Key? key}) : super(key: key);
   @override
   _GlobalNotificationSenderScreenState createState() => _GlobalNotificationSenderScreenState();
}

class _GlobalNotificationSenderScreenState extends State<GlobalNotificationSenderScreen> {
   final ApiService _apiService = ApiService();
   final _subjectCtrl = TextEditingController();
   final _contentCtrl = TextEditingController();
   bool _isSending = false;

   void _transmit() async {
       if (_subjectCtrl.text.trim().isEmpty || _contentCtrl.text.trim().isEmpty) return;
       setState(() => _isSending = true);
       bool ok = await _apiService.sendGlobalNotification(_subjectCtrl.text.trim(), _contentCtrl.text.trim());
       setState(() => _isSending = false);
       if (ok) {
           if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Global Notice Broadcasted successfully.')));
               Navigator.pop(context);
           }
       }
   }

   @override
   Widget build(BuildContext context) {
       return Scaffold(
           backgroundColor: Colors.black,
           appBar: AppBar(title: const Text('COMPOSE BROADCAST', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent, letterSpacing: 2)), backgroundColor: Colors.transparent, iconTheme: const IconThemeData(color: Colors.cyanAccent)),
           body: Padding(
               padding: const EdgeInsets.all(24),
               child: Column(
                   crossAxisAlignment: CrossAxisAlignment.stretch,
                   children: [
                        TextField(
                           controller: _subjectCtrl,
                           style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                           decoration: InputDecoration(
                               hintText: "Notification Subject",
                               hintStyle: const TextStyle(color: Colors.white54),
                               filled: true, fillColor: const Color(0xFF151515),
                               border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                           )
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                            child: TextField(
                               controller: _contentCtrl,
                               maxLines: null,
                               expands: true,
                               textAlignVertical: TextAlignVertical.top,
                               style: const TextStyle(color: Colors.white70, fontSize: 16),
                               decoration: InputDecoration(
                                   hintText: "Write your message to all users...",
                                   hintStyle: const TextStyle(color: Colors.white24),
                                   filled: true, fillColor: const Color(0xFF151515),
                                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                               )
                            )
                        ),
                        const SizedBox(height: 24),
                        Row(
                           children: [
                               Expanded(child: TextButton(onPressed: () => Navigator.pop(context), style: TextButton.styleFrom(backgroundColor: Colors.white10, padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text('DISCARD', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)))),
                               const SizedBox(width: 16),
                               Expanded(flex: 2, child: ElevatedButton(
                                   style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, padding: const EdgeInsets.symmetric(vertical: 16)),
                                   onPressed: _isSending ? null : _transmit,
                                   child: _isSending ? const CircularProgressIndicator(color: Colors.black) : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.send, color: Colors.black), SizedBox(width: 8), Text('TRANSMIT GLOBAL', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))])
                               ))
                           ]
                        )
                   ]
               )
           )
       );
   }
}

class VaultAdminUserCard extends StatefulWidget {
  final Map<String, dynamic> userMap;
  final ApiService apiService;
  final VoidCallback onActionComplete;

  const VaultAdminUserCard({Key? key, required this.userMap, required this.apiService, required this.onActionComplete}) : super(key: key);

  @override
  _VaultAdminUserCardState createState() => _VaultAdminUserCardState();
}

class _VaultAdminUserCardState extends State<VaultAdminUserCard> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  void _toggleUserStatus() async {
     String action = widget.userMap['account_status'] == 'active' ? 'suspend' : 'activate';
     bool ok = await widget.apiService.toggleSuspension(widget.userMap['id'], action);
     if(ok) widget.onActionComplete();
  }

  void _deleteUser() async {
     showDialog(
       context: context, 
       builder: (_) => AlertDialog(
         backgroundColor: const Color(0xFF2C1C1E),
         title: const Text('Aggressive Account Eradication', style: TextStyle(color: Colors.redAccent)),
         content: Text('WARNING: This permanently drops [' + widget.userMap['custom_username'] + '] and eradicates all cascading watch histories. Proceed?', style: const TextStyle(color: Colors.white)),
         actions: [
           TextButton(child: const Text('CANCEL', style: TextStyle(color: Colors.grey)), onPressed: () => Navigator.pop(context)),
           ElevatedButton(
             style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
             child: const Text('DROP TABLE ROW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
             onPressed: () async {
               Navigator.pop(context);
               bool ok = await widget.apiService.deleteUser(widget.userMap['id']);
               if(ok) widget.onActionComplete();
             }
           )
         ]
       )
     );
  }

  void _showExpirationDialog() {
     final daysCtrl = TextEditingController();
     
     showDialog(
       context: context,
       builder: (context) {
         return Dialog(
           backgroundColor: Colors.transparent,
           child: Container(
             padding: const EdgeInsets.all(24),
             decoration: BoxDecoration(
               color: const Color(0xFF151515),
               borderRadius: BorderRadius.circular(24),
               border: Border.all(color: Colors.white24, width: 1.5)
             ),
             child: Column(
               mainAxisSize: MainAxisSize.min,
               children: [
                 const Icon(Icons.timer, size: 60, color: Colors.blueAccent),
                 const SizedBox(height: 16),
                 const Text('Set Expiration Protocol', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                 const SizedBox(height: 8),
                 Text('Targeting Login: ' + widget.userMap['custom_username'], style: const TextStyle(color: Colors.grey)),
                 const SizedBox(height: 24),
                 TextField(
                    controller: daysCtrl, 
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.blueAccent, fontSize: 18, letterSpacing: 2),
                    cursorColor: Colors.blueAccent,
                    decoration: const InputDecoration(
                      labelText: 'Days until Access Expiration', 
                      hintText: 'Leave empty to unlock perpetually',
                      hintStyle: TextStyle(color: Colors.white30, fontSize: 12),
                      labelStyle: TextStyle(color: Colors.white54, letterSpacing: 0),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
                    ), 
                 ),
                 const SizedBox(height: 30),
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     TextButton(onPressed: () => Navigator.pop(context), child: const Text('ABORT', style: TextStyle(color: Colors.grey))),
                     ElevatedButton(
                       style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                       onPressed: () async {
                         int? daysVal = int.tryParse(daysCtrl.text.trim());
                         bool ok = await widget.apiService.setExpirationDays(widget.userMap['id'], daysVal);
                         Navigator.pop(context);
                         if (ok) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Time constraints actively mapped.')));
                            widget.onActionComplete();
                         }
                       },
                       child: const Text('EXECUTE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
                     )
                   ]
                 )
               ]
             )
           )
         );
       }
     );
  }

  void _showResetPasswordDialog() {
     final passwordCtrl = TextEditingController();
     showDialog(
       context: context,
       builder: (context) {
         return Dialog(
           backgroundColor: Colors.transparent,
           child: Container(
             padding: const EdgeInsets.all(24),
             decoration: BoxDecoration(
               color: const Color(0xFF151515),
               borderRadius: BorderRadius.circular(24),
               border: Border.all(color: Colors.white24, width: 1.5)
             ),
             child: Column(
               mainAxisSize: MainAxisSize.min,
               children: [
                 const Icon(Icons.lock_reset, size: 60, color: Colors.amber),
                 const SizedBox(height: 16),
                 const Text('Override Password Lock', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                 const SizedBox(height: 8),
                 Text('Targeting Login: ' + widget.userMap['custom_username'], style: const TextStyle(color: Colors.grey)),
                 const SizedBox(height: 24),
                 TextField(
                    controller: passwordCtrl, 
                    style: const TextStyle(color: Colors.amber, fontSize: 18, letterSpacing: 2),
                    cursorColor: Colors.amber,
                    decoration: const InputDecoration(
                      labelText: 'New Encryption Lock', 
                      labelStyle: TextStyle(color: Colors.white54, letterSpacing: 0),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
                    ), 
                 ),
                 const SizedBox(height: 30),
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     TextButton(onPressed: () => Navigator.pop(context), child: const Text('ABORT', style: TextStyle(color: Colors.grey))),
                     ElevatedButton(
                       style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                       onPressed: () async {
                         bool ok = await widget.apiService.resetPassword(widget.userMap['id'], passwordCtrl.text);
                         Navigator.pop(context);
                         if (ok) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password Hard-Reset Executed')));
                            widget.onActionComplete();
                         }
                       },
                       child: const Text('OVERWRITE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
                     )
                   ]
                 )
               ]
             )
           )
         );
       }
     );
  }

  void _showChangeUsernameDialog() {
     final usernameCtrl = TextEditingController(text: widget.userMap['custom_username']);
     showDialog(
       context: context,
       builder: (context) {
         return AlertDialog(
           backgroundColor: const Color(0xFF1C1C1E),
           title: const Text('Re-map Base Login Identifier', style: TextStyle(color: Colors.white, fontSize: 16)),
           content: TextField(
              controller: usernameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'New Core Custom Username', labelStyle: TextStyle(color: Colors.grey)),
           ),
           actions: [
             TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
             ElevatedButton(
                child: const Text('CONFIRM MAPPING'),
                onPressed: () async {
                   bool ok = await widget.apiService.adminChangeUsername(widget.userMap['id'], usernameCtrl.text.trim());
                   Navigator.pop(context);
                   if (ok) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Base network user string overridden')));
                      widget.onActionComplete();
                   } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Username natively rejected')));
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
      final bool isAdmin = widget.userMap['admin_status'] == true;
      final bool isActive = widget.userMap['account_status'] == 'active';
      final String expirationRaw = widget.userMap['access_expires_at'] ?? '';
      
      bool isExpired = false;
      String expirationText = '♾️ Perpetual Access';
      
      if (expirationRaw.isNotEmpty) {
          DateTime expDate = DateTime.parse(expirationRaw).toLocal();
          if (expDate.isBefore(DateTime.now())) {
              isExpired = true;
              expirationText = '❌ Expired: ${expDate.toString().substring(0, 16)}';
          } else {
              expirationText = '⏳ Expires: ${expDate.toString().substring(0, 16)}';
          }
      }

      return GestureDetector(
         onTap: () {
            setState(() { _isExpanded = !_isExpanded; });
         },
         child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isAdmin ? Colors.amber.withOpacity(0.5) : Colors.white24, width: 1.5),
              gradient: LinearGradient(colors: [const Color(0xFF2C2C2E).withOpacity(0.6), const Color(0xFF151515).withOpacity(0.8)]),
              boxShadow: [BoxShadow(color: isAdmin ? Colors.amber.withOpacity(0.1) : Colors.black54, blurRadius: 15, offset: const Offset(0, 8))]
            ),
            child: ClipRRect(
               borderRadius: BorderRadius.circular(20),
               child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Column(
                     crossAxisAlignment: CrossAxisAlignment.stretch,
                     children: [
                        Padding(
                           padding: const EdgeInsets.all(16.0),
                           child: Row(
                              children: [
                                 CircleAvatar(
                                    radius: 30,
                                    backgroundColor: isAdmin ? Colors.amber.withOpacity(0.2) : Colors.white10,
                                    backgroundImage: (widget.userMap['avatar_url'] != null && widget.userMap['avatar_url'].toString().isNotEmpty) ? NetworkImage(widget.userMap['avatar_url']) : null,
                                    child: (widget.userMap['avatar_url'] == null || widget.userMap['avatar_url'] == '') 
                                        ? Icon(isAdmin ? Icons.shield : Icons.person, color: isAdmin ? Colors.amber : Colors.white54, size: 30)
                                        : null,
                                 ),
                                 const SizedBox(width: 16),
                                 Expanded(
                                    child: Column(
                                       crossAxisAlignment: CrossAxisAlignment.start,
                                       children: [
                                          Row(
                                             children: [
                                                Expanded(child: Text(widget.userMap['custom_username'].toString().toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2), overflow: TextOverflow.ellipsis)),
                                                if(isAdmin) const Icon(Icons.verified, color: Colors.amber, size: 18)
                                             ]
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                             children: [
                                                Container(
                                                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                   decoration: BoxDecoration(color: isActive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                                                   child: Text(widget.userMap['account_status'].toString().toUpperCase(), style: TextStyle(color: isActive ? Colors.greenAccent : Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                   decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)),
                                                   child: Text('AUTH: ${widget.userMap['profile_type'].toString().toUpperCase()}', style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                                                ),
                                             ]
                                          ),
                                          const SizedBox(height: 8),
                                          Text(expirationText, style: TextStyle(color: isExpired ? Colors.redAccent : Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                                       ]
                                    )
                                 ),
                                 Icon(_isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.white54)
                              ]
                           )
                        ),
                        if (_isExpanded && !isAdmin) ...[
                           Container(color: Colors.white10, height: 1),
                           Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Wrap(
                                 spacing: 12,
                                 runSpacing: 12,
                                 alignment: WrapAlignment.center,
                                 children: [
                                     _buildActionButton(Icons.timer, 'EXPIRE', Colors.blueAccent, _showExpirationDialog),
                                     _buildActionButton(isActive ? Icons.stop_circle : Icons.play_circle, isActive ? 'SUSPEND' : 'ACTIVATE', isActive ? Colors.orangeAccent : Colors.greenAccent, _toggleUserStatus),
                                     _buildActionButton(Icons.lock_reset, 'PASS', Colors.amber, _showResetPasswordDialog),
                                     _buildActionButton(Icons.edit_note, 'RENAME', Colors.purpleAccent, _showChangeUsernameDialog),
                                     _buildActionButton(Icons.delete_forever, 'ERADICATE', Colors.redAccent, _deleteUser),
                                 ]
                              )
                           )
                        ]
                     ]
                  )
               )
            )
         )
      );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
      return GestureDetector(
         onTap: onTap,
         child: Container(
            width: 80,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
               color: color.withOpacity(0.1),
               borderRadius: BorderRadius.circular(12),
               border: Border.all(color: color.withOpacity(0.5))
            ),
            child: Column(
               mainAxisSize: MainAxisSize.min,
               children: [
                   Icon(icon, color: color, size: 24),
                   const SizedBox(height: 6),
                   Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold))
               ]
            )
         )
      );
  }
}
