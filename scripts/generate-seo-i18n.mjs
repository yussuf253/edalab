import fs from 'fs';
import path from 'path';

const projectRoot = process.cwd();
const webRoot = path.join(projectRoot, 'web');

const localizedPages = new Set([
  'index.html',
  'food.html',
  'shopping.html',
  'pharmacy.html',
  'doctor.html',
  'hotel.html',
  'ride.html',
  'home-services.html',
  'laundry.html',
]);

const commonReplacements = {
  fr: {
    'All rights reserved.': 'Tous droits réservés.',
    'Made in Djibouti': 'Créé à Djibouti',
    'Order Food': 'Commander des repas',
    'Book a Doctor': 'Prendre rendez-vous avec un médecin',
    'Pharmacies 24/7': 'Pharmacies 24h/24 et 7j/7',
    'Book Ride Now': 'Réserver un trajet maintenant',
    'About Us': 'À propos',
    'List Your Business': 'Référencez votre entreprise',
    'Become a Rider': 'Devenir coursier',
    'Careers': 'Carrières',
    'Support': 'Assistance',
    'Privacy Policy': 'Politique de confidentialité',
    'Terms of Service': 'Conditions d’utilisation',
    'Cookies': 'Cookies',
    'Specialists': 'Spécialistes',
    'Lab Tests': 'Analyses médicales',
    'Vaccinations': 'Vaccinations',
    'Apartments': 'Appartements',
    'Airport Transfer': 'Transfert aéroport',
    'Car Rental': 'Location de voiture',
    'Travel & Stay': 'Voyage et séjour',
    'Ride Service': 'Service de trajet',
    'Contact Support': 'Contacter l’assistance',
    'For Users': 'Pour les utilisateurs',
    'For Partners': 'Pour les partenaires',
    'For Riders': 'Pour les passagers',
    'For Drivers': 'Pour les chauffeurs',
    'For Customers': 'Pour les clients',
    'For Pros': 'Pour les professionnels',
    'Contact': 'Contact',
    'Offers': 'Offres',
    'Help Center': 'Centre d’aide',
    'Blog': 'Blog',
    'How rides work': 'Comment fonctionnent les trajets',
    'How booking works': 'Comment fonctionne la réservation',
    'Partner standards': 'Normes des partenaires',
    'Safety': 'Sécurité',
    'Pricing': 'Tarification',
    'Book a ride': 'Réserver un trajet',
    'Trip history': 'Historique des trajets',
    'Become a driver': 'Devenir chauffeur',
    'Driver support': 'Assistance chauffeur',
    'Requirements': 'Conditions',
    'Browse categories': 'Parcourir les catégories',
    'Find professionals': 'Trouver des professionnels',
    'Partner Portal': 'Portail partenaires',
    'Resources': 'Ressources',
    'Book laundry': 'Réserver une blanchisserie',
    'Track orders': 'Suivre les commandes',
    'Surge Pricing': 'Tarification dynamique',
    'Service Type': 'Type de service',
    'Rating': 'Note',
    'Price Range': 'Fourchette de prix',
    'Availability': 'Disponibilité',
    'All Prices': 'Tous les prix',
    'Today': 'Aujourd’hui',
    'Tomorrow': 'Demain',
    'This Week': 'Cette semaine',
    '5 Stars': '5 étoiles',
    '4+ Stars': '4+ étoiles',
    '3+ Stars': '3+ étoiles',
    'Cleaning': 'Nettoyage',
    'Maintenance': 'Maintenance',
    'Plumbing': 'Plomberie',
    'Electrical': 'Électricité',
    'Available Today': 'Disponible aujourd’hui',
    'Available Now': 'Disponible maintenant',
    'All Ratings': 'Toutes les notes',
    'Star Rating': 'Classement par étoiles',
    'Contact & Support': 'Contact et assistance',
    'Contact & Emergency': 'Contact et urgence',
    '24/7 Support': 'Assistance 24h/24 et 7j/7',
    'Order Again': 'Commander à nouveau',
    'Delivery fee': 'Frais de livraison',
    'Total': 'Total',
  },
  ar: {
    'All rights reserved.': 'جميع الحقوق محفوظة.',
    'Made in Djibouti': 'صنع في جيبوتي',
    'Order Food': 'اطلب الطعام',
    'Book a Doctor': 'احجز طبيباً',
    'Pharmacies 24/7': 'صيدليات 24/7',
    'Book Ride Now': 'احجز مشوارك الآن',
    'About Us': 'من نحن',
    'List Your Business': 'أضف نشاطك التجاري',
    'Become a Rider': 'كن مندوب توصيل',
    'Careers': 'الوظائف',
    'Support': 'الدعم',
    'Privacy Policy': 'سياسة الخصوصية',
    'Terms of Service': 'شروط الخدمة',
    'Cookies': 'ملفات تعريف الارتباط',
    'Specialists': 'الأخصائيون',
    'Lab Tests': 'التحاليل المخبرية',
    'Vaccinations': 'التطعيمات',
    'Apartments': 'الشقق',
    'Airport Transfer': 'نقل المطار',
    'Car Rental': 'تأجير السيارات',
    'Travel & Stay': 'السفر والإقامة',
    'Ride Service': 'خدمة المشاوير',
    'Contact Support': 'تواصل مع الدعم',
    'For Users': 'للمستخدمين',
    'For Partners': 'للشركاء',
    'For Riders': 'للركاب',
    'For Drivers': 'للسائقين',
    'For Customers': 'للعملاء',
    'For Pros': 'للمهنيين',
    'Contact': 'اتصل بنا',
    'Offers': 'العروض',
    'Help Center': 'مركز المساعدة',
    'Blog': 'المدونة',
    'How rides work': 'كيف تعمل المشاوير',
    'How booking works': 'كيف يعمل الحجز',
    'Partner standards': 'معايير الشركاء',
    'Safety': 'السلامة',
    'Pricing': 'الأسعار',
    'Book a ride': 'احجز مشواراً',
    'Trip history': 'سجل المشاوير',
    'Become a driver': 'كن سائقاً',
    'Driver support': 'دعم السائقين',
    'Requirements': 'المتطلبات',
    'Browse categories': 'تصفح الفئات',
    'Find professionals': 'اعثر على المحترفين',
    'Partner Portal': 'بوابة الشركاء',
    'Resources': 'الموارد',
    'Book laundry': 'احجز خدمة الغسيل',
    'Track orders': 'تتبع الطلبات',
    'Surge Pricing': 'التسعير المتغير',
    'Service Type': 'نوع الخدمة',
    'Rating': 'التقييم',
    'Price Range': 'نطاق السعر',
    'Availability': 'التوفر',
    'All Prices': 'كل الأسعار',
    'Today': 'اليوم',
    'Tomorrow': 'غداً',
    'This Week': 'هذا الأسبوع',
    '5 Stars': '5 نجوم',
    '4+ Stars': '4+ نجوم',
    '3+ Stars': '3+ نجوم',
    'Cleaning': 'التنظيف',
    'Maintenance': 'الصيانة',
    'Plumbing': 'السباكة',
    'Electrical': 'الكهرباء',
    'Available Today': 'متاح اليوم',
    'Available Now': 'متاح الآن',
    'All Ratings': 'كل التقييمات',
    'Star Rating': 'تصنيف النجوم',
    'Contact & Support': 'الاتصال والدعم',
    'Contact & Emergency': 'الاتصال والطوارئ',
    '24/7 Support': 'الدعم 24/7',
    'Order Again': 'اطلب مرة أخرى',
    'Delivery fee': 'رسوم التوصيل',
    'Total': 'الإجمالي',
  },
};

