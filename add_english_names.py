import json

# Translation mappings for regions
REGION_TRANSLATIONS = {
    "المنطقة الشرقية": "Eastern Province",
    "منطقة الباحة": "Al Bahah Province",
    "منطقة الجوف": "Al Jawf Province",
    "منطقة الحدود الشمالية": "Northern Borders Province",
    "منطقة الرياض": "Riyadh Province",
    "منطقة القصيم": "Al Qassim Province",
    "منطقة المدينة المنورة": "Madinah Province",
    "منطقة تبوك": "Tabuk Province",
    "منطقة جازان": "Jazan Province",
    "منطقة حائل": "Hail Province",
    "منطقة عسير": "Asir Province",
    "منطقة مكة المكرمة": "Makkah Province",
    "منطقة نجران": "Najran Province"
}

# Translation mappings for cities
CITY_TRANSLATIONS = {
    "ابها": "Abha",
    "ابو عريش": "Abu Arish",
    "احد المسارحة": "Ahad Al Masarihah",
    "احد رفيده": "Ahad Rafidah",
    "الأضارع": "Al Adaraa",
    "الارطاوية": "Al Artawiyah",
    "الاسياح": "Al Asyah",
    "الباحة": "Al Bahah",
    "البجادية": "Al Bujaydiyah",
    "البدائع": "Al Badai",
    "البكيرية": "Al Bukayriyah",
    "الجبيل": "Jubail",
    "الجش": "Al Jish",
    "الجفر": "Al Jafr",
    "الجموم": "Al Jumum",
    "الحرجة": "Al Harjah",
    "الحريق": "Al Hariq",
    "الحصاة": "Al Hasah",
    "الحلوة": "Al Hulwah",
    "الحناكية": "Al Hanakiyah",
    "الخبر": "Al Khobar",
    "الخبراء": "Al Khabra",
    "الخرج": "Al Kharj",
    "الخرمة": "Al Khurmah",
    "الخفجي": "Khafji",
    "الدرعية": "Ad Diriyah",
    "الدلم": "Ad Dilam",
    "الدمام": "Dammam",
    "الدوادمي": "Ad Dawadmi",
    "الرس": "Ar Rass",
    "الرويضة": "Ar Ruwaydah",
    "الرياض": "Riyadh",
    "الرين": "Ar Rayn",
    "الزلفي": "Az Zulfi",
    "السليل": "As Sulayyil",
    "السودة": "As Soudah",
    "الشماسية": "Ash Shimasiyah",
    "الشملي": "Ash Shamli",
    "الشنان": "Ash Shinan",
    "الطائف": "Taif",
    "الظهران": "Dhahran",
    "العارضة": "Al Aridah",
    "العرضية الشمالية": "Al Ardiyah Ash Shamaliyah",
    "العقيق": "Al Aqiq",
    "العلا": "Al Ula",
    "العمران": "Al Omran",
    "العويقلية": "Al Uwayqilah",
    "العيساوية": "Al Aysawiyah",
    "العيون": "Al Oyun",
    "العيينة": "Al Uyaynah",
    "الغاط": "Al Ghat",
    "القريات": "Al Qurayyat",
    "القصب": "Al Qasab",
    "القطيف": "Qatif",
    "القنفذة": "Al Qunfudhah",
    "القوز": "Al Qawz",
    "القويعية": "Al Quwayiyah",
    "القيصومة": "Qaisumah",
    "الليث": "Al Lith",
    "المبرز": "Al Mubarraz",
    "المجاردة": "Al Majardah",
    "المجمعة": "Al Majmaah",
    "المدينة المنورة": "Madinah",
    "المذنب": "Al Midhnab",
    "المرموثة": "Al Marmuthah",
    "المزاحمية": "Al Muzahimiyah",
    "النبهانية": "An Nabhaniyah",
    "النعيرية": "Nairyah",
    "النماص": "An Namas",
    "الهفوف": "Al Hofuf",
    "الهلالية": "Al Hilaliyah",
    "الوجه": "Al Wajh",
    "ام الحمام": "Umm Al Hamam",
    "املج": "Umluj",
    "بدر": "Badr",
    "بريدة": "Buraidah",
    "بقعاء": "Baqaa",
    "بقيق": "Buqayq",
    "بلجرشي": "Baljurashi",
    "بللحمر": "Billahmar",
    "بللسمر": "Billasmar",
    "بيشة": "Bishah",
    "تاروت": "Tarout",
    "تبوك": "Tabuk",
    "تثليث": "Tathleeth",
    "تربه": "Turbah",
    "تمير": "Tumair",
    "تندحة": "Tandahah",
    "تنومة": "Tanomah",
    "تيماء": "Tayma",
    "ثادق": "Thadiq",
    "ثول": "Thuwal",
    "جازان": "Jazan",
    "جدة": "Jeddah",
    "جلاجل": "Jalajil",
    "جواثا": "Jawatha",
    "حائل": "Hail",
    "حبونا": "Habuna",
    "حرمة": "Harmah",
    "حريملاء": "Huraymila",
    "حفر الباطن": "Hafar Al Batin",
    "حقل": "Haql",
    "حوطة بني تميم": "Hotat Bani Tamim",
    "حوطة سدير": "Hotat Sudair",
    "خليص": "Khulais",
    "خميس مشيط": "Khamis Mushait",
    "خيبر": "Khaybar",
    "دارين": "Darin",
    "دومة الجندل": "Dumat Al Jandal",
    "رابغ": "Rabigh",
    "راس تنورة": "Ras Tanura",
    "رفحاء": "Rafha",
    "رنية": "Ranyah",
    "رياض الخبراء": "Riyadh Al Khabra",
    "سبت العلاية": "Sabt Al Alaya",
    "سراة عبيدة": "Sarat Abidah",
    "سكاكا": "Sakaka",
    "سيهات": "Saihat",
    "شرورة": "Sharurah",
    "شقراء": "Shaqra",
    "صامطة": "Samtah",
    "صبيا": "Sabya",
    "صفوى": "Safwa",
    "صوير": "Suwayr",
    "ضبا": "Duba",
    "ضرما": "Dhurma",
    "ضرية": "Dariyah",
    "طبب": "Tabab",
    "طبرجل": "Tabarjal",
    "طريب": "Tarib",
    "طريف": "Turaif",
    "ظهران الجنوب": "Dhahran Al Janoub",
    "عرعر": "Arar",
    "عفيف": "Afif",
    "عقلة الصقور": "Uqlat As Suqur",
    "عنك": "Anak",
    "عنيزة": "Unaizah",
    "عيون الجواء": "Uyun Al Jiwa",
    "قبة": "Qibah",
    "قرية العليا": "Qaryat Al Ulya",
    "ليلى": "Layla",
    "محايل": "Muhayil",
    "مدينة الملك عبدالله الاقتصادية": "King Abdullah Economic City",
    "مكة المكرمة": "Makkah",
    "مهد الذهب": "Mahd Ad Dahab",
    "نجران": "Najran",
    "نفي": "Nifi",
    "وادي الدواسر": "Wadi Ad Dawasir",
    "يبرين": "Yabrin",
    "يدمة": "Yadamah",
    "ينبع": "Yanbu",
    "ينبع الصناعية": "Yanbu Industrial City"
}

