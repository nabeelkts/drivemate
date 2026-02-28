import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/screens/widget/custom_back_button.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class InvitePage extends StatefulWidget {
  const InvitePage({super.key});

  @override
  State<InvitePage> createState() => _InvitePageState();
}

class _InvitePageState extends State<InvitePage> with TickerProviderStateMixin {
  // ─────────────────────────────────────────
  // Controllers
  // ─────────────────────────────────────────

  late AnimationController _tickerController;
  late AnimationController _envelopeController;

  // Envelope animations
  late Animation<double> _cardSlide;
  late Animation<double> _flapRotation;
  late Animation<double> _flapShadowOpacity;

  // ─────────────────────────────────────────
  // State
  // ─────────────────────────────────────────

  bool _isSharing = false;
  bool _isLoadingContacts = false;
  List<Contact> _contacts = [];
  bool _hasPermission = false;

  static const String _appDownloadLink =
      'https://github.com/nabeelkts/drivemate/releases/latest/download/drivemate.apk';

  static const String _referralMessage =
      '🚗 Join me on Drivemate - the smart driving school management app!\n\n'
      '✨ Student & Vehicle Management\n'
      '✨ License & Endorsement Tracking\n'
      '✨ Payment & Fee Management\n\n'
      '📱 Download now: $_appDownloadLink';

  final List<String> _tickerMessages = [
    '⭐  100+ driving schools already using Drivemate',
    '✦  Change your hard copy data to digital',
    '⭐  Access and control your data anytime',
    '✦  Multiple branch management',
    '⭐  Multiple role based access control',
  ];

  // App Orange Theme Colors
  static const Color _bgTop = Color.fromARGB(255, 196, 196, 196);
  static const Color _envBody = kPrimaryColor;
  static const Color _envFlapOpen = kPrimaryColor;
  static const Color _envShadow = kPrimaryColor;
  static const Color _tickerBg = Color.fromARGB(255, 116, 95, 251);
  static const Color _bottomBg = Color(0xFF0D0D0D);
  static const Color _cardBg = Color(0xFF1A1A1A);
  static const Color _whatsappGreen = Color(0xFF25D366);

// ─────────────────────────────────────────
// Animate Envelope Then Share
// ─────────────────────────────────────────

  Future<void> _animateAndShare(Future<void> Function() action) async {
    if (_envelopeController.isAnimating) return;

    setState(() => _isSharing = true);

    await _envelopeController.forward();

    await Future.delayed(const Duration(milliseconds: 250));

    await action();

    await Future.delayed(const Duration(milliseconds: 400));

    await _envelopeController.reverse();

    if (mounted) {
      setState(() => _isSharing = false);
    }
  }
  // ─────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    // Ticker
    _tickerController =
        AnimationController(vsync: this, duration: const Duration(seconds: 22))
          ..repeat();

    // Envelope controller
    _envelopeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
// ─────────────────────────────────────────
// Envelope Animations
// ─────────────────────────────────────────

    _cardSlide = Tween<double>(
      begin: 0,
      end: 55,
    ).animate(
      CurvedAnimation(
        parent: _envelopeController,
        curve: const Interval(
          0.0,
          0.6,
          curve: Curves.easeInCubic,
        ),
      ),
    );

    _flapRotation = Tween<double>(
      begin: -3.0, // open (rotated back ~172°, card visible)
      end: 0.0, // closed (flat, covering card)
    ).animate(
      CurvedAnimation(
        parent: _envelopeController,
        curve: const Interval(
          0.3,
          1.0,
          curve: Curves.easeOutBack,
        ),
      ),
    );

