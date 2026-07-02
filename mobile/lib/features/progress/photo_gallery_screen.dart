import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meu_personal_ai/core/network/api_client.dart';
import 'package:meu_personal_ai/core/theme/app_theme.dart';
import 'package:meu_personal_ai/features/payments/data/revenue_cat_service.dart';
import 'package:meu_personal_ai/features/payments/presentation/feature_gate.dart';

// ── Modelo ────────────────────────────────────────────────────

class ProgressPhoto {
  final String id;
  final String url;
  final DateTime takenAt;
  final String? note;
  final double? weightKg;

  const ProgressPhoto({
    required this.id,
    required this.url,
    required this.takenAt,
    this.note,
    this.weightKg,
  });

  factory ProgressPhoto.fromJson(Map<String, dynamic> j) => ProgressPhoto(
    id:       j['id'],
    url:      j['url'],
    takenAt:  DateTime.parse(j['takenAt']),
    note:     j['note'],
    weightKg: j['weightKg']?.toDouble(),
  );
}

// ── Providers ─────────────────────────────────────────────────

final progressPhotosProvider = FutureProvider<List<ProgressPhoto>>((ref) async {
  final api  = ref.read(apiClientProvider);
  final res  = await api.dio.get('/progress/photos');
  final list = res.data as List;
  return list.map((e) => ProgressPhoto.fromJson(e)).toList()
    ..sort((a, b) => b.takenAt.compareTo(a.takenAt));
});

// ── Tela principal ────────────────────────────────────────────

class PhotoGalleryScreen extends ConsumerStatefulWidget {
  const PhotoGalleryScreen({super.key});

  @override
  createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends ConsumerStatefulWidget {
  @override
  createState() => _State();
}

class _State extends ConsumerState<_PhotoGalleryScreenState>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final photosAsync = ref.watch(progressPhotosProvider);

    return FeatureGate(
      feature: 'Fotos de progresso',
      tier: FeatureTier.pro,
      showOverlay: false,
      child: Scaffold(
        backgroundColor: context.bgColor,
        appBar: AppBar(
          title: const Text('Progresso em fotos'),
          backgroundColor: context.cardColor,
          foregroundColor: context.textColor,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(44),
            child: TabBar(
              controller: _tabs,
              labelColor: AppColors.brandPrimary,
              unselectedLabelColor: context.textSecColor,
              indicatorColor: AppColors.brandPrimary,
              indicatorWeight: 2,
              tabs: const [
                Tab(text: 'Galeria'),
                Tab(text: 'Comparar'),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _uploading ? null : _addPhoto,
          backgroundColor: AppColors.black,
          child: _uploading
              ? const SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : const Icon(Icons.add_a_photo_rounded, color: Colors.white),
        ),
        body: TabBarView(
          controller: _tabs,
          children: [
            // ── Tab 1: Galeria ──────────────────────────────
            photosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:   (e, _) => _ErrorView(
                onRetry: () => ref.invalidate(progressPhotosProvider)),
              data: (photos) => photos.isEmpty
                  ? _EmptyGallery(onAdd: _addPhoto)
                  : _GalleryGrid(photos: photos, onDelete: _deletePhoto),
            ),

            // ── Tab 2: Comparar ─────────────────────────────
            photosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:   (_, __) => const SizedBox.shrink(),
              data: (photos) => photos.length < 2
                  ? _NeedMorePhotos()
                  : _CompareView(photos: photos),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    // Opcional: nota e peso
    final result = await _showPhotoMetaDialog(context);
    if (result == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      final bytes = await picked.readAsBytes();
      final api   = ref.read(apiClientProvider);

      final formData = FormData.fromMap({
        'photo': MultipartFile.fromBytes(bytes, filename: 'progress.jpg'),
        if (result.note?.isNotEmpty == true) 'note': result.note,
        if (result.weight != null) 'weightKg': result.weight.toString(),
      });

      await api.dio.post('/progress/photos', data: formData);
      ref.invalidate(progressPhotosProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto adicionada!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _deletePhoto(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir foto'),
        content: const Text('Esta foto será excluída permanentemente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ref.read(apiClientProvider).dio.delete('/progress/photos/$id');
      ref.invalidate(progressPhotosProvider);
    } catch (_) {}
  }

  Future<_PhotoMeta?> _showPhotoMetaDialog(BuildContext ctx) {
    String? note;
    double? weight;
    return showModalBottomSheet<_PhotoMeta>(
      context: ctx,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20, right: 20, top: 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Adicionar detalhes', style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700,
            color: context.textColor)),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Nota (opcional)',
              hintText: 'Ex: Semana 8, após bulk'),
            onChanged: (v) => note = v,
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Peso atual em kg (opcional)',
              hintText: 'Ex: 82.5'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (v) => weight = double.tryParse(v),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Pular'))),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx, _PhotoMeta(note: note, weight: weight)),
              child: const Text('Salvar'))),
          ]),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}

class _PhotoMeta {
  final String? note;
  final double? weight;
  const _PhotoMeta({this.note, this.weight});
}

// ── Galeria em grid ───────────────────────────────────────────

class _GalleryGrid extends StatelessWidget {
  final List<ProgressPhoto> photos;
  final ValueChanged<String> onDelete;
  const _GalleryGrid({required this.photos, required this.onDelete});

  @override
  Widget build(BuildContext context) => GridView.builder(
    padding: const EdgeInsets.all(12),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      crossAxisSpacing: 4,
      mainAxisSpacing: 4,
    ),
    itemCount: photos.length,
    itemBuilder: (ctx, i) => _PhotoTile(
      photo: photos[i],
      onTap: () => _openDetail(ctx, photos, i),
      onDelete: () => onDelete(photos[i].id),
    ),
  );

  void _openDetail(BuildContext ctx, List<ProgressPhoto> photos, int index) {
    Navigator.push(ctx, MaterialPageRoute(
      builder: (_) => _PhotoDetailScreen(photos: photos, initialIndex: index),
    ));
  }
}

class _PhotoTile extends StatelessWidget {
  final ProgressPhoto photo;
  final VoidCallback onTap, onDelete;
  const _PhotoTile({
    required this.photo, required this.onTap, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    onLongPress: onDelete,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(fit: StackFit.expand, children: [
        Image.network(
          photo.url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: context.divColor,
            child: Icon(Icons.broken_image_rounded,
              color: context.textSecColor)),
        ),
        // Data no canto inferior
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color(0xCC000000), Colors.transparent],
              ),
            ),
            child: Text(
              _fmtDate(photo.takenAt),
              style: const TextStyle(color: Colors.white, fontSize: 9,
                fontWeight: FontWeight.w500),
            ),
          ),
        ),
        if (photo.weightKg != null)
          Positioned(
            top: 4, right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.brandPrimary,
                borderRadius: BorderRadius.circular(8)),
              child: Text('${photo.weightKg!.toStringAsFixed(1)}kg',
                style: const TextStyle(color: Colors.white, fontSize: 8,
                  fontWeight: FontWeight.w700)),
            ),
          ),
      ]),
    ),
  );

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}';
}