const pageConfigs = [
  {
    source: 'index.html',
    output: 'index.html',
    canonicalBase: '/',
    kind: 'home',
    translations: {
      fr: {
        title: 'eDalab — Une seule application pour tous vos besoins | Restauration, médecin, hôtel, pharmacie à Djibouti',
        description: "eDalab est la super-app n°1 de Djibouti. Commandez des repas, réservez des médecins, trouvez des pharmacies, demandez un trajet, faites du shopping, réservez un hôtel et plus encore.",
        ogTitle: 'eDalab — Une seule application pour tous vos besoins',
        ogDescription: 'La super-app de Djibouti. Restauration, médecin, hôtel, pharmacie, trajets, shopping et blanchisserie.',
        scriptReplacements: {
          'NilaApp changed my life in Djibouti! I ordered meds at 2am and they arrived in 20 minutes. The live tracking is so accurate and reassuring.': "eDalab a changé ma vie à Djibouti ! J’ai commandé des médicaments à 2h du matin et ils sont arrivés en 20 minutes. Le suivi en direct est très précis et rassurant.",
          'Booked a hotel and restaurant for our anniversary in one session. Both were perfect. The confirmation was instant and delivery was on time.': 'J’ai réservé un hôtel et un restaurant pour notre anniversaire en une seule fois. Les deux étaient parfaits. La confirmation a été instantanée et tout est arrivé à l’heure.',
          'The doctor booking feature is a game changer. Found a specialist, checked availability, confirmed in 2 minutes. No waiting on the phone!': 'La réservation de médecin change vraiment la donne. J’ai trouvé un spécialiste, vérifié ses disponibilités et confirmé en 2 minutes. Plus besoin d’attendre au téléphone !',
          'Best delivery app in Djibouti by far. The variety is incredible — from traditional Djiboutian food to burgers. Always on time, always fresh.': 'La meilleure application de livraison à Djibouti, de loin. Le choix est incroyable, de la cuisine djiboutienne traditionnelle aux burgers. Toujours à l’heure, toujours frais.',
          'My laundry comes back perfectly folded every time. Pickup is easy, tracking works great. My whole family uses eDalab now.': 'Mon linge revient parfaitement plié à chaque fois. Le ramassage est simple, le suivi fonctionne très bien. Toute ma famille utilise eDalab maintenant.',
          'The ride feature is so convenient. Got picked up in under 5 minutes. Clean car, friendly driver. Will definitely use again.': 'Le service de trajet est très pratique. J’ai été récupéré en moins de 5 minutes. Voiture propre, chauffeur aimable. Je l’utiliserai encore sans hésiter.',
          '💊 Pharmacy': '💊 Pharmacie',
          '🏨 Hotel': '🏨 Hôtel',
          '👨‍⚕️ Doctor': '👨‍⚕️ Médecin',
          '🍔 Food': '🍔 Restauration',
          '🧺 Laundry': '🧺 Blanchisserie',
          '🚕 Ride': '🚕 Trajet',
        },
        replacements: {
          'Home': 'Accueil',
          'Food': 'Restauration',
          'Shopping': 'Boutique',
          'Pharmacy': 'Pharmacie',
          'Doctor': 'Médecin',
          'Hotel': 'Hôtel',
          'Ride': 'Trajet',
          'Services': 'Services',
          'Laundry': 'Blanchisserie',
          'Wishlist': 'Favoris',
          'Cart': 'Panier',
          'Serving Djibouti, City & Regions': 'Disponible à Djibouti-ville et dans les régions',
          'One App For': 'Une seule app pour',
          'All Your Needs': 'tous vos besoins',
          "eDalab connects you to everything in your city — food, doctors, pharmacies, hotels, rides, shopping and laundry. Real people, real fast.": 'eDalab vous connecte à tout dans votre ville : restauration, médecins, pharmacies, hôtels, trajets, shopping et blanchisserie. Des personnes réelles, rapidement.',
          'Search services, products, restaurants…': 'Rechercher des services, produits, restaurants…',
          'Search': 'Rechercher',
          'Trending:': 'Tendance :',
          'Pizza': 'Pizza',
          'Hotels': 'Hôtels',
          'All Services': 'Tous les services',
          'Everything you need, right here': 'Tout ce qu’il vous faut, ici même',
          "8 modules, one app. From your morning coffee to your doctor's appointment — eDalab has you covered.": '8 modules, une seule application. Du café du matin à votre rendez-vous médical, eDalab vous accompagne.',
          'See all services →': 'Voir tous les services →',
          'How It Works': 'Comment ça marche',
          'Order in 4 simple steps': 'Commandez en 4 étapes simples',
          'No learning curve. Just open the app, find what you need, and get it delivered.': 'Aucune difficulté. Ouvrez l’application, trouvez ce qu’il vous faut et faites-vous livrer.',
          'Featured': 'À la une',
          'Trending near you': 'Tendance près de chez vous',
          'View all →': 'Tout voir →',
          'Stay in the loop': 'Restez informé',
          'New restaurants, exclusive deals & city updates in your inbox.': 'Nouveaux restaurants, offres exclusives et infos de la ville dans votre boîte mail.',
          'your@email.com': 'votre@email.com',
          'Subscribe →': 'S’abonner →',
          'Ride Service': 'Service de trajet',
          'Delivery fee': 'Frais de livraison',
          'Total': 'Total',
          'Order Again': 'Commander à nouveau',
        },
      },
      ar: {
        title: 'إيدالاب — تطبيق واحد لكل احتياجاتك | طعام، طبيب، فندق، صيدلية في جيبوتي',
        description: 'إيدالاب هو التطبيق الشامل رقم 1 في جيبوتي. اطلب الطعام، احجز الأطباء، ابحث عن الصيدليات، اطلب مشواراً، تسوق، احجز فندقاً وأكثر.',
        ogTitle: 'إيدالاب — تطبيق واحد لكل احتياجاتك',
        ogDescription: 'التطبيق الشامل في جيبوتي. طعام، طبيب، فندق، صيدلية، مشاوير، تسوق وغسيل.',
        scriptReplacements: {
          'NilaApp changed my life in Djibouti! I ordered meds at 2am and they arrived in 20 minutes. The live tracking is so accurate and reassuring.': 'إيدالاب غيّر حياتي في جيبوتي! طلبت أدوية الساعة الثانية صباحاً ووصلت خلال 20 دقيقة. التتبع المباشر دقيق جداً ويبعث على الاطمئنان.',
          'Booked a hotel and restaurant for our anniversary in one session. Both were perfect. The confirmation was instant and delivery was on time.': 'حجزت فندقاً ومطعماً لذكرى زواجنا في جلسة واحدة. كلاهما كان ممتازاً. التأكيد كان فورياً وكل شيء وصل في الوقت.',
          'The doctor booking feature is a game changer. Found a specialist, checked availability, confirmed in 2 minutes. No waiting on the phone!': 'ميزة حجز الطبيب رائعة فعلاً. وجدت اختصاصياً، تحققت من المواعيد المتاحة، وأكدت الحجز خلال دقيقتين. بدون انتظار على الهاتف!',
          'Best delivery app in Djibouti by far. The variety is incredible — from traditional Djiboutian food to burgers. Always on time, always fresh.': 'أفضل تطبيق توصيل في جيبوتي بلا منافس. التنوع مذهل من الأكلات الجيبوتية التقليدية إلى البرغر. دائماً في الوقت وطازج دائماً.',
          'My laundry comes back perfectly folded every time. Pickup is easy, tracking works great. My whole family uses eDalab now.': 'ملابسي تعود مطوية بشكل ممتاز كل مرة. الاستلام سهل والتتبع يعمل بشكل رائع. عائلتي كلها تستخدم إيدالاب الآن.',
          'The ride feature is so convenient. Got picked up in under 5 minutes. Clean car, friendly driver. Will definitely use again.': 'ميزة المشاوير مريحة جداً. تم استلامي خلال أقل من 5 دقائق. سيارة نظيفة وسائق لطيف. سأستخدمها مرة أخرى بالتأكيد.',
          '💊 Pharmacy': '💊 الصيدلية',
          '🏨 Hotel': '🏨 الفندق',
          '👨‍⚕️ Doctor': '👨‍⚕️ الطبيب',
          '🍔 Food': '🍔 الطعام',
          '🧺 Laundry': '🧺 الغسيل',
          '🚕 Ride': '🚕 المشاوير',
        },
        replacements: {
          'Home': 'الرئيسية',
          'Food': 'الطعام',
          'Shopping': 'التسوق',
          'Pharmacy': 'الصيدلية',
          'Doctor': 'الطبيب',
          'Hotel': 'الفندق',
          'Ride': 'المشاوير',
          'Services': 'الخدمات',
          'Laundry': 'الغسيل',
          'Wishlist': 'المفضلة',
          'Cart': 'السلة',
          'Serving Djibouti, City & Regions': 'نخدم مدينة جيبوتي والمناطق',
          'One App For': 'تطبيق واحد لكل',
          'All Your Needs': 'احتياجاتك',
          "eDalab connects you to everything in your city — food, doctors, pharmacies, hotels, rides, shopping and laundry. Real people, real fast.": 'إيدالاب يوصلك بكل ما تحتاجه في مدينتك: الطعام، الأطباء، الصيدليات، الفنادق، المشاوير، التسوق والغسيل. خدمة حقيقية وبسرعة.',
          'Search services, products, restaurants…': 'ابحث عن خدمات أو منتجات أو مطاعم…',
          'Search': 'بحث',
          'Trending:': 'الرائج:',
          'Pizza': 'بيتزا',
          'Pharmacy': 'صيدلية',
          'Hotels': 'فنادق',
          'Laundry': 'غسيل',
          'Doctor': 'طبيب',
          'All Services': 'كل الخدمات',
          'Everything you need, right here': 'كل ما تحتاجه هنا',
          "8 modules, one app. From your morning coffee to your doctor's appointment — eDalab has you covered.": '8 أقسام في تطبيق واحد. من قهوة الصباح إلى موعد الطبيب، إيدالاب معك.',
          'See all services →': 'عرض كل الخدمات ←',
          'How It Works': 'كيف يعمل',
          'Order in 4 simple steps': 'اطلب في 4 خطوات بسيطة',
          'No learning curve. Just open the app, find what you need, and get it delivered.': 'بدون تعقيد. افتح التطبيق وابحث عما تحتاجه وسيصل إليك.',
          'Featured': 'مميز',
          'Trending near you': 'الرائج بالقرب منك',
          'View all →': 'عرض الكل ←',
          'Stay in the loop': 'ابقَ على اطلاع',
          'New restaurants, exclusive deals & city updates in your inbox.': 'مطاعم جديدة، عروض حصرية، وأخبار المدينة في بريدك.',
          'Subscribe →': 'اشترك ←',
          'Ride Service': 'خدمة المشاوير',
          'Delivery fee': 'رسوم التوصيل',
          'Total': 'الإجمالي',
          'Order Again': 'اطلب مرة أخرى',
        },
      },
    },
  },
  {
    source: 'food.html',
    output: 'food.html',
    canonicalBase: '/food.html',
    kind: 'collection',
    translations: {
      fr: {
        title: 'Livraison de repas - eDalab',
        description: 'Commandez de délicieux repas depuis vos restaurants préférés sur eDalab. Livraison rapide, suivi en direct et offres exclusives.',
        ogTitle: 'Livraison de repas - eDalab',
        ogDescription: 'Commandez des repas à Djibouti avec livraison rapide et suivi en direct.',
        replacements: {
          'Home': 'Accueil',
          'Food': 'Restauration',
          'Shopping': 'Boutique',
          'Pharmacy': 'Pharmacie',
          'Doctor': 'Médecin',
          'Hotel': 'Hôtel',
          'Ride': 'Trajet',
          'Services': 'Services',
          'Laundry': 'Blanchisserie',
          'Wishlist': 'Favoris',
          'Cart': 'Panier',
          'Hungry? Order From Your Favorite Restaurants 🍕': 'Envie de manger ? Commandez auprès de vos restaurants préférés 🍕',
          'Fast delivery, fresh food, and exclusive deals. Everything your taste buds crave!': 'Livraison rapide, repas frais et offres exclusives. Tout ce dont vos papilles ont envie.',
          'Filter & Sort': 'Filtrer et trier',
          'Popular Restaurants': 'Restaurants populaires',
          'Search restaurants or dishes...': 'Rechercher des restaurants ou des plats...',
          'About Us': 'À propos',
          'Careers': 'Carrières',
          'For Users': 'Pour les utilisateurs',
          'Offers': 'Offres',
          'Help Center': 'Centre d’aide',
          'Resources': 'Ressources',
        },
      },
      ar: {
        title: 'توصيل الطعام - إيدالاب',
        description: 'اطلب أشهى الوجبات من مطاعمك المفضلة على إيدالاب. توصيل سريع، تتبع مباشر، وعروض حصرية.',
        ogTitle: 'توصيل الطعام - إيدالاب',
        ogDescription: 'اطلب الطعام في جيبوتي مع توصيل سريع وتتبع مباشر.',
        replacements: {
          'Home': 'الرئيسية',
          'Food': 'الطعام',
          'Shopping': 'التسوق',
          'Pharmacy': 'الصيدلية',
          'Doctor': 'الطبيب',
          'Hotel': 'الفندق',
          'Ride': 'المشاوير',
          'Services': 'الخدمات',
          'Laundry': 'الغسيل',
          'Wishlist': 'المفضلة',
          'Cart': 'السلة',
          'Hungry? Order From Your Favorite Restaurants 🍕': 'هل أنت جائع؟ اطلب من مطاعمك المفضلة 🍕',
          'Fast delivery, fresh food, and exclusive deals. Everything your taste buds crave!': 'توصيل سريع، طعام طازج، وعروض حصرية. كل ما تشتهيه.',
          'Filter & Sort': 'تصفية وترتيب',
          'Popular Restaurants': 'مطاعم مشهورة',
          'Search restaurants or dishes...': 'ابحث عن مطاعم أو أطباق...',
          'About Us': 'من نحن',
          'Careers': 'الوظائف',
          'For Users': 'للمستخدمين',
          'Offers': 'العروض',
          'Help Center': 'مركز المساعدة',
          'Resources': 'الموارد',
        },
      },
    },
  },
  {
    source: 'shopping.html',
    output: 'shopping.html',
    canonicalBase: '/shopping.html',
    kind: 'collection',
    translations: {
      fr: {
        title: 'Shopping - eDalab',
        description: 'Achetez de l’électronique, de la mode, des articles pour la maison et plus encore sur eDalab.',
        ogTitle: 'Shopping - eDalab',
        ogDescription: 'Mode, électronique et articles maison avec livraison rapide à Djibouti.',
        replacements: {
          'Home': 'Accueil', 'Food': 'Restauration', 'Shopping': 'Boutique', 'Pharmacy': 'Pharmacie', 'Doctor': 'Médecin', 'Hotel': 'Hôtel', 'Ride': 'Trajet', 'Services': 'Services', 'Laundry': 'Blanchisserie', 'Wishlist': 'Favoris', 'Cart': 'Panier',
          'Shop Everything You Love 🛍️': 'Achetez tout ce que vous aimez 🛍️',
          'Fashion, electronics, home decor, and more. All in one place with fast delivery.': 'Mode, électronique, décoration et plus encore. Tout au même endroit avec livraison rapide.',
          'Categories': 'Catégories',
          'Shop Now': 'Acheter maintenant',
          'Category': 'Catégorie',
          'All Categories': 'Toutes les catégories',
          'Price Range': 'Fourchette de prix',
          'All Prices': 'Tous les prix',
          'Sort By': 'Trier par',
          'Newest': 'Nouveautés',
          'Price: Low to High': 'Prix : croissant',
          'Price: High to Low': 'Prix : décroissant',
          'Top Rated': 'Mieux notés',
          'Search products...': 'Rechercher des produits...',
        },
      },
      ar: {
        title: 'التسوق - إيدالاب',
        description: 'تسوق الإلكترونيات والموضة ومستلزمات المنزل وأكثر على إيدالاب مع توصيل سريع.',
        ogTitle: 'التسوق - إيدالاب',
        ogDescription: 'موضة وإلكترونيات ومستلزمات منزلية مع توصيل سريع في جيبوتي.',
        replacements: {
          'Home': 'الرئيسية', 'Food': 'الطعام', 'Shopping': 'التسوق', 'Pharmacy': 'الصيدلية', 'Doctor': 'الطبيب', 'Hotel': 'الفندق', 'Ride': 'المشاوير', 'Services': 'الخدمات', 'Laundry': 'الغسيل', 'Wishlist': 'المفضلة', 'Cart': 'السلة',
          'Shop Everything You Love 🛍️': 'تسوق كل ما تحبه 🛍️',
          'Fashion, electronics, home decor, and more. All in one place with fast delivery.': 'موضة وإلكترونيات وديكور منزلي وأكثر. كل شيء في مكان واحد مع توصيل سريع.',
          'Categories': 'الفئات',
          'Shop Now': 'تسوق الآن',
          'Category': 'الفئة',
          'All Categories': 'كل الفئات',
          'Price Range': 'نطاق السعر',
          'All Prices': 'كل الأسعار',
          'Sort By': 'ترتيب حسب',
          'Newest': 'الأحدث',
          'Price: Low to High': 'السعر: من الأقل إلى الأعلى',
          'Price: High to Low': 'السعر: من الأعلى إلى الأقل',
          'Top Rated': 'الأعلى تقييماً',
          'Search products...': 'ابحث عن المنتجات...',
        },
      },
    },
  },
  {
    source: 'pharmacy.html',
    output: 'pharmacy.html',
    canonicalBase: '/pharmacy.html',
    kind: 'collection',
    translations: {
      fr: {
        title: 'Pharmacie - eDalab',
        description: 'Achetez des médicaments et produits de santé sur eDalab. Livraison rapide et conseils fiables.',
        ogTitle: 'Pharmacie - eDalab',
        ogDescription: 'Médicaments et produits de santé livrés rapidement à Djibouti.',
        replacements: {
          'Home': 'Accueil', 'Food': 'Restauration', 'Shopping': 'Boutique', 'Pharmacy': 'Pharmacie', 'Doctor': 'Médecin', 'Hotel': 'Hôtel', 'Ride': 'Trajet', 'Services': 'Services', 'Laundry': 'Blanchisserie', 'Wishlist': 'Favoris', 'Cart': 'Panier',
          'Health & Wellness at Your Fingertips 💊': 'Santé et bien-être à portée de main 💊',
          'Order medicines, health products, and wellness supplements. Fast delivery and trusted quality.': 'Commandez des médicaments, produits de santé et compléments bien-être. Livraison rapide et qualité fiable.',
          'Upload Your Prescription 📋': 'Téléchargez votre ordonnance 📋',
          'Upload your prescription to get medicines delivered': 'Téléchargez votre ordonnance pour recevoir vos médicaments',
          'Upload Prescription': 'Télécharger l’ordonnance',
          'Categories': 'Catégories',
          'Browse Medicines & Products': 'Parcourir médicaments et produits',
          'Category': 'Catégorie',
          'All Categories': 'Toutes les catégories',
          'Type': 'Type',
          'All Types': 'Tous les types',
          'Availability': 'Disponibilité',
          'All': 'Tous',
          'In Stock': 'En stock',
          'No Prescription Required': 'Sans ordonnance',
          'Search medicines, brands...': 'Rechercher des médicaments ou marques...',
          'About Us': 'À propos',
          'Licensed Pharmacists': 'Pharmaciens agréés',
          'For Customers': 'Pour les clients',
          'Browse Medicines': 'Parcourir les médicaments',
          'Prescription Upload': 'Téléversement d’ordonnance',
          'Health Tips': 'Conseils santé',
          'For Pharmacies': 'Pour les pharmacies',
          'Partner with Us': 'Devenir partenaire',
          'Partner Portal': 'Portail partenaires',
          'Resources': 'Ressources',
          'Contact & Support': 'Contact et assistance',
          '24/7 Support': 'Assistance 24h/24 et 7j/7',
        },
      },
      ar: {
        title: 'الصيدلية - إيدالاب',
        description: 'اشترِ الأدوية والمنتجات الصحية على إيدالاب. توصيل سريع ودعم موثوق.',
        ogTitle: 'الصيدلية - إيدالاب',
        ogDescription: 'أدوية ومنتجات صحية مع توصيل سريع في جيبوتي.',
        replacements: {
          'Home': 'الرئيسية', 'Food': 'الطعام', 'Shopping': 'التسوق', 'Pharmacy': 'الصيدلية', 'Doctor': 'الطبيب', 'Hotel': 'الفندق', 'Ride': 'المشاوير', 'Services': 'الخدمات', 'Laundry': 'الغسيل', 'Wishlist': 'المفضلة', 'Cart': 'السلة',
          'Health & Wellness at Your Fingertips 💊': 'الصحة والعافية بين يديك 💊',
          'Order medicines, health products, and wellness supplements. Fast delivery and trusted quality.': 'اطلب الأدوية والمنتجات الصحية ومكملات العافية. توصيل سريع وجودة موثوقة.',
          'Upload Your Prescription 📋': 'ارفع الوصفة الطبية 📋',
          'Upload your prescription to get medicines delivered': 'ارفع وصفتك الطبية ليصلك الدواء',
          'Upload Prescription': 'رفع الوصفة',
          'Categories': 'الفئات',
          'Browse Medicines & Products': 'تصفح الأدوية والمنتجات',
          'Category': 'الفئة',
          'All Categories': 'كل الفئات',
          'Type': 'النوع',
          'All Types': 'كل الأنواع',
          'Availability': 'التوفر',
          'All': 'الكل',
          'In Stock': 'متوفر',
          'No Prescription Required': 'لا يتطلب وصفة',
          'Search medicines, brands...': 'ابحث عن الأدوية أو العلامات...',
          'About Us': 'من نحن',
          'Licensed Pharmacists': 'صيادلة مرخصون',
          'For Customers': 'للعملاء',
          'Browse Medicines': 'تصفح الأدوية',
          'Prescription Upload': 'رفع الوصفة',
          'Health Tips': 'نصائح صحية',
          'For Pharmacies': 'للصيدليات',
          'Partner with Us': 'كن شريكاً معنا',
          'Partner Portal': 'بوابة الشركاء',
          'Resources': 'الموارد',
          'Contact & Support': 'الاتصال والدعم',
          '24/7 Support': 'الدعم 24/7',
        },
      },
    },
  },
  {
    source: 'doctor.html',
    output: 'doctor.html',
    canonicalBase: '/doctor.html',
    kind: 'collection',
    translations: {
      fr: {
        title: 'Médecins & rendez-vous - eDalab',
        description: 'Réservez des rendez-vous médicaux et consultez des professionnels de santé sur eDalab.',
        ogTitle: 'Médecins & rendez-vous - eDalab',
        ogDescription: 'Réservez un médecin à Djibouti et obtenez des conseils fiables.',
        replacements: {
          'Home': 'Accueil', 'Food': 'Restauration', 'Shopping': 'Boutique', 'Pharmacy': 'Pharmacie', 'Doctor': 'Médecin', 'Hotel': 'Hôtel', 'Ride': 'Trajet', 'Services': 'Services', 'Laundry': 'Blanchisserie', 'Wishlist': 'Favoris', 'Cart': 'Panier',
          'Your Health, Our Priority 💊': 'Votre santé, notre priorité 💊',
          'Connect with qualified doctors, book appointments, and get expert medical advice anytime, anywhere.': 'Consultez des médecins qualifiés, prenez rendez-vous et recevez des conseils médicaux à tout moment.',
          'Find a Doctor': 'Trouver un médecin',
          'Top Doctors': 'Meilleurs médecins',
          'Book an Appointment': 'Prendre rendez-vous',
          'Describe your symptoms or reason for visit': 'Décrivez vos symptômes ou la raison de votre visite',
          'Search doctors, specialties...': 'Rechercher des médecins ou spécialités...',
          'All': 'Tous',
          'Availability': 'Disponibilité',
          'Available Today': 'Disponible aujourd’hui',
          'Available Now': 'Disponible maintenant',
          'Rating': 'Note',
          '4.5+ Stars': '4.5+ étoiles',
          '5 Stars': '5 étoiles',
          'Pediatrics': 'Pédiatrie',
          'Dermatology': 'Dermatologie',
          'Psychiatry': 'Psychiatrie',
          'Orthopedics': 'Orthopédie',
          'About Us': 'À propos',
          'Resources': 'Ressources',
          'For Doctors': 'Pour les médecins',
          'Join Us': 'Rejoignez-nous',
          'Doctor Portal': 'Portail médecin',
          'Contact & Emergency': 'Contact et urgence',
          '24/7 Support': 'Assistance 24h/24 et 7j/7',
        },
      },
      ar: {
        title: 'الأطباء والحجوزات - إيدالاب',
        description: 'احجز مواعيد الأطباء واستشر المختصين الصحيين عبر إيدالاب.',
        ogTitle: 'الأطباء والحجوزات - إيدالاب',
        ogDescription: 'احجز طبيباً في جيبوتي واحصل على رعاية موثوقة.',
        replacements: {
          'Home': 'الرئيسية', 'Food': 'الطعام', 'Shopping': 'التسوق', 'Pharmacy': 'الصيدلية', 'Doctor': 'الطبيب', 'Hotel': 'الفندق', 'Ride': 'المشاوير', 'Services': 'الخدمات', 'Laundry': 'الغسيل', 'Wishlist': 'المفضلة', 'Cart': 'السلة',
          'Your Health, Our Priority 💊': 'صحتك أولويتنا 💊',
          'Connect with qualified doctors, book appointments, and get expert medical advice anytime, anywhere.': 'تواصل مع أطباء مؤهلين، واحجز المواعيد، واحصل على نصائح طبية موثوقة في أي وقت.',
          'Find a Doctor': 'ابحث عن طبيب',
          'Top Doctors': 'أفضل الأطباء',
          'Book an Appointment': 'احجز موعداً',
          'Describe your symptoms or reason for visit': 'اشرح الأعراض أو سبب الزيارة',
          'Search doctors, specialties...': 'ابحث عن الأطباء أو التخصصات...',
          'All': 'الكل',
          'Availability': 'التوفر',
          'Available Today': 'متاح اليوم',
          'Available Now': 'متاح الآن',
          'Rating': 'التقييم',
          '4.5+ Stars': '4.5+ نجوم',
          '5 Stars': '5 نجوم',
          'Pediatrics': 'طب الأطفال',
          'Dermatology': 'الأمراض الجلدية',
          'Psychiatry': 'الطب النفسي',
          'Orthopedics': 'جراحة العظام',
          'About Us': 'من نحن',
          'Resources': 'الموارد',
          'For Doctors': 'للأطباء',
          'Join Us': 'انضم إلينا',
          'Doctor Portal': 'بوابة الأطباء',
          'Contact & Emergency': 'الاتصال والطوارئ',
          '24/7 Support': 'الدعم 24/7',
        },
      },
    },
  },
  {
    source: 'hotel.html',
    output: 'hotel.html',
    canonicalBase: '/hotel.html',
    kind: 'collection',
    translations: {
      fr: {
        title: 'Hôtels & réservations - eDalab',
        description: 'Réservez des hôtels et hébergements sur eDalab avec les meilleurs prix et confirmation instantanée.',
        ogTitle: 'Hôtels & réservations - eDalab',
        ogDescription: 'Réservez votre séjour à Djibouti avec confirmation instantanée.',
        replacements: {
          'Home': 'Accueil', 'Food': 'Restauration', 'Shopping': 'Boutique', 'Pharmacy': 'Pharmacie', 'Doctor': 'Médecin', 'Hotel': 'Hôtel', 'Ride': 'Trajet', 'Services': 'Services', 'Laundry': 'Blanchisserie', 'Wishlist': 'Favoris', 'Cart': 'Panier',
          'Find Your Perfect Stay 🏨': 'Trouvez votre séjour idéal 🏨',
          'Comfortable rooms, great locations, and unbeatable prices. Book now and explore amazing destinations!': 'Chambres confortables, excellents emplacements et prix imbattables. Réservez dès maintenant.',
          'Search Hotels': 'Rechercher des hôtels',
          'Filter Results': 'Filtrer les résultats',
          'Search Hotels': 'Rechercher des hôtels',
          'Search Hotels': 'Rechercher des hôtels',
          'Price Range': 'Fourchette de prix',
          'All Prices': 'Tous les prix',
          'Star Rating': 'Classement par étoiles',
          'All Ratings': 'Toutes les notes',
          '4.5+ Stars': '4.5+ étoiles',
          '5 Stars': '5 étoiles',
          'Amenities': 'Équipements',
          'All Amenities': 'Tous les équipements',
          'Swimming Pool': 'Piscine',
          'Fitness Center': 'Salle de sport',
          'Restaurant': 'Restaurant',
          'About Us': 'À propos',
          'Careers': 'Carrières',
          'Resources': 'Ressources',
        },
      },
      ar: {
        title: 'الفنادق والحجوزات - إيدالاب',
        description: 'احجز الفنادق وأماكن الإقامة على إيدالاب بأفضل الأسعار وتأكيد فوري.',
        ogTitle: 'الفنادق والحجوزات - إيدالاب',
        ogDescription: 'احجز إقامتك في جيبوتي مع تأكيد فوري.',
        replacements: {
          'Home': 'الرئيسية', 'Food': 'الطعام', 'Shopping': 'التسوق', 'Pharmacy': 'الصيدلية', 'Doctor': 'الطبيب', 'Hotel': 'الفندق', 'Ride': 'المشاوير', 'Services': 'الخدمات', 'Laundry': 'الغسيل', 'Wishlist': 'المفضلة', 'Cart': 'السلة',
          'Find Your Perfect Stay 🏨': 'اعثر على إقامتك المثالية 🏨',
          'Comfortable rooms, great locations, and unbeatable prices. Book now and explore amazing destinations!': 'غرف مريحة، مواقع رائعة، وأسعار ممتازة. احجز الآن.',
          'Search Hotels': 'ابحث عن الفنادق',
          'Filter Results': 'تصفية النتائج',
          'Price Range': 'نطاق السعر',
          'All Prices': 'كل الأسعار',
          'Star Rating': 'تصنيف النجوم',
          'All Ratings': 'كل التقييمات',
          '4.5+ Stars': '4.5+ نجوم',
          '5 Stars': '5 نجوم',
          'Amenities': 'المرافق',
          'All Amenities': 'كل المرافق',
          'Swimming Pool': 'مسبح',
          'Fitness Center': 'مركز لياقة',
          'Restaurant': 'مطعم',
          'About Us': 'من نحن',
          'Careers': 'الوظائف',
          'Resources': 'الموارد',
        },
      },
    },
  },
  {
    source: 'ride.html',
    output: 'ride.html',
    canonicalBase: '/ride.html',
    kind: 'collection',
    translations: {
      fr: {
        title: 'Trajets - eDalab',
        description: 'Réservez un trajet avec eDalab. Transport rapide, sûr et abordable.',
        ogTitle: 'Trajets - eDalab',
        ogDescription: 'Réservez vos trajets à Djibouti rapidement et en toute sécurité.',
        replacements: {
          'Home': 'Accueil', 'Food': 'Restauration', 'Shopping': 'Boutique', 'Pharmacy': 'Pharmacie', 'Doctor': 'Médecin', 'Hotel': 'Hôtel', 'Ride': 'Trajet', 'Services': 'Services', 'Laundry': 'Blanchisserie', 'Wishlist': 'Favoris', 'Cart': 'Panier',
          'Book Your Ride With eDalab': 'Réservez votre trajet avec eDalab',
          'Ride Types': 'Types de trajets',
          'Book a Ride': 'Réserver un trajet',
          'Enter pickup address': 'Entrez l’adresse de départ',
          'Enter destination address': 'Entrez l’adresse de destination',
          'Luggage, pets, etc.': 'Bagages, animaux, etc.',
          'Where do you want to go?': 'Où voulez-vous aller ?',
          'How rides work': 'Comment fonctionnent les trajets',
          'Safety': 'Sécurité',
          'Pricing': 'Tarification',
          'For Riders': 'Pour les passagers',
          'Book a ride': 'Réserver un trajet',
          'Trip history': 'Historique des trajets',
          'Help Center': 'Centre d’aide',
          'For Drivers': 'Pour les chauffeurs',
          'Become a driver': 'Devenir chauffeur',
          'Driver support': 'Assistance chauffeur',
          'Requirements': 'Conditions',
          'Contact': 'Contact',
          'Surge Pricing': 'Tarification dynamique',
        },
      },
      ar: {
        title: 'المشاوير - إيدالاب',
        description: 'احجز مشوارك مع إيدالاب. تنقل سريع وآمن وبأسعار مناسبة.',
        ogTitle: 'المشاوير - إيدالاب',
        ogDescription: 'احجز مشاويرك في جيبوتي بسرعة وأمان.',
        replacements: {
          'Home': 'الرئيسية', 'Food': 'الطعام', 'Shopping': 'التسوق', 'Pharmacy': 'الصيدلية', 'Doctor': 'الطبيب', 'Hotel': 'الفندق', 'Ride': 'المشاوير', 'Services': 'الخدمات', 'Laundry': 'الغسيل', 'Wishlist': 'المفضلة', 'Cart': 'السلة',
          'Book Your Ride With eDalab': 'احجز مشوارك مع إيدالاب',
          'Ride Types': 'أنواع المشاوير',
          'Book a Ride': 'احجز مشواراً',
          'Enter pickup address': 'أدخل موقع الانطلاق',
          'Enter destination address': 'أدخل الوجهة',
          'Luggage, pets, etc.': 'أمتعة، حيوانات أليفة، وغيرها',
          'Where do you want to go?': 'إلى أين تريد الذهاب؟',
          'How rides work': 'كيف تعمل المشاوير',
          'Safety': 'السلامة',
          'Pricing': 'الأسعار',
          'For Riders': 'للركاب',
          'Book a ride': 'احجز مشواراً',
          'Trip history': 'سجل المشاوير',
          'Help Center': 'مركز المساعدة',
          'For Drivers': 'للسائقين',
          'Become a driver': 'كن سائقاً',
          'Driver support': 'دعم السائقين',
          'Requirements': 'المتطلبات',
          'Contact': 'اتصل بنا',
          'Surge Pricing': 'التسعير المتغير',
        },
      },
    },
  },
  {
    source: 'home-services.html',
    output: 'home-services.html',
    canonicalBase: '/home-services.html',
    kind: 'collection',
    translations: {
      fr: {
        title: 'Services à domicile - eDalab',
        description: 'Réservez des services à domicile, ménage, maintenance, plomberie et plus encore avec des professionnels fiables.',
        ogTitle: 'Services à domicile - eDalab',
        ogDescription: 'Des professionnels fiables à domicile dans toute la ville.',
        replacements: {
          'Home': 'Accueil', 'Food': 'Restauration', 'Shopping': 'Boutique', 'Pharmacy': 'Pharmacie', 'Doctor': 'Médecin', 'Hotel': 'Hôtel', 'Ride': 'Trajet', 'Services': 'Services', 'Laundry': 'Blanchisserie', 'Wishlist': 'Favoris', 'Cart': 'Panier',
          'Trusted Home Services, Ready When You Need Them': 'Des services à domicile fiables, quand vous en avez besoin',
          'Choose a Service': 'Choisissez un service',
          'Available Professionals': 'Professionnels disponibles',
          'Service Type': 'Type de service',
          'All Services': 'Tous les services',
          'Any Rating': 'Toute note',
          'Any Time': 'N’importe quand',
          'Become a provider': 'Devenir prestataire',
          'Search a service or provider...': 'Rechercher un service ou un prestataire...',
          'How booking works': 'Comment fonctionne la réservation',
          'Partner standards': 'Normes des partenaires',
          'Support': 'Assistance',
          'For Customers': 'Pour les clients',
          'Browse categories': 'Parcourir les catégories',
          'Find professionals': 'Trouver des professionnels',
          'Help Center': 'Centre d’aide',
          'For Pros': 'Pour les professionnels',
          'Provider resources': 'Ressources prestataires',
          'Coverage areas': 'Zones couvertes',
          'Cleaning': 'Nettoyage',
          'Maintenance': 'Maintenance',
          'Plumbing': 'Plomberie',
          'Electrical': 'Électricité',
          'Rating': 'Note',
          'Price Range': 'Fourchette de prix',
          'All Prices': 'Tous les prix',
          'Availability': 'Disponibilité',
          'Today': 'Aujourd’hui',
          'Tomorrow': 'Demain',
          'This Week': 'Cette semaine',
          '5 Stars': '5 étoiles',
          '4+ Stars': '4+ étoiles',
          '3+ Stars': '3+ étoiles',
        },
      },
      ar: {
        title: 'الخدمات المنزلية - إيدالاب',
        description: 'احجز خدمات منزلية مثل التنظيف والصيانة والسباكة والمزيد مع محترفين موثوقين.',
        ogTitle: 'الخدمات المنزلية - إيدالاب',
        ogDescription: 'محترفون موثوقون لخدمات المنزل في جميع أنحاء المدينة.',
        replacements: {
          'Home': 'الرئيسية', 'Food': 'الطعام', 'Shopping': 'التسوق', 'Pharmacy': 'الصيدلية', 'Doctor': 'الطبيب', 'Hotel': 'الفندق', 'Ride': 'المشاوير', 'Services': 'الخدمات', 'Laundry': 'الغسيل', 'Wishlist': 'المفضلة', 'Cart': 'السلة',
          'Trusted Home Services, Ready When You Need Them': 'خدمات منزلية موثوقة عندما تحتاجها',
          'Choose a Service': 'اختر خدمة',
          'Available Professionals': 'المحترفون المتاحون',
          'Service Type': 'نوع الخدمة',
          'All Services': 'كل الخدمات',
          'Any Rating': 'أي تقييم',
          'Any Time': 'أي وقت',
          'Become a provider': 'كن مزود خدمة',
          'Search a service or provider...': 'ابحث عن خدمة أو مقدم خدمة...',
          'How booking works': 'كيف يعمل الحجز',
          'Partner standards': 'معايير الشركاء',
          'Support': 'الدعم',
          'For Customers': 'للعملاء',
          'Browse categories': 'تصفح الفئات',
          'Find professionals': 'اعثر على المحترفين',
          'Help Center': 'مركز المساعدة',
          'For Pros': 'للمهنيين',
          'Provider resources': 'موارد مقدمي الخدمة',
          'Coverage areas': 'مناطق التغطية',
          'Cleaning': 'التنظيف',
          'Maintenance': 'الصيانة',
          'Plumbing': 'السباكة',
          'Electrical': 'الكهرباء',
          'Rating': 'التقييم',
          'Price Range': 'نطاق السعر',
          'All Prices': 'كل الأسعار',
          'Availability': 'التوفر',
          'Today': 'اليوم',
          'Tomorrow': 'غداً',
          'This Week': 'هذا الأسبوع',
          '5 Stars': '5 نجوم',
          '4+ Stars': '4+ نجوم',
          '3+ Stars': '3+ نجوم',
        },
      },
    },
  },
  {
    source: 'laundry.html',
    output: 'laundry.html',
    canonicalBase: '/laundry.html',
    kind: 'collection',
    translations: {
      fr: {
        title: 'Blanchisserie - eDalab',
        description: 'Service de blanchisserie rapide et fiable avec collecte et livraison.',
        ogTitle: 'Blanchisserie - eDalab',
        ogDescription: 'Service de blanchisserie avec collecte et livraison à Djibouti.',
        replacements: {
          'Home': 'Accueil', 'Food': 'Restauration', 'Shopping': 'Boutique', 'Pharmacy': 'Pharmacie', 'Doctor': 'Médecin', 'Hotel': 'Hôtel', 'Ride': 'Trajet', 'Services': 'Services', 'Laundry': 'Blanchisserie', 'Wishlist': 'Favoris', 'Cart': 'Panier',
          'Laundry Service Made Simple': 'La blanchisserie simplifiée',
          'Laundry Services': 'Services de blanchisserie',
          'Place Your Order': 'Passez votre commande',
          'Enter your address': 'Entrez votre adresse',
          'e.g., Delicate clothes, hand wash only...': 'ex. vêtements délicats, lavage à la main uniquement...',
          'Search a laundry service...': 'Rechercher un service de blanchisserie...',
          'For Customers': 'Pour les clients',
          'Book laundry': 'Réserver une blanchisserie',
          'Track orders': 'Suivre les commandes',
          'Help Center': 'Centre d’aide',
          'Services': 'Services',
          'Wash & fold': 'Lavage et pliage',
          'Express cleaning': 'Nettoyage express',
          'Stain treatment': 'Traitement des taches',
          'Pickup zones': 'Zones de collecte',
          'Fabric care tips': 'Conseils d’entretien des tissus',
        },
      },
      ar: {
        title: 'الغسيل - إيدالاب',
        description: 'خدمة غسيل سريعة وموثوقة مع الاستلام والتوصيل.',
        ogTitle: 'الغسيل - إيدالاب',
        ogDescription: 'خدمة غسيل مع الاستلام والتوصيل في جيبوتي.',
        replacements: {
          'Home': 'الرئيسية', 'Food': 'الطعام', 'Shopping': 'التسوق', 'Pharmacy': 'الصيدلية', 'Doctor': 'الطبيب', 'Hotel': 'الفندق', 'Ride': 'المشاوير', 'Services': 'الخدمات', 'Laundry': 'الغسيل', 'Wishlist': 'المفضلة', 'Cart': 'السلة',
          'Laundry Service Made Simple': 'خدمة الغسيل بسهولة',
          'Laundry Services': 'خدمات الغسيل',
          'Place Your Order': 'قدّم طلبك',
          'Enter your address': 'أدخل عنوانك',
          'e.g., Delicate clothes, hand wash only...': 'مثال: ملابس حساسة، غسيل يدوي فقط...',
          'Search a laundry service...': 'ابحث عن خدمة غسيل...',
          'For Customers': 'للعملاء',
          'Book laundry': 'احجز خدمة الغسيل',
          'Track orders': 'تتبع الطلبات',
          'Help Center': 'مركز المساعدة',
          'Services': 'الخدمات',
          'Wash & fold': 'غسيل وطي',
          'Express cleaning': 'تنظيف سريع',
          'Stain treatment': 'معالجة البقع',
          'Pickup zones': 'مناطق الاستلام',
          'Fabric care tips': 'نصائح العناية بالأقمشة',
        },
      },
    },
  },
];