    _flapShadowOpacity = Tween<double>(
      begin: 0.0,
      end: 0.35,
    ).animate(
      CurvedAnimation(
        parent: _envelopeController,
        curve: const Interval(
          0.3,
          0.8,
          curve: Curves.easeIn,
        ),
      ),
    );
    _checkPermissionAndLoadContacts();
  }

  @override
  void dispose() {
    _tickerController.dispose();
    _envelopeController.dispose();
    super.dispose();
  }

  // ── Contact helpers ────────────────────────────────────────────────────────

  Future<void> _checkPermissionAndLoadContacts() async {
    setState(() => _isLoadingContacts = true);
    final status = await Permission.contacts.status;
    if (status.isGranted) {
      setState(() => _hasPermission = true);
      await _loadContacts();
    } else {
      final r = await Permission.contacts.request();
      setState(() => _hasPermission = r.isGranted);
      if (r.isGranted) await _loadContacts();
    }
    setState(() => _isLoadingContacts = false);
  }

  Future<void> _loadContacts() async {
    try {
      final all = await FlutterContacts.getContacts(
          withProperties: true, withPhoto: true);
      final valid = all.where((c) => c.phones.isNotEmpty).toList()
        ..sort((a, b) => a.displayName.compareTo(b.displayName));
      setState(() => _contacts = valid.take(20).toList());
    } catch (e) {
      debugPrint('Contacts: $e');
    }
  }

  Future<void> _requestPermission() async {
    final r = await Permission.contacts.request();
    if (r.isGranted) {
      setState(() => _hasPermission = true);
      await _loadContacts();
    } else if (r.isPermanentlyDenied && mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Permission Required'),
          content: const Text('Enable contacts in settings.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                openAppSettings();
                Navigator.pop(context);
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _shareViaWhatsApp() async {
    final url = Uri.parse(
        'https://wa.me/?text=${Uri.encodeComponent(_referralMessage)}');

    await canLaunchUrl(url)
        ? launchUrl(url, mode: LaunchMode.externalApplication)
        : Share.share(_referralMessage);
  }

  Future<void> _shareViaWhatsAppToContact(Contact c) async {
    if (c.phones.isEmpty) return;

    final phone = c.phones.first.number.replaceAll(RegExp(r'[^\d+]'), '');

    final url = Uri.parse(
        'https://wa.me/$phone?text=${Uri.encodeComponent(_referralMessage)}');

    await canLaunchUrl(url)
        ? launchUrl(url, mode: LaunchMode.externalApplication)
        : Share.share(_referralMessage);
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(const ClipboardData(text: _appDownloadLink));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Link copied!'), duration: Duration(seconds: 2)),
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bottomBg,
      body: Column(
        children: [
          _buildEnvelopeSection(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildActionButtons(),
                  const SizedBox(height: 14),
                  _buildReferralLink(),
                  const SizedBox(height: 24),
                  _buildInviteContacts(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  ENVELOPE SECTION

  Widget _buildEnvelopeSection() {
    return Container(
      color: _bgTop,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // App bar
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
              child: Row(
                children: [
                  const CustomBackButton(),
                  const Spacer(),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white38, width: 1.5),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.question_mark,
                          color: Colors.white70, size: 18),
                      onPressed: () => _showHowItWorks(context),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              height: 300,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  const padding = 32.0;
                  final envWidth = width - padding * 2;

                  return Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      // 1️⃣ BACK WALL (static, at bottom)
                      Positioned(
                        top: 90,
                        right: padding,
                        child: CustomPaint(
                          size: Size(envWidth, 180),
                          painter: _EnvelopePainter(
                            bodyColor: _envBody,
                            shadowColor: _envShadow,
                          ),
                        ),
                      ),

                      // 2️⃣ TOP FLAP (Animated) - starts BEHIND card, rotates to front
                      Positioned(
                        top: 90,
                        left: padding,
                        right: padding,
                        child: AnimatedBuilder(
                          animation: _envelopeController,
                          builder: (context, child) {
                            return Transform(
                              alignment: Alignment.topCenter,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.002)
                                ..rotateX(_flapRotation.value),
                              child: CustomPaint(
                                size: Size(envWidth, 110),
                                painter: _TopFlapDownPainter(
                                  color: _envFlapOpen,
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // 3️⃣ CARD (Animated - slides down and fades when closing)
                      Positioned(
                        top: 40,
                        left: padding + 20,
                        right: padding + 20,
                        child: AnimatedBuilder(
                          animation: _envelopeController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _cardSlide.value),
                              child: Opacity(
                                opacity: 1 - (_envelopeController.value * 0.9),
                                child: child,
                              ),
                            );
                          },
                          child: SizedBox(
                            height: 170,
                            child: _buildInviteCard(),
                          ),
                        ),
                      ),

                      // 4️⃣ FRONT WALL WITH CUT
                      Positioned(
                        top: 140,
                        left: padding,
                        right: padding,
                        child: CustomPaint(
                          size: Size(envWidth, 160),
                          painter: _FrontWallCutPainter(
                            color: _envBody,
                          ),
                        ),
                      ),

                      // 5️⃣ FLAP SHADOW (on top)
                      Positioned(
                        top: 90,
                        left: padding,
                        right: padding,
                        child: AnimatedBuilder(
                          animation: _envelopeController,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _flapShadowOpacity.value,
                              child: Container(
                                height: 25,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 32),
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black54,
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            _buildTicker(),
          ],
        ),
      ),
    );
  }

  // ── Invite Card ────────────────────────────────────────────────────────────
  // Only the UPPER portion of this card is visible; the rest is behind the
  // envelope front wall. So we show title + subtitle + button at the top.

  Widget _buildInviteCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(26, 30, 26, 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            'Invite Now',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Help your friends manage their\n'
            'driving school with Drivemate.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 15),
          ),
        ],
      ),
    );
  }

  // ── Ticker ─────────────────────────────────────────────────────────────────

  Widget _buildTicker() {
    final txt = _tickerMessages.join('          ');
    return Container(
      height: 40,
      color: _tickerBg,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 8),
      child: AnimatedBuilder(
        animation: _tickerController,
        builder: (_, __) => ClipRect(
          child: FractionalTranslation(
            translation: Offset(-_tickerController.value, 0),
            child: Text(
              '$txt          $txt',
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
            ),
          ),
        ),
      ),
    );
  }

  // ── Action buttons ─────────────────────────────────────────────────────────

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed:
                  _isSharing ? null : () => _animateAndShare(_shareViaWhatsApp),
              style: ElevatedButton.styleFrom(
                backgroundColor: _whatsappGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: _isSharing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.chat_bubble_outline, size: 20),
              label: Text(
                _isSharing ? 'Opening...' : 'Invite on WhatsApp',
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white12),
          ),
          child: IconButton(
            icon: const Icon(Icons.share, color: Colors.white70, size: 22),
            onPressed: () =>
                _animateAndShare(() => Share.share(_referralMessage)),
          ),
        ),
      ],
    );
  }

  // ── Referral link ──────────────────────────────────────────────────────────

  Widget _buildReferralLink() {
    return Row(
      children: [
        const Text('Invite : ',
            style: TextStyle(color: Colors.white60, fontSize: 14)),
        Expanded(
          child: Text(
            _appDownloadLink,
            style: const TextStyle(
              color: kPrimaryColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: kPrimaryColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _copyLink,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white12),
            ),
            child: const Icon(Icons.copy, size: 16, color: Colors.white54),
          ),
        ),
      ],
    );
  }

  // ── Invite contacts ────────────────────────────────────────────────────────

  Widget _buildInviteContacts() {
    final colors = [
      const Color(0xFF4CAF50),
      const Color(0xFF2196F3),
      const Color(0xFF009688),
      const Color(0xFF00BCD4),
      const Color(0xFFE91E63),
      const Color(0xFF9C27B0),
      const Color(0xFFFF5722),
      const Color(0xFFFF9800),
    ];
    final displayed = _contacts.take(1000).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Invite Contacts',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            GestureDetector(
              onTap: _showSearchContacts,
              child: Row(children: const [
                Icon(Icons.search, color: kPrimaryColor, size: 18),
                SizedBox(width: 4),
                Text('Search',
                    style: TextStyle(
                        color: kPrimaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isLoadingContacts)
          const Center(
              child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(color: kPrimaryColor)))
        else if (!_hasPermission)
          Center(
            child: Column(children: [
              const Icon(Icons.contacts, size: 42, color: Colors.white24),
              const SizedBox(height: 10),
              const Text('Allow access to invite contacts',
                  style: TextStyle(color: Colors.white54)),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _requestPermission,
                style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white),
                child: const Text('Allow Access'),
              ),
            ]),
          )
        else if (displayed.isEmpty)
          const Center(
              child: Text('No contacts found',
                  style: TextStyle(color: Colors.white38)))
        else
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: displayed.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (_, i) {
                final c = displayed[i];
                final col = colors[i % colors.length];
                final ini = _getInitials(c.displayName);
                return GestureDetector(
                  onTap: () =>
                      _animateAndShare(() => _shareViaWhatsAppToContact(c)),
                  child: Column(children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                          color: col, borderRadius: BorderRadius.circular(14)),
                      child: Center(
                        child: c.photo != null && c.photo!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.memory(c.photo!,
                                    width: 60, height: 60, fit: BoxFit.cover))
                            : Text(ini,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 66,
                      child: Text(
                        c.displayName.split(' ').first,
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 11),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                );
              },
            ),
          ),
      ],
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final p = name.trim().split(' ');
    return p.length >= 2
        ? '${p[0][0]}${p[1][0]}'.toUpperCase()
        : p[0][0].toUpperCase();
  }

  void _showSearchContacts() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String query = '';
        final ac = [
          Colors.green,
          Colors.blue,
          Colors.teal,
          Colors.orange,
          Colors.purple,
          Colors.red,
          Colors.indigo,
          Colors.pink,
        ];
        return StatefulBuilder(builder: (ctx, setL) {
          final res = _contacts
              .where((c) =>
                  c.displayName.toLowerCase().contains(query.toLowerCase()))
              .toList();
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Color(0xFF121212),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search contacts...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search, color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF1E1E1E),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                  onChanged: (v) => setL(() => query = v),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: res.length,
                  itemBuilder: (_, i) {
                    final c = res[i];
                    final col = ac[i % ac.length];
                    final ini = _getInitials(c.displayName);
                    return ListTile(
                      leading: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                            color: col,
                            borderRadius: BorderRadius.circular(12)),
                        child: c.photo != null && c.photo!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child:
                                    Image.memory(c.photo!, fit: BoxFit.cover))
                            : Center(
                                child: Text(ini,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700))),
                      ),
                      title: Text(c.displayName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          c.phones.isNotEmpty ? c.phones.first.number : '',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 12)),
                      trailing: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _shareViaWhatsAppToContact(c);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: _whatsappGreen,
                              borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.chat,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ]),
          );
        });
      },
    );
  }

  void _showHowItWorks(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: const BoxDecoration(
          color: Color(0xFF121212),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 20),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const Text('How it works',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
            const SizedBox(height: 24),
            _buildStep(Icons.share, 'Share with Friends',
                'Send your referral link to friends who manage driving schools.'),
            const SizedBox(height: 20),
            _buildStep(Icons.person_add, 'They Download',
                'Your friends download Drivemate using your referral link.'),
            const SizedBox(height: 20),
            _buildStep(Icons.card_giftcard, 'Everyone Benefits',
                'Both you and your friends get access to premium features.'),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: kPrimaryColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const SizedBox(height: 4),
            Text(desc,
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.5),
                    height: 1.4)),
          ]),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  _Tri — generic triangle painter with explicit corner offsets
