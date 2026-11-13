import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:universal_html/html.dart' as html;
import 'package:flutter_web_dashboard/config.dart';
import 'package:flutter_web_dashboard/constants/style.dart';
import 'package:flutter_web_dashboard/service_api/auth_headers.dart';

/// Banner Studio — visiting-card style banners for service and shop
/// listings, built from the service / shop tables.
///
/// Backend (Django, page key 'banners'):
///   GET /api/banners/categories/?type=service|shop
///   GET /api/banners/listings/?type=&cat_id=&search=&page=
///   GET /api/banners/image/?url=   (aarambd.com image passthrough)
///
/// The card is drawn at 1050 x 600 (3.5 x 2 in visiting-card ratio) and
/// exported at 2x = 2100 x 1200 px PNG.
class BannerStudioPage extends StatefulWidget {
  const BannerStudioPage({super.key});

  @override
  State<BannerStudioPage> createState() => _BannerStudioPageState();
}

// ── Card constants ──────────────────────────────────────────────────────────

const double _cardW = 1050;
const double _cardH = 600;
const double _exportRatio = 2.0;

const Color _brand = Color(0xFF7B81ED); // AaramBD brand colour
const Color _brandDark = Color(0xFF4B51B8);
const Color _brandSoft = Color(0xFFEEF0FD);
const Color _ink = Color(0xFF1E1B4B);
const Color _body = Color(0xFF64748B);
const Color _bodyDark = Color(0xFF334155);

TextStyle _font(double size,
    {FontWeight weight = FontWeight.w400,
    Color color = _ink,
    double? height,
    double letterSpacing = 0}) {
  // Poppins for English; Bangla characters in listing data fall back to
  // Noto Sans Bengali instead of rendering as empty boxes.
  return GoogleFonts.poppins(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  ).copyWith(fontFamilyFallback: [GoogleFonts.notoSansBengali().fontFamily!]);
}

/// 01712345678 -> 01712-345678
String formatBdPhone(String raw) {
  final d = raw.replaceAll(RegExp(r'\D'), '');
  if (d.length == 11 && d.startsWith('01')) return '${d.substring(0, 5)}-${d.substring(5)}';
  return raw;
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return 'A';
  final first = parts.first.characters.first;
  final second = parts.length > 1 ? parts[1].characters.first : '';
  return (first + second).toUpperCase();
}

class _CardData {
  final String type; // 'service' | 'shop'
  final String name;
  final String category;
  final String description;
  final String phone;
  final String location;
  final Uint8List? photo;
  final Uint8List? catLogo;

  const _CardData({
    required this.type,
    required this.name,
    required this.category,
    required this.description,
    required this.phone,
    required this.location,
    this.photo,
    this.catLogo,
  });
}

// ── Page state ──────────────────────────────────────────────────────────────

class _BannerStudioPageState extends State<BannerStudioPage> {
  String _type = 'service';

  List<Map<String, dynamic>> _cats = [];
  int? _catId;
  bool _catsLoading = false;

  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _items = [];
  int _page = 1;
  int _total = 0;
  bool _listLoading = false;
  String? _listError;

  Map<String, dynamic>? _selected;
  final _nameCtrl = TextEditingController();
  final _catCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locCtrl = TextEditingController();
  bool _showDescription = true;
  bool _showPhoto = true;

  Uint8List? _photo;
  Uint8List? _catLogo;
  bool _imagesLoading = false;
  final Map<String, Uint8List?> _imageCache = {};

  final GlobalKey _cardKey = GlobalKey();
  bool _exporting = false;

  static const _pageSize = 30;

  @override
  void initState() {
    super.initState();
    for (final c in [_nameCtrl, _catCtrl, _descCtrl, _phoneCtrl, _locCtrl]) {
      c.addListener(() => setState(() {}));
    }
    _loadCategories();
  }