const siteOrigin = 'https://edalab.app';
const buildDate = new Date().toISOString().split('T')[0];
const supportedLangs = ['en', 'fr', 'ar'];

const englishSeoBySource = {
  'index.html': {
    title: 'eDalab — One app for all your needs | Food, doctor, hotel, pharmacy in Djibouti',
    description: 'eDalab is Djibouti’s #1 super-app. Order food, book doctors, find pharmacies, request a ride, shop, book a hotel, and more.',
    ogTitle: 'eDalab — One app for all your needs',
    ogDescription: 'Djibouti’s super-app for food, doctors, hotels, pharmacies, rides, shopping, and laundry.',
  },
  'food.html': {
    title: 'Food Delivery - eDalab',
    description: 'Order delicious meals from your favorite restaurants on eDalab. Fast delivery, live tracking, and exclusive deals.',
    ogTitle: 'Food Delivery - eDalab',
    ogDescription: 'Order food in Djibouti with fast delivery and live tracking.',
  },
  'shopping.html': {
    title: 'Shopping - eDalab',
    description: 'Shop electronics, fashion, home essentials, and more on eDalab with fast delivery.',
    ogTitle: 'Shopping - eDalab',
    ogDescription: 'Fashion, electronics, and home essentials with fast delivery in Djibouti.',
  },
  'pharmacy.html': {
    title: 'Pharmacy - eDalab',
    description: 'Buy medicines and health products on eDalab with fast delivery and trusted support.',
    ogTitle: 'Pharmacy - eDalab',
    ogDescription: 'Medicines and health products delivered fast in Djibouti.',
  },
  'doctor.html': {
    title: 'Doctors & Appointments - eDalab',
    description: 'Book doctor appointments and consult healthcare professionals on eDalab.',
    ogTitle: 'Doctors & Appointments - eDalab',
    ogDescription: 'Book a doctor in Djibouti and get trusted care.',
  },
  'hotel.html': {
    title: 'Hotels & Bookings - eDalab',
    description: 'Book hotels and stays on eDalab with the best prices and instant confirmation.',
    ogTitle: 'Hotels & Bookings - eDalab',
    ogDescription: 'Book your stay in Djibouti with instant confirmation.',
  },
  'ride.html': {
    title: 'Rides - eDalab',
    description: 'Book a ride with eDalab. Fast, safe, and affordable transportation.',
    ogTitle: 'Rides - eDalab',
    ogDescription: 'Book rides in Djibouti quickly and safely.',
  },
  'home-services.html': {
    title: 'Home Services - eDalab',
    description: 'Book home services like cleaning, maintenance, plumbing, and more with trusted professionals.',
    ogTitle: 'Home Services - eDalab',
    ogDescription: 'Trusted professionals for home services across the city.',
  },
  'laundry.html': {
    title: 'Laundry - eDalab',
    description: 'Fast, reliable laundry service with pickup and delivery.',
    ogTitle: 'Laundry - eDalab',
    ogDescription: 'Laundry service with pickup and delivery in Djibouti.',
  },
};

