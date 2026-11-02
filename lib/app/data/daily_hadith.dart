/// Short, widely-known sahih/hasan hadith for the Home "Hadith of the Day"
/// card. Arabic text with its collection and number, like the azkar corpus.
class DailyHadith {
  const DailyHadith(this.text, this.reference);
  final String text;
  final String reference;
}

const dailyHadith = <DailyHadith>[
  DailyHadith(
    'إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ، وَإِنَّمَا لِكُلِّ امْرِئٍ مَا نَوَى',
    'البخاري 1، مسلم 1907',
  ),
  DailyHadith('الدِّينُ النَّصِيحَةُ', 'مسلم 55'),
  DailyHadith(
    'لَا يُؤْمِنُ أَحَدُكُمْ حَتَّى يُحِبَّ لِأَخِيهِ مَا يُحِبُّ لِنَفْسِهِ',
    'البخاري 13، مسلم 45',
  ),
  DailyHadith(
    'مَنْ كَانَ يُؤْمِنُ بِاللَّهِ وَالْيَوْمِ الآخِرِ فَلْيَقُلْ خَيْرًا أَوْ لِيَصْمُتْ',
    'البخاري 6018، مسلم 47',
  ),
  DailyHadith('الطُّهُورُ شَطْرُ الإِيمَانِ', 'مسلم 223'),
  DailyHadith(
    'خَيْرُكُمْ مَنْ تَعَلَّمَ الْقُرْآنَ وَعَلَّمَهُ',
    'البخاري 5027',
  ),
  DailyHadith(
    'الْمُسْلِمُ مَنْ سَلِمَ الْمُسْلِمُونَ مِنْ لِسَانِهِ وَيَدِهِ',
    'البخاري 10، مسلم 40',
  ),
  DailyHadith(
    'مِنْ حُسْنِ إِسْلَامِ الْمَرْءِ تَرْكُهُ مَا لَا يَعْنِيهِ',
    'الترمذي 2317',
  ),
  DailyHadith('لَا تَغْضَبْ', 'البخاري 6116'),
  DailyHadith('الْكَلِمَةُ الطَّيِّبَةُ صَدَقَةٌ', 'البخاري 2989، مسلم 1009'),
  DailyHadith(
    'اتَّقِ اللَّهَ حَيْثُمَا كُنْتَ، وَأَتْبِعِ السَّيِّئَةَ الْحَسَنَةَ تَمْحُهَا، وَخَالِقِ النَّاسَ بِخُلُقٍ حَسَنٍ',
    'الترمذي 1987',
  ),
  DailyHadith('تَبَسُّمُكَ فِي وَجْهِ أَخِيكَ لَكَ صَدَقَةٌ', 'الترمذي 1956'),
  DailyHadith(
    'أَحَبُّ الأَعْمَالِ إِلَى اللَّهِ أَدْوَمُهَا وَإِنْ قَلَّ',
    'البخاري 6464، مسلم 783',
  ),
  DailyHadith(
    'لَيْسَ الشَّدِيدُ بِالصُّرَعَةِ، إِنَّمَا الشَّدِيدُ الَّذِي يَمْلِكُ نَفْسَهُ عِنْدَ الْغَضَبِ',
    'البخاري 6114، مسلم 2609',
  ),
  DailyHadith(
    'يَسِّرُوا وَلَا تُعَسِّرُوا، وَبَشِّرُوا وَلَا تُنَفِّرُوا',
    'البخاري 69، مسلم 1734',
  ),
  DailyHadith('مَنْ لَا يَرْحَمُ لَا يُرْحَمُ', 'البخاري 5997، مسلم 2318'),
];

/// Days since 2024-01-01 for [date]'s calendar day, so a pick changes at
/// local midnight and is the same all day.
int dayIndex(DateTime date) => DateTime.utc(
  date.year,
  date.month,
  date.day,
).difference(DateTime.utc(2024)).inDays;

/// The item for [date]'s day, cycling through [items].
T pickForDay<T>(List<T> items, DateTime date) =>
    items[dayIndex(date) % items.length];