// ── Comparação antes/depois ───────────────────────────────────

class _CompareView extends ConsumerStatefulWidget {
  final List<ProgressPhoto> photos;
  const _CompareView({required this.photos});
  @override
  createState() => _CompareViewState();
}

class _CompareViewState extends ConsumerState<_CompareView> {
  late int _leftIdx;
  late int _rightIdx;

  @override
  void initState() {
    super.initState();
    _leftIdx  = widget.photos.length - 1; // mais antiga
    _rightIdx = 0;                         // mais recente
  }

  @override
  Widget build(BuildContext context) {
    final left  = widget.photos[_leftIdx];
    final right = widget.photos[_rightIdx];

    final weightDiff = (left.weightKg != null && right.weightKg != null)
        ? right.weightKg! - left.weightKg!
        : null;

    final days = right.takenAt.difference(left.takenAt).inDays.abs();

    return Column(children: [
      // Seletores
      Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Expanded(child: _PhotoPicker(
            label: 'Antes',
            photos: widget.photos,
            selectedIndex: _leftIdx,
            onChanged: (i) => setState(() => _leftIdx = i),
          )),
          const SizedBox(width: 8),
          const Icon(Icons.compare_arrows_rounded, size: 20),
          const SizedBox(width: 8),
          Expanded(child: _PhotoPicker(
            label: 'Depois',
            photos: widget.photos,
            selectedIndex: _rightIdx,
            onChanged: (i) => setState(() => _rightIdx = i),
          )),
        ]),
      ),

      // Imagens lado a lado
      Expanded(
        child: Row(children: [
          Expanded(child: _ComparePhoto(photo: left,  label: 'Antes')),
          Container(width: 2, color: AppColors.black),
          Expanded(child: _ComparePhoto(photo: right, label: 'Depois')),
        ]),
      ),

      // Stats de diferença
      if (weightDiff != null || days > 0)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: context.cardColor,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _StatChip(label: 'Período', value: '$days dias'),
            if (weightDiff != null)
              _StatChip(
                label: 'Peso',
                value: '${weightDiff >= 0 ? "+" : ""}${weightDiff.toStringAsFixed(1)} kg',
                color: weightDiff < 0 ? AppColors.success : AppColors.brandPrimary,
              ),
          ]),
        ),
    ]);
  }
}