const englishSourceOverridesBySource = {
  'food.html': {
    'Envie de manger ? Commandez auprès de vos restaurants préférés': 'Hungry? Order from your favorite restaurants',
    'Livraison rapide, plats frais et offres exclusives. Tout ce que vos papilles réclament.': 'Fast delivery, fresh food, and exclusive deals. Everything your taste buds crave.',
    'aria-label="Favoris"': 'aria-label="Wishlist"',
    'aria-label="Panier"': 'aria-label="Cart"',
  },
  'shopping.html': {
    'Achetez tout ce que vous aimez': 'Shop Everything You Love',
    'Mode, électronique, décoration et bien plus encore. Tout au même endroit avec livraison rapide.': 'Fashion, electronics, home decor, and more. All in one place with fast delivery.',
  },
  'pharmacy.html': {
    'Santé et bien-être à portée de main': 'Health & Wellness at Your Fingertips',
    'Commandez médicaments, produits de santé et compléments bien-être. Livraison rapide et qualité de confiance.': 'Order medicines, health products, and wellness supplements. Fast delivery and trusted quality.',
    'Téléchargez votre ordonnance': 'Upload Your Prescription',
    'Téléchargez votre ordonnance pour vous faire livrer vos médicaments': 'Upload your prescription to get medicines delivered',
    'Téléchargez votre ordonnance pour recevoir vos médicaments': 'Upload your prescription to get medicines delivered',
  },
  'doctor.html': {
    'Votre santé, notre priorité': 'Your health, our priority',
    'Entrez en contact avec des médecins qualifiés, prenez rendez-vous et obtenez des conseils médicaux d’experts à tout moment.': 'Connect with qualified doctors, book appointments, and get expert medical advice anytime.',
  },
  'hotel.html': {
    'Trouvez votre séjour idéal': 'Find your perfect stay',
    'Des chambres confortables, d’excellents emplacements et des prix imbattables. Réservez maintenant et découvrez des destinations incroyables.': 'Comfortable rooms, great locations, and unbeatable prices. Book now and explore amazing destinations.',
  },
  'home-services.html': {
    'Des services à domicile fiables quand vous en avez besoin': 'Trusted home services when you need them',
    'Parcourez les catégories, comparez les professionnels et réservez l’aide adaptée à votre maison et à votre quotidien.': 'Browse categories, compare professionals, and book the right help for your home and daily life.',
    'Choisir un service': 'Choose a service',
  },
};

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function invertMap(map = {}) {
  return Object.fromEntries(
    Object.entries(map).map(([key, value]) => [value, key])
  );
}