  @override
  void dispose() {
    for (final c in [_searchCtrl, _nameCtrl, _catCtrl, _descCtrl, _phoneCtrl, _locCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  Future<void> _loadCategories() async {
    setState(() {
      _catsLoading = true;
      _cats = [];
      _catId = null;
    });
    try {
      final res = await http.get(
        Uri.parse('$host/api/banners/categories/?type=$_type'),
        headers: authHeaders(),
      );
      if (res.statusCode == 200) {
        final body = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        _cats = List<Map<String, dynamic>>.from(body['categories'] as List);
      }
    } catch (_) {
      // Category filter is optional; the list below still loads.
    }
    if (!mounted) return;
    setState(() => _catsLoading = false);
    _loadListings(reset: true);
  }

  Future<void> _loadListings({bool reset = false}) async {
    if (reset) _page = 1;
    setState(() {
      _listLoading = true;
      _listError = null;
    });
    final q = <String, String>{
      'type': _type,
      'page': '$_page',
      'page_size': '$_pageSize',
      if (_catId != null) 'cat_id': '$_catId',
      if (_searchCtrl.text.trim().isNotEmpty) 'search': _searchCtrl.text.trim(),
    };
    try {
      final res = await http.get(
        Uri.parse('$host/api/banners/listings/').replace(queryParameters: q),
        headers: authHeaders(),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final body = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        setState(() {
          _items = List<Map<String, dynamic>>.from(body['results'] as List);
          _total = (body['total'] as num?)?.toInt() ?? 0;
          _listLoading = false;
        });
      } else {
        setState(() {
          _listError = res.statusCode == 403
              ? 'You do not have access to Banner Studio.'
              : 'Server returned ${res.statusCode}';
          _listLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _listError = e.toString();
        _listLoading = false;
      });
    }
  }

  Future<Uint8List?> _fetchImage(String url) async {
    if (url.isEmpty) return null;
    if (_imageCache.containsKey(url)) return _imageCache[url];
    Uint8List? bytes;
    try {
      final res = await http.get(
        Uri.parse('$host/api/banners/image/').replace(queryParameters: {'url': url}),
        headers: authHeaders(),
      );
      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        // Make sure the bytes really decode before using them on the card.
        await ui.instantiateImageCodec(res.bodyBytes);
        bytes = res.bodyBytes;
      }
    } catch (_) {
      bytes = null;
    }
    _imageCache[url] = bytes;
    return bytes;
  }

  Future<void> _select(Map<String, dynamic> item) async {
    setState(() {
      _selected = item;
      _nameCtrl.text = '${item['name'] ?? ''}';
      _catCtrl.text = '${item['cat_name'] ?? ''}';
      _descCtrl.text = '${item['description'] ?? ''}';
      _phoneCtrl.text = formatBdPhone('${item['phone'] ?? ''}');
      _locCtrl.text = '${item['location'] ?? ''}';
      _photo = null;
      _catLogo = null;
      _imagesLoading = true;
    });
    final results = await Future.wait([
      _fetchImage('${item['photo_url'] ?? ''}'),
      _fetchImage('${item['cat_logo_url'] ?? ''}'),
    ]);
    if (!mounted || _selected != item) return;
    setState(() {
      _photo = results[0];
      _catLogo = results[1];
      _imagesLoading = false;
    });
  }

  _CardData get _cardData => _CardData(
        type: _type,
        name: _nameCtrl.text.trim(),
        category: _catCtrl.text.trim(),
        description: _showDescription ? _descCtrl.text.trim() : '',
        phone: _phoneCtrl.text.trim(),
        location: _locCtrl.text.trim(),
        photo: _showPhoto ? _photo : null,
        catLogo: _catLogo,
      );

  // ── Export ────────────────────────────────────────────────────────────────

  Future<void> _downloadPng() async {
    if (_selected == null || _exporting) return;
    setState(() => _exporting = true);
    try {
      await GoogleFonts.pendingFonts();
      await WidgetsBinding.instance.endOfFrame;
      final boundary = _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: _exportRatio);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw Exception('Could not encode PNG');
      final bytes = data.buffer.asUint8List();

      final slug = _nameCtrl.text
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'^-+|-+$'), '');
      final fileName = 'aarambd_${_type}_${_selected!['id']}${slug.isEmpty ? '' : '_$slug'}.png';

      final blob = html.Blob([bytes], 'image/png');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..download = fileName
        ..click();
      html.Url.revokeObjectUrl(url);
      _snack('Downloaded $fileName', success: true);
    } catch (e) {
      _snack('Export failed: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _snack(String msg, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? successColor : errorColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  // ── Layout ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
          child: Row(children: [
            const Icon(Icons.badge_rounded, size: 22, color: accentColor),
            const SizedBox(width: 10),
            const Text('Banner Studio',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary)),
            const SizedBox(width: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                    value: 'service',
                    label: Text('Services'),
                    icon: Icon(Icons.miscellaneous_services_rounded, size: 16)),
                ButtonSegment(
                    value: 'shop',
                    label: Text('Shops'),
                    icon: Icon(Icons.storefront_rounded, size: 16)),
              ],
              selected: {_type},
              showSelectedIcon: false,
              onSelectionChanged: (s) {
                setState(() {
                  _type = s.first;
                  _selected = null;
                  _items = [];
                });
                _loadCategories();
              },
            ),
          ]),
        ),
        Expanded(
          child: LayoutBuilder(builder: (context, c) {
            final wide = c.maxWidth >= 1000;
            final list = _listPanel();
            final editor = _editorPanel(scroll: wide);
            if (wide) {
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 340, child: list),
                const SizedBox(width: 16),
                Expanded(child: editor),
              ]);
            }
            return ListView(children: [
              SizedBox(height: 420, child: list),
              const SizedBox(height: 16),
              editor,
            ]);
          }),
        ),
      ],
    );
  }

  BoxDecoration get _panelDeco => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      );

  Widget _listPanel() {
    final pages = (_total / _pageSize).ceil();
    return Container(
      decoration: _panelDeco,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<int?>(
            value: _catId,
            isExpanded: true,
            decoration: _inputDeco(_catsLoading ? 'Loading categories…' : 'Category'),
            items: [
              DropdownMenuItem<int?>(
                  value: null,
                  child: Text('All categories (${_cats.fold<int>(0, (s, c) => s + ((c['listings'] as num?)?.toInt() ?? 0))})')),
              for (final c in _cats)
                DropdownMenuItem<int?>(
                  value: (c['cat_id'] as num).toInt(),
                  child: Text('${c['cat_name']} (${c['listings']})', overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) {
              setState(() => _catId = v);
              _loadListings(reset: true);
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _searchCtrl,
            decoration: _inputDeco('Search name, phone, location').copyWith(
              prefixIcon: const Icon(Icons.search_rounded, size: 18),
            ),
            onSubmitted: (_) => _loadListings(reset: true),
          ),
          const SizedBox(height: 10),
          Text(
            _listLoading ? 'Loading…' : '$_total ${_type == 'shop' ? 'shops' : 'services'}',
            style: const TextStyle(fontSize: 12, color: textSecondary),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: _listError != null
                ? Center(
                    child: Text(_listError!,
                        textAlign: TextAlign.center, style: const TextStyle(color: errorColor)))
                : _listLoading && _items.isEmpty
                    ? const Center(child: CircularProgressIndicator(color: accentColor))
                    : _items.isEmpty
                        ? const Center(
                            child: Text('No listings found', style: TextStyle(color: textMuted)))
                        : ListView.separated(
                            itemCount: _items.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, color: borderColor),
                            itemBuilder: (_, i) => _listTile(_items[i]),
                          ),
          ),
          if (pages > 1)
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton(
                onPressed: _page > 1 && !_listLoading
                    ? () {
                        _page--;
                        _loadListings();
                      }
                    : null,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Text('$_page / $pages', style: const TextStyle(fontSize: 12, color: textSecondary)),
              IconButton(
                onPressed: _page < pages && !_listLoading
                    ? () {
                        _page++;
                        _loadListings();
                      }
                    : null,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ]),
        ],
      ),
    );
  }

  Widget _listTile(Map<String, dynamic> item) {
    final selected = _selected != null && _selected!['id'] == item['id'];
    final paid = item['subscriber_type'] == 'paid';
    return InkWell(
      onTap: () => _select(item),
      child: Container(
        color: selected ? accentLight : null,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: _brandSoft,
            child: Text(_initials('${item['name']}'),
                style: const TextStyle(fontSize: 11, color: _brandDark, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${item['name']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
              Text('${item['cat_name']} · ${formatBdPhone('${item['phone']}')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, color: textSecondary)),
            ]),
          ),
          if (paid) const Icon(Icons.verified_rounded, size: 16, color: successColor),
          if (item['has_photo'] != true)
            const Tooltip(
              message: 'No photo — initials will be used',
              child: Icon(Icons.hide_image_outlined, size: 16, color: textMuted),
            ),
        ]),
      ),
    );
  }

  Widget _editorPanel({bool scroll = true}) {
    if (_selected == null) {
      return Container(
        decoration: _panelDeco,
        height: 360,
        child: const Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.badge_outlined, size: 40, color: textMuted),
            SizedBox(height: 8),
            Text('Choose a listing to make its card', style: TextStyle(color: textSecondary)),
          ]),
        ),
      );
    }
    final content = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Preview
        Container(
          decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.all(20),
          child: Stack(children: [
            FittedBox(
              fit: BoxFit.contain,
              child: RepaintBoundary(
                key: _cardKey,
                child: SizedBox(
                  width: _cardW,
                  height: _cardH,
                  child: _type == 'shop' ? _ShopCard(data: _cardData) : _ServiceCard(data: _cardData),
                ),
              ),
            ),
            if (_imagesLoading)
              const Positioned(
                right: 8,
                top: 8,
                child: SizedBox(
                    width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: accentColor)),
              ),
          ]),
        ),
        const SizedBox(height: 16),
        // Editor
        Container(
          decoration: _panelDeco,
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              const Text('Card text',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Edits change only this card, not the database.',
                    style: TextStyle(fontSize: 12, color: textSecondary)),
              ),
              TextButton.icon(
                onPressed: () => _select(_selected!),
                icon: const Icon(Icons.restart_alt_rounded, size: 16),
                label: const Text('Reset'),
              ),
            ]),
            const SizedBox(height: 10),
            Wrap(spacing: 12, runSpacing: 12, children: [
              _field(_nameCtrl, 'Name', 320),
              _field(_catCtrl, 'Category label', 220),
              _field(_phoneCtrl, 'Phone', 180),
              _field(_locCtrl, 'Location', 320),
              _field(_descCtrl, 'Description', 540, maxLines: 2),
            ]),
            const SizedBox(height: 8),
            Wrap(spacing: 18, children: [
              _check('Show description', _showDescription, (v) => setState(() => _showDescription = v)),
              _check('Show photo', _showPhoto, (v) => setState(() => _showPhoto = v)),
            ]),
            if (_phoneCtrl.text.trim().isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('This listing has no phone number.',
                    style: TextStyle(fontSize: 12, color: errorColor)),
              ),
            const SizedBox(height: 12),
            Row(children: [
              Text('${(_cardW * _exportRatio).toInt()} × ${(_cardH * _exportRatio).toInt()} px PNG',
                  style: const TextStyle(fontSize: 12, color: textSecondary)),
              const Spacer(),
              FilledButton.icon(
                onPressed: _exporting || _imagesLoading ? null : _downloadPng,
                style: FilledButton.styleFrom(backgroundColor: accentColor),
                icon: _exporting
                    ? const SizedBox(
                        width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.download_rounded, size: 18),
                label: Text(_exporting ? 'Preparing…' : 'Download PNG'),
              ),
            ]),
          ]),
        ),
      ]);
    return scroll ? SingleChildScrollView(child: content) : content;
  }

  InputDecoration _inputDeco(String label) => InputDecoration(
        labelText: label,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderColor)),
      );

  Widget _field(TextEditingController ctrl, String label, double width, {int maxLines = 1}) =>
      SizedBox(
        width: width,
        child: TextField(controller: ctrl, maxLines: maxLines, decoration: _inputDeco(label)),
      );

  Widget _check(String label, bool value, ValueChanged<bool> onChanged) => InkWell(
        onTap: () => onChanged(!value),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Checkbox(value: value, activeColor: accentColor, onChanged: (v) => onChanged(v ?? false)),
          Text(label, style: const TextStyle(fontSize: 13, color: textPrimary)),
        ]),
      );
}

