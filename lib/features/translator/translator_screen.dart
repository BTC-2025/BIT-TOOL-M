import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/widgets/neumorphic_widgets.dart';

class TranslatorScreen extends StatefulWidget {
  const TranslatorScreen({super.key});

  @override
  State<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen> {
  final TextEditingController _inputController = TextEditingController();
  String _sourceLang = 'English';
  String _targetLang = 'Spanish';
  String _translatedText = '';
  bool _isTranslating = false;
  bool _isListening = false;

  final List<String> _languages = [
    'English',
    'Spanish',
    'French',
    'German',
    'Hindi',
    'Japanese',
    'Chinese',
    'Arabic',
    'Italian',
    'Korean',
    'Russian',
    'Portuguese',
    'Turkish',
    'Tamil',
  ];

  // Translation dictionary for realistic live translation simulation
  final Map<String, Map<String, String>> _dictionary = {
    'hello': {
      'Spanish': 'Hola',
      'French': 'Bonjour',
      'German': 'Hallo',
      'Hindi': 'नमस्ते (Namaste)',
      'Japanese': 'こんにちは (Konnichiwa)',
      'Chinese': '你好 (Nǐ hǎo)',
      'Arabic': 'مرحباً (Marhaban)',
      'Italian': 'Ciao',
      'Korean': '안녕하세요 (Annyeonghaseyo)',
      'Russian': 'Привет (Privet)',
      'Portuguese': 'Olá',
      'Turkish': 'Merhaba',
      'Tamil': 'வணக்கம் (Vanakkam)',
    },
    'how are you?': {
      'Spanish': '¿Cómo estás?',
      'French': 'Comment ça va?',
      'German': 'Wie geht es dir?',
      'Hindi': 'आप कैसे हैं? (Aap kaise hain?)',
      'Japanese': 'お元気ですか (Ogenki desu ka)',
      'Chinese': '你好吗 (Nǐ hǎo ma)',
      'Arabic': 'كيف حالك؟ (Kayfa haluk?)',
      'Italian': 'Come stai?',
      'Korean': '어떻게 지내세요? (Eotteoke jinaeseyo?)',
      'Russian': 'Как дела? (Kak dela?)',
      'Portuguese': 'Como você está?',
      'Turkish': 'Nasılsın?',
      'Tamil':
          'நீங்கள் எப்படி இருக்கிறீர்கள்? (Neengal eppadi irukkireergall?)',
    },
    'good morning': {
      'Spanish': 'Buenos días',
      'French': 'Bonjour',
      'German': 'Guten Morgen',
      'Hindi': 'सुप्रभात (Suprabhat)',
      'Japanese': 'おはようございます (Ohayou gozaimasu)',
      'Chinese': '早上好 (Zǎoshang hǎo)',
      'Arabic': 'صباح الخير (Sabah al-khair)',
      'Italian': 'Buongiorno',
      'Korean': '좋은 아침입니다 (Joeun achimidnida)',
      'Russian': 'Доброе утро (Dobroye utro)',
      'Portuguese': 'Bom dia',
      'Turkish': 'Günaydın',
      'Tamil': 'காலை வணக்கம் (Kaalai vanakkam)',
    },
    'thank you': {
      'Spanish': 'Gracias',
      'French': 'Merci',
      'German': 'Danke',
      'Hindi': 'धन्यवाद (Dhanyavaad)',
      'Japanese': 'ありがとう (Arigatou)',
      'Chinese': '谢谢 (Xièxiè)',
      'Arabic': 'شكراً (Shukran)',
      'Italian': 'Grazie',
      'Korean': '감사합니다 (Gamsahabnida)',
      'Russian': 'Спасибо (Spasibo)',
      'Portuguese': 'Obrigado',
      'Turkish': 'Teşekkür ederim',
      'Tamil': 'நன்றி (Nandri)',
    },
    'i love coding': {
      'Spanish': 'Me encanta codificar',
      'French': 'J\'adore coder',
      'German': 'Ich liebe das Programmieren',
      'Hindi': 'मुझे कोडिंग पसंद है (Mujhe coding pasand hai)',
      'Japanese': 'コーディングが大好きです (Kōdingu ga daisukidesu)',
      'Chinese': '我喜欢写代码 (Wǒ xǐhuān xiě dàimǎ)',
      'Arabic': 'أنا أحب البرمجة (Ana uhib al-barmaja)',
      'Italian': 'Amo programmare',
      'Korean': '코딩을 사랑합니다 (Koding-eul saranghabnida)',
      'Russian': 'Я люблю программировать (YA lyublyu programmirovat\')',
      'Portuguese': 'Eu amo programar',
      'Turkish': 'Kod yazmayı seviyorum',
      'Tamil':
          'எனக்கு குறியீட்டு முறை பிடிக்கும் (Enakku kuriyeettu murai pidikkum)',
    },
  };

  void _translate() {
    final text = _inputController.text.trim().toLowerCase();
    if (text.isEmpty) {
      setState(() => _translatedText = '');
      return;
    }

    setState(() => _isTranslating = true);

    // Simulate network delay for live translator feel
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;

      String translation = '';
      if (_sourceLang == _targetLang) {
        translation = _inputController.text.trim();
      } else if (_dictionary.containsKey(text) &&
          _dictionary[text]!.containsKey(_targetLang)) {
        translation = _dictionary[text]![_targetLang]!;
      } else {
        // Fallback pseudo-translation generator for any custom user input
        translation = _generatePseudoTranslation(
          _inputController.text.trim(),
          _targetLang,
        );
      }

      setState(() {
        _translatedText = translation;
        _isTranslating = false;
      });
    });
  }

  String _generatePseudoTranslation(String text, String lang) {
    // Generates a mock suffix/prefix translation styling depending on language selected
    switch (lang) {
      case 'Spanish':
        return '${text}o de la traducción';
      case 'French':
        return 'Le $text';
      case 'German':
        return 'Das ${text}en';
      case 'Hindi':
        return '$text (अनुवादित)';
      case 'Japanese':
        return '$text です (desu)';
      case 'Chinese':
        return '翻译 $text';
      case 'Arabic':
        return 'مترجم $text';
      case 'Italian':
        return '$text (tradotto)';
      case 'Korean':
        return '$text (번역됨)';
      case 'Russian':
        return '$text (переведено)';
      case 'Portuguese':
        return '$text (traduzido)';
      case 'Turkish':
        return '$text (çevrildi)';
      case 'Tamil':
        return '$text (மொழிபெயர்க்கப்பட்டது)';
      default:
        return text;
    }
  }

  void _simulateVoiceInput() {
    setState(() => _isListening = true);

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _isListening = false;
        _inputController.text = 'Hello';
        _translate();
      });
    });
  }

  void _speakText(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.volume_up, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text('Speaking: "$text"')),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          // Language Selectors Row
          Row(
            children: [
              Expanded(
                child: NeumorphicCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _sourceLang,
                      isExpanded: true,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                      items: _languages.map((lang) {
                        return DropdownMenuItem(value: lang, child: Text(lang));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _sourceLang = val;
                          });
                          _translate();
                        }
                      },
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(Icons.swap_horiz_rounded, color: Colors.grey),
              ),
              Expanded(
                child: NeumorphicCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _targetLang,
                      isExpanded: true,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                      items: _languages.map((lang) {
                        return DropdownMenuItem(value: lang, child: Text(lang));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _targetLang = val;
                          });
                          _translate();
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Source Input Card
          NeumorphicCard(
            borderRadius: 20,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _sourceLang,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                    if (_inputController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _inputController.clear();
                          setState(() => _translatedText = '');
                        },
                      ),
                  ],
                ),
                TextField(
                  controller: _inputController,
                  maxLines: 4,
                  minLines: 3,
                  style: const TextStyle(fontSize: 16),
                  decoration: const InputDecoration(
                    hintText: 'Type text to translate...',
                    border: InputBorder.none,
                  ),
                  onChanged: (val) => _translate(),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.paste_rounded, size: 18),
                      onPressed: () async {
                        final data = await Clipboard.getData('text/plain');
                        if (data?.text != null) {
                          _inputController.text = data!.text!;
                          _translate();
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        size: 18,
                        color: _isListening ? Colors.red : null,
                      ),
                      onPressed: _simulateVoiceInput,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Translation Result Card
          NeumorphicCard(
            borderRadius: 20,
            inset: true,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _targetLang,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    if (_translatedText.isNotEmpty)
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.volume_up, size: 18),
                            onPressed: () => _speakText(_translatedText),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_all, size: 18),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: _translatedText),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Copied translation to clipboard',
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                _isTranslating
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Text(
                        _translatedText.isEmpty
                            ? 'Translation will appear here...'
                            : _translatedText,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _translatedText.isEmpty ? Colors.grey : null,
                        ),
                      ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Speech listen visualizer modal
          if (_isListening)
            NeumorphicCard(
              borderRadius: 16,
              padding: const EdgeInsets.all(20),
              color: Colors.red.withValues(alpha: 0.05),
              child: Column(
                children: [
                  const Icon(Icons.mic, color: Colors.red, size: 36),
                  const SizedBox(height: 12),
                  const Text(
                    'Listening to voice input...',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 100,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.red.withValues(alpha: 0.1),
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
