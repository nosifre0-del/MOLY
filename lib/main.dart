import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MolyApp());
}

class MolyApp extends StatelessWidget {
  const MolyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MOLY',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0910),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF963FFF),
          secondary: Color(0xFFEBC65B),
        ),
      ),
      home: const MolyHome(),
    );
  }
}

class MolyMessage {
  final String role;
  final String text;

  MolyMessage(this.role, this.text);

  Map<String, dynamic> toJson() => {
        'role': role,
        'text': text,
      };

  factory MolyMessage.fromJson(Map<String, dynamic> json) {
    return MolyMessage(
      json['role']?.toString() ?? 'assistant',
      json['text']?.toString() ?? '',
    );
  }
}

/// نواة MOLY الأولية.
/// هذه ليست نموذجًا لغويًا متقدمًا؛ إنها أساس مستقل
/// لإدارة المحادثات والذاكرة والمعرفة المحلية.
class MolyCore {
  final List<String> knowledge = [];
  final Map<String, String> memory = {};

  String answer(String input) {
    final text = input.trim();
    final normalized = text.toLowerCase();

    if (text.isEmpty) {
      return 'اكتب ما تريد أن نتحدث عنه.';
    }

    if (normalized.contains('من أنت') ||
        normalized.contains('من انت')) {
      return 'أنا MOLY، النواة الأولية لمشروع الذكاء الاصطناعي '
          'التابع لـ NYXS. يجري تطوير قدراتي بصورة مستقلة.';
    }

    if (normalized.contains('اسمك')) {
      return 'اسمي MOLY.';
    }

    if (normalized.contains('مرحبا') ||
        normalized.contains('السلام عليكم')) {
      return 'أهلًا بك. أنا MOLY، كيف يمكنني مساعدتك؟';
    }

    if (normalized.startsWith('تذكر ')) {
      final fact = text.substring('تذكر '.length).trim();

      if (fact.isEmpty) {
        return 'اكتب المعلومة التي تريد حفظها بعد كلمة تذكر.';
      }

      final parts = fact.split('=');

      if (parts.length >= 2) {
        final key = parts.first.trim();
        final value = parts.sublist(1).join('=').trim();

        if (key.isNotEmpty && value.isNotEmpty) {
          memory[key] = value;
          return 'حفظت المعلومة في ذاكرة هذا الجهاز.';
        }
      }

      knowledge.add(fact);
      return 'أضفت المعلومة إلى سجل المعرفة المحلي. '
          'لم تُتحقق صحتها تلقائيًا.';
    }

    if (normalized.startsWith('ابحث في ذاكرتي')) {
      if (memory.isEmpty && knowledge.isEmpty) {
        return 'ذاكرتي المحلية فارغة حاليًا.';
      }

      final entries = <String>[
        ...memory.entries.map((e) => '${e.key}: ${e.value}'),
        ...knowledge,
      ];

      return 'المعلومات المحفوظة:\n${entries.join('\n')}';
    }

    if (normalized.startsWith('ما قيمة ')) {
      final key = text.substring('ما قيمة '.length).trim();

      if (memory.containsKey(key)) {
        return '$key: ${memory[key]}';
      }

      return 'لم أعثر على هذه المعلومة في الذاكرة المحلية.';
    }

    return 'وصلتني رسالتك: "$text"\n\n'
        'هذه نسخة النواة الأولية لمولي. '
        'لم أُربط بنموذج لغوي خارجي، لكنني أيضًا لم أُزوّد بعد '
        'بنموذج لغوي مستقل قادر على فهم الأسئلة المفتوحة والإجابة عنها. '
        'الخطوة التالية هي تشغيل نموذج خاص بمشروع MOLY.';
  }
}

class MolyHome extends StatefulWidget {
  const MolyHome({super.key});

  @override
  State<MolyHome> createState() => _MolyHomeState();
}

class _MolyHomeState extends State<MolyHome> {
  final MolyCore core = MolyCore();
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();

  final List<MolyMessage> messages = [];

  String selectedVoice = 'الصوت الرجولي الشاب';
  bool thinking = false;

  final List<String> voices = const [
    'الصوت الرجولي العميق',
    'الصوت الرجولي الشاب',
    'الصوت النسائي الهادئ',
    'الصوت النسائي الطبيعي',
    'الصوت العربي الفصيح',
    'الصوت العراقي',
    'صوت مولي الخاص',
  ];