function getLocalizedPath(lang, canonicalBase) {
  if (lang === 'fr') {
    return canonicalBase;
  }
  return `/${lang}${canonicalBase === '/' ? '/' : canonicalBase}`;
}

function getAlternateHref(lang, canonicalBase) {
  return `${siteOrigin}${getLocalizedPath(lang, canonicalBase)}`;
}

function buildEnglishCopy(config) {
  const frCopy = config.translations.fr;
  const enSeo = englishSeoBySource[config.source];
  return {
    ...enSeo,
    replacements: {
      ...invertMap(commonReplacements.fr),
      ...invertMap(frCopy.replacements),
    },
    scriptReplacements: invertMap(frCopy.scriptReplacements || {}),
  };
}

function prefixRelativeUrls(html) {
  return html.replace(/\b(href|src)=["'](?!https?:|mailto:|tel:|#|data:|\/\/|\.{2}\/)([^"']+)["']/g, (match, attr, value) => {
    return `${attr}="../${value}"`;
  });
}

function localizeInternalLinks(html, outputFile) {
  let localized = html.replace(/href="\.\.\/index\.html"/g, 'href="index.html"');
  for (const page of localizedPages) {
    if (page === 'index.html') continue;
    localized = localized.replace(new RegExp(`href="\\.\\.\\/${page.replace('.', '\\.')}"`, 'g'), `href="${page}"`);
  }
  return localized;
}

