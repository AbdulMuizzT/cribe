import '../models/models.dart';

/// Central place for UI copy that changes with the selected language.
/// Covers navigation, Home, and the headline labels on the main screens —
/// not every microcopy string in the app (that would be a much larger
/// effort than a hackathon prototype needs), but everything a judge sees
/// first when switching languages. Product descriptions are translated
/// separately per-product via the AI Catalog / Gemini backend.
class AppStrings {
  static const Map<String, Map<String, String>> _s = {
    // Navigation
    'home': {'en': 'Home', 'hi': 'होम', 'ta': 'முகப்பு'},
    'products': {'en': 'Products', 'hi': 'उत्पाद', 'ta': 'பொருட்கள்'},
    'add': {'en': 'Add', 'hi': 'जोड़ें', 'ta': 'சேர்'},
    'markets': {'en': 'Markets', 'hi': 'बाज़ार', 'ta': 'சந்தைகள்'},
    'profile': {'en': 'Profile', 'hi': 'प्रोफ़ाइल', 'ta': 'சுயவிவரம்'},

    // Home
    'goodMorning': {'en': 'Good morning', 'hi': 'सुप्रभात', 'ta': 'காலை வணக்கம்'},
    'assistantSub': {
      'en': 'Your digital business assistant',
      'hi': 'आपका डिजिटल व्यापार सहायक',
      'ta': 'உங்கள் டிஜிட்டல் வணிக உதவியாளர்',
    },
    'quickActions': {'en': 'Quick actions', 'hi': 'त्वरित कार्य', 'ta': 'விரைவு செயல்கள்'},
    'addProduct': {'en': 'Add Product', 'hi': 'उत्पाद जोड़ें', 'ta': 'பொருள் சேர்க்க'},
    'describeByVoice': {'en': 'Describe by Voice', 'hi': 'आवाज़ से बताएं', 'ta': 'குரல் மூலம் விவரிக்க'},
    'myProducts': {'en': 'My Products', 'hi': 'मेरे उत्पाद', 'ta': 'எனது பொருட்கள்'},
    'aiInsight': {'en': 'AI Insight', 'hi': 'एआई सुझाव', 'ta': 'AI பரிந்துரை'},

    // Business Insights
    'businessInsights': {'en': 'Business Insights', 'hi': 'व्यापार अंतर्दृष्टि', 'ta': 'வணிக நுண்ணறிவு'},
    'healthScore': {'en': 'Business Health Score', 'hi': 'व्यापार स्वास्थ्य स्कोर', 'ta': 'வணிக ஆரோக்கிய மதிப்பெண்'},
    'recommendedProduction': {
      'en': 'Recommended production',
      'hi': 'अनुशंसित उत्पादन',
      'ta': 'பரிந்துரைக்கப்பட்ட உற்பத்தி',
    },
    'bestPerforming': {'en': 'Best performing product', 'hi': 'सर्वश्रेष्ठ प्रदर्शन वाला उत्पाद', 'ta': 'சிறந்த செயல்திறன் கொண்ட பொருள்'},

    // Markets / Buyers
    'buyerOpportunities': {'en': 'Buyer Opportunities', 'hi': 'खरीदार अवसर', 'ta': 'வாங்குபவர் வாய்ப்புகள்'},
    'demandBoard': {'en': 'Buyer Demand Board', 'hi': 'खरीदार मांग बोर्ड', 'ta': 'வாங்குபவர் தேவை பலகை'},
    'sendQuote': {'en': 'Send Quote', 'hi': 'कोटेशन भेजें', 'ta': 'மேற்கோள் அனுப்பு'},
    'match': {'en': 'Match', 'hi': 'मेल', 'ta': 'பொருத்தம்'},

    // Product detail / Heritage
    'heritagePassport': {'en': 'Heritage Passport', 'hi': 'विरासत पासपोर्ट', 'ta': 'பாரம்பரிய பாஸ்போர்ட்'},
    'edit': {'en': 'Edit', 'hi': 'संपादित करें', 'ta': 'திருத்து'},
    'publish': {'en': 'Publish', 'hi': 'प्रकाशित करें', 'ta': 'வெளியிடு'},
    'improveWithAI': {'en': 'Improve with AI', 'hi': 'एआई से सुधारें', 'ta': 'AI மூலம் மேம்படுத்து'},
    'changePrice': {'en': 'Change Price', 'hi': 'मूल्य बदलें', 'ta': 'விலையை மாற்று'},

    // Common actions
    'save': {'en': 'Save', 'hi': 'सहेजें', 'ta': 'சேமி'},
    'continueLabel': {'en': 'Continue', 'hi': 'जारी रखें', 'ta': 'தொடரவும்'},
    'regenerate': {'en': 'Regenerate', 'hi': 'पुनः बनाएं', 'ta': 'மீண்டும் உருவாக்கு'},

    // Business Manager
    'businessManager': {'en': 'AI Business Manager', 'hi': 'एआई व्यापार प्रबंधक', 'ta': 'AI வணிக மேலாளர்'},
    'askAnything': {
      'en': 'Ask your business manager anything...',
      'hi': 'अपने व्यापार प्रबंधक से कुछ भी पूछें...',
      'ta': 'உங்கள் வணிக மேலாளரிடம் எதையும் கேளுங்கள்...',
    },
  };

  static String t(AppLanguage lang, String key) {
    final entry = _s[key];
    if (entry == null) return key;
    return entry[lang.code] ?? entry['en'] ?? key;
  }
}