// ══════════════════════════════════════════════════════════════════════════════

class _Tri extends CustomPainter {
  final Color color;
  final Offset p0, p1, p2;
  const _Tri(
      {required this.color,
      required this.p0,
      required this.p1,
      required this.p2});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(p0.dx, p0.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..close(),
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _EnvelopePainter extends CustomPainter {
  final Color bodyColor;
  final Color shadowColor;
  const _EnvelopePainter({required this.bodyColor, required this.shadowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = bodyColor;

    // Draw envelope body with straight top and rounded bottom
    final path = Path()
      ..moveTo(0, 0) // Top-left (straight)
      ..lineTo(size.width, 0) // Top-right (straight)
      ..lineTo(size.width, size.height - 20) // Right side down to curve start
      ..quadraticBezierTo(
        size.width, size.height, // Control point for bottom-right
        size.width - 20, size.height, // Bottom-right corner
      )
      ..lineTo(20, size.height) // Bottom edge
      ..quadraticBezierTo(
        0, size.height, // Control point for bottom-left
        0, size.height - 20, // Bottom-left corner
      )
      ..close();

    canvas.drawPath(path, paint);

    // Optional side shadows
    final shadowPaint = Paint()..color = shadowColor.withOpacity(0.3);
    canvas.drawRect(Rect.fromLTWH(0, 0, 20, size.height), shadowPaint);
    canvas.drawRect(
        Rect.fromLTWH(size.width - 20, 0, 20, size.height), shadowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TopFlapUpPainter extends CustomPainter {
  final Color color;
  const _TopFlapUpPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Top flap pointing DOWN (like an open envelope)
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    final paint = Paint()..color = color;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Top flap that rotates down to close the envelope
class _TopFlapDownPainter extends CustomPainter {
  final Color color;
  const _TopFlapDownPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Triangle pointing DOWN (V-shape)
    // Starts rotated back (open, card visible)
    // Rotates forward to close over the card
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    final paint = Paint()..color = color;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FrontWallCutPainter extends CustomPainter {
  final Color color;
  const _FrontWallCutPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();

    final margin = size.width * 0.1; // 10% margin on both sides
    final cutDepth = 100.0; // how far the curve goes down

    // Start from top-left
    path.moveTo(0, 0);

    // Left straight part before curve
    path.lineTo(margin, 0);

    // Quadratic curve down and up
    path.quadraticBezierTo(
      size.width / 2, cutDepth, // control point at center, depth
      size.width - margin, 0, // end at right margin
    );

    // Right side and bottom
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    final paint = Paint()..color = color;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