class _ComparePhoto extends StatelessWidget {
  final ProgressPhoto photo;
  final String label;
  const _ComparePhoto({required this.photo, required this.label});

  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
    Image.network(photo.url, fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(color: context.divColor)),
    Positioned(
      top: 10, left: 10,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(12)),
        child: Text(label, style: const TextStyle(
          color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    ),
  ]);
}

class _PhotoPicker extends StatelessWidget {
  final String label;
  final List<ProgressPhoto> photos;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  const _PhotoPicker({
    required this.label, required this.photos,
    required this.selectedIndex, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = photos[selectedIndex];
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.divColor)),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(p.url, width: 36, height: 36, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(width: 36, height: 36, color: context.divColor)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 10, color: context.textSecColor)),
            Text(_fmtDate(p.takenAt), style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: context.textColor)),
          ])),
          Icon(Icons.expand_more_rounded, size: 16, color: context.textSecColor),
        ]),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: photos.length,
        itemBuilder: (ctx, i) => ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(photos[i].url, width: 44, height: 44,
              fit: BoxFit.cover)),
          title: Text(_fmtDate(photos[i].takenAt)),
          subtitle: photos[i].weightKg != null
              ? Text('${photos[i].weightKg!.toStringAsFixed(1)} kg') : null,
          selected: i == selectedIndex,
          selectedTileColor: AppColors.brandPrimary.withOpacity(.08),
          onTap: () { onChanged(i); Navigator.pop(ctx); },
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
}

class _StatChip extends StatelessWidget {
  final String label, value;
  final Color? color;
  const _StatChip({required this.label, required this.value, this.color});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(label, style: TextStyle(fontSize: 10, color: context.textSecColor)),
    const SizedBox(height: 2),
    Text(value, style: TextStyle(
      fontSize: 16, fontWeight: FontWeight.w700,
      color: color ?? context.textColor)),
  ]);
}

// ── Tela de detalhe da foto ───────────────────────────────────

class _PhotoDetailScreen extends StatefulWidget {
  final List<ProgressPhoto> photos;
  final int initialIndex;
  const _PhotoDetailScreen({required this.photos, required this.initialIndex});
  @override
  createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<_PhotoDetailScreen> {
  late PageController _pg;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pg = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() { _pg.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photos[_current];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text('${_current + 1} / ${widget.photos.length}',
          style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ),
      body: Stack(children: [
        PageView.builder(
          controller: _pg,
          itemCount: widget.photos.length,
          onPageChanged: (i) => setState(() => _current = i),
          itemBuilder: (_, i) => InteractiveViewer(
            child: Center(child: Image.network(
              widget.photos[i].url,
              fit: BoxFit.contain,
            )),
          ),
        ),
        // Nota e peso
        if (photo.note != null || photo.weightKg != null)
          Positioned(
            bottom: 32, left: 20, right: 20,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (photo.weightKg != null)
                  Text('${photo.weightKg!.toStringAsFixed(1)} kg',
                    style: const TextStyle(color: Colors.white, fontSize: 16,
                      fontWeight: FontWeight.w700)),
                if (photo.note != null) ...[
                  const SizedBox(height: 4),
                  Text(photo.note!, style: const TextStyle(
                    color: Colors.white70, fontSize: 13)),
                ],
              ]),
            ),
          ),
      ]),
    );
  }
}

// ── Estados alternativos ──────────────────────────────────────

class _EmptyGallery extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyGallery({required this.onAdd});
  @override
  Widget build(BuildContext context) => Center(child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.photo_library_outlined, size: 56, color: context.divColor),
      const SizedBox(height: 16),
      Text('Nenhuma foto ainda', style: TextStyle(
        fontSize: 16, fontWeight: FontWeight.w600, color: context.textColor)),
      const SizedBox(height: 6),
      Text('Documente sua evolução.\nA primeira é a mais especial.',
        style: TextStyle(fontSize: 13, color: context.textSecColor),
        textAlign: TextAlign.center),
      const SizedBox(height: 24),
      ElevatedButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add_a_photo_rounded, size: 18),
        label: const Text('Adicionar primeira foto'),
      ),
    ],
  ));
}

class _NeedMorePhotos extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.compare_rounded, size: 48, color: context.divColor),
      const SizedBox(height: 12),
      Text('Adicione ao menos 2 fotos\npara comparar',
        style: TextStyle(fontSize: 14, color: context.textSecColor),
        textAlign: TextAlign.center),
    ],
  ));
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.wifi_off_rounded, size: 48, color: context.divColor),
      const SizedBox(height: 12),
      const Text('Não foi possível carregar'),
      const SizedBox(height: 12),
      ElevatedButton(onPressed: onRetry, child: const Text('Tentar novamente')),
    ],
  ));
}