// ── Shared card pieces ──────────────────────────────────────────────────────

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color fg;
  const _IconBox(this.icon, {this.bg = _brandSoft, this.fg = _brand});
  @override
  Widget build(BuildContext context) => Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, size: 24, color: fg),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final TextStyle style;
  const _InfoRow(this.icon, this.text, this.style);
  @override
  Widget build(BuildContext context) => Row(children: [
        _IconBox(icon),
        const SizedBox(width: 16),
        Expanded(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: style)),
      ]);
}

class _AaramMark extends StatelessWidget {
  final Color textColor;
  final String text;
  const _AaramMark({required this.textColor, required this.text});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 34,
          height: 34,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9)),
          child: Image.asset('assets/icons/logo.png', fit: BoxFit.contain),
        ),
        const SizedBox(width: 10),
        Text(text, style: _font(18, color: textColor, weight: FontWeight.w500)),
      ]);
}

// ── Service card: brand panel left, round photo, details right ─────────────

class _ServiceCard extends StatelessWidget {
  final _CardData data;
  const _ServiceCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        color: Colors.white,
        child: Stack(children: [
          // decorative corner
          Positioned(
            right: -90,
            top: -90,
            child: Container(
                width: 260, height: 260, decoration: const BoxDecoration(color: _brandSoft, shape: BoxShape.circle)),
          ),
          // left brand panel
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 360,
            child: Container(
              color: _brand,
              padding: const EdgeInsets.fromLTRB(30, 50, 30, 34),
              child: Column(children: [
                const Spacer(),
                Container(
                  width: 214,
                  height: 214,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFC9CCF8),
                    border: Border.all(color: Colors.white, width: 8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: data.photo != null
                      ? Image.memory(data.photo!, fit: BoxFit.cover, gaplessPlayback: true)
                      : Center(
                          child: Text(_initials(data.name),
                              style: _font(76, weight: FontWeight.w600, color: _brandDark)),
                        ),
                ),
                const SizedBox(height: 26),
                if (data.category.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxWidth: 290),
                    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(40)),
                    child: Text(data.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: _font(22, weight: FontWeight.w600, color: _brandDark)),
                  ),
                const Spacer(),
                const _AaramMark(textColor: Colors.white, text: 'Find on AaramBD'),
              ]),
            ),
          ),
          // right details
          Positioned(
            left: 420,
            right: 56,
            top: 64,
            bottom: 56,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('SERVICE PROVIDER',
                  style: _font(18, weight: FontWeight.w600, color: _brand, letterSpacing: 4)),
              const SizedBox(height: 10),
              Text(data.name.isEmpty ? 'Name' : data.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _font(50, weight: FontWeight.w700, height: 1.15)),
              if (data.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(data.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _font(23, color: _body, height: 1.4)),
              ],
              const Spacer(),
              if (data.phone.isNotEmpty)
                _InfoRow(Icons.call_rounded, data.phone,
                    _font(38, weight: FontWeight.w700, letterSpacing: 1)),
              if (data.location.isNotEmpty) ...[
                const SizedBox(height: 18),
                _InfoRow(Icons.location_on_rounded, data.location, _font(24, color: _bodyDark)),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Shop card: details left, square photo right, brand phone bar bottom ────

class _ShopCard extends StatelessWidget {
  final _CardData data;
  const _ShopCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        color: Colors.white,
        child: Stack(children: [
          // details
          Positioned(
            left: 60,
            top: 56,
            right: 440,
            bottom: 150,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (data.category.isNotEmpty)
                Container(
                  padding: const EdgeInsets.fromLTRB(8, 8, 22, 8),
                  decoration: BoxDecoration(color: _brandSoft, borderRadius: BorderRadius.circular(40)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(color: _brand, shape: BoxShape.circle),
                      clipBehavior: Clip.antiAlias,
                      child: data.catLogo != null
                          ? Container(
                              color: Colors.white,
                              padding: const EdgeInsets.all(4),
                              child: Image.memory(data.catLogo!, fit: BoxFit.contain))
                          : const Icon(Icons.storefront_rounded, size: 18, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Text(data.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _font(21, weight: FontWeight.w600, color: _brandDark)),
                    ),
                  ]),
                ),
              const SizedBox(height: 22),
              Text(data.name.isEmpty ? 'Shop name' : data.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _font(50, weight: FontWeight.w700, height: 1.15)),
              if (data.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(data.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _font(23, color: _body, height: 1.4)),
              ],
              const Spacer(),
              if (data.location.isNotEmpty)
                _InfoRow(Icons.location_on_rounded, data.location, _font(24, color: _bodyDark)),
            ]),
          ),
          // photo
          Positioned(
            right: 60,
            top: 56,
            width: 340,
            height: 340,
            child: Container(
              decoration: BoxDecoration(color: _brandSoft, borderRadius: BorderRadius.circular(26)),
              clipBehavior: Clip.antiAlias,
              child: data.photo != null
                  ? Image.memory(data.photo!, fit: BoxFit.cover, gaplessPlayback: true)
                  : data.catLogo != null
                      ? Padding(
                          padding: const EdgeInsets.all(70),
                          child: Image.memory(data.catLogo!, fit: BoxFit.contain),
                        )
                      : const Icon(Icons.storefront_rounded, size: 120, color: _brand),
            ),
          ),
          // phone bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 120,
            child: Container(
              color: _brand,
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Row(children: [
                if (data.phone.isNotEmpty) ...[
                  const _IconBox(Icons.call_rounded, bg: Color(0x33FFFFFF), fg: Colors.white),
                  const SizedBox(width: 18),
                  Text(data.phone,
                      style: _font(44, weight: FontWeight.w700, color: Colors.white, letterSpacing: 1)),
                ],
                const Spacer(),
                const _AaramMark(textColor: Colors.white, text: 'Find this shop on AaramBD'),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