function replaceAllTextOutsideScripts(html, replacements) {
  const entries = Object.entries(replacements).sort((a, b) => b[0].length - a[0].length);
  return html
    .split(/(<script[\s\S]*?<\/script>)/gi)
    .map((chunk) => {
      if (/^<script[\s\S]*<\/script>$/i.test(chunk)) {
        return chunk;
      }

      return chunk
        .split(/(<[^>]+>)/g)
        .map((part) => {
          if (part.startsWith('<') && part.endsWith('>')) {
            return part;
          }

          let localized = part;
          for (const [from, to] of entries) {
            if (/^[A-Za-z]+$/.test(from)) {
              localized = localized.replace(new RegExp(`\\b${escapeRegExp(from)}\\b`, 'g'), to);
            } else {
              localized = localized.split(from).join(to);
            }
          }
          return localized;
        })
        .join('');
    })
    .join('');
}

function replaceInsideScripts(html, replacements = {}) {
  const entries = Object.entries(replacements).sort((a, b) => b[0].length - a[0].length);
  if (!entries.length) {
    return html;
  }

  return html
    .split(/(<script[\s\S]*?<\/script>)/gi)
    .map((chunk) => {
      if (!/^<script[\s\S]*<\/script>$/i.test(chunk)) {
        return chunk;
      }

      let localized = chunk;
      for (const [from, to] of entries) {
        localized = localized.split(from).join(to);
      }
      return localized;
    })
    .join('');
}

