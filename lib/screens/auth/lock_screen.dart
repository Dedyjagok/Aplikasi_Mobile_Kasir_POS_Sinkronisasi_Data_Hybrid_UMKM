import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/cashier_model.dart';
import '../../providers/cashier_provider.dart';
import '../../providers/session_provider.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CashierProvider>().loadCashiers();
    });
  }

  void _showOwnerLoginDialog() {
    final passCtrl = TextEditingController();
    bool isLoading = false;
    String? error;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Login Owner',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Masukkan password akun untuk melanjutkan sebagai Owner.'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      errorText: error,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setState(() {
                            isLoading = true;
                            error = null;
                          });
                          try {
                            final email = FirebaseAuth.instance.currentUser?.email;
                            if (email != null) {
                              await FirebaseAuth.instance.signInWithEmailAndPassword(
                                  email: email, password: passCtrl.text);
                              if (context.mounted) {
                                context.read<SessionProvider>().loginAsOwner('Owner');
                                Navigator.pop(ctx);
                              }
                            }
                          } catch (e) {
                            setState(() {
                              isLoading = false;
                              error = 'Password salah';
                            });
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Masuk'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCashierLoginDialog(Cashier cashier) {
    final pinCtrl = TextEditingController();
    String? error;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Login Kasir',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Masukkan PIN untuk masuk sebagai ${cashier.name}.'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: pinCtrl,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: 'PIN 4-6 Digit',
                      errorText: error,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (pinCtrl.text == cashier.pin) {
                      context.read<SessionProvider>().loginAsCashier(cashier);
                      Navigator.pop(ctx);
                    } else {
                      setState(() {
                        error = 'PIN salah';
                      });
                    }
                  },
                  child: const Text('Masuk'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            Text(
              'Pilih Profil',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF00695C),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Siapa yang sedang bertugas saat ini?',
              style: GoogleFonts.poppins(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: Consumer<CashierProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Gabungkan Owner + Cashiers
                  final items = [
                    _ProfileItem(
                      name: 'Owner',
                      isOwner: true,
                      onTap: _showOwnerLoginDialog,
                    ),
                    ...provider.cashiers.map(
                      (c) => _ProfileItem(
                        name: c.name,
                        isOwner: false,
                        onTap: () => _showCashierLoginDialog(c),
                      ),
                    ),
                  ];

                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) => items[index],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final String name;
  final bool isOwner;
  final VoidCallback onTap;

  const _ProfileItem({
    required this.name,
    required this.isOwner,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: isOwner
                  ? const Color(0xFF00695C)
                  : const Color(0xFF00695C).withOpacity(0.1),
              child: Icon(
                isOwner ? Icons.admin_panel_settings : Icons.person,
                size: 35,
                color: isOwner ? Colors.white : const Color(0xFF00695C),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
