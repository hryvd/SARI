import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../application/agent_provider.dart';
import '../application/auth_provider.dart';
import '../application/locale_provider.dart';
import '../theme/app_theme.dart';
import '../theme/store_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _lowStockAlerts = true;
  bool _orderAlerts = true;
  bool _voiceEnabled = true;
  bool _wifiOnlyDownload = true;
  bool _askBeforeChange = true;
  double _confirmThreshold = 500.0;
  String _selectedLang = 'taglish';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _lowStockAlerts = prefs.getBool('notif_low_stock') ?? true;
      _orderAlerts = prefs.getBool('notif_orders') ?? true;
      _voiceEnabled = prefs.getBool('ai_voice_enabled') ?? true;
      _wifiOnlyDownload = prefs.getBool('ai_wifi_only') ?? true;
      _askBeforeChange = prefs.getBool('agent_require_confirm') ?? true;
      _confirmThreshold = prefs.getDouble('agent_confirm_threshold') ?? 500.0;
      _selectedLang = prefs.getString('sari_language') ?? 'taglish';
    });
  }

  Future<void> _setBool(String key, bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = appColors(context);
    final AuthState auth = ref.watch(authProvider).value ?? const AuthState();
    final bool isSeller = auth.user?.role != 'buyer';
    const Color brandGreen = Color(0xFF1E6E5A);
    const Color brandAmber = Color(0xFFC8861A);

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: const Text(
          'Mga Setting · SARI',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: <Widget>[
          // ── 1. ACCOUNT GROUP ──────────────────────────────────────────
          _buildSectionHeader('Account at Pagkakakilanlan', Icons.person_outline),
          _buildCard(
            context,
            children: <Widget>[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: brandGreen.withValues(alpha: 0.15),
                  child: const Text('HD',
                      style: TextStyle(
                          color: brandGreen, fontWeight: FontWeight.bold)),
                ),
                title: Text(
                  auth.user?.storeName.isNotEmpty == true
                      ? auth.user!.storeName
                      : 'Harry V. Dimaano',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  isSeller
                      ? 'May-ari ng Tindahan (Seller) · +63 917 123 4567'
                      : 'Mamimili (Buyer) · +63 917 123 4567',
                  style: TextStyle(fontSize: 12, color: c.textSecondary),
                ),
                trailing: Chip(
                  label: Text(
                    isSeller ? 'Seller' : 'Buyer',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: brandGreen,
                    ),
                  ),
                  backgroundColor: brandGreen.withValues(alpha: 0.1),
                  side: BorderSide.none,
                ),
              ),
              const Divider(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbImage: null,
                activeColor: brandGreen,
                title: const Text(
                  'Mode ng Account: Seller',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: const Text(
                  'I-toggle upang lumipat sa Mamimili (Buyer) mode',
                  style: TextStyle(fontSize: 12),
                ),
                value: isSeller,
                onChanged: (bool val) {
                  final String newRole = val ? 'owner' : 'buyer';
                  ref.read(authProvider.notifier).updateRole(newRole);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        val ? 'Lumipat sa Seller Mode' : 'Lumipat sa Buyer Mode',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.fingerprint, color: brandGreen),
                title: const Text(
                  'PIN at Biometrics Lock',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Protektahan ang POS at Kasaysayan gamit ang 4-digit PIN',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showPinModal(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── 2. STORE SETTINGS (SELLERS ONLY) ──────────────────────────
          if (isSeller) ...<Widget>[
            _buildSectionHeader('Tindahan at Operasyon', Icons.storefront_outlined),
            _buildCard(
              context,
              children: <Widget>[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Text(
                    auth.storeType.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: const Text(
                    'Uri ng Tindahan (Store Type)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    'Kasalukuyan: ${auth.storeType.displayName}',
                    style: TextStyle(fontSize: 12, color: c.textSecondary),
                  ),
                  trailing: const Icon(Icons.swap_horiz, color: brandGreen),
                  onTap: () => _showStoreTypePicker(context, auth.storeType),
                ),
                const Divider(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.local_shipping_outlined, color: brandGreen),
                  title: const Text(
                    'Direktoryo ng mga Supplier',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Metro Supply, Batangas Beverage, Lipa Rice Mill, Aling Rosa',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showSuppliersModal(context),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.print_outlined, color: brandGreen),
                  title: const Text(
                    'Resibo at Thermal Printer',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Bluetooth 58mm / 80mm thermal printer setup',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showPrinterModal(context),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.payments_outlined, color: brandGreen),
                  title: const Text(
                    'Mga Tinatanggap na Bayad',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Cash, GCash QR, Maya QR, Listahan / Utang',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // ── 3. AI AGENT SETTINGS ──────────────────────────────────────
          _buildSectionHeader('SARI AI Agent & Local Models', Icons.auto_awesome),
          _buildCard(
            context,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: brandGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.check_circle, color: brandGreen, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Gemma 4 E2B + FunctionGemma',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: brandGreen,
                            ),
                          ),
                          Text(
                            'LiteRT on-device runtime · 100% Offline Active',
                            style: TextStyle(
                              fontSize: 11,
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Pinakabagong version na ang AI model.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        side: const BorderSide(color: brandGreen),
                      ),
                      child: const Text('Update', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: brandAmber,
                title: const Text(
                  'Voice Input (Push-to-Talk)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Boses na Taglish at transcript confirmation bago i-execute',
                  style: TextStyle(fontSize: 12),
                ),
                value: _voiceEnabled,
                onChanged: (bool val) {
                  setState(() => _voiceEnabled = val);
                  _setBool('ai_voice_enabled', val);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: brandGreen,
                title: const Text(
                  'Download sa Wi-Fi Lamang',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Tipirin ang mobile data ng tindera sa pag-download ng model',
                  style: TextStyle(fontSize: 12),
                ),
                value: _wifiOnlyDownload,
                onChanged: (bool val) {
                  setState(() => _wifiOnlyDownload = val);
                  _setBool('ai_wifi_only', val);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: brandGreen,
                title: const Text(
                  'Tanungin Bago Magbago (Ask Before Change)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Draft-first policy: laging magpapakita ng confirm card ang AI',
                  style: TextStyle(fontSize: 12),
                ),
                value: _askBeforeChange,
                onChanged: (bool val) {
                  setState(() => _askBeforeChange = val);
                  ref.read(agentProvider.notifier).updateSettings(requireConfirm: val);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.security, color: brandAmber),
                title: const Text(
                  'Double-Confirm Threshold',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Humihingi ng pangalawang confirm kapag higit sa ₱${_confirmThreshold.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Text(
                  '₱${_confirmThreshold.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () => _showThresholdPicker(context),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.share_outlined, color: brandGreen),
                title: const Text(
                  'Nearby Model Sharing (P2P Wi-Fi)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Ipasa ang AI model sa kalapit na tindera nang walang internet',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('P2P Hotspot Sharing: Handa mag-broadcast.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history_edu, color: brandGreen),
                title: const Text(
                  'Agent Activity Log (Audit Trail)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Tingnan ang talaan ng mga sinabi at tinawag na tools ng AI',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showActivityLogModal(context),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.label_outline, color: brandGreen),
                title: const Text(
                  'Mga Alias ng Produkto',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Tawag mo sa tindahan: "canton" = Lucky Me Pancit Canton',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showAliasesModal(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── 4. LANGUAGE GROUP ─────────────────────────────────────────
          _buildSectionHeader('Wika / Language', Icons.translate),
          _buildCard(
            context,
            children: <Widget>[
              RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                activeColor: brandGreen,
                value: 'taglish',
                groupValue: _selectedLang,
                title: const Text('Taglish (Likas sa Tindahan)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text(
                  'Pangkaraniwang salita ng mga Pinoy (Kulang, Utang, Benta, Sukli)',
                  style: TextStyle(fontSize: 12),
                ),
                onChanged: (String? val) {
                  if (val != null) {
                    setState(() => _selectedLang = val);
                    _setLanguage(val);
                  }
                },
              ),
              RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                activeColor: brandGreen,
                value: 'filipino',
                groupValue: _selectedLang,
                title: const Text('Filipino (Pormal)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Purong wikang Filipino', style: TextStyle(fontSize: 12)),
                onChanged: (String? val) {
                  if (val != null) {
                    setState(() => _selectedLang = val);
                    _setLanguage(val);
                  }
                },
              ),
              RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                activeColor: brandGreen,
                value: 'english',
                groupValue: _selectedLang,
                title: const Text('English',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Standard English language', style: TextStyle(fontSize: 12)),
                onChanged: (String? val) {
                  if (val != null) {
                    setState(() => _selectedLang = val);
                    _setLanguage(val);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── 5. NOTIFICATIONS ──────────────────────────────────────────
          _buildSectionHeader('Mga Alerto at Paalala', Icons.notifications_none),
          _buildCard(
            context,
            children: <Widget>[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: brandGreen,
                title: const Text(
                  'Alerto sa Mababang Stock',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Ipaalala kapag mababa na sa threshold ang paninda',
                    style: TextStyle(fontSize: 12)),
                value: _lowStockAlerts,
                onChanged: (bool val) {
                  setState(() => _lowStockAlerts = val);
                  _setBool('notif_low_stock', val);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: brandGreen,
                title: const Text(
                  'Mga Order at Mensahe ng Buyer',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Abiso kapag may bagong QR order o mensahe mula sa suki',
                  style: TextStyle(fontSize: 12),
                ),
                value: _orderAlerts,
                onChanged: (bool val) {
                  setState(() => _orderAlerts = val);
                  _setBool('notif_orders', val);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── 6. PRIVACY & DATA (BLOCKED TO AI AGENT) ───────────────────
          _buildSectionHeader('Seguridad at Datos (Privacy & Data)', Icons.lock_outline),
          _buildCard(
            context,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: <Widget>[
                    Icon(Icons.shield_outlined, color: brandAmber, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Protektado: Hindi maaring burahin o i-export ng AI ang mga ito. Ang may-ari lamang ang may karapatan.',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.backup_outlined, color: brandGreen),
                title: const Text('Mag-backup sa Telepono',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text('Lokal na snapshot ng database at listahan',
                    style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Matagumpay na na-backup ang sare.db sa telepono!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.file_download_outlined, color: brandGreen),
                title: const Text('I-export ang CSV (Kasaysayan & Imbentaryo)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text('I-save sa Excel o Google Sheets para sa auditing',
                    style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Na-generate ang SARI_Ledger_Export.csv.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
                title: const Text(
                  'Burahin ang Kasaysayan ng Transaksyon',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
                subtitle: const Text(
                  'Nangangailangan ng PIN confirmation. Hindi na maibabalik.',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.red),
                onTap: () => _showDeleteConfirmation(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── 7. ABOUT SARI ─────────────────────────────────────────────
          _buildSectionHeader('Tungkol sa SARI', Icons.info_outline),
          _buildCard(
            context,
            children: <Widget>[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: brandGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'SARI',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
                title: const Text(
                  'SARI — Smart POS & AI Store Manager',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: const Text(
                  'Version 1.0.0 (Local-First Offline Edition)\n'
                  'CpE 4102 Project · Batangas State University\n'
                  'Prepared for: Harry V. Dimaano',
                  style: TextStyle(fontSize: 12, height: 1.4),
                ),
              ),
              const Divider(height: 16),
              const Text(
                'Dinisenyo para sa lahat ng Pilipinong may-ari ng Sari-Sari, Gulayan, Bigasan, at Carinderia. 100% offline, walang cloud dependency sa benta, at may kasamang magalang at maaasahang AI na katuwang sa pag-unlad.',
                style: TextStyle(fontSize: 12, color: Colors.black87, height: 1.4),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    const Color brandGreen = Color(0xFF1E6E5A);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: brandGreen),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: brandGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required List<Widget> children}) {
    final AppColors c = appColors(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.borderSubtle),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Future<void> _setLanguage(String lang) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('sari_language', lang);
    if (lang == 'english') {
      ref.read(localeProvider.notifier).setLocale(AppLocale.en);
    } else {
      ref.read(localeProvider.notifier).setLocale(AppLocale.fil);
    }
  }

  void _showStoreTypePicker(BuildContext context, StoreType current) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Pumili ng Uri ng Tindahan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 4),
              const Text(
                'Awtomatikong iaangkop ang POS, yunit, at presyuhan ayon sa uri.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              for (final StoreType t in StoreType.values)
                ListTile(
                  leading: Text(t.emoji, style: const TextStyle(fontSize: 26)),
                  title: Text(
                    t.displayName,
                    style: TextStyle(
                      fontWeight:
                          t == current ? FontWeight.w900 : FontWeight.w600,
                    ),
                  ),
                  trailing: t == current
                      ? const Icon(Icons.check, color: Color(0xFF1E6E5A))
                      : null,
                  onTap: () {
                    ref.read(authProvider.notifier).setStoreType(t);
                    Navigator.pop(ctx);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showSuppliersModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          builder: (_, ScrollController controller) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: controller,
                children: const <Widget>[
                  Text(
                    'Direktoryo ng mga Supplier',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  ListTile(
                    leading: Icon(Icons.business, color: Color(0xFF1E6E5A)),
                    title: Text('Metro Supply Distributors'),
                    subtitle: Text('Pancit Canton, Kape, Sabon · 0917-555-0199'),
                  ),
                  ListTile(
                    leading: Icon(Icons.local_drink, color: Color(0xFF1E6E5A)),
                    title: Text('Batangas Beverage Partners'),
                    subtitle: Text('Coke Sakto, Royal, Sprite, C2 · 0918-555-0211'),
                  ),
                  ListTile(
                    leading: Icon(Icons.agriculture, color: Color(0xFF1E6E5A)),
                    title: Text('Lipa Rice Mill & Depot'),
                    subtitle: Text('Sinandomeng, Dinorado (Kilo & Sako) · 0920-555-0344'),
                  ),
                  ListTile(
                    leading: Icon(Icons.egg_outlined, color: Color(0xFF1E6E5A)),
                    title: Text('Aling Rosa Farm'),
                    subtitle: Text('Sariwang Itlog, Gulay · 0922-555-0455'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showPrinterModal(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Thermal Printer Setup'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Konektadong Printer: SARI 58mm POS Printer (Bluetooth)'),
              SizedBox(height: 8),
              Text('Status: Handa / Online', style: TextStyle(color: Colors.green)),
              SizedBox(height: 12),
              Text('Suportado ang automated paper cutting at barcode printing.'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Isara'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Test print sent to Bluetooth printer!')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E6E5A)),
              child: const Text('Test Print', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showThresholdPicker(BuildContext context) {
    double temp = _confirmThreshold;
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext dCtx, StateSetter setModalState) {
            return AlertDialog(
              title: const Text('Double-Confirm Threshold'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('Humihingi ng pangalawang pag-kumpirma kapag ang draft ay higit sa halagang ito:'),
                  const SizedBox(height: 16),
                  Text(
                    '₱${temp.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E6E5A)),
                  ),
                  Slider(
                    value: temp,
                    min: 100,
                    max: 2000,
                    divisions: 19,
                    activeColor: const Color(0xFF1E6E5A),
                    onChanged: (double val) {
                      setModalState(() => temp = val);
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Kanselahin'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _confirmThreshold = temp);
                    ref.read(agentProvider.notifier).updateSettings(threshold: temp);
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E6E5A)),
                  child: const Text('I-save', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showActivityLogModal(BuildContext context) {
    final AgentState agentState = ref.read(agentProvider);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          builder: (_, ScrollController controller) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Agent Activity Log (Audit Trail)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Lahat ng tawag sa tools at drafts ay nakatala dito para sa kaligtasan.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: agentState.activityLogs.isEmpty
                        ? const Center(child: Text('Wala pang nakatalang AI tool activity.'))
                        : ListView.separated(
                            controller: controller,
                            itemCount: agentState.activityLogs.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (_, int i) {
                              final AgentActivityLogEntry l = agentState.activityLogs[i];
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  l.risk == AgentRisk.blocked
                                      ? Icons.lock
                                      : l.risk == AgentRisk.draft
                                          ? Icons.edit_note
                                          : Icons.check,
                                  color: l.risk == AgentRisk.blocked
                                      ? Colors.red
                                      : const Color(0xFF1E6E5A),
                                ),
                                title: Text(l.tool, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${l.arguments}\nBy: ${l.by}'),
                                trailing: Text(
                                  '${l.timestamp.hour}:${l.timestamp.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontSize: 11, color: Colors.black45),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAliasesModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const <Widget>[
              Text(
                'Mga Alias ng Produkto',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Naiintindihan ng SARI AI ang mga palayaw o pinaikling salita:',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              SizedBox(height: 12),
              ListTile(
                title: Text('"canton"'),
                subtitle: Text('Lucky Me Pancit Canton Kalamansi'),
              ),
              ListTile(
                title: Text('"kape"'),
                subtitle: Text('Kopiko Brown Coffee 3-in-1'),
              ),
              ListTile(
                title: Text('"sardinas"'),
                subtitle: Text('Ligo Sardinas in Tomato Sauce'),
              ),
              ListTile(
                title: Text('"toyo" at "suka"'),
                subtitle: Text('Silver Swan Toyo & Datu Puti Suka'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPinModal(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Palitan ang PIN'),
          content: const Text('Ilagay ang bagong 4-digit PIN para sa may-ari o cashier.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Isara'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Burahin ang Kasaysayan?', style: TextStyle(color: Colors.red)),
          content: const Text(
            'Sigurado ka ba? Ang transaksyon at ledger data ay permanenteng mabubura sa device na ito.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Kanselahin'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Operasyon ay pinigilan para sa kaligtasan.')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Burahin', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