function buildSeoLinks(canonicalEn, canonicalLocalized) {
  return [
    `<link rel="alternate" hreflang="en" href="${getAlternateHref('en', canonicalEn)}"/>`,
    `<link rel="alternate" hreflang="fr" href="${getAlternateHref('fr', canonicalEn)}"/>`,
    `<link rel="alternate" hreflang="ar" href="${getAlternateHref('ar', canonicalEn)}"/>`,
    `<link rel="alternate" hreflang="x-default" href="${getAlternateHref('fr', canonicalEn)}"/>`,
    `<link rel="canonical" href="https://edalab.app${canonicalLocalized}"/>`,
  ].join('\n');
}

function injectSeoHead(html, lang, canonicalEn, copy) {
  const canonicalLocalized = getLocalizedPath(lang, canonicalEn);

  let localized = html
    .replace(/<link rel="alternate" hreflang="[^"]+" href="https:\/\/edalab\.(?:dj|app)[^"]*"\/>\n?/g, '')
    .replace(/<link rel="canonical" href="https:\/\/edalab\.(?:dj|app)[^"]*"\/>\n?/g, '');

  localized = localized.replace(/<title\b[^>]*>[\s\S]*?<\/title>/i, `<title>${copy.title}</title>`);

  if (/<meta name="description"/i.test(localized)) {
    localized = localized.replace(/<meta name="description" content="[^"]*"\s*\/?>/i, `<meta name="description" content="${copy.description}"/>`);
  } else {
    localized = localized.replace('</head>', `<meta name="description" content="${copy.description}"/>\n</head>`);
  }

  if (/<meta property="og:title"/i.test(localized)) {
    localized = localized.replace(/<meta property="og:title" content="[^"]*"\s*\/?>/i, `<meta property="og:title" content="${copy.ogTitle}"/>`);
  } else {
    localized = localized.replace(/<meta name="description" content="[^"]*"\s*\/?>/i, (match) => `${match}\n<meta property="og:title" content="${copy.ogTitle}"/>`);
  }

  if (/<meta property="og:description"/i.test(localized)) {
    localized = localized.replace(/<meta property="og:description" content="[^"]*"\s*\/?>/i, `<meta property="og:description" content="${copy.ogDescription}"/>`);
  } else {
    localized = localized.replace(/<meta property="og:title" content="[^"]*"\s*\/?>/i, (match) => `${match}\n<meta property="og:description" content="${copy.ogDescription}"/>`);
  }

  const seoLinks = buildSeoLinks(canonicalEn, canonicalLocalized);
  if (/<meta name="robots"/i.test(localized)) {
    localized = localized.replace(/<meta name="robots" content="[^"]*"\s*\/?>/i, (match) => `${match}\n${seoLinks}`);
  } else {
    localized = localized.replace('</head>', `${seoLinks}\n</head>`);
  }

  return localized;
}

