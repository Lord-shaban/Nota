// ===============================
// 🧠 gemini_prompts.dart
// -------------------------------
// Contains all reusable, organized, and commented prompt templates
// Prompts are written in Arabic for clarity
// ===============================

class GeminiPrompts {
  // 🧩 1. Prompt for summarizing text
  static const String summarizeText = '''
قم بتلخيص النص التالي بشكل دقيق ومفهوم، 
مع الحفاظ على أهم النقاط والأفكار الأساسية فقط:
''' ;

  // 🧩 2. Prompt for generating ideas
  static const String ideaGenerator = '''
أنشئ قائمة بأفكار إبداعية حول الموضوع التالي، 
مع توضيح سبب أهمية كل فكرة بإيجاز:
''' ;

  // 🧩 3. Prompt for code explanation
  static const String explainCode = '''
اشرح الكود التالي خطوة بخطوة بطريقة بسيطة، 
مع توضيح وظيفة كل جزء فيه:
''' ;

  // 🧩 4. Prompt for translation
  static const String translateToArabic = '''
ترجم النص التالي إلى العربية ترجمة احترافية، 
مع الحفاظ على المعنى الدقيق والأسلوب الأصلي:
''' ;

  // 🧩 5. Prompt for question answering
  static const String answerQuestion = '''
أجب عن السؤال التالي بإيجاز ودقة اعتماداً على المعلومات المتوفرة:
''' ;

  // 🧩 6. Prompt for content rewriting
  static const String rewriteContent = '''
أعد صياغة النص التالي بلغة عربية فصيحة وسهلة الفهم، 
مع الحفاظ على المعنى الأساسي للنص:
''' ;

  // 🧩 7. Prompt for technical explanation
  static const String explainTechnical = '''
اشرح المفهوم التقني التالي بطريقة مناسبة للمبتدئين، 
مع مثال عملي لتوضيحه:
''' ;

  // 🧩 8. Prompt for creative writing
  static const String creativeWriting = '''
اكتب نصاً إبداعياً قصيراً مستوحى من الموضوع التالي:
''' ;

  // 🧩 9. Prompt for workflow generation
  static const String workflowBuilder = '''
أنشئ مخطط عمل (Workflow) منظم وواضح للمشروع التالي، 
يوضح الخطوات الأساسية بالتسلسل المنطقي:
''' ;

  // 🧩 10. Prompt for API documentation
  static const String apiDocPrompt = '''
قم بإنشاء توثيق منظم وواضح لـ API التالي،
يتضمن الوصف، المعاملات، والاستجابات:
''' ;
}
