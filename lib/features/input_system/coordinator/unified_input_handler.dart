import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/task_model.dart';
import '../../../core/models/task_group.dart';
import '../../dashboard/tasks/create_task_dialog.dart';
import '../../dashboard/tasks/create_task_group_dialog.dart';
import '../../dashboard/appointments/widgets/add_appointment_dialog.dart';
import '../../dashboard/expenses/widgets/add_expense_dialog.dart';
import '../../dashboard/quotes_diary/widgets/add_entry_dialog.dart';

// Cloudinary Configuration
final _cloudinary = CloudinaryPublic('dlbwwddv5', 'chat123', cache: false);

// Gemini API Key
const String _geminiApiKey = 'AIzaSyDyTexcA5nzBO54Hq9KJ-gzgfVGMhsjrs0';

/// معالج الإدخال الموحد - يدير جميع طرق الإدخال (نص، صوت، صورة، كاميرا)
/// ويوجه البيانات إلى التابات المناسبة
class UnifiedInputHandler {
  final BuildContext context;
  final TabController tabController;
  final VoidCallback? onDataSaved;
  
  late stt.SpeechToText _speech;
  late GenerativeModel _model;
  
  bool _isListening = false;
  String _fullSpeechText = '';
  bool _continuousListening = true;
  Timer? _speechTimer;
  
  List<Map<String, dynamic>> _extractedItems = [];
  
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  UnifiedInputHandler({
    required this.context,
    required this.tabController,
    this.onDataSaved,
  }) {
    _speech = stt.SpeechToText();
    _initializeGemini();
  }

