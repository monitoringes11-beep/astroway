import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../logic/share_content.dart';
import '../theme.dart';

/// Отправка картинки через стандартное меню Android «Поделиться».
/// В тестах подменяется, чтобы не вызывать системное меню.
class ShareService {
  static Future<void> Function(Uint8List png, String text) sender = _systemShare;

  static Future<void> _systemShare(Uint8List png, String text) async {
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        files: [XFile.fromData(png, mimeType: 'image/png', name: 'astroway.png')],
        fileNameOverrides: const ['astroway.png'],
      ),
    );
  }
}

/// Ширина карточки в логических пикселях; картинка сохраняется в 3× = 1080 px.
const shareCardWidth = 360.0;

/// Картинка-карточка в стиле AstroWay: волшебница, золото на тёмно-синем.
class ShareCard extends StatelessWidget {
  final ShareContent content;
  const ShareCard({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    final c = content;
    return MediaQuery(
      // картинка всегда одного размера, без крупного шрифта и системного масштаба
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: AW.ink, fontSize: 15, height: 1.4, decoration: TextDecoration.none),
        child: Container(
          width: shareCardWidth,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AW.gold.withValues(alpha: 0.4)),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AW.navy, AW.deep, Color(0xFF0A1128)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 170,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/images/witch-night.jpg',
                      fit: BoxFit.cover,
                      alignment: const Alignment(0, -0.6),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x000B1430), Color(0x660B1430), AW.navy],
                          stops: [0, 0.55, 1],
                        ),
                      ),
                    ),
                    const Positioned(
                      left: 20,
                      bottom: 10,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AstroWay',
                            style: TextStyle(
                              color: AW.gold,
                              fontSize: 28,
                              fontWeight: FontWeight.w500,
                              shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                            ),
                          ),
                          Text(
                            'сонник · гороскоп · расклады',
                            style: TextStyle(color: AW.soft, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.title,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: AW.ink),
                    ),
                    if (c.subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(c.subtitle!, style: const TextStyle(color: AW.gold, fontSize: 14)),
                      ),
                    for (final s in c.sections) ...[
                      const SizedBox(height: 16),
                      Text(
                        s.title,
                        style: const TextStyle(color: AW.gold, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(s.body),
                    ],
                    if (c.note != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        c.note!,
                        style: const TextStyle(color: AW.soft, fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                height: 1,
                color: AW.gold.withValues(alpha: 0.35),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Column(
                  children: [
                    Text(
                      ShareContent.brand,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AW.gold, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Развлекательный характер',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AW.soft, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Кнопка «Поделиться»: открывает предпросмотр карточки.
class ShareButton extends StatelessWidget {
  final ShareContent Function() content;
  const ShareButton({super.key, required this.content});

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: TextButton.icon(
      onPressed: () => showSharePreview(context, content()),
      icon: const Icon(Icons.share_rounded, size: 20),
      label: const Text('Поделиться'),
    ),
  );
}

Future<void> showSharePreview(BuildContext context, ShareContent content) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: AW.navy,
  showDragHandle: true,
  builder: (_) => _SharePreview(content: content),
);

class _SharePreview extends StatefulWidget {
  final ShareContent content;
  const _SharePreview({required this.content});
  @override
  State<_SharePreview> createState() => _SharePreviewState();
}

class _SharePreviewState extends State<_SharePreview> {
  final _key = GlobalKey();
  bool _busy = false;
  String? _error;

  Future<Uint8List> _capture() async {
    final boundary = _key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  }

  Future<void> _send() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final png = await _capture();
      await ShareService.sender(png, widget.content.plainText);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _error = 'Не получилось открыть меню «Поделиться». Попробуйте ещё раз.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Так увидят ваши друзья', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(
                'Имя, дата рождения и личные ответы на картинку не попадают.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AW.soft, fontSize: 13),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: RepaintBoundary(
                    key: _key,
                    child: ShareCard(content: widget.content),
                  ),
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(_error!, style: const TextStyle(color: Colors.orangeAccent)),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: FilledButton.icon(
                onPressed: _busy ? null : _send,
                icon: _busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.share_rounded),
                label: const Text('Отправить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
