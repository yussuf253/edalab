class AnalyticsEvents {
  AnalyticsEvents._();

  static const appOpened = 'app_opened';
  static const appResumed = 'app_resumed';
  static const screenViewed = 'screen_viewed';
  static const navigationTransition = 'navigation_transition';

  static const navigationTabTapped = 'navigation_tab_tapped';
  static const catalogResultsLoaded = 'catalog_results_loaded';
  static const searchPerformed = 'search_performed';
  static const filterApplied = 'filter_applied';
  static const sortApplied = 'sort_applied';
  static const entityOpened = 'entity_opened';
  static const wishlistToggled = 'wishlist_toggled';
  static const viewCartTapped = 'view_cart_tapped';
  static const checkoutEntryTapped = 'checkout_entry_tapped';
  static const cartTipChanged = 'cart_tip_changed';
  static const cartAdjustmentInitiated = 'cart_adjustment_initiated';

  static const authLoginAttempted = 'auth_login_attempted';
  static const authLoginSucceeded = 'auth_login_succeeded';
  static const authLoginFailed = 'auth_login_failed';
  static const authRegisterAttempted = 'auth_register_attempted';
  static const authRegisterSucceeded = 'auth_register_succeeded';
  static const authRegisterFailed = 'auth_register_failed';
  static const authSessionRestored = 'auth_session_restored';
  static const authSessionRestoreFailed = 'auth_session_restore_failed';
  static const authLoggedOut = 'auth_logged_out';

  static const profileUpdated = 'profile_updated';
  static const profileUpdateFailed = 'profile_update_failed';
  static const addressAdded = 'address_added';
  static const addressAddFailed = 'address_add_failed';
  static const addressUpdated = 'address_updated';
  static const addressUpdateFailed = 'address_update_failed';
  static const addressDeleted = 'address_deleted';
  static const addressDeleteFailed = 'address_delete_failed';
  static const addressDefaultSet = 'address_default_set';
  static const addressDefaultSetFailed = 'address_default_set_failed';

  static const languageChanged = 'language_changed';
  static const themeChanged = 'theme_changed';

  static const cartHydrated = 'cart_hydrated';
  static const cartItemAdded = 'cart_item_added';
  static const cartItemRemoved = 'cart_item_removed';
  static const cartItemQuantityChanged = 'cart_item_quantity_changed';
  static const cartPromoApplied = 'cart_promo_applied';
  static const cartPromoRejected = 'cart_promo_rejected';
  static const cartPromoRemoved = 'cart_promo_removed';
  static const cartModuleCleared = 'cart_module_cleared';
  static const cartCleared = 'cart_cleared';

  static const orderSubmitAttempted = 'order_submit_attempted';
  static const orderSubmitSucceeded = 'order_submit_succeeded';
  static const orderSubmitFailed = 'order_submit_failed';

  static const checkoutViewed = 'checkout_viewed';
  static const checkoutPlaceOrderTapped = 'checkout_place_order_tapped';
  static const checkoutValidationFailed = 'checkout_validation_failed';
  static const checkoutCompleted = 'checkout_completed';

  static const orderSuccessViewed = 'order_success_viewed';
  static const orderSuccessTrackTapped = 'order_success_track_tapped';
  static const orderSuccessBackHomeTapped = 'order_success_back_home_tapped';
}
