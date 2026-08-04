import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/models.dart';
import '../../shared/providers/app_providers.dart';
import 'gemini_service.dart';
import 'lea_responder.dart';

/// Chat conversationnel avec l'assistante Léa.
/// Réponses générées par l'API Gemini, alimentée par le contexte financier
/// réel de l'utilisateur (doublure du microservice Python prévu au cahier
/// des charges §3.2). En cas d'échec réseau/API, repli automatique sur les
/// réponses locales basées sur des règles (§2 : dégradation gracieuse).
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <ChatMessage>[];
  bool _typing = false;

  @override
  void initState() {
    super.initState();
    _messages.add(ChatMessage(
      role: ChatRole.assistant,
      content:
          'Bonjour 👋 Je suis Léa, votre assistante financière. Posez-moi une question : « Combien puis-je épargner ce mois-ci ? », « Où partent mes dépenses ? »…',
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final summary = ref.read(monthSummaryProvider);
    final goals = ref.read(goalsProvider);
    final categories = ref.read(categoriesProvider);

    final history = List<ChatMessage>.from(_messages);
    setState(() {
      _messages.add(ChatMessage(
          role: ChatRole.user, content: text, timestamp: DateTime.now()));
      _controller.clear();
      _typing = true;
    });
    _scrollDown();

    String reply;
    try {
      reply = await GeminiService.reply(
        question: text,
        summary: summary,
        goals: goals,
        categories: categories,
        history: history,
      );
    } catch (_) {
      reply = LeaResponder.reply(text, summary, goals, categories);
    }
    if (!mounted) return;
    setState(() {
      _typing = false;
      _messages.add(ChatMessage(
          role: ChatRole.assistant,
          content: reply,
          timestamp: DateTime.now()));
    });
    _scrollDown();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.milego;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Text('Léa', style: TextStyle(color: c.textPrimary)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_typing ? 1 : 0),
              itemBuilder: (context, i) {
                if (_typing && i == _messages.length) {
                  return const _Bubble(
                    text: 'Léa écrit…',
                    isUser: false,
                    muted: true,
                  );
                }
                final m = _messages[i];
                return _Bubble(
                    text: m.content, isUser: m.role == ChatRole.user);
              },
            ),
          ),
          _SuggestionsBar(onPick: (q) {
            _controller.text = q;
            _send();
          }),
          _Composer(controller: _controller, onSend: _send),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.text,
    required this.isUser,
    this.muted = false,
  });
  final String text;
  final bool isUser;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final c = context.milego;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : c.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          border: isUser ? null : Border.all(color: c.border),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser
                ? Colors.white
                : (muted ? c.textMuted : c.textPrimary),
            height: 1.4,
            fontStyle: muted ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ),
    );
  }
}

class _SuggestionsBar extends StatelessWidget {
  const _SuggestionsBar({required this.onPick});
  final ValueChanged<String> onPick;

  static const _qs = [
    'Combien puis-je épargner ?',
    'Où partent mes dépenses ?',
    'Mes objectifs sont-ils atteignables ?',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          for (final q in _qs)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Text(q, style: const TextStyle(fontSize: 12)),
                onPressed: () => onPick(q),
                backgroundColor: AppColors.primarySoft,
                labelStyle:
                    const TextStyle(color: AppColors.primaryDark),
                side: BorderSide.none,
              ),
            ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.onSend});
  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final c = context.milego;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onSubmitted: (_) => onSend(),
                style: TextStyle(color: c.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Écrire à Léa…',
                  filled: true,
                  fillColor: c.surface,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: c.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: c.border),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: AppColors.primary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onSend,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