  @override
  void initState() {
    super.initState();
    restore();
  }

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();

    final savedMessages = prefs.getString('moly_messages');
    final savedMemory = prefs.getString('moly_memory');
    final savedKnowledge = prefs.getStringList('moly_knowledge');

    if (savedMessages != null) {
      try {
        final decoded = jsonDecode(savedMessages) as List;

        messages.addAll(decoded.map((item) {
          return MolyMessage.fromJson(
            Map<String, dynamic>.from(item as Map),
          );
        }));
      } catch (_) {}
    }

    if (savedMemory != null) {
      try {
        core.memory.addAll(
          Map<String, String>.from(jsonDecode(savedMemory)),
        );
      } catch (_) {}
    }

    if (savedKnowledge != null) {
      core.knowledge.addAll(savedKnowledge);
    }

    if (!mounted) return;

    setState(() {
      selectedVoice =
          prefs.getString('moly_voice') ?? voices[1];
    });
  }

  Future<void> persist() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'moly_messages',
      jsonEncode(messages.map((m) => m.toJson()).toList()),
    );

    await prefs.setString(
      'moly_memory',
      jsonEncode(core.memory),
    );

    await prefs.setStringList(
      'moly_knowledge',
      core.knowledge,
    );

    await prefs.setString('moly_voice', selectedVoice);
  }

  Future<void> send() async {
    final text = controller.text.trim();

    if (text.isEmpty || thinking) return;

    setState(() {
      messages.add(MolyMessage('user', text));
      controller.clear();
      thinking = true;
    });

    await persist();

    final reply = core.answer(text);

    if (!mounted) return;

    setState(() {
      messages.add(MolyMessage('assistant', reply));
      thinking = false;
    });

    await persist();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> chooseVoice() async {
    final voice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF191522),
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text(
                'أصوات MOLY',
                style: TextStyle(
                  color: Color(0xFFEBC65B),
                  fontSize: 21,
                ),
              ),
            ),
            ...voices.map(
              (voice) => ListTile(
                leading: const Icon(
                  Icons.graphic_eq,
                  color: Color(0xFF963FFF),
                ),
                title: Text(voice),
                trailing: voice == selectedVoice
                    ? const Icon(
                        Icons.check,
                        color: Color(0xFFEBC65B),
                      )
                    : null,
                onTap: () => Navigator.pop(context, voice),
              ),
            ),
          ],
        ),
      ),
    );

    if (voice == null) return;

    setState(() => selectedVoice = voice);
    await persist();
  }

  Future<void> clearChat() async {
    setState(() => messages.clear());
    await persist();
  }

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFEBC65B);
    const purple = Color(0xFF963FFF);
    const card = Color(0xFF191522);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF100C18),
          title: const Text(
            'M O L Y',
            style: TextStyle(
              color: gold,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
          actions: [
            IconButton(
              onPressed: chooseVoice,
              icon: const Icon(Icons.graphic_eq, color: gold),
              tooltip: 'الأصوات',
            ),
            IconButton(
              onPressed: clearChat,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'مسح المحادثة',
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: messages.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 78,
                            color: gold,
                          ),
                          SizedBox(height: 20),
                          Text(
                            'أنا MOLY',
                            style: TextStyle(
                              color: gold,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'نواة مستقلة قيد التطوير',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(14),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final user = message.role == 'user';

                        return Align(
                          alignment: user
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              vertical: 6,
                            ),
                            padding: const EdgeInsets.all(14),
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.86,
                            ),
                            decoration: BoxDecoration(
                              color: user
                                  ? const Color(0xFF49236F)
                                  : card,
                              borderRadius: BorderRadius.circular(17),
                              border: Border.all(
                                color: user
                                    ? purple
                                    : gold.withOpacity(0.25),
                              ),
                            ),
                            child: SelectableText(
                              message.text,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.6,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (thinking)
              const LinearProgressIndicator(
                color: purple,
                backgroundColor: card,
              ),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
              color: const Color(0xFF100C18),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 5,
                      onSubmitted: (_) => send(),
                      decoration: InputDecoration(
                        hintText: 'اكتب رسالتك إلى مولي...',
                        filled: true,
                        fillColor: card,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: thinking ? null : send,
                    style: IconButton.styleFrom(
                      backgroundColor: purple,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.arrow_upward),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }
}