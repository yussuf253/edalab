/**
 * Reusable UI Components & Utilities
 * Building blocks for the website features
 */

const UIComponents = {
  logoPath: 'assets/logo/logo.png',
  defaultLanguage: 'en',
  translations: {
    en: {
      'nav.home': 'Home',
      'nav.food': 'Food',
      'nav.shopping': 'Shopping',
      'nav.pharmacy': 'Pharmacy',
      'nav.doctor': 'Doctor',
      'nav.hotel': 'Hotel',
      'nav.ride': 'Ride',
      'nav.services': 'Services',
      'nav.laundry': 'Laundry',
      'nav.wishlist': 'Wishlist',
      'nav.cart': 'Cart',
      'nav.login': 'Login',
      'nav.register': 'Register',
      'nav.profile': 'Profile',
      'nav.logout': 'Logout',
      'home.title': 'eDalab — One App For All Your Needs | Food, Doctor, Hotel, Pharmacy in Djibouti',
      'home.heroEyebrow': 'Serving Djibouti, City & Regions',
      'home.heroTitle': 'One App For',
      'home.heroTitleEmphasis': 'All Your Needs',
      'home.heroDescription': 'eDalab connects you to everything in your city — food, doctors, pharmacies, hotels, rides, shopping and laundry. Real people, real fast.',
      'home.heroSearchPlaceholder': 'Search services, products, restaurants…',
      'home.heroSearchButton': 'Search',
      'home.trendingLabel': 'Trending:',
      'home.trendPizza': 'Pizza',
      'home.trendPharmacy': 'Pharmacy',
      'home.trendHotels': 'Hotels',
      'home.trendLaundry': 'Laundry',
      'home.trendDoctor': 'Doctor',
      'home.servicesLabel': 'All Services',
      'home.servicesTitle': 'Everything you need, right here',
      'home.servicesDescription': "8 modules, one app. From your morning coffee to your doctor's appointment — eDalab has you covered.",
      'home.viewAllServices': 'See all services →',
      'home.howItWorksLabel': 'How It Works',
      'home.howItWorksTitle': 'Order in 4 simple steps',
      'home.howItWorksDescription': 'No learning curve. Just open the app, find what you need, and get it delivered.',
      'home.featuredLabel': 'Featured',
      'home.trendingNearYou': 'Trending near you',
      'home.viewAll': 'View all →',
      'home.newsletterTitle': 'Stay in the loop',
      'home.newsletterDescription': 'New restaurants, exclusive deals & city updates in your inbox.',
      'home.newsletterPlaceholder': 'your@email.com',
      'home.newsletterButton': 'Subscribe →',
      'auth.loginTitle': 'Welcome back',
      'auth.loginSubtitle': 'Sign in to sync your orders, bookings, and profile across the website.',
      'auth.email': 'Email',
      'auth.password': 'Password',
      'auth.forgotPassword': 'Forgot password?',
      'auth.loginButton': 'Login',
      'auth.needAccount': 'Need an account?',
      'auth.createOne': 'Create one',
      'auth.registerTitle': 'Create your account',
      'auth.registerSubtitle': 'Register once to save your orders, addresses, and payment methods.',
      'auth.fullName': 'Full name',
      'auth.phone': 'Phone',
      'auth.passwordHint': 'Use at least 6 characters.',
      'auth.createAccountButton': 'Create account',
      'auth.haveAccount': 'Already have an account?',
      'auth.show': 'Show',
      'auth.hide': 'Hide',
      'auth.loginLoading': 'Signing in...',
      'auth.registerLoading': 'Creating account...',
      'auth.emailPlaceholder': 'you@example.com',
      'auth.passwordPlaceholder': 'Your password',
      'auth.namePlaceholder': 'Your full name',
      'auth.phonePlaceholder': '+253 77 00 00 00',
      'auth.passwordRegisterPlaceholder': 'At least 6 characters',
      'auth.error.loginRequired': 'Enter your email and password.',
      'auth.error.emailRequired': 'Email is required.',
      'auth.error.passwordRequired': 'Password is required.',
      'auth.error.validEmail': 'Enter a valid email address.',
      'auth.error.validEmailHint': 'Use a valid email like name@example.com.',
      'auth.error.loginFailed': 'Login failed. Check your credentials.',
      'auth.error.emailCheck': 'Double-check your email address.',
      'auth.error.passwordMismatch': 'The password does not match this account.',
      'auth.error.registerRequired': 'Fill in the required fields.',
      'auth.error.nameRequired': 'Full name is required.',
      'auth.error.passwordShort': 'Password must be at least 6 characters.',
      'auth.error.passwordShortHint': 'Choose a password with at least 6 characters.',
      'auth.error.validPhone': 'Enter a valid phone number or leave it empty.',
      'auth.error.validPhoneHint': 'Phone number format looks incomplete.',
      'auth.error.registerFailed': 'Registration failed. Try another email.',
      'auth.error.emailInUse': 'This email is already in use.',
      'auth.toast.loginSuccess': 'Logged in successfully!',
      'auth.toast.registerSuccess': 'Account created successfully!',
      'settings.title': 'Settings',
      'settings.notifications': 'Notifications',
      'settings.pushNotifications': 'Push Notifications',
      'settings.pushNotificationsDesc': 'Receive order updates and promotions',
      'settings.emailUpdates': 'Email Updates',
      'settings.emailUpdatesDesc': 'Receive emails about your orders',
      'settings.marketingEmails': 'Marketing Emails',
      'settings.marketingEmailsDesc': 'Receive promotional emails and offers',
      'settings.preferences': 'Preferences',
      'settings.language': 'Language',
      'settings.languageDesc': 'Choose your preferred language',
      'settings.theme': 'Theme',
      'settings.themeDesc': 'Choose light or dark mode',
      'settings.privacy': 'Privacy & Security',
      'settings.twoFactor': 'Two-Factor Authentication',
      'settings.twoFactorDesc': 'Add extra security to your account',
      'settings.privacyPolicy': 'Privacy Policy',
      'settings.privacyPolicyDesc': 'Review our privacy policy',
      'settings.terms': 'Terms of Service',
      'settings.termsDesc': 'Review terms and conditions',
      'settings.view': 'View ›',
      'settings.dangerTitle': 'Danger Zone',
      'settings.dangerDesc': 'These actions are irreversible. Please proceed with caution.',
      'settings.deleteAccount': 'Delete Account',
      'settings.toast.languageUpdated': 'Language updated',
      'settings.toast.themeUpdated': 'Theme updated',
      'settings.authRequired': 'Please log in to manage your settings.',
      'settings.deleteConfirm': 'Are you sure you want to delete your account? This action cannot be undone.',
      'settings.deleteTypeConfirm': 'Type "DELETE" to confirm account deletion',
      'settings.toast.accountDeleted': 'Account deleted',
      'detail.addToCart': 'Add to Cart',
      'detail.buyNow': 'Buy Now',
      'detail.orderNow': 'Order Now',
      'detail.outOfStock': 'This product is out of stock',
      'detail.addedToCartSuffix': 'added to cart!',
      'detail.addedToCartSuffixSimple': 'added to cart!',
      'detail.addedToWishlist': 'Added to wishlist',
      'detail.removedFromWishlist': 'Removed from wishlist',
      'detail.deliciousDish': 'A delicious dish',
      'detail.restaurant': 'Restaurant',
      'detail.noMenuItems': 'No menu items available',
      'detail.add': 'Add',
      'detail.restaurantUnavailable': 'Restaurant unavailable',
      'detail.unavailable': 'Unavailable',
      'detail.backToFood': 'Back to Food',
      'checkout.title': 'Checkout',
      'checkout.deliveryAddress': 'Delivery Address',
      'checkout.addNewAddress': '+ Add New Address',
      'checkout.addNewAddressTitle': 'Add New Address',
      'checkout.type': 'Type',
      'checkout.addressTypeHome': 'Home',
      'checkout.addressTypeWork': 'Work',
      'checkout.addressTypeOther': 'Other',
      'checkout.streetAddress': 'Street Address',
      'checkout.city': 'City',
      'checkout.postalCode': 'Postal Code',
      'checkout.saveAddress': 'Save Address',
      'checkout.cancel': 'Cancel',
      'checkout.deliverySpeed': 'Delivery Speed',
      'checkout.paymentMethod': 'Payment Method',
      'checkout.specialInstructions': 'Special Instructions',
      'checkout.noteForCourier': 'Leave a note for the delivery person',
      'checkout.notesPlaceholder': 'e.g., Please ring the doorbell twice...',
      'checkout.noSavedAddresses': 'No saved addresses',
      'checkout.fillAddressFields': 'Please fill in all address fields',
      'checkout.addressSaved': 'Address saved!',
      'checkout.standardDelivery': 'Standard Delivery',
      'checkout.expressDelivery': 'Express Delivery',
      'checkout.sameDayDelivery': 'Same Day Delivery',
      'checkout.byEvening': 'By Evening',
      'checkout.free': 'FREE',
      'checkout.creditCard': 'Credit Card',
      'checkout.applePay': 'Apple Pay',
      'checkout.paypal': 'PayPal',
      'checkout.cashOnDelivery': 'Cash on Delivery',
      'checkout.payWhenArrives': 'Pay when order arrives',
      'checkout.orderItems': 'Order Items',
      'checkout.pricing': 'Pricing',
      'checkout.subtotal': 'Subtotal',
      'checkout.delivery': 'Delivery',
      'checkout.tax': 'Tax',
      'checkout.discount': 'Discount',
      'checkout.totalAmount': 'Total Amount',
      'checkout.placeOrder': 'Place Order',
      'checkout.selectAddress': 'Please select or add a delivery address',
      'checkout.emptyCartTitle': 'Your Cart is Empty',
      'checkout.emptyCartDescription': 'Add some items to your cart before proceeding to checkout',
      'checkout.continueShopping': 'Continue Shopping',
      'orders.title': 'My Orders',
      'orders.all': 'All Orders',
      'orders.pending': 'Pending',
      'orders.confirmed': 'Confirmed',
      'orders.delivered': 'Delivered',
      'orders.cancelled': 'Cancelled',
      'orders.loginRequired': 'Please log in to view your orders.',
      'orders.empty': 'No orders found',
      'orders.item': 'item',
      'orders.items': 'items',
      'orders.view': 'View',
      'orders.track': 'Track',
      'tracking.title': 'Order Tracking',
      'tracking.orderNumber': 'Order Number',
      'tracking.preparing': 'Preparing',
      'tracking.liveMapSoon': 'Live Tracking Map (Coming Soon)',
      'tracking.deliveryPartner': 'Delivery Partner',
      'tracking.deliveryAddress': 'Delivery Address',
      'tracking.deliveryTo': 'Delivery To',
      'tracking.estimatedDeliveryTime': 'Estimated Delivery Time',
      'tracking.arrivingApprox': 'Arriving in approximately',
      'tracking.needHelp': 'Need Help?',
      'tracking.chatSupport': 'Chat Support',
      'tracking.callSupport': 'Call Support',
      'tracking.onTheWay': 'On the Way',
      'tracking.driverAssigned': 'Driver Assigned',
      'tracking.rideConfirmed': 'Ride Confirmed',
      'tracking.rideConfirmedDesc': 'Your ride request has been accepted',
      'tracking.driverAssignedDesc': 'A nearby driver is heading to your pickup point',
      'tracking.tripInProgress': 'Trip in Progress',
      'tracking.tripInProgressDesc': 'You are on the way to your destination',
      'tracking.tripCompleted': 'Trip Completed',
      'tracking.tripCompletedDesc': 'You have arrived at your destination',
      'tracking.orderConfirmed': 'Order Confirmed',
      'tracking.orderConfirmedDesc': 'Your order has been confirmed and sent to the restaurant',
      'tracking.orderPreparing': 'Order Preparing',
      'tracking.orderPreparingDesc': 'The restaurant is preparing your order',
      'tracking.orderPickedUp': 'Order Picked Up',
      'tracking.orderPickedUpDesc': 'Your order has been picked up for delivery',
      'tracking.outForDelivery': 'Out for Delivery',
      'tracking.outForDeliveryDesc': 'Your order is on the way to you',
      'tracking.deliveredDesc': 'Your order has been delivered successfully',
      'tracking.callingDriver': 'Calling driver...',
      'tracking.openingChat': 'Opening chat...',
      'tracking.contactingSupport': 'Contacting support...',
      'tracking.callingSupport': 'Calling support...',
      'account.profileTitle': 'Profile',
      'account.guestUser': 'Guest User',
      'account.notLoggedIn': 'Not logged in',
      'account.orders': 'Orders',
      'account.spent': 'Spent',
      'account.rewards': 'Rewards',
      'account.editProfile': 'Edit Profile',
      'account.accountSection': 'Account',
      'account.editProfileDesc': 'Update your personal information',
      'account.addresses': 'Addresses',
      'account.addressesDesc': 'Manage delivery addresses',
      'account.payments': 'Payment Methods',
      'account.paymentsDesc': 'Manage your cards and wallets',
      'account.ordersSupport': 'Orders & Support',
      'account.myOrders': 'My Orders',
      'account.myOrdersDesc': 'View your order history',
      'account.helpCenter': 'Help Center',
      'account.helpCenterDesc': 'FAQs and customer support',
      'account.preferences': 'Preferences',
      'account.settings': 'Settings',
      'account.settingsDesc': 'Notifications, language, privacy',
      'account.logout': 'Logout',
      'account.noEmail': 'No email',
      'account.loginRequiredProfile': 'Please log in to view your profile.',
      'account.logoutConfirm': 'Are you sure you want to logout?',
      'account.logoutSuccess': 'Logged out successfully',
      'account.editProfileTitle': 'Edit Profile',
      'account.personalInformation': 'Personal Information',
      'account.firstName': 'First Name',
      'account.lastName': 'Last Name',
      'account.emailAddress': 'Email Address',
      'account.phoneNumber': 'Phone Number',
      'account.dateOfBirth': 'Date of Birth',
      'account.bio': 'Bio',
      'account.tellUsAboutYourself': 'Tell us about yourself',
      'account.saveChanges': 'Save Changes',
      'account.cancel': 'Cancel',
      'account.changePassword': 'Change Password',
      'account.currentPassword': 'Current Password',
      'account.newPassword': 'New Password',
      'account.confirmPassword': 'Confirm Password',
      'account.updatePassword': 'Update Password',
      'account.loginRequiredEdit': 'Please log in to edit your profile.',
      'account.fillRequiredFields': 'Please fill in all required fields',
      'account.profileUpdated': 'Profile updated successfully!',
      'account.fillPasswordFields': 'Please fill in all password fields',
      'account.passwordsDoNotMatch': 'New passwords do not match',
      'account.passwordMinLength': 'Password must be at least 6 characters',
      'account.passwordChanged': 'Password changed successfully!',
      'account.addressesTitle': 'My Addresses',
      'account.addNewAddress': '+ Add New Address',
      'account.addNewAddressTitle': 'Add New Address',
      'account.type': 'Type',
      'account.home': 'Home',
      'account.work': 'Work',
      'account.other': 'Other',
      'account.streetAddress': 'Street Address',
      'account.city': 'City',
      'account.postalCode': 'Postal Code',
      'account.save': 'Save',
      'account.loginRequiredAddresses': 'Please log in to manage your addresses.',
      'account.noSavedAddresses': 'No saved addresses',
      'account.delete': 'Delete',
      'account.fillAllFields': 'Please fill in all fields',
      'account.failedSaveAddress': 'Failed to save address',
      'account.addressSaved': 'Address saved!',
      'account.deleteAddressConfirm': 'Delete this address?',
      'account.failedDeleteAddress': 'Failed to delete address',
      'account.paymentMethodsTitle': 'Payment Methods',
      'account.addPaymentMethod': '+ Add Payment Method',
      'account.addPaymentMethodTitle': 'Add Payment Method',
      'account.cardHolderName': 'Card Holder Name',
      'account.cardNumber': 'Card Number',
      'account.expires': 'Expires',
      'account.cvv': 'CVV',
      'account.loginRequiredPayments': 'Please log in to manage your payment methods.',
      'account.noPaymentMethods': 'No payment methods',
      'account.card': 'Card',
      'account.remove': 'Remove',
      'account.failedSavePayment': 'Failed to save payment method',
      'account.paymentSaved': 'Payment method saved!',
      'account.deletePaymentConfirm': 'Delete this payment method?',
      'account.failedDeletePayment': 'Failed to delete payment method',
      'support.helpCenterTitle': 'Help Center',
      'support.searchFaqs': 'Search FAQs...',
      'support.contactTitle': "Didn't find what you're looking for?",
      'support.contactInfo': "Contact our support team. We're here to help!",
      'support.chat': 'Chat',
      'support.call': 'Call',
      'support.openingChatSupport': 'Opening chat support...',
      'support.callingSupport': 'Calling support...',
      'wishlist.title': 'Your Wishlist',
      'wishlist.subtitle': 'Save products you love and move them to cart when you are ready.',
      'wishlist.continueShopping': 'Continue Shopping',
      'wishlist.emptyTitle': 'Your wishlist is empty',
      'wishlist.emptyDescription': 'Browse the modules and save products you want to come back to.',
      'wishlist.savedForLater': 'Saved for later.',
      'wishlist.addToCart': 'Add to Cart',
      'wishlist.remove': 'Remove',
      'wishlist.addedToCart': 'Added to cart!',
      'wishlist.removed': 'Removed from wishlist',
      'cart.title': 'Your Shopping Cart',
      'cart.promoCode': 'Promo Code',
      'cart.enterCode': 'Enter code',
      'cart.apply': 'Apply',
      'cart.subtotal': 'Subtotal',
      'cart.deliveryFee': 'Delivery Fee',
      'cart.discount': 'Discount',
      'cart.total': 'Total',
      'cart.proceedToCheckout': 'Proceed to Checkout',
      'cart.continueShopping': 'Continue Shopping',
      'cart.empty': 'Your cart is empty',
      'cart.startShopping': 'Start Shopping',
      'cart.enterPromo': 'Please enter a promo code',
      'cart.promoAppliedPrefix': 'Promo code applied! You saved',
      'cart.invalidPromo': 'Invalid promo code',
      'cart.emptyToast': 'Your cart is empty',
      'cart.aboutEdalab': 'About eDalab',
      'cart.aboutUs': 'About Us',
      'cart.careers': 'Careers',
      'cart.blog': 'Blog',
      'cart.forUsers': 'For Users',
      'cart.helpCenter': 'Help Center',
      'cart.trackOrder': 'Track Order',
      'cart.account': 'Account',
      'cart.legal': 'Legal',
      'cart.terms': 'Terms & Conditions',
      'cart.privacy': 'Privacy Policy',
      'cart.contact': 'Contact',
      'success.title': 'Order Confirmed!',
      'success.message': "Your order has been successfully placed and confirmed. We're preparing your items now.",
      'success.orderNumber': 'Order Number',
      'success.orderDate': 'Order Date',
      'success.estimatedDelivery': 'Estimated Delivery',
      'success.deliveryAddress': 'Delivery Address',
      'success.paymentMethod': 'Payment Method',
      'success.orderItems': 'Order Items',
      'success.whatNext': 'What Happens Next?',
      'success.step1Title': "We're Preparing Your Order",
      'success.step1Desc': 'Our team is carefully preparing and packing your items',
      'success.step2Title': 'Your Order is on the Way',
      'success.step2Desc': 'A delivery partner will pick up your order soon',
      'success.step3Title': 'Delivery Confirmation',
      'success.step3Desc': "You'll receive your order at the specified address",
      'success.trackOrder': 'Track Order',
      'success.continueShopping': 'Continue Shopping',
      'success.unknownPayment': 'Unknown',
      'ride.whereToGo': 'Where do you want to go?',
      'ride.go': 'Go',
      'ride.fillRequired': 'Please fill in all required fields',
      'ride.booking': 'Booking...',
      'ride.bookNow': 'Book Ride Now',
      'ride.bookedSuccess': 'Ride booked successfully!',
      'ride.bookFailed': 'Failed to book ride',
      'ride.pickupFallback': 'Pickup',
      'ride.destinationFallback': 'Destination',
      'ride.noActive': 'No active rides',
      'ride.track': 'Track',
      'ride.none': 'None',
      'laundry.searchService': 'Search a laundry service...',
      'laundry.find': 'Find',
      'laundry.baseService': 'Base Service',
      'laundry.additionalServices': 'Additional Services',
      'laundry.pickupDelivery': 'Pickup & Delivery',
      'laundry.totalEstimate': 'Total Estimate',
      'laundry.placeOrder': 'Place Order',
      'laundry.placingOrder': 'Placing Order...',
      'laundry.fillRequired': 'Please fill in all required fields',
      'laundry.orderSuccess': 'Laundry order placed successfully!',
      'laundry.orderFailed': 'Failed to place order',
      'laundry.noOrders': 'No orders yet',
      'laundry.placedOn': 'Placed on',
      'laundry.viewDetails': 'View Details',
      'services.search': 'Search a service or provider...',
      'services.searchButton': 'Search',
      'services.allServices': 'All Services',
      'services.fromPrice': 'From',
      'services.providersCount': 'providers',
      'services.noProviders': 'No providers found',
      'services.homeService': 'Home Service',
      'services.priceStarting': 'starting',
      'services.priceOnRequest': 'Price on request',
      'services.bookNow': 'Book Now',
      'services.bookedSuccessSuffix': 'booked successfully!',
      'doctor.failedLoad': 'Failed to load doctors',
      'doctor.searchPlaceholder': 'Search doctors, specialties...',
      'doctor.noDoctors': 'No doctors found matching your criteria',
      'doctor.bookWith': 'Book Appointment with',
      'doctor.selectDoctor': 'Please select a doctor',
      'doctor.fillRequired': 'Please fill all required fields',
      'doctor.appointmentName': 'Doctor Appointment',
      'doctor.defaultReason': 'General consultation',
      'doctor.bookedSuccess': 'Appointment booked successfully!',
      'doctor.bookFailed': 'Failed to book appointment',
    },
    fr: {
      'nav.home': 'Accueil',
      'nav.food': 'Restauration',
      'nav.shopping': 'Boutique',
      'nav.pharmacy': 'Pharmacie',
      'nav.doctor': 'Médecin',
      'nav.hotel': 'Hôtel',
      'nav.ride': 'Trajet',
      'nav.services': 'Services',
      'nav.laundry': 'Blanchisserie',
      'nav.wishlist': 'Favoris',
      'nav.cart': 'Panier',
      'nav.login': 'Connexion',
      'nav.register': 'Inscription',
      'nav.profile': 'Profil',
      'nav.logout': 'Déconnexion',
      'home.title': 'eDalab — Une seule application pour tous vos besoins | Restauration, médecin, hôtel, pharmacie à Djibouti',
      'home.heroEyebrow': 'Disponible à Djibouti-ville et dans les régions',
      'home.heroTitle': 'Une seule application pour',
      'home.heroTitleEmphasis': 'tous vos besoins',
      'home.heroDescription': 'eDalab vous connecte à tout dans votre ville : restauration, médecins, pharmacies, hôtels, trajets, shopping et blanchisserie. Des personnes réelles, rapidement.',
      'home.heroSearchPlaceholder': 'Rechercher des services, produits, restaurants…',
      'home.heroSearchButton': 'Rechercher',
      'home.trendingLabel': 'Tendance :',
      'home.trendPizza': 'Pizza',
      'home.trendPharmacy': 'Pharmacie',
      'home.trendHotels': 'Hôtels',
      'home.trendLaundry': 'Blanchisserie',
      'home.trendDoctor': 'Médecin',
      'home.servicesLabel': 'Tous les services',
      'home.servicesTitle': 'Tout ce qu’il vous faut, ici même',
      'home.servicesDescription': '8 modules, une seule application. Du café du matin à votre rendez-vous médical, eDalab vous accompagne.',
      'home.viewAllServices': 'Voir tous les services →',
      'home.howItWorksLabel': 'Comment ça marche',
      'home.howItWorksTitle': 'Commandez en 4 étapes simples',
      'home.howItWorksDescription': 'Aucune difficulté. Ouvrez l’application, trouvez ce qu’il vous faut et faites-vous livrer.',
      'home.featuredLabel': 'À la une',
      'home.trendingNearYou': 'Tendance près de chez vous',
      'home.viewAll': 'Tout voir →',
      'home.newsletterTitle': 'Restez informé',
      'home.newsletterDescription': 'Nouveaux restaurants, offres exclusives et infos de la ville dans votre boîte mail.',
      'home.newsletterPlaceholder': 'votre@email.com',
      'home.newsletterButton': 'S’abonner →',
      'auth.loginTitle': 'Bon retour',
      'auth.loginSubtitle': 'Connectez-vous pour synchroniser vos commandes, réservations et profil sur le site.',
      'auth.email': 'E-mail',
      'auth.password': 'Mot de passe',
      'auth.forgotPassword': 'Mot de passe oublié ?',
      'auth.loginButton': 'Connexion',
      'auth.needAccount': 'Besoin d’un compte ?',
      'auth.createOne': 'Créer un compte',
      'auth.registerTitle': 'Créez votre compte',
      'auth.registerSubtitle': 'Inscrivez-vous une fois pour enregistrer vos commandes, adresses et moyens de paiement.',
      'auth.fullName': 'Nom complet',
      'auth.phone': 'Téléphone',
      'auth.passwordHint': 'Utilisez au moins 6 caractères.',
      'auth.createAccountButton': 'Créer un compte',
      'auth.haveAccount': 'Vous avez déjà un compte ?',
      'auth.show': 'Afficher',
      'auth.hide': 'Masquer',
      'auth.loginLoading': 'Connexion...',
      'auth.registerLoading': 'Création du compte...',
      'auth.emailPlaceholder': 'vous@exemple.com',
      'auth.passwordPlaceholder': 'Votre mot de passe',
      'auth.namePlaceholder': 'Votre nom complet',
      'auth.phonePlaceholder': '+253 77 00 00 00',
      'auth.passwordRegisterPlaceholder': 'Au moins 6 caractères',
      'auth.error.loginRequired': 'Saisissez votre e-mail et votre mot de passe.',
      'auth.error.emailRequired': 'L’e-mail est requis.',
      'auth.error.passwordRequired': 'Le mot de passe est requis.',
      'auth.error.validEmail': 'Saisissez une adresse e-mail valide.',
      'auth.error.validEmailHint': 'Utilisez un e-mail valide comme nom@exemple.com.',
      'auth.error.loginFailed': 'Échec de la connexion. Vérifiez vos identifiants.',
      'auth.error.emailCheck': 'Vérifiez votre adresse e-mail.',
      'auth.error.passwordMismatch': 'Le mot de passe ne correspond pas à ce compte.',
      'auth.error.registerRequired': 'Remplissez les champs requis.',
      'auth.error.nameRequired': 'Le nom complet est requis.',
      'auth.error.passwordShort': 'Le mot de passe doit contenir au moins 6 caractères.',
      'auth.error.passwordShortHint': 'Choisissez un mot de passe d’au moins 6 caractères.',
      'auth.error.validPhone': 'Saisissez un numéro valide ou laissez ce champ vide.',
      'auth.error.validPhoneHint': 'Le format du numéro semble incomplet.',
      'auth.error.registerFailed': 'Échec de l’inscription. Essayez un autre e-mail.',
      'auth.error.emailInUse': 'Cet e-mail est déjà utilisé.',
      'auth.toast.loginSuccess': 'Connexion réussie !',
      'auth.toast.registerSuccess': 'Compte créé avec succès !',
      'settings.title': 'Paramètres',
      'settings.notifications': 'Notifications',
      'settings.pushNotifications': 'Notifications push',
      'settings.pushNotificationsDesc': 'Recevoir les mises à jour et promotions',
      'settings.emailUpdates': 'Mises à jour par e-mail',
      'settings.emailUpdatesDesc': 'Recevoir des e-mails sur vos commandes',
      'settings.marketingEmails': 'E-mails marketing',
      'settings.marketingEmailsDesc': 'Recevoir des offres et promotions',
      'settings.preferences': 'Préférences',
      'settings.language': 'Langue',
      'settings.languageDesc': 'Choisissez votre langue préférée',
      'settings.theme': 'Thème',
      'settings.themeDesc': 'Choisissez le mode clair ou sombre',
      'settings.privacy': 'Confidentialité et sécurité',
      'settings.twoFactor': 'Authentification à deux facteurs',
      'settings.twoFactorDesc': 'Ajoutez une sécurité supplémentaire à votre compte',
      'settings.privacyPolicy': 'Politique de confidentialité',
      'settings.privacyPolicyDesc': 'Consultez notre politique de confidentialité',
      'settings.terms': "Conditions d’utilisation",
      'settings.termsDesc': 'Consultez les conditions générales',
      'settings.view': 'Voir ›',
      'settings.dangerTitle': 'Zone sensible',
      'settings.dangerDesc': 'Ces actions sont irréversibles. Veuillez agir avec prudence.',
      'settings.deleteAccount': 'Supprimer le compte',
      'settings.toast.languageUpdated': 'Langue mise à jour',
      'settings.toast.themeUpdated': 'Thème mis à jour',
      'settings.authRequired': 'Veuillez vous connecter pour gérer vos paramètres.',
      'settings.deleteConfirm': 'Voulez-vous vraiment supprimer votre compte ? Cette action est irréversible.',
      'settings.deleteTypeConfirm': 'Tapez "DELETE" pour confirmer la suppression du compte',
      'settings.toast.accountDeleted': 'Compte supprimé',
      'detail.addToCart': 'Ajouter au panier',
      'detail.buyNow': 'Acheter maintenant',
      'detail.orderNow': 'Commander maintenant',
      'detail.outOfStock': 'Ce produit est en rupture de stock',
      'detail.addedToCartSuffix': 'ajouté au panier !',
      'detail.addedToCartSuffixSimple': 'ajouté au panier !',
      'detail.addedToWishlist': 'Ajouté aux favoris',
      'detail.removedFromWishlist': 'Retiré des favoris',
      'detail.deliciousDish': 'Un plat délicieux',
      'detail.restaurant': 'Restaurant',
      'detail.noMenuItems': 'Aucun élément du menu disponible',
      'detail.add': 'Ajouter',
      'detail.restaurantUnavailable': 'Restaurant indisponible',
      'detail.unavailable': 'Indisponible',
      'detail.backToFood': 'Retour à la restauration',
      'checkout.title': 'Paiement',
      'checkout.deliveryAddress': 'Adresse de livraison',
      'checkout.addNewAddress': '+ Ajouter une adresse',
      'checkout.addNewAddressTitle': 'Ajouter une adresse',
      'checkout.type': 'Type',
      'checkout.addressTypeHome': 'Maison',
      'checkout.addressTypeWork': 'Travail',
      'checkout.addressTypeOther': 'Autre',
      'checkout.streetAddress': 'Adresse',
      'checkout.city': 'Ville',
      'checkout.postalCode': 'Code postal',
      'checkout.saveAddress': 'Enregistrer l’adresse',
      'checkout.cancel': 'Annuler',
      'checkout.deliverySpeed': 'Vitesse de livraison',
      'checkout.paymentMethod': 'Mode de paiement',
      'checkout.specialInstructions': 'Instructions spéciales',
      'checkout.noteForCourier': 'Laissez une note au livreur',
      'checkout.notesPlaceholder': 'ex. veuillez sonner deux fois...',
      'checkout.noSavedAddresses': 'Aucune adresse enregistrée',
      'checkout.fillAddressFields': 'Veuillez remplir tous les champs de l’adresse',
      'checkout.addressSaved': 'Adresse enregistrée !',
      'checkout.standardDelivery': 'Livraison standard',
      'checkout.expressDelivery': 'Livraison express',
      'checkout.sameDayDelivery': 'Livraison le jour même',
      'checkout.byEvening': 'Dans la soirée',
      'checkout.free': 'GRATUIT',
      'checkout.creditCard': 'Carte bancaire',
      'checkout.applePay': 'Apple Pay',
      'checkout.paypal': 'PayPal',
      'checkout.cashOnDelivery': 'Paiement à la livraison',
      'checkout.payWhenArrives': 'Payer à la réception',
      'checkout.orderItems': 'Articles commandés',
      'checkout.pricing': 'Tarification',
      'checkout.subtotal': 'Sous-total',
      'checkout.delivery': 'Livraison',
      'checkout.tax': 'Taxe',
      'checkout.discount': 'Remise',
      'checkout.totalAmount': 'Montant total',
      'checkout.placeOrder': 'Passer la commande',
      'checkout.selectAddress': 'Veuillez sélectionner ou ajouter une adresse de livraison',
      'checkout.emptyCartTitle': 'Votre panier est vide',
      'checkout.emptyCartDescription': 'Ajoutez des articles avant de passer au paiement',
      'checkout.continueShopping': 'Continuer vos achats',
      'orders.title': 'Mes commandes',
      'orders.all': 'Toutes les commandes',
      'orders.pending': 'En attente',
      'orders.confirmed': 'Confirmée',
      'orders.delivered': 'Livrée',
      'orders.cancelled': 'Annulée',
      'orders.loginRequired': 'Veuillez vous connecter pour voir vos commandes.',
      'orders.empty': 'Aucune commande trouvée',
      'orders.item': 'article',
      'orders.items': 'articles',
      'orders.view': 'Voir',
      'orders.track': 'Suivre',
      'tracking.title': 'Suivi de commande',
      'tracking.orderNumber': 'Numéro de commande',
      'tracking.preparing': 'Préparation',
      'tracking.liveMapSoon': 'Carte de suivi en direct (bientôt disponible)',
      'tracking.deliveryPartner': 'Partenaire de livraison',
      'tracking.deliveryAddress': 'Adresse de livraison',
      'tracking.deliveryTo': 'Livrer à',
      'tracking.estimatedDeliveryTime': 'Heure de livraison estimée',
      'tracking.arrivingApprox': 'Arrive dans environ',
      'tracking.needHelp': 'Besoin d’aide ?',
      'tracking.chatSupport': 'Assistance chat',
      'tracking.callSupport': 'Appeler l’assistance',
      'tracking.onTheWay': 'En route',
      'tracking.driverAssigned': 'Chauffeur assigné',
      'tracking.rideConfirmed': 'Trajet confirmé',
      'tracking.rideConfirmedDesc': 'Votre demande de trajet a été acceptée',
      'tracking.driverAssignedDesc': 'Un chauffeur proche se dirige vers votre point de départ',
      'tracking.tripInProgress': 'Trajet en cours',
      'tracking.tripInProgressDesc': 'Vous êtes en route vers votre destination',
      'tracking.tripCompleted': 'Trajet terminé',
      'tracking.tripCompletedDesc': 'Vous êtes arrivé à destination',
      'tracking.orderConfirmed': 'Commande confirmée',
      'tracking.orderConfirmedDesc': 'Votre commande a été confirmée et transmise au restaurant',
      'tracking.orderPreparing': 'Commande en préparation',
      'tracking.orderPreparingDesc': 'Le restaurant prépare votre commande',
      'tracking.orderPickedUp': 'Commande récupérée',
      'tracking.orderPickedUpDesc': 'Votre commande a été récupérée pour la livraison',
      'tracking.outForDelivery': 'En cours de livraison',
      'tracking.outForDeliveryDesc': 'Votre commande est en route vers vous',
      'tracking.deliveredDesc': 'Votre commande a été livrée avec succès',
      'tracking.callingDriver': 'Appel du chauffeur...',
      'tracking.openingChat': 'Ouverture du chat...',
      'tracking.contactingSupport': 'Contact du support...',
      'tracking.callingSupport': 'Appel du support...',
      'account.profileTitle': 'Profil',
      'account.guestUser': 'Invité',
      'account.notLoggedIn': 'Non connecté',
      'account.orders': 'Commandes',
      'account.spent': 'Dépensé',
      'account.rewards': 'Récompenses',
      'account.editProfile': 'Modifier le profil',
      'account.accountSection': 'Compte',
      'account.editProfileDesc': 'Mettez à jour vos informations personnelles',
      'account.addresses': 'Adresses',
      'account.addressesDesc': 'Gérez vos adresses de livraison',
      'account.payments': 'Moyens de paiement',
      'account.paymentsDesc': 'Gérez vos cartes et portefeuilles',
      'account.ordersSupport': 'Commandes et assistance',
      'account.myOrders': 'Mes commandes',
      'account.myOrdersDesc': 'Consultez l’historique de vos commandes',
      'account.helpCenter': 'Centre d’aide',
      'account.helpCenterDesc': 'FAQ et assistance client',
      'account.preferences': 'Préférences',
      'account.settings': 'Paramètres',
      'account.settingsDesc': 'Notifications, langue, confidentialité',
      'account.logout': 'Déconnexion',
      'account.noEmail': 'Aucun e-mail',
      'account.loginRequiredProfile': 'Veuillez vous connecter pour voir votre profil.',
      'account.logoutConfirm': 'Voulez-vous vraiment vous déconnecter ?',
      'account.logoutSuccess': 'Déconnexion réussie',
      'account.editProfileTitle': 'Modifier le profil',
      'account.personalInformation': 'Informations personnelles',
      'account.firstName': 'Prénom',
      'account.lastName': 'Nom',
      'account.emailAddress': 'Adresse e-mail',
      'account.phoneNumber': 'Numéro de téléphone',
      'account.dateOfBirth': 'Date de naissance',
      'account.bio': 'Bio',
      'account.tellUsAboutYourself': 'Parlez-nous de vous',
      'account.saveChanges': 'Enregistrer les modifications',
      'account.cancel': 'Annuler',
      'account.changePassword': 'Changer le mot de passe',
      'account.currentPassword': 'Mot de passe actuel',
      'account.newPassword': 'Nouveau mot de passe',
      'account.confirmPassword': 'Confirmer le mot de passe',
      'account.updatePassword': 'Mettre à jour le mot de passe',
      'account.loginRequiredEdit': 'Veuillez vous connecter pour modifier votre profil.',
      'account.fillRequiredFields': 'Veuillez remplir tous les champs obligatoires',
      'account.profileUpdated': 'Profil mis à jour avec succès !',
      'account.fillPasswordFields': 'Veuillez remplir tous les champs du mot de passe',
      'account.passwordsDoNotMatch': 'Les nouveaux mots de passe ne correspondent pas',
      'account.passwordMinLength': 'Le mot de passe doit contenir au moins 6 caractères',
      'account.passwordChanged': 'Mot de passe modifié avec succès !',
      'account.addressesTitle': 'Mes adresses',
      'account.addNewAddress': '+ Ajouter une adresse',
      'account.addNewAddressTitle': 'Ajouter une adresse',
      'account.type': 'Type',
      'account.home': 'Maison',
      'account.work': 'Travail',
      'account.other': 'Autre',
      'account.streetAddress': 'Adresse',
      'account.city': 'Ville',
      'account.postalCode': 'Code postal',
      'account.save': 'Enregistrer',
      'account.loginRequiredAddresses': 'Veuillez vous connecter pour gérer vos adresses.',
      'account.noSavedAddresses': 'Aucune adresse enregistrée',
      'account.delete': 'Supprimer',
      'account.fillAllFields': 'Veuillez remplir tous les champs',
      'account.failedSaveAddress': 'Échec de l’enregistrement de l’adresse',
      'account.addressSaved': 'Adresse enregistrée !',
      'account.deleteAddressConfirm': 'Supprimer cette adresse ?',
      'account.failedDeleteAddress': 'Échec de la suppression de l’adresse',
      'account.paymentMethodsTitle': 'Moyens de paiement',
      'account.addPaymentMethod': '+ Ajouter un moyen de paiement',
      'account.addPaymentMethodTitle': 'Ajouter un moyen de paiement',
      'account.cardHolderName': 'Nom du titulaire',
      'account.cardNumber': 'Numéro de carte',
      'account.expires': 'Expire',
      'account.cvv': 'CVV',
      'account.loginRequiredPayments': 'Veuillez vous connecter pour gérer vos moyens de paiement.',
      'account.noPaymentMethods': 'Aucun moyen de paiement',
      'account.card': 'Carte',
      'account.remove': 'Retirer',
      'account.failedSavePayment': 'Échec de l’enregistrement du moyen de paiement',
      'account.paymentSaved': 'Moyen de paiement enregistré !',
      'account.deletePaymentConfirm': 'Supprimer ce moyen de paiement ?',
      'account.failedDeletePayment': 'Échec de la suppression du moyen de paiement',
      'support.helpCenterTitle': 'Centre d’aide',
      'support.searchFaqs': 'Rechercher dans la FAQ...',
      'support.contactTitle': 'Vous ne trouvez pas ce que vous cherchez ?',
      'support.contactInfo': 'Contactez notre équipe d’assistance. Nous sommes là pour vous aider !',
      'support.chat': 'Chat',
      'support.call': 'Appeler',
      'support.openingChatSupport': 'Ouverture du chat d’assistance...',
      'support.callingSupport': 'Appel de l’assistance...',
      'wishlist.title': 'Vos favoris',
      'wishlist.subtitle': 'Enregistrez les produits que vous aimez et ajoutez-les au panier quand vous êtes prêt.',
      'wishlist.continueShopping': 'Continuer vos achats',
      'wishlist.emptyTitle': 'Votre liste de favoris est vide',
      'wishlist.emptyDescription': 'Parcourez les modules et enregistrez les produits que vous souhaitez retrouver plus tard.',
      'wishlist.savedForLater': 'Enregistré pour plus tard.',
      'wishlist.addToCart': 'Ajouter au panier',
      'wishlist.remove': 'Retirer',
      'wishlist.addedToCart': 'Ajouté au panier !',
      'wishlist.removed': 'Retiré des favoris',
      'cart.title': 'Votre panier',
      'cart.promoCode': 'Code promo',
      'cart.enterCode': 'Saisir le code',
      'cart.apply': 'Appliquer',
      'cart.subtotal': 'Sous-total',
      'cart.deliveryFee': 'Frais de livraison',
      'cart.discount': 'Remise',
      'cart.total': 'Total',
      'cart.proceedToCheckout': 'Passer au paiement',
      'cart.continueShopping': 'Continuer vos achats',
      'cart.empty': 'Votre panier est vide',
      'cart.startShopping': 'Commencer vos achats',
      'cart.enterPromo': 'Veuillez saisir un code promo',
      'cart.promoAppliedPrefix': 'Code promo appliqué ! Vous avez économisé',
      'cart.invalidPromo': 'Code promo invalide',
      'cart.emptyToast': 'Votre panier est vide',
      'cart.aboutEdalab': 'À propos d’eDalab',
      'cart.aboutUs': 'À propos',
      'cart.careers': 'Carrières',
      'cart.blog': 'Blog',
      'cart.forUsers': 'Pour les utilisateurs',
      'cart.helpCenter': 'Centre d’aide',
      'cart.trackOrder': 'Suivre la commande',
      'cart.account': 'Compte',
      'cart.legal': 'Mentions légales',
      'cart.terms': 'Conditions générales',
      'cart.privacy': 'Politique de confidentialité',
      'cart.contact': 'Contact',
      'success.title': 'Commande confirmée !',
      'success.message': 'Votre commande a été passée et confirmée avec succès. Nous préparons vos articles maintenant.',
      'success.orderNumber': 'Numéro de commande',
      'success.orderDate': 'Date de commande',
      'success.estimatedDelivery': 'Livraison estimée',
      'success.deliveryAddress': 'Adresse de livraison',
      'success.paymentMethod': 'Mode de paiement',
      'success.orderItems': 'Articles commandés',
      'success.whatNext': 'Que se passe-t-il ensuite ?',
      'success.step1Title': 'Nous préparons votre commande',
      'success.step1Desc': 'Notre équipe prépare et emballe soigneusement vos articles',
      'success.step2Title': 'Votre commande est en route',
      'success.step2Desc': 'Un partenaire de livraison récupérera votre commande bientôt',
      'success.step3Title': 'Confirmation de livraison',
      'success.step3Desc': 'Vous recevrez votre commande à l’adresse indiquée',
      'success.trackOrder': 'Suivre la commande',
      'success.continueShopping': 'Continuer vos achats',
      'success.unknownPayment': 'Inconnu',
      'ride.whereToGo': 'Où voulez-vous aller ?',
      'ride.go': 'Aller',
      'ride.fillRequired': 'Veuillez remplir tous les champs requis',
      'ride.booking': 'Réservation...',
      'ride.bookNow': 'Réserver maintenant',
      'ride.bookedSuccess': 'Trajet réservé avec succès !',
      'ride.bookFailed': 'Échec de la réservation du trajet',
      'ride.pickupFallback': 'Départ',
      'ride.destinationFallback': 'Destination',
      'ride.noActive': 'Aucun trajet actif',
      'ride.track': 'Suivre',
      'ride.none': 'Aucune',
      'laundry.searchService': 'Rechercher un service de blanchisserie...',
      'laundry.find': 'Trouver',
      'laundry.baseService': 'Service de base',
      'laundry.additionalServices': 'Services supplémentaires',
      'laundry.pickupDelivery': 'Collecte et livraison',
      'laundry.totalEstimate': 'Estimation totale',
      'laundry.placeOrder': 'Passer la commande',
      'laundry.placingOrder': 'Commande en cours...',
      'laundry.fillRequired': 'Veuillez remplir tous les champs requis',
      'laundry.orderSuccess': 'Commande de blanchisserie passée avec succès !',
      'laundry.orderFailed': 'Échec de la commande',
      'laundry.noOrders': 'Aucune commande pour le moment',
      'laundry.placedOn': 'Passée le',
      'laundry.viewDetails': 'Voir les détails',
      'services.search': 'Rechercher un service ou un prestataire...',
      'services.searchButton': 'Rechercher',
      'services.allServices': 'Tous les services',
      'services.fromPrice': 'À partir de',
      'services.providersCount': 'prestataires',
      'services.noProviders': 'Aucun prestataire trouvé',
      'services.homeService': 'Service à domicile',
      'services.priceStarting': 'de départ',
      'services.priceOnRequest': 'Prix sur demande',
      'services.bookNow': 'Réserver',
      'services.bookedSuccessSuffix': 'réservé avec succès !',
      'doctor.failedLoad': 'Échec du chargement des médecins',
      'doctor.searchPlaceholder': 'Rechercher des médecins ou spécialités...',
      'doctor.noDoctors': 'Aucun médecin ne correspond à vos critères',
      'doctor.bookWith': 'Prendre rendez-vous avec',
      'doctor.selectDoctor': 'Veuillez sélectionner un médecin',
      'doctor.fillRequired': 'Veuillez remplir tous les champs requis',
      'doctor.appointmentName': 'Rendez-vous médical',
      'doctor.defaultReason': 'Consultation générale',
      'doctor.bookedSuccess': 'Rendez-vous réservé avec succès !',
      'doctor.bookFailed': 'Échec de la réservation du rendez-vous',
    },
    ar: {
      'nav.home': 'الرئيسية',
      'nav.food': 'الطعام',
      'nav.shopping': 'التسوق',
      'nav.pharmacy': 'الصيدلية',
      'nav.doctor': 'الطبيب',
      'nav.hotel': 'الفندق',
      'nav.ride': 'المشاوير',
      'nav.services': 'الخدمات',
      'nav.laundry': 'الغسيل',
      'nav.wishlist': 'المفضلة',
      'nav.cart': 'السلة',
      'nav.login': 'تسجيل الدخول',
      'nav.register': 'إنشاء حساب',
      'nav.profile': 'الملف الشخصي',
      'nav.logout': 'تسجيل الخروج',
      'home.title': 'إيدالاب — تطبيق واحد لكل احتياجاتك | طعام، طبيب، فندق، صيدلية في جيبوتي',
      'home.heroEyebrow': 'نخدم مدينة جيبوتي والمناطق',
      'home.heroTitle': 'تطبيق واحد لكل',
      'home.heroTitleEmphasis': 'احتياجاتك',
      'home.heroDescription': 'إيدالاب يوصلك بكل ما تحتاجه في مدينتك: الطعام، الأطباء، الصيدليات، الفنادق، المشاوير، التسوق والغسيل. خدمة حقيقية وبسرعة.',
      'home.heroSearchPlaceholder': 'ابحث عن خدمات أو منتجات أو مطاعم…',
      'home.heroSearchButton': 'بحث',
      'home.trendingLabel': 'الرائج:',
      'home.trendPizza': 'بيتزا',
      'home.trendPharmacy': 'صيدلية',
      'home.trendHotels': 'فنادق',
      'home.trendLaundry': 'غسيل',
      'home.trendDoctor': 'طبيب',
      'home.servicesLabel': 'كل الخدمات',
      'home.servicesTitle': 'كل ما تحتاجه هنا',
      'home.servicesDescription': '8 أقسام في تطبيق واحد. من قهوة الصباح إلى موعد الطبيب، إيدالاب معك.',
      'home.viewAllServices': 'عرض كل الخدمات ←',
      'home.howItWorksLabel': 'كيف يعمل',
      'home.howItWorksTitle': 'اطلب في 4 خطوات بسيطة',
      'home.howItWorksDescription': 'بدون تعقيد. افتح التطبيق، وابحث عما تحتاجه، وسيصل إليك.',
      'home.featuredLabel': 'مميز',
      'home.trendingNearYou': 'الرائج بالقرب منك',
      'home.viewAll': 'عرض الكل ←',
      'home.newsletterTitle': 'ابقَ على اطلاع',
      'home.newsletterDescription': 'مطاعم جديدة، عروض حصرية، وأخبار المدينة في بريدك.',
      'home.newsletterPlaceholder': 'your@email.com',
      'home.newsletterButton': 'اشترك ←',
      'auth.loginTitle': 'مرحباً بعودتك',
      'auth.loginSubtitle': 'سجل الدخول لمزامنة طلباتك وحجوزاتك وملفك الشخصي عبر الموقع.',
      'auth.email': 'البريد الإلكتروني',
      'auth.password': 'كلمة المرور',
      'auth.forgotPassword': 'هل نسيت كلمة المرور؟',
      'auth.loginButton': 'تسجيل الدخول',
      'auth.needAccount': 'تحتاج إلى حساب؟',
      'auth.createOne': 'أنشئ حساباً',
      'auth.registerTitle': 'أنشئ حسابك',
      'auth.registerSubtitle': 'سجل مرة واحدة لحفظ طلباتك وعناوينك ووسائل الدفع.',
      'auth.fullName': 'الاسم الكامل',
      'auth.phone': 'الهاتف',
      'auth.passwordHint': 'استخدم 6 أحرف على الأقل.',
      'auth.createAccountButton': 'إنشاء حساب',
      'auth.haveAccount': 'لديك حساب بالفعل؟',
      'auth.show': 'إظهار',
      'auth.hide': 'إخفاء',
      'auth.loginLoading': 'جار تسجيل الدخول...',
      'auth.registerLoading': 'جار إنشاء الحساب...',
      'auth.emailPlaceholder': 'you@example.com',
      'auth.passwordPlaceholder': 'كلمة المرور',
      'auth.namePlaceholder': 'اسمك الكامل',
      'auth.phonePlaceholder': '+253 77 00 00 00',
      'auth.passwordRegisterPlaceholder': '6 أحرف على الأقل',
      'auth.error.loginRequired': 'أدخل البريد الإلكتروني وكلمة المرور.',
      'auth.error.emailRequired': 'البريد الإلكتروني مطلوب.',
      'auth.error.passwordRequired': 'كلمة المرور مطلوبة.',
      'auth.error.validEmail': 'أدخل بريداً إلكترونياً صالحاً.',
      'auth.error.validEmailHint': 'استخدم بريداً صالحاً مثل name@example.com.',
      'auth.error.loginFailed': 'فشل تسجيل الدخول. تحقق من بياناتك.',
      'auth.error.emailCheck': 'تحقق من عنوان بريدك الإلكتروني.',
      'auth.error.passwordMismatch': 'كلمة المرور لا تطابق هذا الحساب.',
      'auth.error.registerRequired': 'املأ الحقول المطلوبة.',
      'auth.error.nameRequired': 'الاسم الكامل مطلوب.',
      'auth.error.passwordShort': 'يجب أن تكون كلمة المرور 6 أحرف على الأقل.',
      'auth.error.passwordShortHint': 'اختر كلمة مرور من 6 أحرف على الأقل.',
      'auth.error.validPhone': 'أدخل رقماً صحيحاً أو اترك الحقل فارغاً.',
      'auth.error.validPhoneHint': 'صيغة رقم الهاتف تبدو غير مكتملة.',
      'auth.error.registerFailed': 'فشل إنشاء الحساب. جرب بريداً آخر.',
      'auth.error.emailInUse': 'هذا البريد مستخدم بالفعل.',
      'auth.toast.loginSuccess': 'تم تسجيل الدخول بنجاح!',
      'auth.toast.registerSuccess': 'تم إنشاء الحساب بنجاح!',
      'settings.title': 'الإعدادات',
      'settings.notifications': 'الإشعارات',
      'settings.pushNotifications': 'الإشعارات الفورية',
      'settings.pushNotificationsDesc': 'استلم تحديثات الطلبات والعروض',
      'settings.emailUpdates': 'تحديثات البريد',
      'settings.emailUpdatesDesc': 'استلم رسائل حول طلباتك',
      'settings.marketingEmails': 'رسائل تسويقية',
      'settings.marketingEmailsDesc': 'استلم العروض والرسائل الترويجية',
      'settings.preferences': 'التفضيلات',
      'settings.language': 'اللغة',
      'settings.languageDesc': 'اختر لغتك المفضلة',
      'settings.theme': 'المظهر',
      'settings.themeDesc': 'اختر الوضع الفاتح أو الداكن',
      'settings.privacy': 'الخصوصية والأمان',
      'settings.twoFactor': 'المصادقة الثنائية',
      'settings.twoFactorDesc': 'أضف طبقة حماية إضافية لحسابك',
      'settings.privacyPolicy': 'سياسة الخصوصية',
      'settings.privacyPolicyDesc': 'راجع سياسة الخصوصية الخاصة بنا',
      'settings.terms': 'شروط الخدمة',
      'settings.termsDesc': 'راجع الشروط والأحكام',
      'settings.view': 'عرض ›',
      'settings.dangerTitle': 'منطقة حساسة',
      'settings.dangerDesc': 'هذه الإجراءات لا يمكن التراجع عنها. يرجى المتابعة بحذر.',
      'settings.deleteAccount': 'حذف الحساب',
      'settings.toast.languageUpdated': 'تم تحديث اللغة',
      'settings.toast.themeUpdated': 'تم تحديث المظهر',
      'settings.authRequired': 'يرجى تسجيل الدخول لإدارة إعداداتك.',
      'settings.deleteConfirm': 'هل أنت متأكد أنك تريد حذف حسابك؟ لا يمكن التراجع عن هذا الإجراء.',
      'settings.deleteTypeConfirm': 'اكتب "DELETE" لتأكيد حذف الحساب',
      'settings.toast.accountDeleted': 'تم حذف الحساب',
      'detail.addToCart': 'أضف إلى السلة',
      'detail.buyNow': 'اشترِ الآن',
      'detail.orderNow': 'اطلب الآن',
      'detail.outOfStock': 'هذا المنتج غير متوفر حالياً',
      'detail.addedToCartSuffix': 'تمت إضافته إلى السلة!',
      'detail.addedToCartSuffixSimple': 'تمت إضافته إلى السلة!',
      'detail.addedToWishlist': 'تمت إضافته إلى المفضلة',
      'detail.removedFromWishlist': 'تمت إزالته من المفضلة',
      'detail.deliciousDish': 'طبق لذيذ',
      'detail.restaurant': 'مطعم',
      'detail.noMenuItems': 'لا توجد عناصر متاحة في القائمة',
      'detail.add': 'أضف',
      'detail.restaurantUnavailable': 'المطعم غير متاح',
      'detail.unavailable': 'غير متاح',
      'detail.backToFood': 'العودة إلى الطعام',
      'checkout.title': 'إتمام الطلب',
      'checkout.deliveryAddress': 'عنوان التوصيل',
      'checkout.addNewAddress': '+ إضافة عنوان جديد',
      'checkout.addNewAddressTitle': 'إضافة عنوان جديد',
      'checkout.type': 'النوع',
      'checkout.addressTypeHome': 'المنزل',
      'checkout.addressTypeWork': 'العمل',
      'checkout.addressTypeOther': 'أخرى',
      'checkout.streetAddress': 'عنوان الشارع',
      'checkout.city': 'المدينة',
      'checkout.postalCode': 'الرمز البريدي',
      'checkout.saveAddress': 'حفظ العنوان',
      'checkout.cancel': 'إلغاء',
      'checkout.deliverySpeed': 'سرعة التوصيل',
      'checkout.paymentMethod': 'طريقة الدفع',
      'checkout.specialInstructions': 'تعليمات خاصة',
      'checkout.noteForCourier': 'اترك ملاحظة لمندوب التوصيل',
      'checkout.notesPlaceholder': 'مثال: يرجى قرع الجرس مرتين...',
      'checkout.noSavedAddresses': 'لا توجد عناوين محفوظة',
      'checkout.fillAddressFields': 'يرجى تعبئة كل حقول العنوان',
      'checkout.addressSaved': 'تم حفظ العنوان!',
      'checkout.standardDelivery': 'توصيل عادي',
      'checkout.expressDelivery': 'توصيل سريع',
      'checkout.sameDayDelivery': 'توصيل في نفس اليوم',
      'checkout.byEvening': 'بحلول المساء',
      'checkout.free': 'مجاناً',
      'checkout.creditCard': 'بطاقة ائتمان',
      'checkout.applePay': 'Apple Pay',
      'checkout.paypal': 'PayPal',
      'checkout.cashOnDelivery': 'الدفع عند الاستلام',
      'checkout.payWhenArrives': 'ادفع عند وصول الطلب',
      'checkout.orderItems': 'عناصر الطلب',
      'checkout.pricing': 'التسعير',
      'checkout.subtotal': 'المجموع الفرعي',
      'checkout.delivery': 'التوصيل',
      'checkout.tax': 'الضريبة',
      'checkout.discount': 'الخصم',
      'checkout.totalAmount': 'المبلغ الإجمالي',
      'checkout.placeOrder': 'تأكيد الطلب',
      'checkout.selectAddress': 'يرجى اختيار أو إضافة عنوان توصيل',
      'checkout.emptyCartTitle': 'سلتك فارغة',
      'checkout.emptyCartDescription': 'أضف بعض العناصر إلى سلتك قبل إتمام الطلب',
      'checkout.continueShopping': 'مواصلة التسوق',
      'orders.title': 'طلباتي',
      'orders.all': 'كل الطلبات',
      'orders.pending': 'قيد الانتظار',
      'orders.confirmed': 'مؤكد',
      'orders.delivered': 'تم التوصيل',
      'orders.cancelled': 'ملغى',
      'orders.loginRequired': 'يرجى تسجيل الدخول لعرض طلباتك.',
      'orders.empty': 'لم يتم العثور على طلبات',
      'orders.item': 'عنصر',
      'orders.items': 'عناصر',
      'orders.view': 'عرض',
      'orders.track': 'تتبع',
      'tracking.title': 'تتبع الطلب',
      'tracking.orderNumber': 'رقم الطلب',
      'tracking.preparing': 'قيد التحضير',
      'tracking.liveMapSoon': 'خريطة التتبع المباشر (قريباً)',
      'tracking.deliveryPartner': 'شريك التوصيل',
      'tracking.deliveryAddress': 'عنوان التوصيل',
      'tracking.deliveryTo': 'التوصيل إلى',
      'tracking.estimatedDeliveryTime': 'وقت التوصيل المتوقع',
      'tracking.arrivingApprox': 'سيصل تقريباً خلال',
      'tracking.needHelp': 'هل تحتاج إلى مساعدة؟',
      'tracking.chatSupport': 'دعم المحادثة',
      'tracking.callSupport': 'اتصل بالدعم',
      'tracking.onTheWay': 'في الطريق',
      'tracking.driverAssigned': 'تم تعيين السائق',
      'tracking.rideConfirmed': 'تم تأكيد المشوار',
      'tracking.rideConfirmedDesc': 'تم قبول طلب المشوار الخاص بك',
      'tracking.driverAssignedDesc': 'سائق قريب في طريقه إلى نقطة الانطلاق',
      'tracking.tripInProgress': 'المشوار جارٍ',
      'tracking.tripInProgressDesc': 'أنت الآن في الطريق إلى وجهتك',
      'tracking.tripCompleted': 'اكتمل المشوار',
      'tracking.tripCompletedDesc': 'لقد وصلت إلى وجهتك',
      'tracking.orderConfirmed': 'تم تأكيد الطلب',
      'tracking.orderConfirmedDesc': 'تم تأكيد طلبك وإرساله إلى المطعم',
      'tracking.orderPreparing': 'الطلب قيد التحضير',
      'tracking.orderPreparingDesc': 'المطعم يقوم بتحضير طلبك',
      'tracking.orderPickedUp': 'تم استلام الطلب',
      'tracking.orderPickedUpDesc': 'تم استلام طلبك لبدء التوصيل',
      'tracking.outForDelivery': 'الطلب في طريقه إليك',
      'tracking.outForDeliveryDesc': 'طلبك في الطريق إليك الآن',
      'tracking.deliveredDesc': 'تم توصيل طلبك بنجاح',
      'tracking.callingDriver': 'جارٍ الاتصال بالسائق...',
      'tracking.openingChat': 'جارٍ فتح المحادثة...',
      'tracking.contactingSupport': 'جارٍ التواصل مع الدعم...',
      'tracking.callingSupport': 'جارٍ الاتصال بالدعم...',
      'account.profileTitle': 'الملف الشخصي',
      'account.guestUser': 'مستخدم زائر',
      'account.notLoggedIn': 'غير مسجل الدخول',
      'account.orders': 'الطلبات',
      'account.spent': 'الإنفاق',
      'account.rewards': 'المكافآت',
      'account.editProfile': 'تعديل الملف الشخصي',
      'account.accountSection': 'الحساب',
      'account.editProfileDesc': 'حدّث معلوماتك الشخصية',
      'account.addresses': 'العناوين',
      'account.addressesDesc': 'إدارة عناوين التوصيل',
      'account.payments': 'طرق الدفع',
      'account.paymentsDesc': 'إدارة بطاقاتك ومحافظك',
      'account.ordersSupport': 'الطلبات والدعم',
      'account.myOrders': 'طلباتي',
      'account.myOrdersDesc': 'عرض سجل طلباتك',
      'account.helpCenter': 'مركز المساعدة',
      'account.helpCenterDesc': 'الأسئلة الشائعة ودعم العملاء',
      'account.preferences': 'التفضيلات',
      'account.settings': 'الإعدادات',
      'account.settingsDesc': 'الإشعارات واللغة والخصوصية',
      'account.logout': 'تسجيل الخروج',
      'account.noEmail': 'لا يوجد بريد إلكتروني',
      'account.loginRequiredProfile': 'يرجى تسجيل الدخول لعرض ملفك الشخصي.',
      'account.logoutConfirm': 'هل أنت متأكد أنك تريد تسجيل الخروج؟',
      'account.logoutSuccess': 'تم تسجيل الخروج بنجاح',
      'account.editProfileTitle': 'تعديل الملف الشخصي',
      'account.personalInformation': 'المعلومات الشخصية',
      'account.firstName': 'الاسم الأول',
      'account.lastName': 'اسم العائلة',
      'account.emailAddress': 'البريد الإلكتروني',
      'account.phoneNumber': 'رقم الهاتف',
      'account.dateOfBirth': 'تاريخ الميلاد',
      'account.bio': 'نبذة',
      'account.tellUsAboutYourself': 'أخبرنا عنك',
      'account.saveChanges': 'حفظ التغييرات',
      'account.cancel': 'إلغاء',
      'account.changePassword': 'تغيير كلمة المرور',
      'account.currentPassword': 'كلمة المرور الحالية',
      'account.newPassword': 'كلمة المرور الجديدة',
      'account.confirmPassword': 'تأكيد كلمة المرور',
      'account.updatePassword': 'تحديث كلمة المرور',
      'account.loginRequiredEdit': 'يرجى تسجيل الدخول لتعديل ملفك الشخصي.',
      'account.fillRequiredFields': 'يرجى تعبئة كل الحقول المطلوبة',
      'account.profileUpdated': 'تم تحديث الملف الشخصي بنجاح!',
      'account.fillPasswordFields': 'يرجى تعبئة كل حقول كلمة المرور',
      'account.passwordsDoNotMatch': 'كلمتا المرور الجديدتان غير متطابقتين',
      'account.passwordMinLength': 'يجب أن تكون كلمة المرور 6 أحرف على الأقل',
      'account.passwordChanged': 'تم تغيير كلمة المرور بنجاح!',
      'account.addressesTitle': 'عناويني',
      'account.addNewAddress': '+ إضافة عنوان جديد',
      'account.addNewAddressTitle': 'إضافة عنوان جديد',
      'account.type': 'النوع',
      'account.home': 'المنزل',
      'account.work': 'العمل',
      'account.other': 'أخرى',
      'account.streetAddress': 'عنوان الشارع',
      'account.city': 'المدينة',
      'account.postalCode': 'الرمز البريدي',
      'account.save': 'حفظ',
      'account.loginRequiredAddresses': 'يرجى تسجيل الدخول لإدارة عناوينك.',
      'account.noSavedAddresses': 'لا توجد عناوين محفوظة',
      'account.delete': 'حذف',
      'account.fillAllFields': 'يرجى تعبئة كل الحقول',
      'account.failedSaveAddress': 'فشل حفظ العنوان',
      'account.addressSaved': 'تم حفظ العنوان!',
      'account.deleteAddressConfirm': 'هل تريد حذف هذا العنوان؟',
      'account.failedDeleteAddress': 'فشل حذف العنوان',
      'account.paymentMethodsTitle': 'طرق الدفع',
      'account.addPaymentMethod': '+ إضافة طريقة دفع',
      'account.addPaymentMethodTitle': 'إضافة طريقة دفع',
      'account.cardHolderName': 'اسم حامل البطاقة',
      'account.cardNumber': 'رقم البطاقة',
      'account.expires': 'تاريخ الانتهاء',
      'account.cvv': 'CVV',
      'account.loginRequiredPayments': 'يرجى تسجيل الدخول لإدارة طرق الدفع الخاصة بك.',
      'account.noPaymentMethods': 'لا توجد طرق دفع',
      'account.card': 'بطاقة',
      'account.remove': 'إزالة',
      'account.failedSavePayment': 'فشل حفظ طريقة الدفع',
      'account.paymentSaved': 'تم حفظ طريقة الدفع!',
      'account.deletePaymentConfirm': 'هل تريد حذف طريقة الدفع هذه؟',
      'account.failedDeletePayment': 'فشل حذف طريقة الدفع',
      'support.helpCenterTitle': 'مركز المساعدة',
      'support.searchFaqs': 'ابحث في الأسئلة الشائعة...',
      'support.contactTitle': 'لم تجد ما تبحث عنه؟',
      'support.contactInfo': 'تواصل مع فريق الدعم لدينا. نحن هنا لمساعدتك!',
      'support.chat': 'محادثة',
      'support.call': 'اتصال',
      'support.openingChatSupport': 'جارٍ فتح دعم المحادثة...',
      'support.callingSupport': 'جارٍ الاتصال بالدعم...',
      'wishlist.title': 'قائمة المفضلة',
      'wishlist.subtitle': 'احفظ المنتجات التي تحبها وانقلها إلى السلة عندما تكون جاهزاً.',
      'wishlist.continueShopping': 'مواصلة التسوق',
      'wishlist.emptyTitle': 'قائمة المفضلة فارغة',
      'wishlist.emptyDescription': 'تصفح الأقسام واحفظ المنتجات التي تريد العودة إليها لاحقاً.',
      'wishlist.savedForLater': 'محفوظة لوقت لاحق.',
      'wishlist.addToCart': 'أضف إلى السلة',
      'wishlist.remove': 'إزالة',
      'wishlist.addedToCart': 'تمت الإضافة إلى السلة!',
      'wishlist.removed': 'تمت الإزالة من المفضلة',
      'cart.title': 'سلة التسوق',
      'cart.promoCode': 'رمز الخصم',
      'cart.enterCode': 'أدخل الرمز',
      'cart.apply': 'تطبيق',
      'cart.subtotal': 'المجموع الفرعي',
      'cart.deliveryFee': 'رسوم التوصيل',
      'cart.discount': 'الخصم',
      'cart.total': 'الإجمالي',
      'cart.proceedToCheckout': 'المتابعة إلى الدفع',
      'cart.continueShopping': 'مواصلة التسوق',
      'cart.empty': 'سلتك فارغة',
      'cart.startShopping': 'ابدأ التسوق',
      'cart.enterPromo': 'يرجى إدخال رمز خصم',
      'cart.promoAppliedPrefix': 'تم تطبيق رمز الخصم! لقد وفرت',
      'cart.invalidPromo': 'رمز الخصم غير صالح',
      'cart.emptyToast': 'سلتك فارغة',
      'cart.aboutEdalab': 'عن eDalab',
      'cart.aboutUs': 'من نحن',
      'cart.careers': 'الوظائف',
      'cart.blog': 'المدونة',
      'cart.forUsers': 'للمستخدمين',
      'cart.helpCenter': 'مركز المساعدة',
      'cart.trackOrder': 'تتبع الطلب',
      'cart.account': 'الحساب',
      'cart.legal': 'قانوني',
      'cart.terms': 'الشروط والأحكام',
      'cart.privacy': 'سياسة الخصوصية',
      'cart.contact': 'اتصل بنا',
      'success.title': 'تم تأكيد الطلب!',
      'success.message': 'تم تقديم طلبك وتأكيده بنجاح. نحن نحضر عناصر طلبك الآن.',
      'success.orderNumber': 'رقم الطلب',
      'success.orderDate': 'تاريخ الطلب',
      'success.estimatedDelivery': 'وقت التوصيل المتوقع',
      'success.deliveryAddress': 'عنوان التوصيل',
      'success.paymentMethod': 'طريقة الدفع',
      'success.orderItems': 'عناصر الطلب',
      'success.whatNext': 'ماذا يحدث بعد ذلك؟',
      'success.step1Title': 'نحن نحضر طلبك',
      'success.step1Desc': 'فريقنا يحضر ويغلف عناصر طلبك بعناية',
      'success.step2Title': 'طلبك في الطريق',
      'success.step2Desc': 'سيقوم شريك التوصيل باستلام طلبك قريباً',
      'success.step3Title': 'تأكيد التوصيل',
      'success.step3Desc': 'ستستلم طلبك على العنوان المحدد',
      'success.trackOrder': 'تتبع الطلب',
      'success.continueShopping': 'مواصلة التسوق',
      'success.unknownPayment': 'غير معروف',
      'ride.whereToGo': 'إلى أين تريد الذهاب؟',
      'ride.go': 'اذهب',
      'ride.fillRequired': 'يرجى تعبئة كل الحقول المطلوبة',
      'ride.booking': 'جارٍ الحجز...',
      'ride.bookNow': 'احجز المشوار الآن',
      'ride.bookedSuccess': 'تم حجز المشوار بنجاح!',
      'ride.bookFailed': 'فشل حجز المشوار',
      'ride.pickupFallback': 'الانطلاق',
      'ride.destinationFallback': 'الوجهة',
      'ride.noActive': 'لا توجد مشاوير نشطة',
      'ride.track': 'تتبع',
      'ride.none': 'لا يوجد',
      'laundry.searchService': 'ابحث عن خدمة غسيل...',
      'laundry.find': 'ابحث',
      'laundry.baseService': 'الخدمة الأساسية',
      'laundry.additionalServices': 'خدمات إضافية',
      'laundry.pickupDelivery': 'الاستلام والتوصيل',
      'laundry.totalEstimate': 'التقدير الإجمالي',
      'laundry.placeOrder': 'تأكيد الطلب',
      'laundry.placingOrder': 'جارٍ تقديم الطلب...',
      'laundry.fillRequired': 'يرجى تعبئة كل الحقول المطلوبة',
      'laundry.orderSuccess': 'تم تقديم طلب الغسيل بنجاح!',
      'laundry.orderFailed': 'فشل تقديم الطلب',
      'laundry.noOrders': 'لا توجد طلبات بعد',
      'laundry.placedOn': 'تم الطلب في',
      'laundry.viewDetails': 'عرض التفاصيل',
      'services.search': 'ابحث عن خدمة أو مقدم خدمة...',
      'services.searchButton': 'بحث',
      'services.allServices': 'كل الخدمات',
      'services.fromPrice': 'ابتداءً من',
      'services.providersCount': 'مزودين',
      'services.noProviders': 'لم يتم العثور على مزودين',
      'services.homeService': 'خدمة منزلية',
      'services.priceStarting': 'ابتداءً من',
      'services.priceOnRequest': 'السعر عند الطلب',
      'services.bookNow': 'احجز الآن',
      'services.bookedSuccessSuffix': 'تم حجزه بنجاح!',
      'doctor.failedLoad': 'فشل تحميل الأطباء',
      'doctor.searchPlaceholder': 'ابحث عن الأطباء أو التخصصات...',
      'doctor.noDoctors': 'لم يتم العثور على أطباء مطابقين لمعاييرك',
      'doctor.bookWith': 'احجز موعداً مع',
      'doctor.selectDoctor': 'يرجى اختيار طبيب',
      'doctor.fillRequired': 'يرجى تعبئة كل الحقول المطلوبة',
      'doctor.appointmentName': 'موعد طبي',
      'doctor.defaultReason': 'استشارة عامة',
      'doctor.bookedSuccess': 'تم حجز الموعد بنجاح!',
      'doctor.bookFailed': 'فشل حجز الموعد',
    },
  },
  pageTranslations: {
    'edalab-website.html': {
      fr: {
        text: {
          '.hiw-step:nth-of-type(1) .hiw-n': 'Étape 01',
          '.hiw-step:nth-of-type(1) .hiw-t': 'Parcourez',
          '.hiw-step:nth-of-type(1) .hiw-d': 'Recherchez parmi les 8 catégories de services et filtrez par distance, note ou prix.',
          '.hiw-step:nth-of-type(2) .hiw-n': 'Étape 02',
          '.hiw-step:nth-of-type(2) .hiw-t': 'Sélectionnez',
          '.hiw-step:nth-of-type(2) .hiw-d': 'Choisissez vos articles, personnalisez votre commande et sélectionnez la livraison ou le retrait.',
          '.hiw-step:nth-of-type(3) .hiw-n': 'Étape 03',
          '.hiw-step:nth-of-type(3) .hiw-t': 'Payez',
          '.hiw-step:nth-of-type(3) .hiw-d': 'Payez en ligne, par mobile money ou en espèces à la livraison.',
          '.hiw-step:nth-of-type(4) .hiw-n': 'Étape 04',
          '.hiw-step:nth-of-type(4) .hiw-t': 'Suivi en direct',
          '.hiw-step:nth-of-type(4) .hiw-d': 'Suivez votre livraison en temps réel, de la préparation jusqu’à votre porte.',
          '.testi-sec .sec-label': '❤️ Histoires vraies',
          '.testi-sec .sec-h': 'Adoré par les Djiboutiens',
          '.testi-sec .sec-p': 'Ce ne sont pas des robots, ce sont vos voisins qui utilisent eDalab chaque jour.',
          '.testi-sec .sec-head > div:last-child > div:last-child': '85 000+ avis',
          '.partners-sec .sec-label': 'Nos partenaires',
          '.partners-sec .sec-h': 'Des entreprises de confiance à travers Djibouti',
          '.app-tag': '📱 Disponible sur iOS et Android',
          '.app-sec-left p': 'Suivi en direct, notifications, récompenses, adresses enregistrées et historique des commandes dans votre poche.',
          '.dl-btn:first-child .dl-sub': 'Télécharger sur',
          '.dl-btn:first-child .dl-name': 'App Store',
          '.dl-btn:last-child .dl-sub': 'Disponible sur',
          '.dl-btn:last-child .dl-name': 'Google Play',
          '.ft-brand p': 'La super-app n°1 de Djibouti. Une seule plateforme pour la restauration, la santé, le voyage, les services et plus encore.',
          '.ft-grid > .ft-col:nth-child(2) h5': 'Restauration et boissons',
          '.ft-grid > .ft-col:nth-child(2) a:nth-of-type(1)': 'Tous les restaurants',
          '.ft-grid > .ft-col:nth-child(2) a:nth-of-type(2)': 'Restauration rapide',
          '.ft-grid > .ft-col:nth-child(2) a:nth-of-type(3)': 'Cafés et boulangeries',
          '.ft-grid > .ft-col:nth-child(2) a:nth-of-type(4)': 'Cuisine djiboutienne',
          '.ft-grid > .ft-col:nth-child(2) a:nth-of-type(5)': 'Livraison de courses',
          '.ft-grid > .ft-col:nth-child(3) h5': 'Santé',
          '.ft-grid > .ft-col:nth-child(3) a:nth-of-type(1)': 'Pharmacies 24h/24 et 7j/7',
          '.ft-grid > .ft-col:nth-child(3) a:nth-of-type(2)': 'Prendre rendez-vous avec un médecin',
          '.ft-grid > .ft-col:nth-child(3) a:nth-of-type(3)': 'Spécialistes',
          '.ft-grid > .ft-col:nth-child(3) a:nth-of-type(4)': 'Analyses médicales',
          '.ft-grid > .ft-col:nth-child(3) a:nth-of-type(5)': 'Vaccinations',
          '.ft-grid > .ft-col:nth-child(4) h5': 'Voyage et séjour',
          '.ft-grid > .ft-col:nth-child(4) a:nth-of-type(1)': 'Hôtels',
          '.ft-grid > .ft-col:nth-child(4) a:nth-of-type(2)': 'Appartements',
          '.ft-grid > .ft-col:nth-child(4) a:nth-of-type(3)': 'Service de trajet',
          '.ft-grid > .ft-col:nth-child(4) a:nth-of-type(4)': 'Transfert aéroport',
          '.ft-grid > .ft-col:nth-child(4) a:nth-of-type(5)': 'Location de voiture',
          '.ft-grid > .ft-col:nth-child(5) a:nth-of-type(1)': 'À propos',
          '.ft-grid > .ft-col:nth-child(5) a:nth-of-type(2)': 'Référencez votre entreprise',
          '.ft-grid > .ft-col:nth-child(5) a:nth-of-type(3)': 'Devenir coursier',
          '.ft-grid > .ft-col:nth-child(5) a:nth-of-type(4)': 'Carrières',
          '.ft-grid > .ft-col:nth-child(5) a:nth-of-type(5)': 'Assistance',
          '.ft-links a:nth-of-type(1)': 'Politique de confidentialité',
          '.ft-links a:nth-of-type(2)': 'Conditions d’utilisation',
          '.ft-links a:nth-of-type(3)': 'Cookies',
          '.track-summary .ts-title': 'Résumé de commande',
          '.track-summary .ts-row:nth-of-type(4) span:first-child': 'Frais de livraison',
          '.track-summary .ts-total span:first-child': 'Total',
          '.track-wrap button.track-back': '← Retour à eDalab',
        },
        html: {
          '.app-sec-left h2': 'Téléchargez eDalab sur<br>votre téléphone',
          '.ft-bottom > span': '© 2025 eDalab. Tous droits réservés. <span class="ft-badge">🇩🇯 Créé à Djibouti</span>',
        },
      },
      ar: {
        text: {
          '.hiw-step:nth-of-type(1) .hiw-n': 'الخطوة 01',
          '.hiw-step:nth-of-type(1) .hiw-t': 'تصفح',
          '.hiw-step:nth-of-type(1) .hiw-d': 'ابحث في 8 فئات خدمات مع التصفية حسب المسافة أو التقييم أو السعر.',
          '.hiw-step:nth-of-type(2) .hiw-n': 'الخطوة 02',
          '.hiw-step:nth-of-type(2) .hiw-t': 'اختر',
          '.hiw-step:nth-of-type(2) .hiw-d': 'اختر العناصر، خصص طلبك، وحدد التوصيل أو الاستلام.',
          '.hiw-step:nth-of-type(3) .hiw-n': 'الخطوة 03',
          '.hiw-step:nth-of-type(3) .hiw-t': 'ادفع',
          '.hiw-step:nth-of-type(3) .hiw-d': 'ادفع بأمان عبر الإنترنت أو بالموبايل موني أو نقداً عند التسليم.',
          '.hiw-step:nth-of-type(4) .hiw-n': 'الخطوة 04',
          '.hiw-step:nth-of-type(4) .hiw-t': 'تتبع مباشر',
          '.hiw-step:nth-of-type(4) .hiw-d': 'تابع طلبك لحظة بلحظة من التحضير حتى باب منزلك.',
          '.testi-sec .sec-label': '❤️ قصص حقيقية',
          '.testi-sec .sec-h': 'محبوب من الجيبوتيين',
          '.testi-sec .sec-p': 'هؤلاء ليسوا روبوتات، بل جيرانك الذين يستخدمون إيدالاب كل يوم.',
          '.testi-sec .sec-head > div:last-child > div:last-child': '85,000+ تقييم',
          '.partners-sec .sec-label': 'شركاؤنا',
          '.partners-sec .sec-h': 'موثوق به من الشركات في أنحاء جيبوتي',
          '.app-tag': '📱 متوفر على iOS وAndroid',
          '.app-sec-left p': 'تتبع مباشر، إشعارات، مكافآت، عناوين محفوظة، وسجل الطلبات في جيبك.',
          '.dl-btn:first-child .dl-sub': 'حمّل من',
          '.dl-btn:first-child .dl-name': 'App Store',
          '.dl-btn:last-child .dl-sub': 'احصل عليه من',
          '.dl-btn:last-child .dl-name': 'Google Play',
          '.ft-brand p': 'التطبيق الشامل رقم 1 في جيبوتي. منصة واحدة للطعام والصحة والسفر والخدمات وأكثر.',
          '.ft-grid > .ft-col:nth-child(2) h5': 'الطعام والشراب',
          '.ft-grid > .ft-col:nth-child(2) a:nth-of-type(1)': 'كل المطاعم',
          '.ft-grid > .ft-col:nth-child(2) a:nth-of-type(2)': 'الوجبات السريعة',
          '.ft-grid > .ft-col:nth-child(2) a:nth-of-type(3)': 'المقاهي والمخابز',
          '.ft-grid > .ft-col:nth-child(2) a:nth-of-type(4)': 'المطبخ الجيبوتي',
          '.ft-grid > .ft-col:nth-child(2) a:nth-of-type(5)': 'توصيل البقالة',
          '.ft-grid > .ft-col:nth-child(3) h5': 'الصحة',
          '.ft-grid > .ft-col:nth-child(3) a:nth-of-type(1)': 'صيدليات 24/7',
          '.ft-grid > .ft-col:nth-child(3) a:nth-of-type(2)': 'احجز طبيباً',
          '.ft-grid > .ft-col:nth-child(3) a:nth-of-type(3)': 'الأخصائيون',
          '.ft-grid > .ft-col:nth-child(3) a:nth-of-type(4)': 'التحاليل المخبرية',
          '.ft-grid > .ft-col:nth-child(3) a:nth-of-type(5)': 'التطعيمات',
          '.ft-grid > .ft-col:nth-child(4) h5': 'السفر والإقامة',
          '.ft-grid > .ft-col:nth-child(4) a:nth-of-type(1)': 'فنادق',
          '.ft-grid > .ft-col:nth-child(4) a:nth-of-type(2)': 'الشقق',
          '.ft-grid > .ft-col:nth-child(4) a:nth-of-type(3)': 'خدمة المشاوير',
          '.ft-grid > .ft-col:nth-child(4) a:nth-of-type(4)': 'نقل المطار',
          '.ft-grid > .ft-col:nth-child(4) a:nth-of-type(5)': 'تأجير السيارات',
          '.ft-grid > .ft-col:nth-child(5) a:nth-of-type(1)': 'من نحن',
          '.ft-grid > .ft-col:nth-child(5) a:nth-of-type(2)': 'أضف نشاطك التجاري',
          '.ft-grid > .ft-col:nth-child(5) a:nth-of-type(3)': 'كن مندوب توصيل',
          '.ft-grid > .ft-col:nth-child(5) a:nth-of-type(4)': 'الوظائف',
          '.ft-grid > .ft-col:nth-child(5) a:nth-of-type(5)': 'الدعم',
          '.ft-links a:nth-of-type(1)': 'سياسة الخصوصية',
          '.ft-links a:nth-of-type(2)': 'شروط الخدمة',
          '.ft-links a:nth-of-type(3)': 'ملفات تعريف الارتباط',
          '.track-summary .ts-title': 'ملخص الطلب',
          '.track-summary .ts-row:nth-of-type(4) span:first-child': 'رسوم التوصيل',
          '.track-summary .ts-total span:first-child': 'الإجمالي',
          '.track-wrap button.track-back': '← العودة إلى إيدالاب',
        },
        html: {
          '.app-sec-left h2': 'حمّل إيدالاب على<br>هاتفك',
          '.ft-bottom > span': '© 2025 eDalab. جميع الحقوق محفوظة. <span class="ft-badge">🇩🇯 صنع في جيبوتي</span>',
        },
      },
    },
    'food.html': {
      fr: {
        text: {
          '.food-hero h1': 'Envie de manger ? Commandez auprès de vos restaurants préférés 🍕',
          '.food-hero p': 'Livraison rapide, repas frais et offres exclusives. Tout ce dont vos papilles ont envie.',
          '.filter-section h2': 'Filtrer et trier',
          '.food-section h2': 'Restaurants populaires',
          '.footer-section:nth-of-type(1) h3': 'eDalab Restauration',
          '.footer-section:nth-of-type(1) a:nth-of-type(1)': 'À propos',
          '.footer-section:nth-of-type(1) a:nth-of-type(2)': 'Carrières',
          '.footer-section:nth-of-type(2) h3': 'Pour les utilisateurs',
          '.footer-section:nth-of-type(2) a:nth-of-type(1)': 'Commander des repas',
          '.footer-section:nth-of-type(2) a:nth-of-type(2)': 'Offres',
          '.footer-section:nth-of-type(2) a:nth-of-type(3)': 'Centre d’aide',
          '.footer-section:nth-of-type(3) h3': 'Pour les partenaires',
          '.footer-section:nth-of-type(4) h3': 'Contact',
          '.footer-bottom p': '© 2024 eDalab. Tous droits réservés.',
          '#search-container .search-input': 'Rechercher des restaurants ou des plats...',
        },
        placeholder: {
          '#search-container .search-input': 'Rechercher des restaurants ou des plats...',
        },
      },
      ar: {
        text: {
          '.food-hero h1': 'هل أنت جائع؟ اطلب من مطاعمك المفضلة 🍕',
          '.food-hero p': 'توصيل سريع، طعام طازج، وعروض حصرية. كل ما تشتهيه.',
          '.filter-section h2': 'تصفية وترتيب',
          '.food-section h2': 'مطاعم مشهورة',
          '.footer-section:nth-of-type(1) h3': 'eDalab الطعام',
          '.footer-section:nth-of-type(1) a:nth-of-type(1)': 'من نحن',
          '.footer-section:nth-of-type(1) a:nth-of-type(2)': 'الوظائف',
          '.footer-section:nth-of-type(2) h3': 'للمستخدمين',
          '.footer-section:nth-of-type(2) a:nth-of-type(1)': 'اطلب الطعام',
          '.footer-section:nth-of-type(2) a:nth-of-type(2)': 'العروض',
          '.footer-section:nth-of-type(2) a:nth-of-type(3)': 'مركز المساعدة',
          '.footer-section:nth-of-type(3) h3': 'للشركاء',
          '.footer-section:nth-of-type(4) h3': 'اتصل بنا',
          '.footer-bottom p': '© 2024 eDalab. جميع الحقوق محفوظة.',
        },
        placeholder: {
          '#search-container .search-input': 'ابحث عن مطاعم أو أطباق...',
        },
      },
    },
    'shopping.html': {
      fr: {
        text: {
          '.shopping-hero h1': 'Achetez tout ce que vous aimez 🛍️',
          '.shopping-hero p': 'Mode, électronique, décoration et plus encore. Tout au même endroit avec livraison rapide.',
          'main > section:first-of-type h2': 'Catégories',
          '.filter-section h2': 'Acheter maintenant',
          '#category-filter option[value=""]': 'Toutes les catégories',
          '.filter-item:nth-of-type(1) label': 'Catégorie',
          '.filter-item:nth-of-type(2) label': 'Fourchette de prix',
          '#price-filter option[value=""]': 'Tous les prix',
          '.filter-item:nth-of-type(3) label': 'Trier par',
          '#sort-filter option[value="newest"]': 'Nouveautés',
          '#sort-filter option[value="price-low"]': 'Prix : croissant',
          '#sort-filter option[value="price-high"]': 'Prix : décroissant',
          '#sort-filter option[value="rating"]': 'Mieux notés',
          '.footer-section:nth-of-type(1) h3': 'eDalab Boutique',
          '.footer-section:nth-of-type(2) h3': 'Pour les acheteurs',
          '.footer-section:nth-of-type(3) h3': 'Pour les vendeurs',
          '.footer-section:nth-of-type(4) h3': 'Contact',
          '.footer-bottom p': '© 2024 eDalab. Tous droits réservés.',
        },
        placeholder: { '#search-container .search-input': 'Rechercher des produits...' },
      },
      ar: {
        text: {
          '.shopping-hero h1': 'تسوق كل ما تحبه 🛍️',
          '.shopping-hero p': 'موضة وإلكترونيات وديكور منزلي وأكثر. كل شيء في مكان واحد مع توصيل سريع.',
          'main > section:first-of-type h2': 'الفئات',
          '.filter-section h2': 'تسوق الآن',
          '#category-filter option[value=""]': 'كل الفئات',
          '.filter-item:nth-of-type(1) label': 'الفئة',
          '.filter-item:nth-of-type(2) label': 'نطاق السعر',
          '#price-filter option[value=""]': 'كل الأسعار',
          '.filter-item:nth-of-type(3) label': 'ترتيب حسب',
          '#sort-filter option[value="newest"]': 'الأحدث',
          '#sort-filter option[value="price-low"]': 'السعر: من الأقل إلى الأعلى',
          '#sort-filter option[value="price-high"]': 'السعر: من الأعلى إلى الأقل',
          '#sort-filter option[value="rating"]': 'الأعلى تقييماً',
          '.footer-section:nth-of-type(1) h3': 'eDalab التسوق',
          '.footer-section:nth-of-type(2) h3': 'للمتسوقين',
          '.footer-section:nth-of-type(3) h3': 'للبائعين',
          '.footer-section:nth-of-type(4) h3': 'اتصل بنا',
          '.footer-bottom p': '© 2024 eDalab. جميع الحقوق محفوظة.',
        },
        placeholder: { '#search-container .search-input': 'ابحث عن المنتجات...' },
      },
    },
    'pharmacy.html': {
      fr: {
        text: {
          '.pharmacy-hero h1': 'Santé et bien-être à portée de main 💊',
          '.pharmacy-hero p': 'Commandez des médicaments, produits de santé et compléments bien-être. Livraison rapide et qualité fiable.',
          'main > section:first-of-type h3': 'Téléchargez votre ordonnance 📋',
          'main > section:first-of-type p': 'Téléchargez votre ordonnance pour recevoir vos médicaments',
          'main > section:first-of-type button': 'Télécharger l’ordonnance',
          'main > section:nth-of-type(2) h2': 'Catégories',
          '.filter-section h2': 'Parcourir médicaments et produits',
          '.filter-item:nth-of-type(1) label': 'Catégorie',
          '#category-filter option[value=""]': 'Toutes les catégories',
          '.filter-item:nth-of-type(2) label': 'Type',
          '#type-filter option[value=""]': 'Tous les types',
          '.filter-item:nth-of-type(3) label': 'Disponibilité',
          '#availability-filter option[value=""]': 'Tous',
          '#availability-filter option[value="in-stock"]': 'En stock',
          '#availability-filter option[value="no-prescription"]': 'Sans ordonnance',
          '.footer-bottom p': '© 2024 eDalab. Tous droits réservés.',
        },
        placeholder: { '#search-container .search-input': 'Rechercher des médicaments ou marques...' },
      },
      ar: {
        text: {
          '.pharmacy-hero h1': 'الصحة والعافية بين يديك 💊',
          '.pharmacy-hero p': 'اطلب الأدوية والمنتجات الصحية ومكملات العافية. توصيل سريع وجودة موثوقة.',
          'main > section:first-of-type h3': 'ارفع الوصفة الطبية 📋',
          'main > section:first-of-type p': 'ارفع وصفتك الطبية ليصلك الدواء',
          'main > section:first-of-type button': 'رفع الوصفة',
          'main > section:nth-of-type(2) h2': 'الفئات',
          '.filter-section h2': 'تصفح الأدوية والمنتجات',
          '.filter-item:nth-of-type(1) label': 'الفئة',
          '#category-filter option[value=""]': 'كل الفئات',
          '.filter-item:nth-of-type(2) label': 'النوع',
          '#type-filter option[value=""]': 'كل الأنواع',
          '.filter-item:nth-of-type(3) label': 'التوفر',
          '#availability-filter option[value=""]': 'الكل',
          '#availability-filter option[value="in-stock"]': 'متوفر',
          '#availability-filter option[value="no-prescription"]': 'لا يتطلب وصفة',
          '.footer-bottom p': '© 2024 eDalab. جميع الحقوق محفوظة.',
        },
        placeholder: { '#search-container .search-input': 'ابحث عن الأدوية أو العلامات...' },
      },
    },
    'doctor.html': {
      fr: {
        text: {
          '.doctor-hero h1': 'Votre santé, notre priorité 💊',
          '.doctor-hero p': 'Consultez des médecins qualifiés, prenez rendez-vous et recevez des conseils médicaux à tout moment.',
          '.filter-section h2': 'Trouver un médecin',
          '.doctor-section h2': 'Meilleurs médecins',
          '.filter-item:nth-of-type(1) label': 'Spécialité',
          '#specialty-filter option[value=""]': 'Toutes les spécialités',
          '.filter-item:nth-of-type(2) label': 'Disponibilité',
          '#availability-filter option[value=""]': 'Tous',
          '#availability-filter option[value="available"]': 'Disponible maintenant',
          '#availability-filter option[value="upcoming"]': 'Disponible aujourd’hui',
          '.filter-item:nth-of-type(3) label': 'Note',
          '#rating-filter option[value=""]': 'Tous',
          '#rating-filter option[value="4"]': '4+ étoiles',
          '#rating-filter option[value="4.5"]': '4.5+ étoiles',
          '#rating-filter option[value="5"]': '5 étoiles',
          '#booking-modal-overlay .modal-header h2': 'Prendre rendez-vous',
          '#booking-form .form-group:nth-of-type(1) label': 'Choisir la date',
          '#booking-form .form-group:nth-of-type(2) label': 'Choisir l’heure',
          '#appointment-time option[value=""]': 'Choisir un créneau',
          '#booking-form .form-group:nth-of-type(3) label': 'Motif de la visite',
          '#booking-modal-overlay .modal-btn.secondary': 'Annuler',
          '#booking-modal-overlay .modal-btn.primary': 'Réserver',
          '.footer-section:nth-of-type(1) h3': 'eDalab Santé',
          '.footer-section:nth-of-type(2) h3': 'Pour les patients',
          '.footer-section:nth-of-type(3) h3': 'Pour les médecins',
          '.footer-section:nth-of-type(4) h3': 'Contact et urgence',
          '.footer-bottom p': '© 2024 eDalab. Tous droits réservés.',
        },
        placeholder: {
          '#doctor-search': 'Rechercher des médecins ou spécialités...',
          '#appointment-reason': 'Décrivez vos symptômes ou la raison de votre visite',
        },
      },
      ar: {
        text: {
          '.doctor-hero h1': 'صحتك أولويتنا 💊',
          '.doctor-hero p': 'تواصل مع أطباء مؤهلين، واحجز المواعيد، واحصل على نصائح طبية موثوقة في أي وقت.',
          '.filter-section h2': 'ابحث عن طبيب',
          '.doctor-section h2': 'أفضل الأطباء',
          '.filter-item:nth-of-type(1) label': 'التخصص',
          '#specialty-filter option[value=""]': 'كل التخصصات',
          '.filter-item:nth-of-type(2) label': 'التوفر',
          '#availability-filter option[value=""]': 'الكل',
          '#availability-filter option[value="available"]': 'متاح الآن',
          '#availability-filter option[value="upcoming"]': 'متاح اليوم',
          '.filter-item:nth-of-type(3) label': 'التقييم',
          '#rating-filter option[value=""]': 'الكل',
          '#rating-filter option[value="4"]': '4+ نجوم',
          '#rating-filter option[value="4.5"]': '4.5+ نجوم',
          '#rating-filter option[value="5"]': '5 نجوم',
          '#booking-modal-overlay .modal-header h2': 'احجز موعداً',
          '#booking-form .form-group:nth-of-type(1) label': 'اختر التاريخ',
          '#booking-form .form-group:nth-of-type(2) label': 'اختر الوقت',
          '#appointment-time option[value=""]': 'اختر وقتاً متاحاً',
          '#booking-form .form-group:nth-of-type(3) label': 'سبب الزيارة',
          '#booking-modal-overlay .modal-btn.secondary': 'إلغاء',
          '#booking-modal-overlay .modal-btn.primary': 'تأكيد الحجز',
          '.footer-section:nth-of-type(1) h3': 'eDalab الصحة',
          '.footer-section:nth-of-type(2) h3': 'للمرضى',
          '.footer-section:nth-of-type(3) h3': 'للأطباء',
          '.footer-section:nth-of-type(4) h3': 'التواصل والطوارئ',
          '.footer-bottom p': '© 2024 eDalab. جميع الحقوق محفوظة.',
        },
        placeholder: {
          '#doctor-search': 'ابحث عن الأطباء أو التخصصات...',
          '#appointment-reason': 'اشرح الأعراض أو سبب الزيارة',
        },
      },
    },
    'hotel.html': {
      fr: {
        text: {
          '.hotel-hero h1': 'Trouvez votre séjour idéal 🏨',
          '.hotel-hero p': 'Chambres confortables, excellents emplacements et prix imbattables. Réservez dès maintenant.',
          'main > div:first-of-type h2': 'Rechercher des hôtels',
          '.date-picker .filter-item:nth-of-type(1) label': 'Date d’arrivée',
          '.date-picker .filter-item:nth-of-type(2) label': 'Date de départ',
          '.guests-picker .filter-item:nth-of-type(1) label': 'Voyageurs',
          '.guests-picker .filter-item:nth-of-type(2) label': 'Type de chambre',
          '#guests-count option[value="1"]': '1 voyageur',
          '#guests-count option[value="2"]': '2 voyageurs',
          '#guests-count option[value="3"]': '3 voyageurs',
          '#guests-count option[value="4"]': '4 voyageurs',
          '#guests-count option[value="5"]': '5+ voyageurs',
          '#room-type option[value=""]': 'Tout type',
          '#room-type option[value="single"]': 'Chambre simple',
          '#room-type option[value="double"]': 'Chambre double',
          '#room-type option[value="suite"]': 'Suite',
          '#room-type option[value="villa"]': 'Villa',
          'main > div:first-of-type button': 'Rechercher des hôtels',
          '.filter-section h2': 'Filtrer les résultats',
          '.filter-item:nth-of-type(1) label': 'Fourchette de prix',
          '#price-filter option[value=""]': 'Tous les prix',
          '.filter-item:nth-of-type(2) label': 'Classement par étoiles',
          '#rating-filter option[value=""]': 'Toutes les notes',
          '.filter-item:nth-of-type(3) label': 'Équipements',
          '#amenities-filter option[value=""]': 'Tous les équipements',
          '#amenities-filter option[value="pool"]': 'Piscine',
          '#amenities-filter option[value="gym"]': 'Salle de sport',
          '#booking-modal-overlay .modal-header h2': 'Réserver un hôtel',
          '.footer-bottom p': '© 2024 eDalab. Tous droits réservés.',
        },
        placeholder: { '#special-requests': 'Ex. arrivée tardive, étage élevé, chambre calme' },
      },
      ar: {
        text: {
          '.hotel-hero h1': 'اعثر على إقامتك المثالية 🏨',
          '.hotel-hero p': 'غرف مريحة، مواقع رائعة، وأسعار ممتازة. احجز الآن.',
          'main > div:first-of-type h2': 'ابحث عن الفنادق',
          '.date-picker .filter-item:nth-of-type(1) label': 'تاريخ الوصول',
          '.date-picker .filter-item:nth-of-type(2) label': 'تاريخ المغادرة',
          '.guests-picker .filter-item:nth-of-type(1) label': 'الضيوف',
          '.guests-picker .filter-item:nth-of-type(2) label': 'نوع الغرفة',
          '#guests-count option[value="1"]': 'ضيف واحد',
          '#guests-count option[value="2"]': 'ضيفان',
          '#guests-count option[value="3"]': '3 ضيوف',
          '#guests-count option[value="4"]': '4 ضيوف',
          '#guests-count option[value="5"]': '5+ ضيوف',
          '#room-type option[value=""]': 'أي نوع',
          '#room-type option[value="single"]': 'غرفة مفردة',
          '#room-type option[value="double"]': 'غرفة مزدوجة',
          '#room-type option[value="suite"]': 'جناح',
          '#room-type option[value="villa"]': 'فيلا',
          'main > div:first-of-type button': 'ابحث عن الفنادق',
          '.filter-section h2': 'تصفية النتائج',
          '.filter-item:nth-of-type(1) label': 'نطاق السعر',
          '#price-filter option[value=""]': 'كل الأسعار',
          '.filter-item:nth-of-type(2) label': 'تصنيف النجوم',
          '#rating-filter option[value=""]': 'كل التقييمات',
          '.filter-item:nth-of-type(3) label': 'المرافق',
          '#amenities-filter option[value=""]': 'كل المرافق',
          '#amenities-filter option[value="pool"]': 'مسبح',
          '#amenities-filter option[value="gym"]': 'مركز لياقة',
          '#booking-modal-overlay .modal-header h2': 'احجز الفندق',
          '.footer-bottom p': '© 2024 eDalab. جميع الحقوق محفوظة.',
        },
        placeholder: { '#special-requests': 'مثال: وصول متأخر، طابق مرتفع، غرفة هادئة' },
      },
    },
    'ride.html': {
      fr: {
        text: {
          '.ride-hero h1, .wrap h1': 'Réservez votre trajet avec eDalab',
          '.ride-hero p': 'Transport rapide, sûr et abordable avec des tarifs clairs et une gestion simple du trajet.',
          'main > section:first-of-type h2': 'Types de trajets',
          '.ride-booking-form h2': 'Réserver un trajet',
          '.form-group:nth-of-type(1) label': 'Lieu de départ',
          '.form-group:nth-of-type(2) label': 'Lieu de destination',
          '.form-row:nth-of-type(1) .form-group:nth-of-type(1) label': 'Date de départ',
          '.form-row:nth-of-type(1) .form-group:nth-of-type(2) label': 'Heure de départ',
          '.form-row:nth-of-type(2) .form-group:nth-of-type(1) label': 'Passagers',
          '.form-row:nth-of-type(2) .form-group:nth-of-type(2) label': 'Demandes spéciales',
          '#passengerCount option[value="1"]': '1 passager',
          '#passengerCount option[value="2"]': '2 passagers',
          '#passengerCount option[value="3"]': '3 passagers',
          '#passengerCount option[value="4"]': '4 passagers',
          '.ride-info h3': 'Pourquoi choisir eDalab Rides ?',
          '.active-rides h3': 'Vos trajets en cours',
          '#bookButton': 'Réserver maintenant',
          '.footer-section:nth-of-type(1) h3': 'eDalab Ride',
          '.footer-section:nth-of-type(2) h3': 'Pour les passagers',
          '.footer-section:nth-of-type(3) h3': 'Pour les chauffeurs',
          '.footer-section:nth-of-type(4) h3': 'Contact',
          '.footer-bottom p': '© 2024 eDalab. Tous droits réservés.',
        },
        placeholder: {
          '#pickupLocation': 'Entrez l’adresse de départ',
          '#dropoffLocation': 'Entrez l’adresse de destination',
          '#specialRequests': 'Bagages, animaux, etc.',
          '#ride-hero-search': 'Où voulez-vous aller ?',
        },
      },
      ar: {
        text: {
          '.ride-hero h1, .wrap h1': 'احجز مشوارك مع إيدالاب',
          '.ride-hero p': 'تنقل سريع وآمن وبأسعار واضحة مع إدارة سهلة للمشوار.',
          'main > section:first-of-type h2': 'أنواع المشاوير',
          '.ride-booking-form h2': 'احجز مشواراً',
          '.form-group:nth-of-type(1) label': 'موقع الانطلاق',
          '.form-group:nth-of-type(2) label': 'موقع الوصول',
          '.form-row:nth-of-type(1) .form-group:nth-of-type(1) label': 'تاريخ الانطلاق',
          '.form-row:nth-of-type(1) .form-group:nth-of-type(2) label': 'وقت الانطلاق',
          '.form-row:nth-of-type(2) .form-group:nth-of-type(1) label': 'الركاب',
          '.form-row:nth-of-type(2) .form-group:nth-of-type(2) label': 'طلبات خاصة',
          '#passengerCount option[value="1"]': 'راكب واحد',
          '#passengerCount option[value="2"]': 'راكبان',
          '#passengerCount option[value="3"]': '3 ركاب',
          '#passengerCount option[value="4"]': '4 ركاب',
          '.ride-info h3': 'لماذا تختار مشاوير إيدالاب؟',
          '.active-rides h3': 'مشاويرك الحالية',
          '#bookButton': 'احجز المشوار الآن',
          '.footer-section:nth-of-type(1) h3': 'eDalab المشاوير',
          '.footer-section:nth-of-type(2) h3': 'للركاب',
          '.footer-section:nth-of-type(3) h3': 'للسائقين',
          '.footer-section:nth-of-type(4) h3': 'اتصل بنا',
          '.footer-bottom p': '© 2024 eDalab. جميع الحقوق محفوظة.',
        },
        placeholder: {
          '#pickupLocation': 'أدخل موقع الانطلاق',
          '#dropoffLocation': 'أدخل الوجهة',
          '#specialRequests': 'أمتعة، حيوانات أليفة، وغيرها',
          '#ride-hero-search': 'إلى أين تريد الذهاب؟',
        },
      },
    },
    'home-services.html': {
      fr: {
        text: {
          '.services-hero h1, .wrap h1': 'Des services à domicile fiables, quand vous en avez besoin',
          '.services-hero p': 'Parcourez les catégories, comparez les professionnels et réservez la bonne aide pour votre maison et votre quotidien.',
          'main > section:first-of-type h2': 'Choisissez un service',
          '.filter-item:nth-of-type(1) label': 'Type de service',
          '.filter-item:nth-of-type(2) label': 'Note',
          '.filter-item:nth-of-type(3) label': 'Fourchette de prix',
          '.filter-item:nth-of-type(4) label': 'Disponibilité',
          '#ratingFilter option[value=""]': 'Toutes les notes',
          '#ratingFilter option[value="5"]': '5 étoiles',
          '#ratingFilter option[value="4"]': '4+ étoiles',
          '#ratingFilter option[value="3"]': '3+ étoiles',
          '#priceFilter option[value=""]': 'Tous les prix',
          '#availabilityFilter option[value=""]': 'N’importe quand',
          '#availabilityFilter option[value="today"]': 'Aujourd’hui',
          '#availabilityFilter option[value="tomorrow"]': 'Demain',
          '#availabilityFilter option[value="week"]': 'Cette semaine',
          'main > section:nth-of-type(2) h2': 'Professionnels disponibles',
          '.footer-section:nth-of-type(1) h3': 'eDalab Services',
          '.footer-section:nth-of-type(2) h3': 'Pour les clients',
          '.footer-section:nth-of-type(3) h3': 'Pour les pros',
          '.footer-section:nth-of-type(4) h3': 'Contact',
          '.footer-bottom p': '© 2024 eDalab. Tous droits réservés.',
        },
        placeholder: { '#services-hero-search': 'Rechercher un service ou un prestataire...' },
      },
      ar: {
        text: {
          '.services-hero h1, .wrap h1': 'خدمات منزلية موثوقة عندما تحتاجها',
          '.services-hero p': 'تصفح الفئات، وقارن بين المحترفين، واحجز المساعدة المناسبة لمنزلك وحياتك اليومية.',
          'main > section:first-of-type h2': 'اختر خدمة',
          '.filter-item:nth-of-type(1) label': 'نوع الخدمة',
          '.filter-item:nth-of-type(2) label': 'التقييم',
          '.filter-item:nth-of-type(3) label': 'نطاق السعر',
          '.filter-item:nth-of-type(4) label': 'التوفر',
          '#ratingFilter option[value=""]': 'كل التقييمات',
          '#ratingFilter option[value="5"]': '5 نجوم',
          '#ratingFilter option[value="4"]': '4+ نجوم',
          '#ratingFilter option[value="3"]': '3+ نجوم',
          '#priceFilter option[value=""]': 'كل الأسعار',
          '#availabilityFilter option[value=""]': 'أي وقت',
          '#availabilityFilter option[value="today"]': 'اليوم',
          '#availabilityFilter option[value="tomorrow"]': 'غداً',
          '#availabilityFilter option[value="week"]': 'هذا الأسبوع',
          'main > section:nth-of-type(2) h2': 'المحترفون المتاحون',
          '.footer-section:nth-of-type(1) h3': 'eDalab الخدمات',
          '.footer-section:nth-of-type(2) h3': 'للعملاء',
          '.footer-section:nth-of-type(3) h3': 'للمحترفين',
          '.footer-section:nth-of-type(4) h3': 'اتصل بنا',
          '.footer-bottom p': '© 2024 eDalab. جميع الحقوق محفوظة.',
        },
        placeholder: { '#services-hero-search': 'ابحث عن خدمة أو مقدم خدمة...' },
      },
    },
    'laundry.html': {
      fr: {
        text: {
          '.laundry-hero h1, .wrap h1': 'La blanchisserie simplifiée',
          'main > section:first-of-type h2': 'Services de blanchisserie',
          '.laundry-form h2': 'Passez votre commande',
          '.laundry-hero p': 'Collecte, nettoyage et livraison professionnels avec des horaires flexibles et des estimations transparentes.',
          '.laundry-form > label': 'Services supplémentaires',
          '.checkbox-item:nth-of-type(1) label': 'Repassage (+$5)',
          '.checkbox-item:nth-of-type(2) label': 'Séchage machine (+$3)',
          '.checkbox-item:nth-of-type(3) label': 'Pliage (+$4)',
          '.checkbox-item:nth-of-type(4) label': 'Amidon (+$2)',
          '.form-group:nth-of-type(1) label': 'Adresse de collecte',
          '.form-group:nth-of-type(2) label': 'Instructions spéciales',
          '.form-row .form-group:nth-of-type(1) label': 'Date de collecte',
          '.form-row .form-group:nth-of-type(2) label': 'Heure de collecte',
          '#pickupTime option[value=""]': 'Choisir l’heure',
          '#deliveryDate option[value=""]': 'Choisir la livraison',
          '#serviceChargesRow span:first-child': 'Services supplémentaires',
          '.price-row:nth-of-type(3) span:first-child': 'Collecte et livraison',
          '.price-total span:first-child': 'Estimation totale',
          '.laundry-info h3': 'Pourquoi choisir notre blanchisserie ?',
          '.active-orders h3, .laundry-orders h3': 'Vos commandes de blanchisserie',
          '#submitButton': 'Passer la commande',
          '.footer-section:nth-of-type(1) h3': 'eDalab Laundry',
          '.footer-section:nth-of-type(2) h3': 'Pour les clients',
          '.footer-section:nth-of-type(3) h3': 'Services',
          '.footer-section:nth-of-type(4) h3': 'Contact',
          '.footer-bottom p': '© 2024 eDalab. Tous droits réservés.',
        },
        placeholder: {
          '#pickupAddress': 'Entrez votre adresse',
          '#specialInstructions': 'ex. vêtements délicats, lavage à la main uniquement...',
          '#laundry-hero-search': 'Rechercher un service de blanchisserie...',
        },
      },
      ar: {
        text: {
          '.laundry-hero h1, .wrap h1': 'خدمة الغسيل بسهولة',
          'main > section:first-of-type h2': 'خدمات الغسيل',
          '.laundry-form h2': 'قدّم طلبك',
          '.laundry-hero p': 'استلام وتنظيف وتوصيل احترافي مع مواعيد مرنة وتقديرات واضحة.',
          '.laundry-form > label': 'خدمات إضافية',
          '.checkbox-item:nth-of-type(1) label': 'كي (+$5)',
          '.checkbox-item:nth-of-type(2) label': 'تجفيف آلي (+$3)',
          '.checkbox-item:nth-of-type(3) label': 'طي (+$4)',
          '.checkbox-item:nth-of-type(4) label': 'نشا (+$2)',
          '.form-group:nth-of-type(1) label': 'عنوان الاستلام',
          '.form-group:nth-of-type(2) label': 'تعليمات خاصة',
          '.form-row .form-group:nth-of-type(1) label': 'تاريخ الاستلام',
          '.form-row .form-group:nth-of-type(2) label': 'وقت الاستلام',
          '#pickupTime option[value=""]': 'اختر الوقت',
          '#deliveryDate option[value=""]': 'اختر التوصيل',
          '#serviceChargesRow span:first-child': 'خدمات إضافية',
          '.price-row:nth-of-type(3) span:first-child': 'الاستلام والتوصيل',
          '.price-total span:first-child': 'التقدير الإجمالي',
          '.laundry-info h3': 'لماذا تختار خدمة الغسيل لدينا؟',
          '.active-orders h3, .laundry-orders h3': 'طلبات الغسيل الخاصة بك',
          '#submitButton': 'تأكيد الطلب',
          '.footer-section:nth-of-type(1) h3': 'eDalab الغسيل',
          '.footer-section:nth-of-type(2) h3': 'للعملاء',
          '.footer-section:nth-of-type(3) h3': 'الخدمات',
          '.footer-section:nth-of-type(4) h3': 'اتصل بنا',
          '.footer-bottom p': '© 2024 eDalab. جميع الحقوق محفوظة.',
        },
        placeholder: {
          '#pickupAddress': 'أدخل عنوانك',
          '#specialInstructions': 'مثال: ملابس حساسة، غسيل يدوي فقط...',
          '#laundry-hero-search': 'ابحث عن خدمة غسيل...',
        },
      },
    },
    'checkout.html': {
      fr: {
        text: {
          'title': 'Paiement - Edalab',
          'body > div[style*="text-align: center"] h1': 'Paiement',
          '.checkout-form:nth-of-type(1) .section-header': 'Adresse de livraison',
          '.add-new-address-btn': '+ Ajouter une adresse',
          '#addressForm h4': 'Ajouter une adresse',
          '#addressForm .form-group:nth-of-type(1) .form-label': 'Type',
          '#addressType option[value="home"]': 'Maison',
          '#addressType option[value="work"]': 'Travail',
          '#addressType option[value="other"]': 'Autre',
          '#addressForm .form-group:nth-of-type(2) .form-label': 'Adresse',
          '#addressForm .form-row .form-group:nth-of-type(1) .form-label': 'Ville',
          '#addressForm .form-row .form-group:nth-of-type(2) .form-label': 'Code postal',
          '#addressForm button:first-of-type': 'Enregistrer l’adresse',
          '#addressForm button:last-of-type': 'Annuler',
          '.checkout-form:nth-of-type(2) .section-header': 'Vitesse de livraison',
          '.checkout-form:nth-of-type(3) .section-header': 'Mode de paiement',
          '.checkout-form:nth-of-type(4) .section-header': 'Instructions spéciales',
          '.checkout-form:nth-of-type(4) .form-label': 'Laissez une note au livreur',
        },
        placeholder: {
          '#addressStreet': '123 rue principale',
          '#addressCity': 'Ville',
          '#addressZip': 'Code postal',
          '#deliveryNotes': 'ex. veuillez sonner deux fois...',
        },
      },
      ar: {
        text: {
          'title': 'إتمام الطلب - Edalab',
          'body > div[style*="text-align: center"] h1': 'إتمام الطلب',
          '.checkout-form:nth-of-type(1) .section-header': 'عنوان التوصيل',
          '.add-new-address-btn': '+ إضافة عنوان جديد',
          '#addressForm h4': 'إضافة عنوان جديد',
          '#addressForm .form-group:nth-of-type(1) .form-label': 'النوع',
          '#addressType option[value="home"]': 'المنزل',
          '#addressType option[value="work"]': 'العمل',
          '#addressType option[value="other"]': 'أخرى',
          '#addressForm .form-group:nth-of-type(2) .form-label': 'عنوان الشارع',
          '#addressForm .form-row .form-group:nth-of-type(1) .form-label': 'المدينة',
          '#addressForm .form-row .form-group:nth-of-type(2) .form-label': 'الرمز البريدي',
          '#addressForm button:first-of-type': 'حفظ العنوان',
          '#addressForm button:last-of-type': 'إلغاء',
          '.checkout-form:nth-of-type(2) .section-header': 'سرعة التوصيل',
          '.checkout-form:nth-of-type(3) .section-header': 'طريقة الدفع',
          '.checkout-form:nth-of-type(4) .section-header': 'تعليمات خاصة',
          '.checkout-form:nth-of-type(4) .form-label': 'اترك ملاحظة لمندوب التوصيل',
        },
        placeholder: {
          '#addressStreet': '123 الشارع الرئيسي',
          '#addressCity': 'المدينة',
          '#addressZip': 'الرمز البريدي',
          '#deliveryNotes': 'مثال: يرجى قرع الجرس مرتين...',
        },
      },
    },
    'orders.html': {
      fr: {
        text: {
          'title': 'Mes commandes - Edalab',
          '.page-title': 'Mes commandes',
          '.filters .filter-btn:nth-of-type(1)': 'Toutes les commandes',
          '.filters .filter-btn:nth-of-type(2)': 'En attente',
          '.filters .filter-btn:nth-of-type(3)': 'Confirmée',
          '.filters .filter-btn:nth-of-type(4)': 'Livrée',
          '.filters .filter-btn:nth-of-type(5)': 'Annulée',
        },
      },
      ar: {
        text: {
          'title': 'طلباتي - Edalab',
          '.page-title': 'طلباتي',
          '.filters .filter-btn:nth-of-type(1)': 'كل الطلبات',
          '.filters .filter-btn:nth-of-type(2)': 'قيد الانتظار',
          '.filters .filter-btn:nth-of-type(3)': 'مؤكد',
          '.filters .filter-btn:nth-of-type(4)': 'تم التوصيل',
          '.filters .filter-btn:nth-of-type(5)': 'ملغى',
        },
      },
    },
    'tracking.html': {
      fr: {
        text: {
          'title': 'Suivi de commande - Edalab',
          '.order-header .order-id': 'Numéro de commande',
          '#orderStatus': 'Préparation',
          '.map-container': '🗺️ Carte de suivi en direct (bientôt disponible)',
          '#driverSection .info-title': 'Partenaire de livraison',
          '.delivery-info .info-section:nth-of-type(2) .info-title': 'Adresse de livraison',
          '.delivery-info .info-section:nth-of-type(2) .address-label': 'Livrer à',
          '.delivery-info .info-section:nth-of-type(3) .info-title': 'Heure de livraison estimée',
          '.delivery-info .info-section:nth-of-type(3) .address-label': 'Arrive dans environ',
          '.contact-section .info-title': 'Besoin d’aide ?',
          '.contact-buttons .contact-btn:first-of-type div:last-child': 'Assistance chat',
          '.contact-buttons .contact-btn:last-of-type div:last-child': 'Appeler l’assistance',
        },
      },
      ar: {
        text: {
          'title': 'تتبع الطلب - Edalab',
          '.order-header .order-id': 'رقم الطلب',
          '#orderStatus': 'قيد التحضير',
          '.map-container': '🗺️ خريطة التتبع المباشر (قريباً)',
          '#driverSection .info-title': 'شريك التوصيل',
          '.delivery-info .info-section:nth-of-type(2) .info-title': 'عنوان التوصيل',
          '.delivery-info .info-section:nth-of-type(2) .address-label': 'التوصيل إلى',
          '.delivery-info .info-section:nth-of-type(3) .info-title': 'وقت التوصيل المتوقع',
          '.delivery-info .info-section:nth-of-type(3) .address-label': 'سيصل تقريباً خلال',
          '.contact-section .info-title': 'هل تحتاج إلى مساعدة؟',
          '.contact-buttons .contact-btn:first-of-type div:last-child': 'دعم المحادثة',
          '.contact-buttons .contact-btn:last-of-type div:last-child': 'اتصل بالدعم',
        },
      },
    },
    'profile.html': {
      fr: {
        text: {
          'title': 'Profil - Edalab',
          '#profileName': 'Invité',
          '#profileEmail': 'Non connecté',
          '.profile-stats .stat:nth-of-type(1) .stat-label': 'Commandes',
          '.profile-stats .stat:nth-of-type(2) .stat-label': 'Dépensé',
          '.profile-stats .stat:nth-of-type(3) .stat-label': 'Récompenses',
          '.edit-profile-btn': 'Modifier le profil',
          '.menu-section:nth-of-type(1) .section-title': 'Compte',
          '.menu-section:nth-of-type(1) .menu-item:nth-of-type(1) .menu-label': 'Modifier le profil',
          '.menu-section:nth-of-type(1) .menu-item:nth-of-type(1) .menu-desc': 'Mettez à jour vos informations personnelles',
          '.menu-section:nth-of-type(1) .menu-item:nth-of-type(2) .menu-label': 'Adresses',
          '.menu-section:nth-of-type(1) .menu-item:nth-of-type(2) .menu-desc': 'Gérez vos adresses de livraison',
          '.menu-section:nth-of-type(1) .menu-item:nth-of-type(3) .menu-label': 'Moyens de paiement',
          '.menu-section:nth-of-type(1) .menu-item:nth-of-type(3) .menu-desc': 'Gérez vos cartes et portefeuilles',
          '.menu-section:nth-of-type(2) .section-title': 'Commandes et assistance',
          '.menu-section:nth-of-type(2) .menu-item:nth-of-type(1) .menu-label': 'Mes commandes',
          '.menu-section:nth-of-type(2) .menu-item:nth-of-type(1) .menu-desc': 'Consultez l’historique de vos commandes',
          '.menu-section:nth-of-type(2) .menu-item:nth-of-type(2) .menu-label': 'Centre d’aide',
          '.menu-section:nth-of-type(2) .menu-item:nth-of-type(2) .menu-desc': 'FAQ et assistance client',
          '.menu-section:nth-of-type(3) .section-title': 'Préférences',
          '.menu-section:nth-of-type(3) .menu-item .menu-label': 'Paramètres',
          '.menu-section:nth-of-type(3) .menu-item .menu-desc': 'Notifications, langue, confidentialité',
          '#logoutBtn': 'Déconnexion',
          '.app-info p:first-of-type': 'Application Edalab v1.0.0',
          '.app-info p:last-of-type': '© 2024 Tous droits réservés',
        },
      },
      ar: {
        text: {
          'title': 'الملف الشخصي - Edalab',
          '#profileName': 'مستخدم زائر',
          '#profileEmail': 'غير مسجل الدخول',
          '.profile-stats .stat:nth-of-type(1) .stat-label': 'الطلبات',
          '.profile-stats .stat:nth-of-type(2) .stat-label': 'الإنفاق',
          '.profile-stats .stat:nth-of-type(3) .stat-label': 'المكافآت',
          '.edit-profile-btn': 'تعديل الملف الشخصي',
          '.menu-section:nth-of-type(1) .section-title': 'الحساب',
          '.menu-section:nth-of-type(1) .menu-item:nth-of-type(1) .menu-label': 'تعديل الملف الشخصي',
          '.menu-section:nth-of-type(1) .menu-item:nth-of-type(1) .menu-desc': 'حدّث معلوماتك الشخصية',
          '.menu-section:nth-of-type(1) .menu-item:nth-of-type(2) .menu-label': 'العناوين',
          '.menu-section:nth-of-type(1) .menu-item:nth-of-type(2) .menu-desc': 'إدارة عناوين التوصيل',
          '.menu-section:nth-of-type(1) .menu-item:nth-of-type(3) .menu-label': 'طرق الدفع',
          '.menu-section:nth-of-type(1) .menu-item:nth-of-type(3) .menu-desc': 'إدارة بطاقاتك ومحافظك',
          '.menu-section:nth-of-type(2) .section-title': 'الطلبات والدعم',
          '.menu-section:nth-of-type(2) .menu-item:nth-of-type(1) .menu-label': 'طلباتي',
          '.menu-section:nth-of-type(2) .menu-item:nth-of-type(1) .menu-desc': 'عرض سجل طلباتك',
          '.menu-section:nth-of-type(2) .menu-item:nth-of-type(2) .menu-label': 'مركز المساعدة',
          '.menu-section:nth-of-type(2) .menu-item:nth-of-type(2) .menu-desc': 'الأسئلة الشائعة ودعم العملاء',
          '.menu-section:nth-of-type(3) .section-title': 'التفضيلات',
          '.menu-section:nth-of-type(3) .menu-item .menu-label': 'الإعدادات',
          '.menu-section:nth-of-type(3) .menu-item .menu-desc': 'الإشعارات واللغة والخصوصية',
          '#logoutBtn': 'تسجيل الخروج',
          '.app-info p:first-of-type': 'تطبيق Edalab v1.0.0',
          '.app-info p:last-of-type': '© 2024 جميع الحقوق محفوظة',
        },
      },
    },
    'addresses.html': {
      fr: {
        text: {
          'title': 'Mes adresses - Edalab',
          '.page-title': 'Mes adresses',
          '.btn-add': '+ Ajouter une adresse',
          '#addressForm h3': 'Ajouter une adresse',
          '#addressForm .form-group:nth-of-type(1) .form-label': 'Type',
          '#addressType option[value="home"]': 'Maison',
          '#addressType option[value="work"]': 'Travail',
          '#addressType option[value="other"]': 'Autre',
          '#addressForm .form-group:nth-of-type(2) .form-label': 'Adresse',
          '#addressForm .form-row .form-group:nth-of-type(1) .form-label': 'Ville',
          '#addressForm .form-row .form-group:nth-of-type(2) .form-label': 'Code postal',
          '#addressForm .form-buttons .btn-primary:first-of-type': 'Enregistrer',
          '#addressForm .form-buttons .btn-primary:last-of-type': 'Annuler',
        },
        placeholder: {
          '#addressStreet': '123 rue principale',
          '#addressCity': 'Ville',
          '#addressZip': 'Code postal',
        },
      },
      ar: {
        text: {
          'title': 'عناويني - Edalab',
          '.page-title': 'عناويني',
          '.btn-add': '+ إضافة عنوان جديد',
          '#addressForm h3': 'إضافة عنوان جديد',
          '#addressForm .form-group:nth-of-type(1) .form-label': 'النوع',
          '#addressType option[value="home"]': 'المنزل',
          '#addressType option[value="work"]': 'العمل',
          '#addressType option[value="other"]': 'أخرى',
          '#addressForm .form-group:nth-of-type(2) .form-label': 'عنوان الشارع',
          '#addressForm .form-row .form-group:nth-of-type(1) .form-label': 'المدينة',
          '#addressForm .form-row .form-group:nth-of-type(2) .form-label': 'الرمز البريدي',
          '#addressForm .form-buttons .btn-primary:first-of-type': 'حفظ',
          '#addressForm .form-buttons .btn-primary:last-of-type': 'إلغاء',
        },
        placeholder: {
          '#addressStreet': '123 الشارع الرئيسي',
          '#addressCity': 'المدينة',
          '#addressZip': 'الرمز البريدي',
        },
      },
    },
    'payments.html': {
      fr: {
        text: {
          'title': 'Moyens de paiement - Edalab',
          '.page-title': 'Moyens de paiement',
          '.btn-add': '+ Ajouter un moyen de paiement',
          '#paymentForm h3': 'Ajouter un moyen de paiement',
          '#paymentForm .form-group:nth-of-type(1) .form-label': 'Nom du titulaire',
          '#paymentForm .form-group:nth-of-type(2) .form-label': 'Numéro de carte',
          '#paymentForm .form-row .form-group:nth-of-type(1) .form-label': 'Expire',
          '#paymentForm .form-row .form-group:nth-of-type(2) .form-label': 'CVV',
          '#paymentForm .form-buttons .btn-primary:first-of-type': 'Enregistrer',
          '#paymentForm .form-buttons .btn-primary:last-of-type': 'Annuler',
        },
        placeholder: {
          '#cardName': 'Jean Dupont',
        },
      },
      ar: {
        text: {
          'title': 'طرق الدفع - Edalab',
          '.page-title': 'طرق الدفع',
          '.btn-add': '+ إضافة طريقة دفع',
          '#paymentForm h3': 'إضافة طريقة دفع',
          '#paymentForm .form-group:nth-of-type(1) .form-label': 'اسم حامل البطاقة',
          '#paymentForm .form-group:nth-of-type(2) .form-label': 'رقم البطاقة',
          '#paymentForm .form-row .form-group:nth-of-type(1) .form-label': 'تاريخ الانتهاء',
          '#paymentForm .form-row .form-group:nth-of-type(2) .form-label': 'CVV',
          '#paymentForm .form-buttons .btn-primary:first-of-type': 'حفظ',
          '#paymentForm .form-buttons .btn-primary:last-of-type': 'إلغاء',
        },
        placeholder: {
          '#cardName': 'أحمد محمد',
        },
      },
    },
    'edit-profile.html': {
      fr: {
        text: {
          'title': 'Modifier le profil - Edalab',
          '.form-title': 'Modifier le profil',
          '.form-card:first-of-type .section-header': 'Informations personnelles',
          '.form-row:first-of-type .form-group:nth-of-type(1) .form-label': 'Prénom',
          '.form-row:first-of-type .form-group:nth-of-type(2) .form-label': 'Nom',
          '.form-card:first-of-type > .form-group:nth-of-type(1) .form-label': 'Adresse e-mail',
          '.form-card:first-of-type > .form-group:nth-of-type(2) .form-label': 'Numéro de téléphone',
          '.form-card:first-of-type > .form-group:nth-of-type(3) .form-label': 'Date de naissance',
          '.form-card:first-of-type > .form-group:nth-of-type(4) .form-label': 'Bio',
          '.form-buttons .btn-primary': 'Enregistrer les modifications',
          '.form-buttons .btn-secondary': 'Annuler',
          '.form-card:nth-of-type(2) .section-header': 'Changer le mot de passe',
          '.form-card:nth-of-type(2) .form-group:nth-of-type(1) .form-label': 'Mot de passe actuel',
          '.form-card:nth-of-type(2) .form-group:nth-of-type(2) .form-label': 'Nouveau mot de passe',
          '.form-card:nth-of-type(2) .form-group:nth-of-type(3) .form-label': 'Confirmer le mot de passe',
          '.form-card:nth-of-type(2) .btn-primary': 'Mettre à jour le mot de passe',
        },
        placeholder: {
          '#firstName': 'Jean',
          '#lastName': 'Dupont',
          '#bio': 'Parlez-nous de vous',
        },
      },
      ar: {
        text: {
          'title': 'تعديل الملف الشخصي - Edalab',
          '.form-title': 'تعديل الملف الشخصي',
          '.form-card:first-of-type .section-header': 'المعلومات الشخصية',
          '.form-row:first-of-type .form-group:nth-of-type(1) .form-label': 'الاسم الأول',
          '.form-row:first-of-type .form-group:nth-of-type(2) .form-label': 'اسم العائلة',
          '.form-card:first-of-type > .form-group:nth-of-type(1) .form-label': 'البريد الإلكتروني',
          '.form-card:first-of-type > .form-group:nth-of-type(2) .form-label': 'رقم الهاتف',
          '.form-card:first-of-type > .form-group:nth-of-type(3) .form-label': 'تاريخ الميلاد',
          '.form-card:first-of-type > .form-group:nth-of-type(4) .form-label': 'نبذة',
          '.form-buttons .btn-primary': 'حفظ التغييرات',
          '.form-buttons .btn-secondary': 'إلغاء',
          '.form-card:nth-of-type(2) .section-header': 'تغيير كلمة المرور',
          '.form-card:nth-of-type(2) .form-group:nth-of-type(1) .form-label': 'كلمة المرور الحالية',
          '.form-card:nth-of-type(2) .form-group:nth-of-type(2) .form-label': 'كلمة المرور الجديدة',
          '.form-card:nth-of-type(2) .form-group:nth-of-type(3) .form-label': 'تأكيد كلمة المرور',
          '.form-card:nth-of-type(2) .btn-primary': 'تحديث كلمة المرور',
        },
        placeholder: {
          '#firstName': 'أحمد',
          '#lastName': 'محمد',
          '#bio': 'أخبرنا عنك',
        },
      },
    },
    'help-center.html': {
      fr: {
        text: {
          'title': 'Centre d’aide - Edalab',
          '.page-title': 'Centre d’aide',
          '.contact-title': 'Vous ne trouvez pas ce que vous cherchez ?',
          '.contact-info': 'Contactez notre équipe d’assistance. Nous sommes là pour vous aider !',
          '.contact-btns .btn-contact:first-of-type': '💬 Chat',
          '.contact-btns .btn-contact:last-of-type': '📞 Appeler',
        },
        placeholder: {
          '#searchBox': 'Rechercher dans la FAQ...',
        },
      },
      ar: {
        text: {
          'title': 'مركز المساعدة - Edalab',
          '.page-title': 'مركز المساعدة',
          '.contact-title': 'لم تجد ما تبحث عنه؟',
          '.contact-info': 'تواصل مع فريق الدعم لدينا. نحن هنا لمساعدتك!',
          '.contact-btns .btn-contact:first-of-type': '💬 محادثة',
          '.contact-btns .btn-contact:last-of-type': '📞 اتصال',
        },
        placeholder: {
          '#searchBox': 'ابحث في الأسئلة الشائعة...',
        },
      },
    },
    'wishlist.html': {
      fr: {
        text: {
          'title': 'Favoris - eDalab',
          '.wishlist-head h1': 'Vos favoris',
          '.wishlist-head p': 'Enregistrez les produits que vous aimez et ajoutez-les au panier quand vous êtes prêt.',
          '.wishlist-actions a': 'Continuer vos achats',
        },
      },
      ar: {
        text: {
          'title': 'المفضلة - eDalab',
          '.wishlist-head h1': 'قائمة المفضلة',
          '.wishlist-head p': 'احفظ المنتجات التي تحبها وانقلها إلى السلة عندما تكون جاهزاً.',
          '.wishlist-actions a': 'مواصلة التسوق',
        },
      },
    },
    'cart.html': {
      fr: {
        text: {
          'title': 'Panier - eDalab',
          'main > h1': 'Votre panier 🛒',
          '.promo-section label': 'Code promo',
          '.promo-input button': 'Appliquer',
          '.summary-row:nth-of-type(1) span:first-child': 'Sous-total',
          '.summary-row:nth-of-type(2) span:first-child': 'Frais de livraison',
          '#discount-row span:first-child': 'Remise',
          '.summary-row-total span:first-child': 'Total',
          '.checkout-btn': 'Passer au paiement',
          '.continue-btn': 'Continuer vos achats',
          '.footer-section:nth-of-type(1) h3': 'À propos d’eDalab',
          '.footer-section:nth-of-type(1) a:nth-of-type(1)': 'À propos',
          '.footer-section:nth-of-type(1) a:nth-of-type(2)': 'Carrières',
          '.footer-section:nth-of-type(1) a:nth-of-type(3)': 'Blog',
          '.footer-section:nth-of-type(2) h3': 'Pour les utilisateurs',
          '.footer-section:nth-of-type(2) a:nth-of-type(1)': 'Centre d’aide',
          '.footer-section:nth-of-type(2) a:nth-of-type(2)': 'Suivre la commande',
          '.footer-section:nth-of-type(2) a:nth-of-type(3)': 'Compte',
          '.footer-section:nth-of-type(3) h3': 'Mentions légales',
          '.footer-section:nth-of-type(3) a:nth-of-type(1)': 'Conditions générales',
          '.footer-section:nth-of-type(3) a:nth-of-type(2)': 'Politique de confidentialité',
          '.footer-section:nth-of-type(3) a:nth-of-type(3)': 'Contact',
          '.footer-bottom p': '© 2024 eDalab. Tous droits réservés.',
        },
        placeholder: {
          '#promo-code': 'Saisir le code',
        },
      },
      ar: {
        text: {
          'title': 'السلة - eDalab',
          'main > h1': 'سلة التسوق 🛒',
          '.promo-section label': 'رمز الخصم',
          '.promo-input button': 'تطبيق',
          '.summary-row:nth-of-type(1) span:first-child': 'المجموع الفرعي',
          '.summary-row:nth-of-type(2) span:first-child': 'رسوم التوصيل',
          '#discount-row span:first-child': 'الخصم',
          '.summary-row-total span:first-child': 'الإجمالي',
          '.checkout-btn': 'المتابعة إلى الدفع',
          '.continue-btn': 'مواصلة التسوق',
          '.footer-section:nth-of-type(1) h3': 'عن eDalab',
          '.footer-section:nth-of-type(1) a:nth-of-type(1)': 'من نحن',
          '.footer-section:nth-of-type(1) a:nth-of-type(2)': 'الوظائف',
          '.footer-section:nth-of-type(1) a:nth-of-type(3)': 'المدونة',
          '.footer-section:nth-of-type(2) h3': 'للمستخدمين',
          '.footer-section:nth-of-type(2) a:nth-of-type(1)': 'مركز المساعدة',
          '.footer-section:nth-of-type(2) a:nth-of-type(2)': 'تتبع الطلب',
          '.footer-section:nth-of-type(2) a:nth-of-type(3)': 'الحساب',
          '.footer-section:nth-of-type(3) h3': 'قانوني',
          '.footer-section:nth-of-type(3) a:nth-of-type(1)': 'الشروط والأحكام',
          '.footer-section:nth-of-type(3) a:nth-of-type(2)': 'سياسة الخصوصية',
          '.footer-section:nth-of-type(3) a:nth-of-type(3)': 'اتصل بنا',
          '.footer-bottom p': '© 2024 eDalab. جميع الحقوق محفوظة.',
        },
        placeholder: {
          '#promo-code': 'أدخل الرمز',
        },
      },
    },
    'order-success.html': {
      fr: {
        text: {
          'title': 'Commande confirmée - Edalab',
          '.success-title': 'Commande confirmée !',
          '.success-message': 'Votre commande a été passée et confirmée avec succès. Nous préparons vos articles maintenant.',
          '.tracking-label': 'Numéro de commande',
          '.detail-row:nth-of-type(1) .detail-label': 'Date de commande',
          '.detail-row:nth-of-type(2) .detail-label': 'Livraison estimée',
          '.detail-row:nth-of-type(3) .detail-label': 'Adresse de livraison',
          '.detail-row:nth-of-type(4) .detail-label': 'Mode de paiement',
          '.steps-title': 'Que se passe-t-il ensuite ?',
          '.step:nth-of-type(1) .step-title': 'Nous préparons votre commande',
          '.step:nth-of-type(1) .step-description': 'Notre équipe prépare et emballe soigneusement vos articles',
          '.step:nth-of-type(2) .step-title': 'Votre commande est en route',
          '.step:nth-of-type(2) .step-description': 'Un partenaire de livraison récupérera votre commande bientôt',
          '.step:nth-of-type(3) .step-title': 'Confirmation de livraison',
          '.step:nth-of-type(3) .step-description': 'Vous recevrez votre commande à l’adresse indiquée',
          '.action-buttons .btn-primary': 'Suivre la commande',
          '.action-buttons .btn-secondary': 'Continuer vos achats',
        },
      },
      ar: {
        text: {
          'title': 'تم تأكيد الطلب - Edalab',
          '.success-title': 'تم تأكيد الطلب!',
          '.success-message': 'تم تقديم طلبك وتأكيده بنجاح. نحن نحضر عناصر طلبك الآن.',
          '.tracking-label': 'رقم الطلب',
          '.detail-row:nth-of-type(1) .detail-label': 'تاريخ الطلب',
          '.detail-row:nth-of-type(2) .detail-label': 'وقت التوصيل المتوقع',
          '.detail-row:nth-of-type(3) .detail-label': 'عنوان التوصيل',
          '.detail-row:nth-of-type(4) .detail-label': 'طريقة الدفع',
          '.steps-title': 'ماذا يحدث بعد ذلك؟',
          '.step:nth-of-type(1) .step-title': 'نحن نحضر طلبك',
          '.step:nth-of-type(1) .step-description': 'فريقنا يحضر ويغلف عناصر طلبك بعناية',
          '.step:nth-of-type(2) .step-title': 'طلبك في الطريق',
          '.step:nth-of-type(2) .step-description': 'سيقوم شريك التوصيل باستلام طلبك قريباً',
          '.step:nth-of-type(3) .step-title': 'تأكيد التوصيل',
          '.step:nth-of-type(3) .step-description': 'ستستلم طلبك على العنوان المحدد',
          '.action-buttons .btn-primary': 'تتبع الطلب',
          '.action-buttons .btn-secondary': 'مواصلة التسوق',
        },
      },
    },
    'product-detail.html': {
      fr: {
        text: {
          '.detail-breadcrumbs a:nth-of-type(1)': 'Accueil',
          '.detail-breadcrumbs a:nth-of-type(2)': 'Boutique',
          '#productBreadcrumb': 'Détails du produit',
          '#productBrand': 'Marque',
          '.detail-meta-row .detail-chip strong': '0 avis',
          '#availability': 'En stock',
          '#specificationsContainer .detail-section-title': 'Spécifications',
          '.detail-purchase-card .detail-section-title': 'Quantité',
          '.detail-qty-bar > span': 'Choisissez la quantité souhaitée',
          '#addCartBtn': 'Ajouter au panier',
          '#buyNowBtn': 'Acheter maintenant',
        },
      },
      ar: {
        text: {
          '.detail-breadcrumbs a:nth-of-type(1)': 'الرئيسية',
          '.detail-breadcrumbs a:nth-of-type(2)': 'التسوق',
          '#productBreadcrumb': 'تفاصيل المنتج',
          '#productBrand': 'العلامة التجارية',
          '.detail-meta-row .detail-chip strong': '0 تقييم',
          '#availability': 'متوفر',
          '#specificationsContainer .detail-section-title': 'المواصفات',
          '.detail-purchase-card .detail-section-title': 'الكمية',
          '.detail-qty-bar > span': 'اختر الكمية التي تريدها',
          '#addCartBtn': 'أضف إلى السلة',
          '#buyNowBtn': 'اشترِ الآن',
        },
      },
    },
    'restaurant-detail.html': {
      fr: {
        text: {
          '.detail-breadcrumbs a:nth-of-type(1)': 'Accueil',
          '.detail-breadcrumbs a:nth-of-type(2)': 'Restauration',
          '#restaurantBreadcrumb': 'Détails du restaurant',
          '#restaurantCuisine': 'Restaurant',
          '#restaurantDescription': 'Chargement des détails du restaurant...',
          '#menuContainer + * .detail-section-title, .detail-section-card .detail-section-title': 'Menu',
          '.detail-btn-primary': 'Ouvrir le panier',
        },
      },
      ar: {
        text: {
          '.detail-breadcrumbs a:nth-of-type(1)': 'الرئيسية',
          '.detail-breadcrumbs a:nth-of-type(2)': 'الطعام',
          '#restaurantBreadcrumb': 'تفاصيل المطعم',
          '#restaurantCuisine': 'مطعم',
          '#restaurantDescription': 'جار تحميل تفاصيل المطعم...',
          '#menuContainer + * .detail-section-title, .detail-section-card .detail-section-title': 'القائمة',
          '.detail-btn-primary': 'افتح السلة',
        },
      },
    },
    'food-dish-detail.html': {
      fr: {
        text: {
          '.detail-breadcrumbs a:nth-of-type(1)': 'Accueil',
          '.detail-breadcrumbs a:nth-of-type(2)': 'Restauration',
          '#dishBreadcrumb': 'Détails du plat',
          '#dishContext': 'Élément du menu',
          '#dishDescription': 'Chargement des détails du plat...',
          '#availability': 'Disponible',
          '.detail-section-card .detail-section-title': 'Détails du plat',
          '#customizationsCard .detail-section-title': 'Personnalisez votre commande',
          '.detail-purchase-card .detail-section-title': 'Quantité',
          '.detail-qty-bar > span': 'Choisissez votre portion',
          '#addCartBtn': 'Ajouter au panier',
          '#buyNowBtn': 'Commander maintenant',
        },
      },
      ar: {
        text: {
          '.detail-breadcrumbs a:nth-of-type(1)': 'الرئيسية',
          '.detail-breadcrumbs a:nth-of-type(2)': 'الطعام',
          '#dishBreadcrumb': 'تفاصيل الطبق',
          '#dishContext': 'عنصر من القائمة',
          '#dishDescription': 'جار تحميل تفاصيل الطبق...',
          '#availability': 'متوفر',
          '.detail-section-card .detail-section-title': 'تفاصيل الطبق',
          '#customizationsCard .detail-section-title': 'خصص طلبك',
          '.detail-purchase-card .detail-section-title': 'الكمية',
          '.detail-qty-bar > span': 'اختر حصتك',
          '#addCartBtn': 'أضف إلى السلة',
          '#buyNowBtn': 'اطلب الآن',
        },
      },
    },
  },

  getCurrentPageName() {
    return window.location.pathname.split('/').pop() || 'edalab-website.html';
  },

  applySelectorTextMap(map = {}, root = document) {
    Object.entries(map).forEach(([selector, value]) => {
      root.querySelectorAll(selector).forEach((element) => {
        element.textContent = value;
      });
    });
  },

  applySelectorHtmlMap(map = {}, root = document) {
    Object.entries(map).forEach(([selector, value]) => {
      root.querySelectorAll(selector).forEach((element) => {
        element.innerHTML = value;
      });
    });
  },

  applySelectorPlaceholderMap(map = {}, root = document) {
    Object.entries(map).forEach(([selector, value]) => {
      root.querySelectorAll(selector).forEach((element) => {
        element.setAttribute('placeholder', value);
      });
    });
  },

  applyPageTranslations(root = document) {
    const page = this.getCurrentPageName();
    const language = this.getLanguage();
    const config = this.pageTranslations[page]?.[language];
    if (config) {
      this.applySelectorTextMap(config.text, root);
      this.applySelectorHtmlMap(config.html, root);
      this.applySelectorPlaceholderMap(config.placeholder, root);
    }

    if (page === 'edalab-website.html' && typeof window.refreshHomepageLocalizedContent === 'function') {
      window.refreshHomepageLocalizedContent();
      if (config) {
        this.applySelectorTextMap(config.text, root);
        this.applySelectorHtmlMap(config.html, root);
        this.applySelectorPlaceholderMap(config.placeholder, root);
      }
    }

    if (typeof window.refreshPageLocalizedContent === 'function') {
      window.refreshPageLocalizedContent();
      if (config) {
        this.applySelectorTextMap(config.text, root);
        this.applySelectorHtmlMap(config.html, root);
        this.applySelectorPlaceholderMap(config.placeholder, root);
      }
    }
  },

  getImageSrc(item, fallback = 'https://via.placeholder.com/200x200') {
    return item?.imageUrl || item?.image || item?.images?.[0] || fallback;
  },

  getLanguage() {
    const forcedLanguage = document?.documentElement?.dataset?.pageLanguage;
    if (forcedLanguage && this.translations[forcedLanguage]) {
      return forcedLanguage;
    }

    const selected = stateManager?.getLanguage?.() || this.defaultLanguage;
    return this.translations[selected] ? selected : this.defaultLanguage;
  },

  t(key, fallback = '') {
    const language = this.getLanguage();
    return this.translations[language]?.[key]
      || this.translations[this.defaultLanguage]?.[key]
      || fallback
      || key;
  },

  setLanguage(language) {
    const normalized = this.translations[language] ? language : this.defaultLanguage;
    stateManager?.setLanguage?.(normalized);
    this.applyTranslations();
    return normalized;
  },

  updateDocumentLanguage(language = this.getLanguage()) {
    const isRtl = language === 'ar';
    document.documentElement.lang = language;
    document.documentElement.dir = isRtl ? 'rtl' : 'ltr';
    document.body?.classList.toggle('rtl-layout', isRtl);
  },

  applyTranslations(root = document) {
    const language = this.getLanguage();
    this.updateDocumentLanguage(language);

    root.querySelectorAll('[data-i18n]').forEach((element) => {
      const key = element.dataset.i18n;
      element.textContent = this.t(key, element.textContent.trim());
    });

    root.querySelectorAll('[data-i18n-html]').forEach((element) => {
      const key = element.dataset.i18nHtml;
      element.innerHTML = this.t(key, element.innerHTML);
    });

    root.querySelectorAll('[data-i18n-placeholder]').forEach((element) => {
      const key = element.dataset.i18nPlaceholder;
      element.setAttribute('placeholder', this.t(key, element.getAttribute('placeholder') || ''));
    });

    root.querySelectorAll('[data-i18n-title]').forEach((element) => {
      const key = element.dataset.i18nTitle;
      element.setAttribute('title', this.t(key, element.getAttribute('title') || ''));
    });

    root.querySelectorAll('[data-i18n-aria-label]').forEach((element) => {
      const key = element.dataset.i18nAriaLabel;
      element.setAttribute('aria-label', this.t(key, element.getAttribute('aria-label') || ''));
    });

    this.applyPageTranslations(root);
    clearTimeout(this._deferredPageTranslationTimer);
    this._deferredPageTranslationTimer = setTimeout(() => this.applyPageTranslations(document), 0);
  },

  getLogoMarkup() {
    return `<img src="${this.logoPath}" alt="eDalab logo">`;
  },

  // ═══ PRODUCT CARD ═══
  createProductCard(product, onAddToCart, onAddToWishlist) {
    const isInWishlist = stateManager.isInWishlist(product.id);
    const discountPercentage = product.originalPrice
      ? Math.round(
          ((product.originalPrice - product.price) / product.originalPrice) * 100
        )
      : 0;

    return `
      <div class="product-card" data-id="${product.id}" onclick="window.location.href='product-detail.html?id=${product.id}'">
        <div class="pc-image-wrapper">
          <img src="${this.getImageSrc(product)}" alt="${product.name}" class="pc-image" />
          ${discountPercentage > 0
            ? `<span class="pc-badge-discount">-${discountPercentage}%</span>`
            : ''}
          <button class="pc-wishlist-btn ${isInWishlist ? 'active' : ''}" 
                  onclick="UIComponents.handleWishlist('${product.id}', event)">
            <svg class="icon">${isInWishlist ? '❤️' : '🤍'}</svg>
          </button>
        </div>
        <div class="pc-content">
          <h3 class="pc-name">${product.name}</h3>
          <p class="pc-description">${product.description || ''}</p>
          <div class="pc-rating">
            ${
              product.rating
                ? `<span class="pc-stars">★ ${product.rating.toFixed(1)}</span>`
                : ''
            }
            ${product.reviewCount ? `<span class="pc-reviews">(${product.reviewCount})</span>` : ''}
          </div>
          <div class="pc-price">
            <span class="pc-price-current">$${product.price.toFixed(2)}</span>
            ${
              product.originalPrice
                ? `<span class="pc-price-original">$${product.originalPrice.toFixed(2)}</span>`
                : ''
            }
          </div>
          <button class="pc-add-btn" onclick="UIComponents.handleAddToCart('${product.id}', event)">
            Add to Cart
          </button>
        </div>
      </div>
    `;
  },

  // ═══ RESTAURANT CARD ═══
  createRestaurantCard(restaurant) {
    return `
      <div class="restaurant-card" onclick="window.location.href='restaurant-detail.html?id=${restaurant.id}'">
        <div class="rc-image">
          <img src="${this.getImageSrc(restaurant, 'https://via.placeholder.com/300x200')}" alt="${restaurant.name}" />
          ${restaurant.badge ? `<span class="rc-badge">${restaurant.badge}</span>` : ''}
          <div class="rc-status ${restaurant.isOpen ? 'open' : 'closed'}">
            ${restaurant.isOpen ? 'Open' : 'Closed'}
          </div>
        </div>
        <div class="rc-content">
          <h3 class="rc-name">${restaurant.name}</h3>
          <p class="rc-cuisine">${restaurant.cuisine || restaurant.type || 'Restaurant'}</p>
          <div class="rc-meta">
            <span class="rc-rating">★ ${restaurant.rating || 4.5}</span>
            <span class="rc-time">⏱ ${restaurant.deliveryTime || '30-40'} min</span>
            <span class="rc-fee">🚚 $${restaurant.deliveryFee || 2.50}</span>
          </div>
        </div>
      </div>
    `;
  },

  // ═══ DOCTOR CARD ═══
  createDoctorCard(doctor) {
    return `
      <div class="doctor-card" onclick="navigateTo('/doctor/${doctor.id}')">
        <div class="dc-image">
          <img src="${this.getImageSrc(doctor, 'assets/icons/doctor.png')}" alt="${doctor.name}" />
          ${doctor.isVerified ? '<span class="dc-verified">✓</span>' : ''}
          ${doctor.isAvailable ? '<span class="dc-available">Available</span>' : '<span class="dc-unavailable">Unavailable</span>'}
        </div>
        <div class="dc-content">
          <h3 class="dc-name">${doctor.name}</h3>
          <p class="dc-specialty">${doctor.specialty}</p>
          <p class="dc-experience">${doctor.experience} experience</p>
          <div class="dc-rating">
            <span class="dc-stars">★ ${doctor.rating.toFixed(1)}</span>
            <span class="dc-reviews">(${doctor.reviewCount} reviews)</span>
          </div>
          <div class="dc-fee">Consultation: $${doctor.consultationFee}</div>
          <button class="dc-book-btn" onclick="navigateTo('/book-appointment/${doctor.id}'); event.stopPropagation();">
            Book Now
          </button>
        </div>
      </div>
    `;
  },

  // ═══ HOTEL CARD ═══
  createHotelCard(hotel) {
    return `
      <div class="hotel-card" onclick="navigateTo('/hotel/${hotel.id}')">
        <div class="hc-image">
          <img src="${this.getImageSrc(hotel, 'https://via.placeholder.com/300x200')}" alt="${hotel.name}" />
          <span class="hc-rating">★ ${hotel.rating}</span>
        </div>
        <div class="hc-content">
          <h3 class="hc-name">${hotel.name}</h3>
          <p class="hc-location">📍 ${hotel.location}</p>
          <p class="hc-description">${hotel.description || ''}</p>
          <div class="hc-amenities">
            ${(hotel.amenities || [])
              .slice(0, 3)
              .map((a) => `<span class="hc-amenity">${a}</span>`)
              .join('')}
          </div>
          <div class="hc-price">
            <span class="hc-price-from">From</span>
            <span class="hc-price-value">$${hotel.pricePerNight}/night</span>
          </div>
          <button class="hc-book-btn">Book Now</button>
        </div>
      </div>
    `;
  },

  // ═══ MODAL ═══
  createModal(id, title, content, actions = []) {
    const actionButtons = actions
      .map(
        (a) =>
          `<button class="modal-btn ${a.variant || 'secondary'}" onclick="${a.onclick}">${a.label}</button>`
      )
      .join('');

    return `
      <div class="modal-overlay" id="${id}-overlay" onclick="UIComponents.closeModal('${id}')">
        <div class="modal" onclick="event.stopPropagation()">
          <div class="modal-header">
            <h2>${title}</h2>
            <button class="modal-close" onclick="UIComponents.closeModal('${id}')">✕</button>
          </div>
          <div class="modal-body">
            ${content}
          </div>
          <div class="modal-actions">
            ${actionButtons}
          </div>
        </div>
      </div>
    `;
  },

  showModal(id) {
    const overlay = document.getElementById(`${id}-overlay`);
    if (overlay) {
      overlay.style.display = 'flex';
    }
  },

  closeModal(id) {
    const overlay = document.getElementById(`${id}-overlay`);
    if (overlay) {
      overlay.style.display = 'none';
    }
  },

  // ═══ LOADING SKELETON ═══
  createSkeleton(type = 'card', count = 3) {
    let skeleton = '';
    for (let i = 0; i < count; i++) {
      skeleton += `
        <div class="skeleton skeleton-${type}">
          ${type === 'card'
            ? `
            <div class="skeleton-line skeleton-image"></div>
            <div class="skeleton-line" style="width: 80%;"></div>
            <div class="skeleton-line" style="width: 60%;"></div>
          `
            : ''}
        </div>
      `;
    }
    return skeleton;
  },

  createSearchSkeleton() {
    return `
      <div class="module-skeleton-search" aria-hidden="true">
        <div class="module-skeleton-block module-skeleton-input"></div>
        <div class="module-skeleton-block module-skeleton-button"></div>
      </div>
    `;
  },

  createFilterSkeleton(count = 3) {
    return `
      <div class="module-skeleton-filter-grid" aria-hidden="true">
        ${Array.from({ length: count }, () => `
          <div class="module-skeleton-group">
            <div class="module-skeleton-block module-skeleton-line sm" style="width: 42%;"></div>
            <div class="module-skeleton-block module-skeleton-input"></div>
          </div>
        `).join('')}
      </div>
    `;
  },

  createCategorySkeleton(count = 6) {
    return Array.from({ length: count }, () => `
      <div class="module-skeleton-category-card" aria-hidden="true">
        <div class="module-skeleton-block module-skeleton-category-icon"></div>
        <div class="module-skeleton-block module-skeleton-title"></div>
        <div class="module-skeleton-block module-skeleton-text short" style="margin-top: 12px;"></div>
      </div>
    `).join('');
  },

  createCardGridSkeleton(count = 6) {
    return Array.from({ length: count }, () => `
      <div class="module-skeleton-card" aria-hidden="true">
        <div class="module-skeleton-block module-skeleton-media"></div>
        <div class="module-skeleton-block module-skeleton-title"></div>
        <div class="module-skeleton-block module-skeleton-text mid" style="margin-top: 12px;"></div>
        <div class="module-skeleton-meta">
          <div class="module-skeleton-block module-skeleton-line"></div>
          <div class="module-skeleton-block module-skeleton-line"></div>
          <div class="module-skeleton-block module-skeleton-line"></div>
        </div>
        <div class="module-skeleton-block module-skeleton-cta"></div>
      </div>
    `).join('');
  },

  createChoiceSkeleton(count = 3) {
    return Array.from({ length: count }, () => `
      <div class="module-skeleton-choice-card" aria-hidden="true">
        <div class="module-skeleton-block module-skeleton-category-icon"></div>
        <div class="module-skeleton-block module-skeleton-title"></div>
        <div class="module-skeleton-block module-skeleton-text short" style="margin-top: 12px;"></div>
      </div>
    `).join('');
  },

  createListSkeleton(count = 3) {
    return Array.from({ length: count }, () => `
      <div class="module-skeleton-list-item" aria-hidden="true">
        <div class="module-skeleton-list-meta">
          <div class="module-skeleton-block module-skeleton-title"></div>
          <div class="module-skeleton-block module-skeleton-text mid"></div>
          <div class="module-skeleton-block module-skeleton-text short"></div>
        </div>
        <div class="module-skeleton-block module-skeleton-button"></div>
      </div>
    `).join('');
  },

  // ═══ SEARCH BAR ═══
  createSearchBar(id, placeholder = 'Search...', onSearch) {
    return `
      <div class="search-bar">
        <input type="text" id="${id}" class="search-input" placeholder="${placeholder}" />
        <button class="search-btn" onclick="${onSearch}">🔍</button>
      </div>
    `;
  },

  // ═══ FILTER BAR ═══
  createFilterBar(filters) {
    return `
      <div class="filter-bar">
        ${filters
          .map(
            (f, i) =>
              `
          <button class="filter-chip ${i === 0 ? 'active' : ''}" data-filter="${f}">
            ${f}
          </button>
        `
          )
          .join('')}
      </div>
    `;
  },

  // ═══ PAGINATION ═══
  createPagination(currentPage, totalPages, onPageChange) {
    let html = '<div class="pagination">';

    if (currentPage > 1) {
      html += `<button class="page-btn" onclick="${onPageChange}(${currentPage - 1})">← Prev</button>`;
    }

    for (let i = 1; i <= totalPages; i++) {
      if (i === currentPage) {
        html += `<span class="page-current">${i}</span>`;
      } else {
        html += `<button class="page-btn" onclick="${onPageChange}(${i})">${i}</button>`;
      }
    }

    if (currentPage < totalPages) {
      html += `<button class="page-btn" onclick="${onPageChange}(${currentPage + 1})">Next →</button>`;
    }

    html += '</div>';
    return html;
  },

  // ═══ CART ITEM ═══
  createCartItem(item, module) {
    return `
      <div class="cart-item" data-id="${item.id}">
        <img src="${this.getImageSrc(item, 'https://via.placeholder.com/80x80')}" alt="${item.name}" class="cart-item-image" />
        <div class="cart-item-details">
          <h4>${item.name}</h4>
          <p class="cart-item-brand">${item.brand || item.restaurant || 'eDaLab'}</p>
          <div class="cart-item-price">$${item.price.toFixed(2)}</div>
        </div>
        <div class="cart-item-controls">
          <button class="quantity-btn" onclick="stateManager.updateCartItemQuantity('${item.id}', ${item.quantity - 1}, '${module}')">−</button>
          <span class="quantity">${item.quantity}</span>
          <button class="quantity-btn" onclick="stateManager.updateCartItemQuantity('${item.id}', ${item.quantity + 1}, '${module}')">+</button>
        </div>
        <div class="cart-item-total">$${(item.price * item.quantity).toFixed(2)}</div>
        <button class="remove-btn" onclick="stateManager.removeFromCart('${item.id}', '${module}')">🗑</button>
      </div>
    `;
  },

  // ═══ TOAST NOTIFICATION ═══
  showToast(message, type = 'info', duration = 3000) {
    const id = `toast-${Date.now()}`;
    const toast = document.createElement('div');
    toast.id = id;
    toast.className = `toast toast-${type}`;
    toast.textContent = message;
    document.body.appendChild(toast);

    setTimeout(() => {
      toast.classList.add('show');
    }, 10);

    setTimeout(() => {
      toast.classList.remove('show');
      setTimeout(() => {
        document.body.removeChild(toast);
      }, 300);
    }, duration);
  },

  // ═══ EVENT HANDLERS ═══

  handleAddToCart(productId, event) {
    event.stopPropagation();
    const product = window.currentProducts?.find((p) => p.id === productId);
    if (product) {
      const moduleName = stateManager.resolveCartModule(product);
      stateManager.addToCart(product, 1, moduleName);
      this.showToast(`${product.name} added to cart!`, 'success');
    }
  },

  handleWishlist(productId, event) {
    event.stopPropagation();
    const product = window.currentProducts?.find((p) => p.id === productId);
    if (product) {
      if (stateManager.isInWishlist(productId)) {
        stateManager.removeFromWishlist(productId);
        this.showToast('Removed from wishlist', 'info');
      } else {
        stateManager.addToWishlist(product);
        this.showToast('Added to wishlist!', 'success');
      }
    }
  },

  getPostAuthRedirect() {
    try {
      const params = new URLSearchParams(window.location.search);
      return params.get('next') || localStorage.getItem('edaLabPostAuthRedirect') || '';
    } catch (error) {
      return localStorage.getItem('edaLabPostAuthRedirect') || '';
    }
  },

  consumePostAuthRedirect(fallback = 'profile.html') {
    const next = this.getPostAuthRedirect();
    localStorage.removeItem('edaLabPostAuthRedirect');
    return next || fallback;
  },

  requireAuth(options = {}) {
    const {
      message = 'Please log in first.',
      redirectTo = 'login.html',
      next = `${window.location.pathname.split('/').pop() || 'profile.html'}${window.location.search || ''}`,
      delay = 300,
    } = options;
    const user = stateManager.getUser();

    if (user?.id) {
      return user;
    }

    if (next) {
      localStorage.setItem('edaLabPostAuthRedirect', next);
    }

    this.showToast(message, 'info');
    setTimeout(() => {
      window.location.href = `${redirectTo}?next=${encodeURIComponent(next)}`;
    }, delay);
    return null;
  },

  syncAuthNav(options = {}) {
    const {
      containerSelector = '.nav-right',
      mode = 'cart',
      cartCountId = 'cart-count',
      cartLabel = this.t('nav.cart', 'Cart'),
      loginLabel = this.t('nav.login', 'Login'),
      registerLabel = this.t('nav.register', 'Register'),
      profileLabel = this.t('nav.profile', 'Profile'),
      logoutLabel = this.t('nav.logout', 'Logout'),
      appLabel = this.t('nav.register', 'Register'),
      loginHref = 'login.html',
      registerHref = 'register.html',
      profileHref = 'profile.html',
      cartHref = 'cart.html',
      logoutRedirect = `${window.location.pathname.split('/').pop() || 'edalab-website.html'}${window.location.search || ''}`,
    } = options;

    const container = document.querySelector(containerSelector);
    if (!container) return;

    const logo = document.querySelector('.nav-logo');
    if (logo) {
      if (logo.tagName !== 'A') {
        const anchor = document.createElement('a');
        anchor.className = logo.className;
        anchor.href = 'edalab-website.html';
        anchor.innerHTML = logo.innerHTML;
        logo.replaceWith(anchor);
      } else {
        logo.setAttribute('href', 'edalab-website.html');
      }

      const logoText = document.querySelector('.nav-logo span');
      if (logoText) {
        logoText.textContent = 'eDalab';
      }

      const logoIcon = document.querySelector('.nav-logo-icon');
      if (logoIcon) {
        logoIcon.innerHTML = this.getLogoMarkup();
      }
    }

    const user = stateManager.getUser();
    const existingCount = document.getElementById(cartCountId)?.textContent?.trim() || '';

    if (mode === 'profile') {
      container.innerHTML = user?.id
        ? `
          <button class="n-ghost" data-auth-action="logout">${logoutLabel}</button>
          <button class="n-solid" data-auth-action="profile">👤 ${profileLabel}</button>
        `
        : `
          <button class="n-ghost" data-auth-action="login">${loginLabel}</button>
          <button class="n-solid" data-auth-action="register">✨ ${registerLabel}</button>
        `;
    } else if (mode === 'app') {
      container.innerHTML = user?.id
        ? `
          <button class="n-ghost" data-auth-action="logout">${logoutLabel}</button>
          <button class="n-solid" data-auth-action="profile">👤 ${profileLabel}</button>
        `
        : `
          <button class="n-ghost" data-auth-action="login">${loginLabel}</button>
          <button class="n-solid" data-auth-action="register">✨ ${appLabel}</button>
        `;
    } else {
      container.innerHTML = user?.id
        ? `
          <button class="n-ghost" data-auth-action="profile">👤 ${profileLabel}</button>
          <button class="n-solid" data-auth-action="cart">🛒 ${cartLabel} <span id="${cartCountId}">${existingCount}</span></button>
        `
        : `
          <button class="n-ghost" data-auth-action="login">${loginLabel}</button>
          <button class="n-solid" data-auth-action="cart">🛒 ${cartLabel} <span id="${cartCountId}">${existingCount}</span></button>
        `;
    }

    container.querySelector('[data-auth-action="login"]')?.addEventListener('click', () => {
      window.location.href = loginHref;
    });

    container.querySelector('[data-auth-action="register"]')?.addEventListener('click', () => {
      window.location.href = registerHref;
    });

    container.querySelector('[data-auth-action="profile"]')?.addEventListener('click', () => {
      window.location.href = profileHref;
    });

    container.querySelector('[data-auth-action="cart"]')?.addEventListener('click', () => {
      window.location.href = cartHref;
    });

    container.querySelector('[data-auth-action="logout"]')?.addEventListener('click', () => {
      StateManager.logout();
      this.showToast(this.t('nav.logout', 'Logout'), 'success');
      setTimeout(() => {
        window.location.href = logoutRedirect;
      }, 250);
    });
  },

  updateUnifiedNavbarBadges(options = {}) {
    const {
      cartCountId = 'navCartCount',
      wishlistCountId = 'navWishlistCount',
    } = options;
    const cartCount = stateManager.getCartCount();
    const wishlistCount = stateManager.getWishlist().length;
    const cartBadge = document.getElementById(cartCountId) || document.querySelector('[data-nav-badge="cart"]');
    const wishlistBadge = document.getElementById(wishlistCountId) || document.querySelector('[data-nav-badge="wishlist"]');

    if (cartBadge) {
      cartBadge.textContent = cartCount;
      cartBadge.classList.toggle('is-empty', cartCount === 0);
    }

    if (wishlistBadge) {
      wishlistBadge.textContent = wishlistCount;
      wishlistBadge.classList.toggle('is-empty', wishlistCount === 0);
    }
  },

  getUnifiedNavbarMarkup(options = {}) {
    const {
      cartCountId = 'navCartCount',
      wishlistCountId = 'navWishlistCount',
    } = options;
    const links = [
      { key: 'home', label: this.t('nav.home', 'Home'), href: 'edalab-website.html' },
      { key: 'food', label: this.t('nav.food', 'Food'), href: 'food.html' },
      { key: 'shopping', label: this.t('nav.shopping', 'Shopping'), href: 'shopping.html' },
      { key: 'pharmacy', label: this.t('nav.pharmacy', 'Pharmacy'), href: 'pharmacy.html' },
      { key: 'doctor', label: this.t('nav.doctor', 'Doctor'), href: 'doctor.html' },
      { key: 'hotel', label: this.t('nav.hotel', 'Hotel'), href: 'hotel.html' },
      { key: 'ride', label: this.t('nav.ride', 'Ride'), href: 'ride.html' },
      { key: 'services', label: this.t('nav.services', 'Services'), href: 'home-services.html' },
      { key: 'laundry', label: this.t('nav.laundry', 'Laundry'), href: 'laundry.html' },
    ];

    return `
      <div class="nav-w nav-w-unified">
        <a class="nav-logo" href="edalab-website.html">
          <div class="nav-logo-icon">
            ${this.getLogoMarkup()}
          </div>
          <span>eDalab</span>
        </a>
        <div class="nav-links nav-links-unified">
          ${links.map((link) => `
            <a href="${link.href}" class="nav-a" data-nav-link="${link.key}">${link.label}</a>
          `).join('')}
        </div>
        <div class="nav-right nav-right-unified">
          <div class="nav-quick-actions">
            <a href="wishlist.html" class="nav-icon-btn" aria-label="Wishlist">
              <span class="nav-icon-symbol">♡</span>
              <span class="nav-icon-label">${this.t('nav.wishlist', 'Wishlist')}</span>
              <span class="nav-badge is-empty" id="${wishlistCountId}" data-nav-badge="wishlist">0</span>
            </a>
            <a href="cart.html" class="nav-icon-btn" aria-label="Cart">
              <span class="nav-icon-symbol">🛒</span>
              <span class="nav-icon-label">${this.t('nav.cart', 'Cart')}</span>
              <span class="nav-badge is-empty" id="${cartCountId}" data-nav-badge="cart">0</span>
            </a>
          </div>
          <div class="nav-auth-slot"></div>
        </div>
      </div>
    `;
  },

  inferUnifiedNavbarActive() {
    const currentPage = window.location.pathname.split('/').pop() || 'edalab-website.html';
    const routeMap = {
      'edalab-website.html': 'home',
      'food.html': 'food',
      'restaurant-detail.html': 'food',
      'shopping.html': 'shopping',
      'product-detail.html': 'shopping',
      'pharmacy.html': 'pharmacy',
      'doctor.html': 'doctor',
      'hotel.html': 'hotel',
      'ride.html': 'ride',
      'home-services.html': 'services',
      'laundry.html': 'laundry',
    };

    return routeMap[currentPage] || '';
  },

  getUnifiedNavbarOptions(options = {}) {
    const nav = document.getElementById('nav');
    const currentPage = window.location.pathname.split('/').pop() || 'edalab-website.html';

    return {
      active: nav?.dataset.navActive || this.inferUnifiedNavbarActive(),
      cartCountId: nav?.dataset.cartCountId || 'navCartCount',
      wishlistCountId: nav?.dataset.wishlistCountId || 'navWishlistCount',
      offsetBody: nav?.dataset.navOffset === 'true',
      logoutRedirect: `${currentPage}${window.location.search || ''}`,
      ...options,
    };
  },

  mountUnifiedNavbar(options = {}) {
    const nav = document.getElementById('nav');
    if (!nav) return;

    const normalizedOptions = this.getUnifiedNavbarOptions(options);

    document.body.classList.toggle('has-unified-nav-offset', !!normalizedOptions.offsetBody);
    if (!nav.dataset.staticUnified && !nav.children.length) {
      nav.innerHTML = this.getUnifiedNavbarMarkup(normalizedOptions);
    }

    nav.querySelectorAll('[data-nav-link]').forEach((link) => {
      const key = link.dataset.navLink;
      if (key) {
        link.textContent = this.t(`nav.${key}`, link.textContent.trim());
      }
    });

    nav.querySelectorAll('.nav-icon-btn').forEach((button) => {
      const href = button.getAttribute('href') || '';
      if (href.includes('wishlist')) {
        button.setAttribute('aria-label', this.t('nav.wishlist', 'Wishlist'));
        const label = button.querySelector('.nav-icon-label');
        if (label) label.textContent = this.t('nav.wishlist', label.textContent.trim());
      }
      if (href.includes('cart')) {
        button.setAttribute('aria-label', this.t('nav.cart', 'Cart'));
        const label = button.querySelector('.nav-icon-label');
        if (label) label.textContent = this.t('nav.cart', label.textContent.trim());
      }
    });

    nav.querySelectorAll('[data-nav-link]').forEach((link) => {
      link.classList.toggle('on', link.dataset.navLink === normalizedOptions.active);
    });

    this.syncAuthNav({
      containerSelector: '#nav .nav-auth-slot',
      mode: 'profile',
      loginLabel: this.t('nav.login', 'Login'),
      registerLabel: this.t('nav.register', 'Register'),
      profileLabel: this.t('nav.profile', 'Profile'),
      logoutLabel: this.t('nav.logout', 'Logout'),
      logoutRedirect: normalizedOptions.logoutRedirect,
    });

    this.updateUnifiedNavbarBadges(normalizedOptions);

    window.__edaUnifiedNavState = normalizedOptions;
    if (!window.__edaUnifiedNavBound) {
      stateManager.subscribe('auth', () => this.syncAuthNav({
        containerSelector: '#nav .nav-auth-slot',
        mode: 'profile',
        loginLabel: this.t('nav.login', 'Login'),
        registerLabel: this.t('nav.register', 'Register'),
        profileLabel: this.t('nav.profile', 'Profile'),
        logoutLabel: this.t('nav.logout', 'Logout'),
        logoutRedirect: (window.__edaUnifiedNavState || normalizedOptions).logoutRedirect,
      }));
      stateManager.subscribe('preferences', () => {
        this.mountUnifiedNavbar(window.__edaUnifiedNavState || normalizedOptions);
        this.applyTranslations();
      });
      stateManager.subscribe('cart', () => this.updateUnifiedNavbarBadges(window.__edaUnifiedNavState || normalizedOptions));
      stateManager.subscribe('wishlist', () => this.updateUnifiedNavbarBadges(window.__edaUnifiedNavState || normalizedOptions));
      window.__edaUnifiedNavBound = true;
    }
  },

  bootUnifiedNavbar() {
    const nav = document.getElementById('nav');
    if (!nav || window.__edaUnifiedNavBooted) return;
    window.__edaUnifiedNavBooted = true;
    this.mountUnifiedNavbar();
  },
};

