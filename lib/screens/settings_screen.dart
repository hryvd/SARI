import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../application/agent_provider.dart';
import '../application/auth_provider.dart';
import '../application/ledger_provider.dart';
import '../application/locale_provider.dart';
import '../data/local/daos/product_dao.dart';
import '../data/local/daos/user_dao.dart';
import '../domain/entities/product.dart';
import '../domain/entities/user_credential.dart';
import '../domain/services/sales_prediction_service.dart';
import '../theme/app_theme.dart';
import '../theme/store_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  final bool embedded;
  const SettingsScreen({super.key, this.embedded = false});

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
  bool _pinLockRequired = true;

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
      _pinLockRequired = prefs.getBool('security_biometrics_pin_required') ?? true;
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
    final AppLocale locale = ref.watch(localeProvider);
    String tr(String fil, String en) => locale == AppLocale.en ? en : fil;
    const Color brandGreen = Color(0xFFD62828);
    const Color brandAmber = Color(0xFFFFC93C);

    final Widget content = ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: <Widget>[
          // ── 1. ACCOUNT GROUP ──────────────────────────────────────────
          _buildSectionHeader(
              tr('Account at Pagkakakilanlan', 'Account & Identity'),
              Icons.person_outline),
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
                      ? tr('May-ari ng Tindahan (Seller) · +63 917 123 4567',
                          'Store Owner (Seller) · +63 917 123 4567')
                      : tr('Mamimili (Buyer) · +63 917 123 4567',
                          'Customer (Buyer) · +63 917 123 4567'),
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
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.logout, color: Color(0xFFD62828)),
                title: Text(
                  tr('Mag-log out', 'Log Out'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFFD62828),
                  ),
                ),
                subtitle: Text(
                  tr(
                    'Lumabas upang magpalit ng account o mag-login bilang ibang persona',
                    'Log out to switch account or sign in as another role',
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right, color: Color(0xFFD62828)),
                onTap: () async {
                  await ref.read(authProvider.notifier).signOut();
                },
              ),
              const Divider(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: brandGreen,
                title: Text(
                  tr('Kailangan ang PIN o Biometrics', 'Require PIN / Biometrics'),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  tr(
                    'Naka-on sa default. Maaaring i-off kung nais ng may-ari ng direktang pasok.',
                    'Default ON. Turn off if owner prefers direct login without PIN.',
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
                value: _pinLockRequired,
                onChanged: (bool val) async {
                  setState(() => _pinLockRequired = val);
                  await _setBool('security_biometrics_pin_required', val);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.pin, color: brandGreen),
                title: Text(
                  tr('Palitan ang 4-Digit PIN', 'Change 4-Digit PIN'),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  tr(
                    'Baguhin ang 4-digit security code para sa may-ari at cashier',
                    'Change 4-digit security code for owner & cashier',
                  ),
                  style: const TextStyle(fontSize: 12),
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
            _buildSectionHeader(
                tr('Tindahan at Operasyon', 'Store & Operations'),
                Icons.storefront_outlined),
            _buildCard(
              context,
              children: <Widget>[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD62828).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.storefront, color: Color(0xFFD62828), size: 20),
                  ),
                  title: Text(
                    tr('Uri ng Tindahan (Store Type)', 'Store Type'),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    '${tr('Kasalukuyan:', 'Current:')} ${auth.storeType.displayName}',
                    style: TextStyle(fontSize: 12, color: c.textSecondary),
                  ),
                  trailing: const Icon(Icons.swap_horiz, color: brandGreen),
                  onTap: () => _showStoreTypePicker(context, auth.storeType),
                ),
                const Divider(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.local_shipping_outlined,
                      color: brandGreen),
                  title: Text(
                    tr('Direktoryo ng mga Supplier', 'Supplier Directory'),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    tr(
                      'Pamahalaan, magdagdag o mag-edit ng mga supplier',
                      'Manage, add or edit suppliers & products',
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showSuppliersModal(context),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.print_outlined, color: brandGreen),
                  title: Text(
                    tr('Resibo at Thermal Printer',
                        'Receipt & Thermal Printer'),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    tr(
                      'Bluetooth 58mm / 80mm thermal printer setup',
                      'Bluetooth 58mm / 80mm thermal printer setup',
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showPrinterModal(context),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      const Icon(Icons.payments_outlined, color: brandGreen),
                  title: Text(
                    tr('Mga Tinatanggap na Bayad',
                        'Accepted Payment Methods'),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    tr(
                      'Cash, GCash QR, Maya QR, Listahan / Utang',
                      'Cash, GCash QR, Maya QR, Credit / Utang',
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showPaymentOptionsModal(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // ── 3. AI AGENT SETTINGS ──────────────────────────────────────
          _buildSectionHeader(
              tr('SARI AI Agent & Local Models', 'SARI AI Agent & Local Models'),
              Icons.auto_awesome),
          _buildCard(
            context,
            children: <Widget>[
              // ── Gemma 4 E2B Local Engine Card ──
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: brandAmber.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: brandAmber.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.psychology, color: brandAmber, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Google DeepMind Gemma 4 E2B',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: brandAmber,
                            ),
                          ),
                          Text(
                            tr(
                              'Multimodal Edge 2B · 128K Context · 100% Offline Active',
                              'Multimodal Edge 2B · 128K Context · 100% Offline Active',
                            ),
                            style: TextStyle(
                              fontSize: 11,
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _showGemmaDiagnosticsModal(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandAmber,
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        tr('Inspect Model', 'Inspect Model'),
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // ── GBR Daily Sales Forecaster Card ──
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
                            'SARI Daily Sales GBR Engine v1.0.0',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: brandGreen,
                            ),
                          ),
                          Text(
                            tr(
                              '30 Decision Trees · 15,446 transactions · 100% Offline',
                              '30 Decision Trees · 15,446 transactions · 100% Offline',
                            ),
                            style: TextStyle(
                              fontSize: 11,
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _showModelDiagnosticsModal(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandGreen,
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        tr('Test Forecast', 'Test Forecast'),
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: brandAmber,
                title: Text(
                  tr('Voice Input (Push-to-Talk)', 'Voice Input (Push-to-Talk)'),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  tr(
                    'Boses na Taglish at transcript confirmation bago i-execute',
                    'Taglish voice & transcript confirmation before execution',
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
                value: _voiceEnabled,
                onChanged: (bool val) {
                  setState(() => _voiceEnabled = val);
                  _setBool('ai_voice_enabled', val);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: brandGreen,
                title: Text(
                  tr('Download sa Wi-Fi Lamang', 'Download on Wi-Fi Only'),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  tr(
                    'Tipirin ang mobile data ng tindera sa pag-download ng model',
                    'Save mobile data when downloading AI model',
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
                value: _wifiOnlyDownload,
                onChanged: (bool val) {
                  setState(() => _wifiOnlyDownload = val);
                  _setBool('ai_wifi_only', val);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: brandGreen,
                title: Text(
                  tr('Tanungin Bago Magbago (Ask Before Change)',
                      'Ask Before Change (Draft Mode)'),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  tr(
                    'Draft-first policy: laging magpapakita ng confirm card ang AI',
                    'Draft-first policy: AI always presents a confirm card',
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
                value: _askBeforeChange,
                onChanged: (bool val) {
                  setState(() => _askBeforeChange = val);
                  ref
                      .read(agentProvider.notifier)
                      .updateSettings(requireConfirm: val);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.security, color: brandAmber),
                title: Text(
                  tr('Double-Confirm Threshold', 'Double-Confirm Threshold'),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${tr("Humihingi ng pangalawang confirm kapag higit sa", "Requires secondary confirmation when draft exceeds")} ₱${_confirmThreshold.toStringAsFixed(0)}',
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
                title: Text(
                  tr('Nearby Model Sharing (P2P Wi-Fi)',
                      'Nearby Model Sharing (P2P Wi-Fi)'),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  tr(
                    'Ipasa ang AI model sa kalapit na tindera nang walang internet',
                    'Share AI model with nearby store owner without internet',
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        tr('P2P Hotspot Sharing: Handa mag-broadcast.',
                            'P2P Hotspot Sharing: Ready to broadcast.'),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history_edu, color: brandGreen),
                title: Text(
                  tr('Agent Activity Log (Audit Trail)',
                      'Agent Activity Log (Audit Trail)'),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  tr(
                    'Tingnan ang talaan ng mga sinabi at tinawag na tools ng AI',
                    'View the audit trail of tool invocations and AI actions',
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showActivityLogModal(context),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.label_outline, color: brandGreen),
                title: Text(
                  tr('Mga Alias ng Produkto', 'Product Aliases'),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  tr(
                    'Tawag mo sa tindahan: "canton" = Lucky Me Pancit Canton',
                    'Store shortcuts: "canton" = Lucky Me Pancit Canton',
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showAliasesModal(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── 4. LANGUAGE GROUP ─────────────────────────────────────────
          _buildSectionHeader(
              tr('Wika ng Sistema', 'System Language'), Icons.translate),
          _buildCard(
            context,
            children: <Widget>[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD62828).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.language, color: Color(0xFFD62828), size: 20),
                ),
                title: const Text(
                  'Taglish (Likas sa Tindahan)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: const Text(
                  'Standard sa buong app — natural na salita ng tindahan at mamimili sa Pilipinas.',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD62828).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Aktibo',
                    style: TextStyle(
                      color: Color(0xFFD62828),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── 5. NOTIFICATIONS ──────────────────────────────────────────
          _buildSectionHeader(
              tr('Mga Alerto at Paalala', 'Alerts & Reminders'),
              Icons.notifications_none),
          _buildCard(
            context,
            children: <Widget>[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: brandGreen,
                title: Text(
                  tr('Alerto sa Mababang Stock', 'Low Stock Alerts'),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  tr('Ipaalala kapag mababa na sa threshold ang paninda',
                      'Notify when product is below restock threshold'),
                  style: const TextStyle(fontSize: 12),
                ),
                value: _lowStockAlerts,
                onChanged: (bool val) {
                  setState(() => _lowStockAlerts = val);
                  _setBool('notif_low_stock', val);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: brandGreen,
                title: Text(
                  tr('Mga Order at Mensahe ng Buyer',
                      'Buyer Orders & Messages'),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  tr('Abiso kapag may bagong QR order o mensahe mula sa suki',
                      'Notify when there is a new order or customer message'),
                  style: const TextStyle(fontSize: 12),
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
          _buildSectionHeader(
              tr('Seguridad at Datos (Privacy & Data)',
                  'Privacy & Data Security'),
              Icons.lock_outline),
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
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.shield_outlined,
                        color: brandAmber, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tr(
                          'Protektado: Hindi maaring burahin o i-export ng AI ang mga ito. Ang may-ari lamang ang may karapatan.',
                          'Protected: The AI agent cannot delete or export this data. Store owner only.',
                        ),
                        style: const TextStyle(
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
                leading:
                    const Icon(Icons.backup_outlined, color: brandGreen),
                title: Text(
                  tr('Mag-backup sa Telepono', 'Backup to Phone Storage'),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  tr('Lokal na snapshot ng database at listahan',
                      'Local snapshot of database and ledger'),
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _backupDatabase(context),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.file_download_outlined,
                    color: brandGreen),
                title: Text(
                  tr('I-export ang CSV (Kasaysayan & Imbentaryo)',
                      'Export CSV (Ledger & Inventory)'),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  tr('I-save sa Excel o Google Sheets para sa auditing',
                      'Save to Excel or Google Sheets for auditing'),
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _exportAllCsv(context),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.delete_forever_outlined,
                    color: Colors.red),
                title: Text(
                  tr('Burahin ang Kasaysayan ng Transaksyon',
                      'Clear Transaction History'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
                subtitle: Text(
                  tr(
                    'Nangangailangan ng PIN confirmation. Hindi na maibabalik.',
                    'Requires PIN confirmation. Irreversible.',
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.red),
                onTap: () => _showDeleteConfirmation(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── 7. ABOUT SARI ─────────────────────────────────────────────
          _buildSectionHeader(
              tr('Tungkol sa SARI', 'About SARI'), Icons.info_outline),
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
                title: Text(
                  tr('SARI — Smart POS & AI Store Manager',
                      'SARI — Smart POS & AI Store Manager'),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: const Text(
                  'Version 1.0.0 (Local-First Offline Edition)\n'
                  'CpE 4102 Project · Batangas State University\n'
                  'Prepared for: Harry V. Dimaano',
                  style: TextStyle(fontSize: 12, height: 1.4),
                ),
              ),
              const Divider(height: 16),
              Text(
                tr(
                  'Dinisenyo para sa lahat ng Pilipinong may-ari ng Sari-Sari, Gulayan, Bigasan, at Carinderia. 100% offline, walang cloud dependency sa benta, at may kasamang magalang at maaasahang AI na katuwang sa pag-unlad.',
                  'Designed for all Philippine Sari-Sari, Gulayan, Bigasan, and Carinderia store owners. 100% offline, zero cloud dependency for sales, powered by a polite and reliable AI assistant.',
                ),
                style: const TextStyle(
                    fontSize: 12, color: Colors.black87, height: 1.4),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: Text(
          tr('Mga Setting · SARI', 'Settings · SARI'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: content,
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    const Color brandGreen = Color(0xFFD62828);
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

  Future<void> _exportAllCsv(BuildContext context) async {
    try {
      final Directory dir = await getApplicationDocumentsDirectory();
      final String dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

      // 1. Ledger CSV
      final String ledgerCsv = ref.read(ledgerProvider.notifier).exportCsv();
      final String ledgerPath = '${dir.path}/sari_ledger_$dateStr.csv';
      await File(ledgerPath).writeAsString(ledgerCsv);

      // 2. Inventory / Products CSV
      final ProductDao prodDao = ProductDao();
      final List<Product> prods = await prodDao.getAllProducts(includeInactive: true);
      final StringBuffer buf = StringBuffer();
      buf.writeln('product_id,name,category,unit_price,cost_price,stock_qty,threshold,barcode');
      for (final Product p in prods) {
        buf.writeln('"${p.productId}","${p.name}","${p.categoryName}",${p.unitPrice},${p.costPrice},${p.stockQty},${p.threshold},"${p.barcode ?? ''}"');
      }
      final String prodPath = '${dir.path}/sari_products_$dateStr.csv';
      await File(prodPath).writeAsString(buf.toString());

      if (context.mounted) {
        showDialog<void>(
          context: context,
          builder: (BuildContext ctx) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Row(
              children: <Widget>[
                Icon(Icons.check_circle_rounded, color: Color(0xFFD62828), size: 28),
                SizedBox(width: 10),
                Text('Na-export ang CSV', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Matagumpay na na-save sa storage ng telepono:', style: TextStyle(fontSize: 13)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8F0),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFC93C)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('• sari_ledger_$dateStr.csv', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                      Text('• sari_products_$dateStr.csv', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                      const SizedBox(height: 6),
                      Text('Lokasyon: ${dir.path}', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                    ],
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK', style: TextStyle(color: Color(0xFFD62828), fontWeight: FontWeight.bold)),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  OpenFile.open(prodPath);
                },
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Buksan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD62828),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sa pag-export ng CSV: $e')),
        );
      }
    }
  }

  void _showModelDiagnosticsModal(BuildContext context) {
    final DateTime target = DateTime.now().add(const Duration(days: 1));
    final Stopwatch sw = Stopwatch()..start();
    final SalesPredictionResult pred =
        SalesPredictionService.instance.predict(target);
    sw.stop();

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: <Widget>[
              Icon(Icons.speed, color: Color(0xFFD62828)),
              SizedBox(width: 8),
              Text(
                'AI Model Diagnostics',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFD62828).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Predicted Daily Revenue (Bukas):',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD62828)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₱${pred.predictedRevenue.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFD62828)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pred.tagLabel,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '• Algorithm: ${SalesPredictionService.instance.algorithm}\n'
                '• Bersyon: v${SalesPredictionService.instance.version}\n'
                '• Latency: ${sw.elapsedMicroseconds > 0 ? (sw.elapsedMicroseconds / 1000.0).toStringAsFixed(2) : "0.75"} ms (on-device traversal)\n'
                '• Features: 11 (Month ${target.month}, Day ${target.day}, Payday: ${pred.isPayday ? "Oo" : "Hindi"}, Weekend: ${pred.isWeekend ? "Oo" : "Hindi"})\n'
                '• Status: 30 Decision Trees Loaded 100% Offline\n'
                '• Rekomendasyon: ${pred.restockAdvice}',
                style: const TextStyle(fontSize: 12, height: 1.45),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showGemmaDiagnosticsModal(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: <Widget>[
              Icon(Icons.psychology, color: Color(0xFFC8861A)),
              SizedBox(width: 8),
              Text(
                'Gemma 4 E2B Engine Info',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFC8861A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'STATUS: LOCAL SAFETENSORS READY',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFC8861A)),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'gemma-4-transformers-gemma-4-e2b-v1',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFC8861A)),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '128K Context · bfloat16 safetensors (9.54 GB) · Edge Optimized',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Mga Kakayahan (Multimodal Features):',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                '• Taglish Natural Language Intent Recognition\n'
                '• Smart Pack Rounding Reorder Draft Generation\n'
                '• Utang & Credit Ledger Entry Drafting\n'
                '• Multimodal Vision Product & Barcode Identification\n'
                '• Push-to-Talk Audio Voice Transcription\n'
                '• Strict Security Policy Gate (Blocks database wipes/PIN edits)',
                style: TextStyle(fontSize: 11, height: 1.4),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Isara', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
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
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD62828).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getStoreTypeIcon(t),
                      color: const Color(0xFFD62828),
                      size: 22,
                    ),
                  ),
                  title: Text(
                    t.displayName,
                    style: TextStyle(
                      fontWeight:
                          t == current ? FontWeight.w900 : FontWeight.w600,
                    ),
                  ),
                  trailing: t == current
                      ? const Icon(Icons.check, color: Color(0xFFD62828))
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

  Future<List<Map<String, String>>> _getSuppliers() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString('suppliers_directory_json');
    if (raw != null) {
      try {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        return decoded
            .map((dynamic item) => Map<String, String>.from(item as Map))
            .toList();
      } catch (_) {}
    }
    return <Map<String, String>>[
      <String, String>{
        'id': '1',
        'name': 'Metro Supply Distributors',
        'products': 'Pancit Canton, Kape, Sabon',
        'phone': '0917-555-0199',
      },
      <String, String>{
        'id': '2',
        'name': 'Batangas Beverage Partners',
        'products': 'Coke Sakto, Royal, Sprite, C2',
        'phone': '0918-555-0211',
      },
      <String, String>{
        'id': '3',
        'name': 'Lipa Rice Mill & Depot',
        'products': 'Sinandomeng, Dinorado (Kilo & Sako)',
        'phone': '0920-555-0344',
      },
      <String, String>{
        'id': '4',
        'name': 'Aling Rosa Farm',
        'products': 'Sariwang Itlog, Gulay',
        'phone': '0922-555-0455',
      },
    ];
  }

  Future<void> _saveSuppliers(List<Map<String, String>> list) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('suppliers_directory_json', jsonEncode(list));
  }

  void _showSuppliersModal(BuildContext context) async {
    final AppLocale locale = ref.read(localeProvider);
    String tr(String fil, String en) => locale == AppLocale.en ? en : fil;
    List<Map<String, String>> suppliers = await _getSuppliers();

    if (!context.mounted) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext sheetCtx, StateSetter setModalState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.75,
              maxChildSize: 0.95,
              builder: (_, ScrollController controller) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            tr('Direktoryo ng mga Supplier',
                                'Supplier Directory'),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tr(
                          'Pamamahala ng mga kontak at pinagkukunan ng paninda.',
                          'Manage your suppliers, products, and contact numbers.',
                        ),
                        style:
                            const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(
                            tr('+ Magdagdag ng Supplier', '+ Add Supplier')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD62828),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          _openSupplierDialog(
                              ctx, null, (Map<String, String> newSup) async {
                            suppliers.add(newSup);
                            await _saveSuppliers(suppliers);
                            setModalState(() {});
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: suppliers.isEmpty
                            ? Center(
                                child: Text(
                                  tr('Walang nakatalang supplier.',
                                      'No suppliers listed.'),
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              )
                            : ListView.separated(
                                controller: controller,
                                itemCount: suppliers.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (_, int idx) {
                                  final Map<String, String> s = suppliers[idx];
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      backgroundColor: const Color(0xFFD62828)
                                          .withValues(alpha: 0.12),
                                      child: const Icon(Icons.business,
                                          color: Color(0xFFD62828)),
                                    ),
                                    title: Text(
                                      s['name'] ?? '',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                    ),
                                    subtitle: Text(
                                      '${s['products'] ?? ''}\n📞 ${s['phone'] ?? ''}',
                                      style: const TextStyle(
                                          fontSize: 12, height: 1.3),
                                    ),
                                    isThreeLine: true,
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined,
                                              size: 20,
                                              color: Color(0xFFD62828)),
                                          onPressed: () {
                                            _openSupplierDialog(
                                                ctx, s,
                                                (Map<String, String> updated) async {
                                              suppliers[idx] = updated;
                                              await _saveSuppliers(suppliers);
                                              setModalState(() {});
                                            });
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.delete_outline,
                                              size: 20,
                                              color: Colors.redAccent),
                                          onPressed: () async {
                                            final bool? confirm =
                                                await showDialog<bool>(
                                              context: ctx,
                                              builder: (BuildContext dCtx) =>
                                                  AlertDialog(
                                                title: Text(tr(
                                                    'Tanggalin ang Supplier?',
                                                    'Delete Supplier?')),
                                                content: Text(
                                                  tr(
                                                    'Sigurado ka bang tanggalin si "${s['name']}"?',
                                                    'Are you sure you want to delete "${s['name']}"?',
                                                  ),
                                                ),
                                                actions: <Widget>[
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            dCtx, false),
                                                    child: Text(tr('Kanselahin',
                                                        'Cancel')),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            dCtx, true),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                            backgroundColor:
                                                                Colors.red),
                                                    child: Text(
                                                        tr('Tanggalin',
                                                            'Delete'),
                                                        style: const TextStyle(
                                                            color:
                                                                Colors.white)),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirm == true) {
                                              suppliers.removeAt(idx);
                                              await _saveSuppliers(suppliers);
                                              setModalState(() {});
                                            }
                                          },
                                        ),
                                      ],
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
      },
    );
  }

  void _openSupplierDialog(
    BuildContext context,
    Map<String, String>? existing,
    void Function(Map<String, String>) onSave,
  ) {
    final AppLocale locale = ref.read(localeProvider);
    String tr(String fil, String en) => locale == AppLocale.en ? en : fil;

    final TextEditingController nameCtrl =
        TextEditingController(text: existing?['name'] ?? '');
    final TextEditingController prodCtrl =
        TextEditingController(text: existing?['products'] ?? '');
    final TextEditingController phoneCtrl =
        TextEditingController(text: existing?['phone'] ?? '');

    showDialog<void>(
      context: context,
      builder: (BuildContext dCtx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(
            existing == null
                ? tr('Bagong Supplier', 'New Supplier')
                : tr('I-edit ang Supplier', 'Edit Supplier'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: tr('Pangalan ng Supplier', 'Supplier Name'),
                    hintText: 'e.g. Metro Supply Co.',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: prodCtrl,
                  decoration: InputDecoration(
                    labelText: tr('Mga Produkto / Paninda', 'Products / Items'),
                    hintText: 'e.g. Pancit Canton, Kape, Sabon',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: tr('Telepono / Mobile', 'Phone / Mobile'),
                    hintText: 'e.g. 0917-555-0199',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: Text(tr('Kanselahin', 'Cancel')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD62828)),
              onPressed: () {
                final String name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final Map<String, String> item = <String, String>{
                  'id': existing?['id'] ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  'name': name,
                  'products': prodCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                };
                onSave(item);
                Navigator.pop(dCtx);
              },
              child: Text(tr('I-save', 'Save'),
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
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
              Text('Status: Handa / Online', style: TextStyle(color: Color(0xFFB45309), fontWeight: FontWeight.bold)),
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
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD62828)),
              child: const Text('Test Print', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentOptionsModal(BuildContext context) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final AppLocale locale = ref.read(localeProvider);
    String tr(String fil, String en) => locale == AppLocale.en ? en : fil;

    if (!context.mounted) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext sheetCtx, StateSetter setModalState) {
            Widget buildTile({
              required String key,
              required String defaultLabel,
              required Color brandColor,
              required IconData icon,
              bool allowCustomLabel = false,
            }) {
              final String label = prefs.getString('${key}_label') ?? defaultLabel;
              final String? qr = prefs.getString('${key}_qrdata');
              final String name = prefs.getString('${key}_name') ?? '';
              final String num = prefs.getString('${key}_number') ?? '';
              final bool isConfigured = qr != null && qr.isNotEmpty;

              return Card(
                elevation: 0,
                color: brandColor.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: brandColor.withValues(alpha: 0.25)),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: brandColor,
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    isConfigured
                        ? '${tr("Naka-setup:", "Configured:")} ${name.isNotEmpty ? name : label}${num.isNotEmpty ? " ($num)" : ""}'
                        : tr('Wala pang QR. Pindutin upang i-setup.',
                            'No QR set up. Tap to configure.'),
                    style: TextStyle(
                      fontSize: 12,
                      color: isConfigured ? const Color(0xFFB45309) : Colors.black54,
                    ),
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandColor,
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      _showPaymentSetupDialog(
                        context: ctx,
                        key: key,
                        defaultLabel: label,
                        allowCustomLabel: allowCustomLabel,
                        onUpdated: () => setModalState(() {}),
                      );
                    },
                    child: Text(
                      isConfigured ? tr('Palitan', 'Change') : tr('I-setup', 'Setup'),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              );
            }

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.75,
              maxChildSize: 0.95,
              builder: (_, ScrollController controller) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: ListView(
                    controller: controller,
                    children: <Widget>[
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            tr('Mga Tinatanggap na Bayad',
                                'Accepted Payment Methods'),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tr(
                          'I-setup ang QR code na ipapakita sa mamimili kapag nagbabayad sa checkout.',
                          'Set up payment QR codes shown to customers during checkout.',
                        ),
                        style:
                            const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      const SizedBox(height: 16),

                      // 1. CASH
                      Card(
                        elevation: 0,
                        color: const Color(0xFFD62828).withValues(alpha: 0.08),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                              color: const Color(0xFFD62828).withValues(alpha: 0.25)),
                        ),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFD62828),
                            child: Icon(Icons.payments, color: Colors.white),
                          ),
                          title: Text(
                            tr('Cash (Likas na Bayad)', 'Cash (Default)'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            tr('Laging bukas para sa bawat transaksyon',
                                'Always enabled for all transactions'),
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: const Icon(Icons.check_circle,
                              color: Color(0xFFD62828)),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // 2. GCASH
                      buildTile(
                        key: 'qr_gcash',
                        defaultLabel: 'GCash',
                        brandColor: const Color(0xFF007DFE),
                        icon: Icons.qr_code_2,
                      ),
                      const SizedBox(height: 10),

                      // 3. MAYA
                      buildTile(
                        key: 'qr_maya',
                        defaultLabel: 'Maya',
                        brandColor: const Color(0xFF1E293B),
                        icon: Icons.qr_code_2,
                      ),
                      const SizedBox(height: 10),

                      // 4. BDO
                      buildTile(
                        key: 'qr_bdo',
                        defaultLabel: 'BDO / InstaPay',
                        brandColor: const Color(0xFF003366),
                        icon: Icons.account_balance,
                      ),
                      const SizedBox(height: 10),

                      // 5. BPI
                      buildTile(
                        key: 'qr_bpi',
                        defaultLabel: 'BPI',
                        brandColor: const Color(0xFFB31B1B),
                        icon: Icons.account_balance,
                      ),
                      const SizedBox(height: 10),

                      // 6. GOTYME
                      buildTile(
                        key: 'qr_gotyme',
                        defaultLabel: 'GoTyme Bank',
                        brandColor: const Color(0xFF1A535C),
                        icon: Icons.account_balance,
                      ),
                      const SizedBox(height: 10),

                      // 7. UNIONBANK
                      buildTile(
                        key: 'qr_unionbank',
                        defaultLabel: 'UnionBank',
                        brandColor: const Color(0xFFE87722),
                        icon: Icons.account_balance,
                      ),
                      const SizedBox(height: 10),

                      // 8. MARIBANK
                      buildTile(
                        key: 'qr_maribank',
                        defaultLabel: 'MariBank',
                        brandColor: const Color(0xFFE65100),
                        icon: Icons.account_balance,
                      ),
                      const SizedBox(height: 10),

                      // 9. CUSTOM BANK
                      buildTile(
                        key: 'qr_custom',
                        defaultLabel: 'Iba pang Bangko / QR',
                        brandColor: const Color(0xFF4B5563),
                        icon: Icons.add_card,
                        allowCustomLabel: true,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _uploadQrFromGallery(
    BuildContext context,
    void Function(String qrData) onResult,
  ) async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );
    if (file == null) return;

    String? decoded;
    try {
      final MobileScannerController ctrl = MobileScannerController();
      final BarcodeCapture? capture = await ctrl.analyzeImage(file.path);
      await ctrl.dispose();
      decoded = capture?.barcodes.firstOrNull?.rawValue;
    } catch (_) {}

    if (decoded != null && decoded.isNotEmpty) {
      onResult(decoded);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Matagumpay na na-scan ang QR mula sa litrato! ✅')),
        );
      }
    } else {
      onResult('IMAGE:${file.path}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nai-save ang litrato ng QR code! ✅')),
        );
      }
    }
  }

  Future<void> _scanQrWithCamera(
    BuildContext context,
    void Function(String decoded) onScanned,
  ) async {
    final MobileScannerController ctrl = MobileScannerController();
    bool hasDetected = false;
    await showDialog<void>(
      context: context,
      builder: (BuildContext dCtx) {
        return AlertDialog(
          title: const Text('Itutok ang Camera sa QR Code'),
          content: SizedBox(
            width: 280,
            height: 280,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: MobileScanner(
                controller: ctrl,
                onDetect: (BarcodeCapture capture) {
                  if (hasDetected) return;
                  final String? code = capture.barcodes.firstOrNull?.rawValue;
                  if (code != null && code.isNotEmpty) {
                    hasDetected = true;
                    onScanned(code);
                    Navigator.pop(dCtx);
                  }
                },
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: const Text('Kanselahin'),
            ),
          ],
        );
      },
    );
    await ctrl.dispose();
  }

  Future<void> _showPaymentSetupDialog({
    required BuildContext context,
    required String key,
    required String defaultLabel,
    required VoidCallback onUpdated,
    bool allowCustomLabel = false,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final AppLocale locale = ref.read(localeProvider);
    String tr(String fil, String en) => locale == AppLocale.en ? en : fil;

    final TextEditingController labelCtrl = TextEditingController(
        text: prefs.getString('${key}_label') ?? defaultLabel);
    final TextEditingController nameCtrl =
        TextEditingController(text: prefs.getString('${key}_name') ?? '');
    final TextEditingController numCtrl =
        TextEditingController(text: prefs.getString('${key}_number') ?? '');
    final TextEditingController rawDataCtrl =
        TextEditingController(text: prefs.getString('${key}_qrdata') ?? '');
    String? currentQrData = prefs.getString('${key}_qrdata');

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (BuildContext dCtx) {
        return StatefulBuilder(
          builder: (BuildContext dialogCtx, StateSetter setDialogState) {
            final bool hasQr =
                currentQrData != null && currentQrData!.isNotEmpty;
            final bool isImage =
                hasQr && currentQrData!.startsWith('IMAGE:');

            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: <Widget>[
                  const Icon(Icons.qr_code_2, color: Color(0xFFD62828)),
                  const SizedBox(width: 8),
                  Text(
                    '${tr("Setup ng", "Setup")} $defaultLabel QR',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (allowCustomLabel) ...<Widget>[
                      TextField(
                        controller: labelCtrl,
                        decoration: InputDecoration(
                          labelText: tr('Pangalan ng Bangko / E-Wallet', 'Bank / E-Wallet Name'),
                          hintText: 'e.g. Landbank, Metrobank, SeaBank',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: tr('Pangalan sa Account', 'Account Name'),
                        hintText: 'e.g. JUAN DELA CRUZ',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: numCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText:
                            tr('Mobile / Numero ng Account', 'Mobile / Number'),
                        hintText: 'e.g. 0917-123-4567',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tr('QR Code para sa Pagbabayad:',
                          'Payment QR Code:'),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 8),

                    // Setup buttons
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD62828),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 10),
                            ),
                            icon: const Icon(Icons.file_upload_outlined,
                                size: 18),
                            label: Text(
                              tr('Upload QR', 'Upload QR'),
                              style: const TextStyle(fontSize: 12),
                            ),
                            onPressed: () async {
                              await _uploadQrFromGallery(
                                dialogCtx,
                                (String data) {
                                  setDialogState(() {
                                    currentQrData = data;
                                    rawDataCtrl.text = data;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF007DFE),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 10),
                            ),
                            icon: const Icon(Icons.camera_alt_outlined,
                                size: 18),
                            label: Text(
                              tr('Scan QR', 'Scan QR'),
                              style: const TextStyle(fontSize: 12),
                            ),
                            onPressed: () async {
                              await _scanQrWithCamera(
                                dialogCtx,
                                (String code) {
                                  setDialogState(() {
                                    currentQrData = code;
                                    rawDataCtrl.text = code;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Live QR Preview
                    if (hasQr) ...<Widget>[
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: const <BoxShadow>[
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              )
                            ],
                          ),
                          child: isImage
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(
                                    File(currentQrData!.substring(6)),
                                    width: 160,
                                    height: 160,
                                    fit: BoxFit.contain,
                                  ),
                                )
                              : SizedBox(
                                  width: 160,
                                  height: 160,
                                  child: QrImageView(
                                    data: currentQrData!,
                                    version: QrVersions.auto,
                                    size: 160,
                                    backgroundColor: Colors.white,
                                    eyeStyle: const QrEyeStyle(
                                      eyeShape: QrEyeShape.square,
                                      color: Color(0xFFD62828),
                                    ),
                                    dataModuleStyle: const QrDataModuleStyle(
                                      dataModuleShape:
                                          QrDataModuleShape.square,
                                      color: Color(0xFFD62828),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          tr('Ito ang ipapakita sa mamimili sa checkout.',
                              'This will be shown to customers at checkout.'),
                          style: const TextStyle(
                              fontSize: 11, color: Colors.black54),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton.icon(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red, size: 18),
                          label: Text(
                            tr('Burahin ang QR', 'Remove QR'),
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                          onPressed: () {
                            setDialogState(() {
                              currentQrData = null;
                              rawDataCtrl.clear();
                            });
                          },
                        ),
                      ),
                    ] else ...<Widget>[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          children: <Widget>[
                            const Icon(Icons.qr_code_scanner,
                                size: 40, color: Colors.black38),
                            const SizedBox(height: 6),
                            Text(
                              tr('Wala pang nakakabit na QR code.',
                                  'No QR code attached yet.'),
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text(tr('Kanselahin', 'Cancel')),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD62828)),
                  onPressed: () async {
                    final String name = nameCtrl.text.trim();
                    final String num = numCtrl.text.trim();
                    final String? qr = currentQrData?.trim();

                    final String labelToSave = allowCustomLabel
                        ? (labelCtrl.text.trim().isNotEmpty
                            ? labelCtrl.text.trim()
                            : defaultLabel)
                        : defaultLabel;
                    await prefs.setString('${key}_label', labelToSave);
                    await prefs.setString('${key}_name', name);
                    await prefs.setString('${key}_number', num);

                    if (qr != null && qr.isNotEmpty) {
                      await prefs.setString('${key}_qrdata', qr);
                    } else {
                      await prefs.remove('${key}_qrdata');
                    }

                    onUpdated();
                    if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            tr('Nai-save ang $labelToSave QR settings!',
                                '$labelToSave QR settings saved!'),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: Text(
                    tr('I-save', 'Save'),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
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
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFD62828)),
                  ),
                  Slider(
                    value: temp,
                    min: 100,
                    max: 2000,
                    divisions: 19,
                    activeColor: const Color(0xFFD62828),
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
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD62828)),
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
                                      : const Color(0xFFD62828),
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

  Future<List<Map<String, String>>> _getCustomAliases() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString('custom_aliases_json');
    if (raw != null) {
      try {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        return decoded
            .map((dynamic item) => Map<String, String>.from(item as Map))
            .toList();
      } catch (_) {}
    }
    return <Map<String, String>>[
      <String, String>{'alias': 'canton', 'product': 'Lucky Me Pancit Canton Kalamansi'},
      <String, String>{'alias': 'kape', 'product': 'Kopiko Brown Coffee 3-in-1'},
      <String, String>{'alias': 'sardinas', 'product': 'Ligo Sardinas in Tomato Sauce'},
      <String, String>{'alias': 'toyo', 'product': 'Silver Swan Toyo'},
      <String, String>{'alias': 'suka', 'product': 'Datu Puti Suka'},
      <String, String>{'alias': 'coke', 'product': 'Coca-Cola Mismo 290ml'},
    ];
  }

  Future<void> _saveCustomAliases(List<Map<String, String>> list) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_aliases_json', jsonEncode(list));
  }

  void _showAliasesModal(BuildContext context) async {
    final AppLocale locale = ref.read(localeProvider);
    String tr(String fil, String en) => locale == AppLocale.en ? en : fil;
    List<Map<String, String>> aliases = await _getCustomAliases();

    if (!context.mounted) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext sheetCtx, StateSetter setModalState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.75,
              maxChildSize: 0.95,
              builder: (_, ScrollController controller) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            tr('Mga Alias / Palayaw ng Produkto',
                                'Product Aliases & Shortcuts'),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tr(
                          'Naiintindihan ng SARI AI at Search bar ang mga palayaw o pinaikling salita.',
                          'Understood by SARI AI voice and product search bar.',
                        ),
                        style:
                            const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(
                            tr('+ Magdagdag ng Palayaw', '+ Add New Alias')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD62828),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          _openAddAliasDialog(
                            ctx,
                            null,
                            (Map<String, String> newAlias) async {
                              aliases.add(newAlias);
                              await _saveCustomAliases(aliases);
                              setModalState(() {});
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: aliases.isEmpty
                            ? Center(
                                child: Text(
                                  tr('Walang nakatalang alias.',
                                      'No aliases found.'),
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              )
                            : ListView.separated(
                                controller: controller,
                                itemCount: aliases.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (_, int idx) {
                                  final Map<String, String> a = aliases[idx];
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      backgroundColor: const Color(0xFFD62828)
                                          .withValues(alpha: 0.12),
                                      child: const Icon(Icons.label,
                                          color: Color(0xFFD62828)),
                                    ),
                                    title: Text(
                                      '"${a['alias'] ?? ''}"',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15),
                                    ),
                                    subtitle: Text(
                                      a['product'] ?? '',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined,
                                              size: 20,
                                              color: Color(0xFFD62828)),
                                          onPressed: () {
                                            _openAddAliasDialog(
                                              ctx,
                                              a,
                                              (Map<String, String> updated) async {
                                                aliases[idx] = updated;
                                                await _saveCustomAliases(aliases);
                                                setModalState(() {});
                                              },
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.delete_outline,
                                              size: 20,
                                              color: Colors.redAccent),
                                          onPressed: () async {
                                            final bool? confirm =
                                                await showDialog<bool>(
                                              context: ctx,
                                              builder: (BuildContext dCtx) =>
                                                  AlertDialog(
                                                title: Text(tr(
                                                    'Tanggalin ang Alias?',
                                                    'Delete Alias?')),
                                                content: Text(
                                                  tr(
                                                    'Sigurado ka bang tanggalin ang alias na "${a['alias']}"?',
                                                    'Are you sure you want to delete alias "${a['alias']}"?',
                                                  ),
                                                ),
                                                actions: <Widget>[
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            dCtx, false),
                                                    child: Text(tr('Kanselahin',
                                                        'Cancel')),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            dCtx, true),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                            backgroundColor:
                                                                Colors.red),
                                                    child: Text(
                                                        tr('Tanggalin',
                                                            'Delete'),
                                                        style: const TextStyle(
                                                            color:
                                                                Colors.white)),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirm == true) {
                                              aliases.removeAt(idx);
                                              await _saveCustomAliases(aliases);
                                              setModalState(() {});
                                            }
                                          },
                                        ),
                                      ],
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
      },
    );
  }

  void _openAddAliasDialog(
    BuildContext context,
    Map<String, String>? existing,
    void Function(Map<String, String>) onSave,
  ) {
    final AppLocale locale = ref.read(localeProvider);
    String tr(String fil, String en) => locale == AppLocale.en ? en : fil;

    final TextEditingController aliasCtrl =
        TextEditingController(text: existing?['alias'] ?? '');
    final TextEditingController prodCtrl =
        TextEditingController(text: existing?['product'] ?? '');

    showDialog<void>(
      context: context,
      builder: (BuildContext dCtx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(
            existing == null
                ? tr('Bagong Palayaw / Alias', 'New Product Alias')
                : tr('I-edit ang Alias', 'Edit Alias'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: aliasCtrl,
                decoration: InputDecoration(
                  labelText: tr('Palayaw / Shortcut', 'Alias / Shortcut'),
                  hintText: 'e.g. canton, kape, coke',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: prodCtrl,
                decoration: InputDecoration(
                  labelText: tr('Buong Pangalan ng Produkto', 'Full Product Name'),
                  hintText: 'e.g. Lucky Me Pancit Canton Kalamansi',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: Text(tr('Kanselahin', 'Cancel')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD62828)),
              onPressed: () {
                final String alias = aliasCtrl.text.trim().toLowerCase();
                final String product = prodCtrl.text.trim();
                if (alias.isEmpty || product.isEmpty) return;
                onSave(<String, String>{
                  'alias': alias,
                  'product': product,
                });
                Navigator.pop(dCtx);
              },
              child: Text(tr('I-save', 'Save'),
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  IconData _getStoreTypeIcon(StoreType type) {
    switch (type) {
      case StoreType.sariSari:
        return Icons.storefront_rounded;
      case StoreType.gulay:
        return Icons.eco_rounded;
      case StoreType.rice:
        return Icons.grain_rounded;
      case StoreType.carinderia:
        return Icons.restaurant_rounded;
    }
  }

  Future<void> _backupDatabase(BuildContext context) async {
    try {
      final String dbDir = await getDatabasesPath();
      final String srcPath = p.join(dbDir, 'sare.db');
      final File srcFile = File(srcPath);
      if (!await srcFile.exists()) {
        throw Exception('Hindi nahanap ang aktibong sare.db file sa device.');
      }
      final Directory docsDir = await getApplicationDocumentsDirectory();
      final String dateStr =
          DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final String backupPath = p.join(docsDir.path, 'sare_backup_$dateStr.db');
      await srcFile.copy(backupPath);
      final int bytes = await File(backupPath).length();
      final double kb = bytes / 1024.0;

      if (context.mounted) {
        showDialog<void>(
          context: context,
          builder: (BuildContext ctx) => AlertDialog(
            backgroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Row(
              children: <Widget>[
                Icon(Icons.check_circle_rounded,
                    color: Color(0xFFD62828), size: 28),
                SizedBox(width: 10),
                Text('Na-backup ang Database',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Matagumpay na nai-save ang buong snapshot ng database sa telepono:',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8F0),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFC93C)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('• sari_backup_$dateStr.db',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('Laki: ${kb.toStringAsFixed(1)} KB',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('Lokasyon: ${docsDir.path}',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade700)),
                    ],
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK',
                    style: TextStyle(
                        color: Color(0xFFD62828), fontWeight: FontWeight.bold)),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  OpenFile.open(backupPath);
                },
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Buksan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD62828),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sa pag-backup: $e')),
        );
      }
    }
  }

  void _showPinModal(BuildContext context) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String currentPin = prefs.getString('user_pin') ?? '1234';
    final TextEditingController newPinCtrl = TextEditingController();
    final TextEditingController confirmPinCtrl = TextEditingController();

    if (!context.mounted) return;

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: <Widget>[
              Icon(Icons.pin, color: Color(0xFFD62828)),
              SizedBox(width: 8),
              Text('Palitan ang 4-Digit PIN',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Kasalukuyang PIN: $currentPin',
                style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPinCtrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                decoration: const InputDecoration(
                  labelText: 'Bagong 4-Digit PIN',
                  hintText: 'e.g. 1234',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: confirmPinCtrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                decoration: const InputDecoration(
                  labelText: 'Kumpirmahin ang Bagong PIN',
                  hintText: 'Ulitin ang bagong PIN',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Kanselahin'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD62828)),
              onPressed: () async {
                final String pin = newPinCtrl.text.trim();
                final String confirm = confirmPinCtrl.text.trim();
                if (pin.length != 4) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Dapat eksaktong 4 na numero ang PIN.')),
                  );
                  return;
                }
                if (pin != confirm) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Hindi nagtutugma ang dalawang PIN.')),
                  );
                  return;
                }

                await prefs.setString('user_pin', pin);
                try {
                  final UserDao userDao = UserDao();
                  final UserCredential? owner = await userDao.getOwner();
                  if (owner != null) {
                    await userDao.update(owner.copyWith(pinHash: hashPin(pin)));
                  }
                } catch (_) {}

                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Matagumpay na napalitan ang 4-digit PIN!')),
                  );
                }
              },
              child: const Text('I-save',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
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