def add_english_names(input_file, output_file):
    """
    Add English translations for city and region names to the JSON data.
    """
    # Load the JSON data
    print(f"Loading data from {input_file}...")
    with open(input_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    print(f"Processing {len(data)} entries...")
    
    # Add English names to each entry
    entries_updated = 0
    missing_cities = set()
    missing_regions = set()
    
    for entry in data:
        city_ar = entry.get('city_name_ar', '')
        region_ar = entry.get('region_name_ar', '')
        
        # Add city English name
        if city_ar in CITY_TRANSLATIONS:
            entry['city_name_en'] = CITY_TRANSLATIONS[city_ar]
        else:
            entry['city_name_en'] = city_ar  # Fallback to Arabic if not found
            missing_cities.add(city_ar)
        
        # Add region English name
        if region_ar in REGION_TRANSLATIONS:
            entry['region_name_en'] = REGION_TRANSLATIONS[region_ar]
        else:
            entry['region_name_en'] = region_ar  # Fallback to Arabic if not found
            missing_regions.add(region_ar)
        
        entries_updated += 1
    
    # Save the updated data
    print(f"Saving updated data to {output_file}...")
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print(f"\n✓ Successfully updated {entries_updated} entries!")
    
    if missing_cities:
        print(f"\n⚠ Warning: {len(missing_cities)} cities not found in translation mapping:")
        for city in sorted(missing_cities):
            print(f"  - {city}")
    
    if missing_regions:
        print(f"\n⚠ Warning: {len(missing_regions)} regions not found in translation mapping:")
        for region in sorted(missing_regions):
            print(f"  - {region}")
    
    print(f"\nOutput saved to: {output_file}")

if __name__ == "__main__":
    input_file = "geo_units_sorted_by_region_city_district.json"
    output_file = "geo_units_sorted_by_region_city_district.json"
    
    add_english_names(input_file, output_file)
