import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _ownerPinCtrl = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _storeNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _ownerPinCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    
    final auth = context.read<AuthProvider>();
    final success = await auth.signUp(
      _emailCtrl.text, 
      _passCtrl.text, 
      _storeNameCtrl.text,
      _phoneCtrl.text,
      _ownerPinCtrl.text,
    );

    // Jika sukses, main.dart otomatis route ke layar selanjutnya (HomeScreen/LockScreen)
    if (success && mounted) {
      Navigator.pop(context); // Tutup layar register, biarkan router bekerja
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF00695C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // ── Header ──────────────────────────────────────
            Expanded(
              flex: 1,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.app_registration,
                          size: 60, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

            // ── Form Area ───────────────────────────────────
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Buat Akun Owner',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF00695C),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Daftarkan warung/toko Anda untuk mulai menggunakan sistem POS Hybrid.',
                          textAlign: TextAlign.start,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Nama Toko
                        TextFormField(
                          controller: _storeNameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nama Toko / Warung',
                            prefixIcon: Icon(Icons.store),
                          ),
                          validator: (v) =>
                              v!.isEmpty ? 'Nama toko tidak boleh kosong' : null,
                        ),
                        const SizedBox(height: 16),

                        // No Telepon
                        TextFormField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Nomor Telepon / WhatsApp',
                            prefixIcon: Icon(Icons.phone),
                          ),
                          validator: (v) =>
                              v!.isEmpty ? 'Nomor telepon tidak boleh kosong' : null,
                        ),
                        const SizedBox(height: 16),

                        // Email
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Email wajib diisi';
                            if (!v.contains('@')) return 'Format email tidak valid';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password
                        TextFormField(
                          controller: _passCtrl,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) => v!.length < 6
                              ? 'Password minimal 6 karakter'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Konfirmasi Password
                        TextFormField(
                          controller: _confirmPassCtrl,
                          obscureText: _obscureConfirm,
                          decoration: InputDecoration(
                            labelText: 'Konfirmasi Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () =>
                                  setState(() => _obscureConfirm = !_obscureConfirm),
                            ),
                          ),
                          validator: (v) {
                            if (v != _passCtrl.text) {
                              return 'Password tidak cocok';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // PIN Owner
                        TextFormField(
                          controller: _ownerPinCtrl,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'PIN Owner (Akses Offline)',
                            prefixIcon: Icon(Icons.pin),
                            counterText: '',
                          ),
                          validator: (v) => v!.length < 4
                              ? 'PIN minimal 4 angka'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Error Message
                        if (auth.errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              auth.errorMessage!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        // Tombol Daftar
                        ElevatedButton(
                          onPressed: auth.isLoading ? null : _register,
                          child: auth.isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Daftar Sekarang'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