function injectStructuredData(html, config, lang, copy) {
  const localizedPath = getLocalizedPath(lang, config.canonicalBase);
  const url = `${siteOrigin}${localizedPath}`;

  let schema;
  if (config.kind === 'home') {
    schema = [
      {
        '@context': 'https://schema.org',
        '@type': 'WebSite',
        name: 'eDalab',
        url,
        inLanguage: lang,
        potentialAction: {
        '@type': 'SearchAction',
          target: `${siteOrigin}${getLocalizedPath(lang, '/')}?q={search_term_string}`,
          'query-input': 'required name=search_term_string',
        },
      },
      {
        '@context': 'https://schema.org',
        '@type': 'Organization',
        name: 'eDalab',
        url: siteOrigin,
        logo: `${siteOrigin}/assets/logo/logo.png`,
        sameAs: [],
      },
    ];
  } else {
    schema = {
      '@context': 'https://schema.org',
      '@type': 'CollectionPage',
      name: copy.ogTitle,
      description: copy.description,
      url,
      inLanguage: lang,
      isPartOf: {
        '@type': 'WebSite',
        name: 'eDalab',
        url: siteOrigin,
      },
      mainEntity: {
        '@type': 'ItemList',
        name: copy.ogTitle,
        description: copy.description,
      },
    };
  }

  const script = `<script type="application/ld+json">\n${JSON.stringify(schema, null, 2)}\n</script>`;
  return html.replace('</head>', `${script}\n</head>`);
}

function buildLocalizedPage(config, lang) {
  const copy = lang === 'en' ? buildEnglishCopy(config) : config.translations[lang];
  const replacements = {
    ...(lang === 'en' ? {} : commonReplacements[lang]),
    ...copy.replacements,
  };
  let html = fs.readFileSync(path.join(webRoot, config.source), 'utf8');
  const localizedPath = getLocalizedPath(lang, config.canonicalBase);

  html = html.replace('<html lang="en">', `<html lang="${lang}" dir="${lang === 'ar' ? 'rtl' : 'ltr'}" data-page-language="${lang}">`);
  html = html.replace('<html lang="fr" dir="ltr" data-page-language="fr">', `<html lang="${lang}" dir="${lang === 'ar' ? 'rtl' : 'ltr'}" data-page-language="${lang}">`);
  html = html.replace(/<script type="application\/ld\+json">[\s\S]*?<\/script>\n?/g, '');
  html = prefixRelativeUrls(html);
  html = localizeInternalLinks(html, config.output);
  html = replaceAllTextOutsideScripts(html, replacements);
  if (lang === 'en' && englishSourceOverridesBySource[config.source]) {
    html = replaceAllTextOutsideScripts(html, englishSourceOverridesBySource[config.source]);
  }
  html = replaceInsideScripts(html, copy.scriptReplacements);
  html = html.replaceAll(`${siteOrigin}${config.canonicalBase}`, `${siteOrigin}${localizedPath}`);
  html = html.replace(/<script type="application\/ld\+json">[\s\S]*?<\/script>\n?/g, '');
  html = html
    .replace(/id="nav[^"]*Count"\s+data-nav-badge="wishlist"/g, 'id="navWishlistCount" data-nav-badge="wishlist"')
    .replace(/id="nav[^"]*Count"\s+data-nav-badge="cart"/g, 'id="navCartCount" data-nav-badge="cart"');
  html = injectSeoHead(html, lang, config.canonicalBase, copy);
  html = injectStructuredData(html, config, lang, copy);

  const outDir = path.join(webRoot, lang);
  fs.mkdirSync(outDir, { recursive: true });
  fs.writeFileSync(path.join(outDir, config.output), html);
}

function generateSitemap() {
  const urls = [];

  for (const config of pageConfigs) {
    urls.push(getAlternateHref('fr', config.canonicalBase));
    urls.push(getAlternateHref('en', config.canonicalBase));
    urls.push(getAlternateHref('ar', config.canonicalBase));
  }

  const uniqueUrls = [...new Set(urls)];
  const xml = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">
${uniqueUrls.map((url) => {
  const path = url.replace(siteOrigin, '') || '/';
  const baseMatch = pageConfigs.find((config) => {
    return supportedLangs.some((lang) => path === getLocalizedPath(lang, config.canonicalBase));
  });
  const canonicalBase = baseMatch?.canonicalBase || '/';
  const enHref = getAlternateHref('en', canonicalBase);
  const frHref = getAlternateHref('fr', canonicalBase);
  const arHref = getAlternateHref('ar', canonicalBase);
  return `  <url>
    <loc>${url}</loc>
    <lastmod>${buildDate}</lastmod>
    <xhtml:link rel="alternate" hreflang="en" href="${enHref}"/>
    <xhtml:link rel="alternate" hreflang="fr" href="${frHref}"/>
    <xhtml:link rel="alternate" hreflang="ar" href="${arHref}"/>
    <xhtml:link rel="alternate" hreflang="x-default" href="${frHref}"/>
  </url>`;
}).join('\n')}
</urlset>
`;

  fs.writeFileSync(path.join(webRoot, 'sitemap.xml'), xml);
}

function generateRobots() {
  const robots = `User-agent: *
Allow: /

Sitemap: ${siteOrigin}/sitemap.xml
`;

  fs.writeFileSync(path.join(webRoot, 'robots.txt'), robots);
}

for (const config of pageConfigs) {
  for (const lang of supportedLangs) {
    buildLocalizedPage(config, lang);
    console.log(`Generated ${lang}/${config.output}`);
  }
}

generateSitemap();
generateRobots();
console.log('Generated sitemap.xml');
console.log('Generated robots.txt');