  void _initializeGemini() {
    _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _geminiApiKey);
  }

  void dispose() {
    _speechTimer?.cancel();
  }

  /// عرض ورقة إضافة سريعة شاملة
  void showQuickAddSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _QuickAddSheet(
        onTextInput: () {
          Navigator.pop(ctx);
          _showTextInputDialog();
        },
        onVoiceInput: () {
          Navigator.pop(ctx);
          _startVoiceInput();
        },
        onCameraInput: () {
          Navigator.pop(ctx);
          _pickImage(ImageSource.camera);
        },
        onGalleryInput: () {
          Navigator.pop(ctx);
          _pickImage(ImageSource.gallery);
        },
        onManualAdd: (type) {
          Navigator.pop(ctx);
          _showManualAddDialog(type);
        },
      ),
    );
  }

  /// إضافة يدوية حسب النوع
  void _showManualAddDialog(String type) {
    switch (type) {
      case 'task':
        _showTaskCreationFlow();
        break;
      case 'appointment':
        showDialog(
          context: context,
          builder: (ctx) => const AddAppointmentDialog(),
        );
        break;
      case 'expense':
        showDialog(
          context: context,
          builder: (ctx) => const AddExpenseDialog(),
        );
        break;
      case 'quote':
        showDialog(
          context: context,
          builder: (ctx) => const AddEntryDialog(),
        );
        break;
    }
  }

  /// عرض نافذة إدخال النص الذكي
  void _showTextInputDialog() {
    final noteController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF58CC02).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFF58CC02),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'إدخال ذكي',
              style: GoogleFonts.tajawal(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                hintText: 'اكتب أي شيء وسأستخرجه تلقائياً...',
                hintStyle: GoogleFonts.tajawal(color: Colors.grey),
                border: const OutlineInputBorder(),
              ),
              maxLines: 5,
              autofocus: true,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.tips_and_updates,
                    size: 16,
                    color: Color(0xFF58CC02),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'مثال: اشتري حليب غداً، اجتماع الساعة 3، دفعت 50 جنيه',
                      style: GoogleFonts.tajawal(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.tajawal()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF58CC02),
            ),
            onPressed: () async {
              if (noteController.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await _processTextWithAI(noteController.text);
            },
            child: Text(
              'تحليل',
              style: GoogleFonts.tajawal(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// معالجة النص بالذكاء الاصطناعي
  Future<void> _processTextWithAI(String text) async {
    _showLoadingDialog('الذكاء الاصطناعي يحلل النص...');

    try {
      final prompt = '''
قم بتحليل النص التالي واستخراج جميع العناصر منه بدقة:

النص: "$text"

استخرج العناصر التالية:
- المهام: أي شيء يحتاج إنجاز (مثل: اشتري، اعمل، راجع، اتصل)
  * اقترح مجموعة مناسبة للمهمة من: 📚 مذاكرة، 🛒 تسوق، 💼 عمل، 🏠 منزل، 🏋️ رياضة، 🎯 شخصي
  * حدد الأولوية: urgent (عاجل)، high (عالي)، medium (متوسط)، low (منخفض)
- المواعيد: أي حدث بتاريخ/وقت (مثل: اجتماع، موعد، غداً، الساعة)
- المصروفات: أي ذكر للمال (مثل: دفعت، اشتريت، جنيه، ريال، دولار)
- الاقتباسات: عبارات ملهمة أو حكم
- الملاحظات: أي شيء آخر

أرجع JSON فقط بدون أي نص إضافي:
{
  "items": [
    {
      "type": "task",
      "title": "عنوان قصير (3-5 كلمات)",
      "content": "المحتوى الكامل",
      "date": "YYYY-MM-DD أو null",
      "time": "HH:MM أو null",
      "amount": رقم أو null,
      "currency": "ر.س/جنيه/دولار أو null",
      "suggestedGroup": "اسم المجموعة مع الإيموجي (للمهام فقط)",
      "priority": "urgent/high/medium/low (للمهام فقط، افتراضي medium)"
    }
  ]
}

مهم جداً: 
- أرجع JSON صحيح فقط
- type يجب أن يكون: task أو appointment أو expense أو quote أو note
- التاريخ بصيغة YYYY-MM-DD
- الوقت بصيغة 24 ساعة HH:MM
- suggestedGroup و priority للمهام فقط
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (context.mounted) Navigator.pop(context);

      if (response.text != null && response.text!.isNotEmpty) {
        var jsonStr = response.text!.trim();
        jsonStr = jsonStr.replaceAll('```json', '').replaceAll('```', '').trim();
        
        final jsonStart = jsonStr.indexOf('{');
        final jsonEnd = jsonStr.lastIndexOf('}');
        
        if (jsonStart != -1 && jsonEnd != -1) {
          jsonStr = jsonStr.substring(jsonStart, jsonEnd + 1);
          
          try {
            final data = json.decode(jsonStr);
            
            if (data['items'] != null && data['items'] is List && (data['items'] as List).isNotEmpty) {
              _extractedItems = List<Map<String, dynamic>>.from(data['items']);
              _showExtractedItemsDialog();
              return;
            }
          } catch (e) {
            debugPrint('JSON Parse Error: $e');
          }
        }
      }
      
      // إذا فشل التحليل، احفظ كملاحظة عادية
      if (context.mounted) {
        await _saveAsNote(text);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم الحفظ كملاحظة عادية', style: GoogleFonts.tajawal())),
        );
      }
    } catch (e) {
      debugPrint('AI Error: $e');
      if (context.mounted) {
        Navigator.pop(context);
        await _saveAsNote(text);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الاتصال - تم الحفظ كملاحظة', style: GoogleFonts.tajawal()),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  /// بدء الإدخال الصوتي
  Future<void> _startVoiceInput() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
    }

    bool available = await _speech.initialize();
    if (!available) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('التعرف على الصوت غير متاح', style: GoogleFonts.tajawal()),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    _fullSpeechText = '';
    _continuousListening = true;

    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _isListening
                          ? [const Color(0xFFFFB800), const Color(0xFFFFD900)]
                          : [Colors.grey[400]!, Colors.grey[600]!],
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_isListening)
                        Lottie.network(
                          'https://assets10.lottiefiles.com/packages/lf20_p7ml1rhe.json',
                          width: 150,
                          height: 150,
                        ),
                      Icon(
                        _isListening ? Icons.mic : Icons.mic_off,
                        color: Colors.white,
                        size: 48,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _isListening ? 'أستمع إليك...' : 'اضغط للتحدث',
                  style: GoogleFonts.tajawal(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  constraints: const BoxConstraints(minHeight: 100, maxHeight: 200),
                  child: SingleChildScrollView(
                    child: Text(
                      _fullSpeechText.isEmpty ? 'ابدأ بالتحدث...' : _fullSpeechText,
                      style: GoogleFonts.tajawal(
                        color: _fullSpeechText.isEmpty ? Colors.grey : Colors.black,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        _continuousListening = false;
                        _isListening = false;
                        _speechTimer?.cancel();
                        _speech.stop();
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.close, color: Colors.white),
                      label: Text('إلغاء', style: GoogleFonts.tajawal(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        if (_isListening) {
                          _continuousListening = false;
                          _isListening = false;
                          _speechTimer?.cancel();
                          await _speech.stop();
                          setDialogState(() => _isListening = false);
                          if (_fullSpeechText.isNotEmpty) {
                            Navigator.pop(context);
                            await _processTextWithAI(_fullSpeechText);
                            _fullSpeechText = '';
                          }
                        } else {
                          _continuousListening = true;
                          setDialogState(() => _isListening = true);
                          _startContinuousListening(setDialogState);
                        }
                      },
                      icon: Icon(_isListening ? Icons.check : Icons.mic, color: Colors.white),
                      label: Text(
                        _isListening ? 'حفظ' : 'تحدث',
                        style: GoogleFonts.tajawal(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isListening ? const Color(0xFF58CC02) : const Color(0xFFFFB800),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  void _startContinuousListening(StateSetter setDialogState) async {
    if (!_continuousListening) return;
    try {
      await _speech.listen(
        onResult: (result) {
          setDialogState(() {
            if (result.finalResult) {
              if (_fullSpeechText.isNotEmpty) _fullSpeechText += ' ';
              _fullSpeechText += result.recognizedWords;
            }
          });
        },
        listenFor: const Duration(minutes: 5),
        pauseFor: const Duration(seconds: 60),
        partialResults: true,
        cancelOnError: false,
        listenMode: stt.ListenMode.dictation,
        localeId: 'ar-SA',
      );
    } catch (e) {
      debugPrint('Speech Error: $e');
    }
  }

  /// التقاط صورة ومعالجتها
  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source, imageQuality: 85);

      if (image != null) {
        _showLoadingDialog('جاري معالجة الصورة...');

        try {
          CloudinaryResponse cloudinaryResponse = await _cloudinary.uploadFile(
            CloudinaryFile.fromFile(image.path, resourceType: CloudinaryResourceType.Image),
          );

          final imageBytes = await File(image.path).readAsBytes();
          
          final prompt = '''
قم بتحليل هذه الصورة بدقة واستخرج جميع المعلومات:
- إذا كانت فاتورة: استخرج المصروفات والمبالغ
- إذا كانت قائمة مهام: استخرج المهام
- إذا كانت جدول مواعيد: استخرج المواعيد
- إذا كانت نص: استخرج المحتوى

أرجع JSON فقط:
{
  "items": [
    {
      "type": "task/appointment/expense/quote/note",
      "title": "عنوان قصير",
      "content": "المحتوى",
      "amount": رقم أو null,
      "currency": "العملة أو null"
    }
  ]
}
''';

          final content = [Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)])];
          final aiResponse = await _model.generateContent(content);

          if (context.mounted) Navigator.pop(context);

          if (aiResponse.text != null && aiResponse.text!.isNotEmpty) {
            var jsonStr = aiResponse.text!.trim();
            jsonStr = jsonStr.replaceAll('```json', '').replaceAll('```', '').trim();
            
            final jsonStart = jsonStr.indexOf('{');
            final jsonEnd = jsonStr.lastIndexOf('}');
            
            if (jsonStart != -1 && jsonEnd != -1) {
              jsonStr = jsonStr.substring(jsonStart, jsonEnd + 1);
              
              try {
                final data = json.decode(jsonStr);
                if (data['items'] != null && data['items'] is List && (data['items'] as List).isNotEmpty) {
                  _extractedItems = List<Map<String, dynamic>>.from(data['items']);
                  for (var item in _extractedItems) {
                    item['imageUrl'] = cloudinaryResponse.secureUrl;
                  }
                  _showExtractedItemsDialog();
                  return;
                }
              } catch (e) {
                debugPrint('Image JSON Parse Error: $e');
              }
            }
          }
          
          // إذا فشل التحليل، احفظ الصورة كملاحظة
          if (context.mounted) {
            await _saveImageAsNote(cloudinaryResponse.secureUrl);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('تم حفظ الصورة', style: GoogleFonts.tajawal())),
            );
          }
        } catch (e) {
          debugPrint('Image Upload/Process Error: $e');
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('خطأ في معالجة الصورة', style: GoogleFonts.tajawal()),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Image Picker Error: $e');
    }
  }

  /// عرض العناصر المستخرجة للمراجعة
  void _showExtractedItemsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF58CC02).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF58CC02)),
              ),
              const SizedBox(width: 12),
              Text(
                'تم استخراج ${_extractedItems.length} عنصر',
                style: GoogleFonts.tajawal(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxHeight: 400),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _extractedItems.length,
              itemBuilder: (context, index) => _buildExtractedItemCard(
                _extractedItems[index], 
                index, 
                () => setDialogState(() => _extractedItems.removeAt(index)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _extractedItems.clear();
                Navigator.pop(context);
              },
              child: Text('إلغاء', style: GoogleFonts.tajawal(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _saveMultipleItems();
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF58CC02)),
              child: Text('حفظ الكل', style: GoogleFonts.tajawal(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtractedItemCard(Map<String, dynamic> item, int index, VoidCallback onRemove) {
    IconData icon;
    Color color;
    switch (item['type']) {
      case 'task':
        icon = Icons.task_alt_rounded;
        color = const Color(0xFF58CC02);
        break;
      case 'appointment':
        icon = Icons.calendar_month_rounded;
        color = const Color(0xFFFFB800);
        break;
      case 'expense':
        icon = Icons.attach_money_rounded;
        color = Colors.blue;
        break;
      case 'quote':
        icon = Icons.format_quote_rounded;
        color = Colors.purple;
        break;
      default:
        icon = Icons.note_rounded;
        color = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          item['title'] ?? 'بدون عنوان',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          item['content'] ?? '',
          style: GoogleFonts.tajawal(fontSize: 12),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 20),
          onPressed: onRemove,
        ),
      ),
    );
  }

  /// حفظ عناصر متعددة
  Future<void> _saveMultipleItems() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    _showLoadingDialog('جاري الحفظ...');

    int savedCount = 0;

    for (var item in _extractedItems) {
      switch (item['type']) {
        case 'task':
          await _saveTaskWithGroup(item);
          break;
        case 'appointment':
          await _saveAppointment(item);
          break;
        case 'expense':
          await _saveExpense(item);
          break;
        case 'quote':
          await _saveQuote(item);
          break;
        default:
          await _firestore.collection('users').doc(userId).collection('notes').add({
            ...item,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
      }
      savedCount++;
    }

    if (context.mounted) {
      Navigator.pop(context);
      _extractedItems.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حفظ $savedCount عنصر', style: GoogleFonts.tajawal()),
          backgroundColor: const Color(0xFF58CC02),
        ),
      );

      onDataSaved?.call();
    }
  }

  /// حفظ مهمة مع المجموعة
  Future<void> _saveTaskWithGroup(Map<String, dynamic> item) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    // البحث عن مجموعة أو إنشاء واحدة افتراضية
    String? groupId;
    final groupsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('taskGroups')
        .limit(1)
        .get();

    if (groupsSnapshot.docs.isNotEmpty) {
      groupId = groupsSnapshot.docs.first.id;
    } else {
      final newGroupRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('taskGroups')
          .add({
        'title': '📝 عام',
        'icon': '📝',
        'description': 'مجموعة عامة للمهام',
        'color': '#58CC02',
        'userId': userId,
        'totalTasks': 0,
        'completedTasks': 0,
        'taskIds': [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      groupId = newGroupRef.id;
    }

    DateTime? dueDate;
    if (item['date'] != null) {
      try {
        dueDate = DateTime.parse(item['date']);
      } catch (e) {
        debugPrint('Error parsing date: $e');
      }
    }

    final task = TaskModel(
      id: '',
      title: item['title'] ?? '',
      description: item['content'] ?? '',
      groupId: groupId,
      priority: item['priority'] ?? 'medium',
      dueDate: dueDate,
      tags: [],
      notes: '',
      isCompleted: false,
      createdAt: DateTime.now(),
      userId: userId,
    );

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('taskGroups')
        .doc(groupId)
        .collection('tasks')
        .add(task.toFirestore());
  }

  /// حفظ موعد
  Future<void> _saveAppointment(Map<String, dynamic> item) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    DateTime? dateTime;
    if (item['date'] != null) {
      try {
        dateTime = DateTime.parse(item['date']);
        if (item['time'] != null) {
          final timeParts = (item['time'] as String).split(':');
          dateTime = dateTime.add(Duration(
            hours: int.parse(timeParts[0]),
            minutes: int.parse(timeParts[1]),
          ));
        }
      } catch (e) {
        dateTime = DateTime.now();
      }
    } else {
      dateTime = DateTime.now();
    }

    await _firestore.collection('appointments').add({
      'title': item['title'] ?? '',
      'description': item['content'] ?? '',
      'dateTime': Timestamp.fromDate(dateTime),
      'userId': userId,
      'status': 'pending',
      'type': 'other',
      'reminder': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// حفظ مصروف
  Future<void> _saveExpense(Map<String, dynamic> item) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore.collection('expenses').add({
      'title': item['title'] ?? '',
      'description': item['content'] ?? '',
      'amount': (item['amount'] ?? 0).toDouble(),
      'currency': item['currency'] ?? 'ر.س',
      'category': 'other',
      'paymentMethod': 'cash',
      'date': Timestamp.now(),
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// حفظ اقتباس
  Future<void> _saveQuote(Map<String, dynamic> item) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore.collection('users').doc(userId).collection('notes').add({
      'type': 'quote',
      'title': item['title'] ?? '',
      'content': item['content'] ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// حفظ كملاحظة عادية
  Future<void> _saveAsNote(String text) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore.collection('users').doc(userId).collection('notes').add({
      'type': 'note',
      'title': text.length > 30 ? '${text.substring(0, 30)}...' : text,
      'content': text,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// حفظ صورة كملاحظة
  Future<void> _saveImageAsNote(String imageUrl) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore.collection('users').doc(userId).collection('notes').add({
      'type': 'note',
      'title': 'صورة - ${DateTime.now().toString().substring(0, 16)}',
      'content': 'صورة تم رفعها',
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// عرض نافذة تحميل
  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(color: Color(0xFF58CC02)),
            const SizedBox(width: 20),
            Expanded(child: Text(message, style: GoogleFonts.tajawal())),
          ],
        ),
      ),
    );
  }

  /// عرض تدفق إنشاء المهمة
  Future<void> _showTaskCreationFlow() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final groupsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('taskGroups')
        .get();

    if (!context.mounted) return;

    final selectedGroupId = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF58CC02).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.folder_rounded, color: Color(0xFF58CC02)),
            ),
            const SizedBox(width: 12),
            Text('اختر المجموعة', style: GoogleFonts.tajawal(fontWeight: FontWeight.w600)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Card(
                color: const Color(0xFFF8F8F8),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.task_alt, size: 24),
                  ),
                  title: Text('بدون مجموعة', style: GoogleFonts.tajawal(fontWeight: FontWeight.w600)),
                  subtitle: Text('إنشاء مهمة مستقلة', style: GoogleFonts.tajawal(fontSize: 12)),
                  onTap: () => Navigator.pop(ctx, 'NO_GROUP'),
                ),
              ),
              if (groupsSnapshot.docs.isNotEmpty) ...[
                const Divider(),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: groupsSnapshot.docs.length,
                    itemBuilder: (context, index) {
                      final doc = groupsSnapshot.docs[index];
                      final group = TaskGroup.fromFirestore(doc);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Text(group.icon, style: const TextStyle(fontSize: 32)),
                          title: Text(group.title, style: GoogleFonts.tajawal(fontWeight: FontWeight.w600)),
                          subtitle: Text(group.description ?? '', style: GoogleFonts.tajawal(fontSize: 12)),
                          onTap: () => Navigator.pop(ctx, group.id),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.tajawal()),
          ),
          if (groupsSnapshot.docs.isEmpty)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                showDialog(context: context, builder: (context) => const CreateTaskGroupDialog());
              },
              child: Text('إنشاء مجموعة', style: GoogleFonts.tajawal(color: const Color(0xFF58CC02))),
            ),
        ],
      ),
    );

    if (selectedGroupId != null && context.mounted) {
      if (selectedGroupId == 'NO_GROUP') {
        _showQuickTaskDialog();
      } else {
        showDialog(
          context: context,
          builder: (context) => CreateTaskDialog(groupId: selectedGroupId),
        );
      }
    }
  }

  /// مهمة سريعة بدون مجموعة
  void _showQuickTaskDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedPriority = 'medium';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF58CC02).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.task_alt, color: Color(0xFF58CC02)),
              ),
              const SizedBox(width: 12),
              Text('مهمة سريعة', style: GoogleFonts.tajawal(fontWeight: FontWeight.w600)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: 'عنوان المهمة',
                  labelStyle: GoogleFonts.tajawal(),
                  border: const OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descCtrl,
                decoration: InputDecoration(
                  labelText: 'الوصف (اختياري)',
                  labelStyle: GoogleFonts.tajawal(),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('الأولوية:', style: GoogleFonts.tajawal(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedPriority,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        DropdownMenuItem(value: 'urgent', child: Text('🔴 عاجل', style: GoogleFonts.tajawal())),
                        DropdownMenuItem(value: 'high', child: Text('🟠 عالي', style: GoogleFonts.tajawal())),
                        DropdownMenuItem(value: 'medium', child: Text('🟡 متوسط', style: GoogleFonts.tajawal())),
                        DropdownMenuItem(value: 'low', child: Text('🟢 منخفض', style: GoogleFonts.tajawal())),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => selectedPriority = value);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء', style: GoogleFonts.tajawal()),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF58CC02)),
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                
                final userId = _auth.currentUser?.uid;
                if (userId == null) return;

                await _firestore.collection('users').doc(userId).collection('notes').add({
                  'type': 'task',
                  'title': titleCtrl.text.trim(),
                  'content': descCtrl.text.trim(),
                  'priority': selectedPriority,
                  'completed': false,
                  'createdAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });

                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم إنشاء المهمة بنجاح', style: GoogleFonts.tajawal()),
                      backgroundColor: const Color(0xFF58CC02),
                    ),
                  );
                  onDataSaved?.call();
                }
              },
              child: Text('حفظ', style: GoogleFonts.tajawal(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

/// ورقة الإضافة السريعة
class _QuickAddSheet extends StatelessWidget {
  final VoidCallback onTextInput;
  final VoidCallback onVoiceInput;
  final VoidCallback onCameraInput;
  final VoidCallback onGalleryInput;
  final Function(String) onManualAdd;

  const _QuickAddSheet({
    required this.onTextInput,
    required this.onVoiceInput,
    required this.onCameraInput,
    required this.onGalleryInput,
    required this.onManualAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'إضافة جديد',
            style: GoogleFonts.tajawal(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // طرق الإدخال الذكية
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إدخال ذكي بالـ AI',
                  style: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildAIInputOption(Icons.keyboard_rounded, 'نص', const Color(0xFF58CC02), onTextInput),
                    _buildAIInputOption(Icons.mic_rounded, 'صوت', const Color(0xFFFFB800), onVoiceInput),
                    _buildAIInputOption(Icons.camera_alt_rounded, 'كاميرا', Colors.blue, onCameraInput),
                    _buildAIInputOption(Icons.image_rounded, 'صورة', Colors.purple, onGalleryInput),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // الإضافة اليدوية
          Text(
            'أو إضافة يدوية',
            style: GoogleFonts.tajawal(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 4,
            children: [
              _buildQuickAddOption(Icons.add_task_rounded, 'مهمة', const Color(0xFF58CC02), () => onManualAdd('task')),
              _buildQuickAddOption(Icons.event_rounded, 'موعد', const Color(0xFFFFB800), () => onManualAdd('appointment')),
              _buildQuickAddOption(Icons.receipt_long_rounded, 'مصروف', Colors.blue, () => onManualAdd('expense')),
              _buildQuickAddOption(Icons.format_quote_rounded, 'اقتباس', Colors.purple, () => onManualAdd('quote')),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAIInputOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildQuickAddOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