// Navigation helper
function navigateTo(path) {
  const normalized = normalizeWebPath(path);
  window.location.href = normalized;
}

function normalizeWebPath(path) {
  if (!path) return 'edalab-website.html';
  if (!path.startsWith('/')) return path;

  const routePatterns = [
    [/^\/$/, 'edalab-website.html'],
    [/^\/login$/, 'login.html'],
    [/^\/messages$/, 'profile.html'],
    [/^\/doctor\/appointments$/, 'orders.html'],
    [/^\/order-detail\/([^/]+)$/, 'tracking.html?orderId=$1'],
    [/^\/food\/tracking\/([^/]+)$/, 'tracking.html?orderId=$1'],
    [/^\/ride\/tracking\/([^/]+)$/, 'tracking.html?rideId=$1'],
    [/^\/doctor\/([^/]+)$/, 'doctor.html?doctorId=$1'],
    [/^\/book-appointment\/([^/]+)$/, 'doctor.html?doctorId=$1&book=1'],
    [/^\/hotel\/([^/]+)$/, 'hotel.html?hotelId=$1'],
  ];

  for (const [pattern, replacement] of routePatterns) {
    if (pattern.test(path)) {
      return path.replace(pattern, replacement);
    }
  }

  return 'edalab-website.html';
}

// Debounce helper for search
function debounce(func, delay) {
  let timeoutId;
  return function (...args) {
    clearTimeout(timeoutId);
    timeoutId = setTimeout(() => func.apply(this, args), delay);
  };
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    UIComponents.bootUnifiedNavbar();
    UIComponents.applyTranslations();
  }, { once: true });
} else {
  UIComponents.bootUnifiedNavbar();
  UIComponents.applyTranslations();
}
