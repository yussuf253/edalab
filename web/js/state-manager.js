/**
 * State Management & Local Storage
 * Handles cart, auth, preferences, and other app state
 */

class StateManager {
  constructor() {
    this.listeners = new Map();
    this.state = {
      auth: this.loadAuth(),
      cart: this.loadCart(),
      wishlist: this.loadWishlist(),
      preferences: this.loadPreferences(),
      orders: this.loadOrders(),
      discount: this.loadDiscount(),
    };
  }

  // ═══ STATE MANAGEMENT ═══

  subscribe(key, callback) {
    if (!this.listeners.has(key)) {
      this.listeners.set(key, []);
    }
    this.listeners.get(key).push(callback);
    return () => {
      const callbacks = this.listeners.get(key);
      callbacks.splice(callbacks.indexOf(callback), 1);
    };
  }

  notify(key) {
    const callbacks = this.listeners.get(key) || [];
    callbacks.forEach((cb) => cb(this.state[key]));
  }

  // ═══ AUTH STATE ═══

  setUser(user) {
    const normalizedUser = this.normalizeUser(user);
    this.state.auth = normalizedUser;
    this.saveAuth(normalizedUser);
    this.notify('auth');
  }

  getUser() {
    return this.state.auth;
  }

  isAuthenticated() {
    return this.state.auth && this.state.auth.id;
  }

  logout() {
    this.state.auth = null;
    localStorage.removeItem('edaLabAuth');
    this.notify('auth');
  }

  loadAuth() {
    const stored = localStorage.getItem('edaLabAuth');
    return stored ? JSON.parse(stored) : null;
  }

  saveAuth(auth) {
    if (auth) {
      localStorage.setItem('edaLabAuth', JSON.stringify(auth));
    } else {
      localStorage.removeItem('edaLabAuth');
    }
  }

  // ═══ CART STATE ═══

  addToCart(item, quantity = 1, module = 'shopping') {
    const resolvedModule = this.resolveCartModule(item, module);
    const normalizedItem = this.normalizeCartItem(item, quantity, resolvedModule);

    if (!this.state.cart[resolvedModule]) {
      this.state.cart[resolvedModule] = [];
    }

    const existingItem = this.state.cart[resolvedModule].find(
      (i) =>
        i.id === normalizedItem.id ||
        (i.productId && normalizedItem.productId && i.productId === normalizedItem.productId)
    );

    if (existingItem) {
      existingItem.quantity += normalizedItem.quantity;
    } else {
      this.state.cart[resolvedModule].push(normalizedItem);
    }

    this.saveCart();
    this.notify('cart');
  }

  removeFromCart(itemId, module = 'shopping') {
    if (this.state.cart[module]) {
      this.state.cart[module] = this.state.cart[module].filter(
        (i) => i.id !== itemId
      );
      this.saveCart();
      this.notify('cart');
    }
  }

  updateCartItemQuantity(itemId, quantity, module = 'shopping') {
    if (this.state.cart[module]) {
      const item = this.state.cart[module].find((i) => i.id === itemId);
      if (item) {
        item.quantity = Math.max(1, quantity);
        this.saveCart();
        this.notify('cart');
      }
    }
  }

  clearCart(module) {
    if (module) {
      this.state.cart[module] = [];
    } else {
      this.state.cart = {};
    }
    this.saveCart();
    this.notify('cart');
  }

  getCart(module) {
    if (!module) {
      return Object.values(this.state.cart).flat();
    }
    return this.state.cart[this.normalizeModuleName(module)] || [];
  }

  getCartSubtotal(module) {
    return this.getCart(module).reduce(
      (sum, item) => sum + (item.price || 0) * (item.quantity || 0),
      0
    );
  }

  getCartCount(module = null) {
    return this.getCart(module).reduce(
      (sum, item) => sum + (item.quantity || 0),
      0
    );
  }

  loadCart() {
    const stored = localStorage.getItem('edaLabCart');
    return stored ? JSON.parse(stored) : {};
  }

  saveCart() {
    localStorage.setItem('edaLabCart', JSON.stringify(this.state.cart));
  }

  // ═══ WISHLIST STATE ═══

  addToWishlist(item) {
    if (!this.state.wishlist.find((i) => i.id === item.id)) {
      this.state.wishlist.push({
        ...item,
        addedAt: new Date().toISOString(),
      });
      this.saveWishlist();
      this.notify('wishlist');
    }
  }

  removeFromWishlist(itemId) {
    this.state.wishlist = this.state.wishlist.filter(
      (i) => i.id !== itemId
    );
    this.saveWishlist();
    this.notify('wishlist');
  }

  isInWishlist(itemId) {
    return this.state.wishlist.some((i) => i.id === itemId);
  }

  getWishlist() {
    return this.state.wishlist;
  }

  loadWishlist() {
    const stored = localStorage.getItem('edaLabWishlist');
    return stored ? JSON.parse(stored) : [];
  }

  saveWishlist() {
    localStorage.setItem('edaLabWishlist', JSON.stringify(this.state.wishlist));
  }

  // ═══ PREFERENCES ═══

  setPreference(key, value) {
    this.state.preferences[key] = value;
    this.savePreferences();
    this.notify('preferences');
  }

  getPreference(key, defaultValue = null) {
    return this.state.preferences[key] ?? defaultValue;
  }

  setLanguage(language) {
    this.setPreference('language', language);
  }

  getLanguage() {
    return this.getPreference('language', 'en');
  }

  setTheme(theme) {
    this.setPreference('theme', theme);
  }

  getTheme() {
    return this.getPreference('theme', 'light');
  }

  loadPreferences() {
    const stored = localStorage.getItem('edaLabPreferences');
    return stored ? JSON.parse(stored) : {};
  }

  savePreferences() {
    localStorage.setItem(
      'edaLabPreferences',
      JSON.stringify(this.state.preferences)
    );
  }

  // ═══ ORDERS & CHECKOUT ═══

  getOrders() {
    return this.state.orders;
  }

  setOrders(orders) {
    this.state.orders = Array.isArray(orders) ? orders : [];
    this.saveOrders();
    this.notify('orders');
  }

  addOrder(order) {
    this.state.orders = this.state.orders.filter((entry) => entry.id !== order.id);
    this.state.orders.unshift({
      ...order,
      createdAt: order.createdAt || new Date().toISOString(),
      updatedAt: order.updatedAt || new Date().toISOString(),
    });
    this.saveOrders();
    this.notify('orders');
  }

  loadOrders() {
    const stored = localStorage.getItem('edaLabOrders');
    return stored ? JSON.parse(stored) : [];
  }

  saveOrders() {
    localStorage.setItem('edaLabOrders', JSON.stringify(this.state.orders));
  }

  getDiscount() {
    return Number(this.state.discount || 0);
  }

  setDiscount(value) {
    this.state.discount = Number(value || 0);
    this.saveDiscount();
    this.notify('discount');
  }

  loadDiscount() {
    const stored = localStorage.getItem('edaLabDiscount');
    return stored ? Number(stored) : 0;
  }

  saveDiscount() {
    localStorage.setItem('edaLabDiscount', String(this.state.discount || 0));
  }

  // ═══ NORMALIZATION HELPERS ═══

  normalizeModuleName(module) {
    const value = String(module || '').trim().toLowerCase();
    const aliasMap = {
      shop: 'shopping',
      shopping: 'shopping',
      food: 'food',
      pharmacy: 'pharmacy',
      hotel: 'hotel',
      doctor: 'doctor',
      ride: 'ride',
      laundry: 'laundry',
      'home-services': 'home-services',
      home_services: 'home-services',
      homeservices: 'home-services',
      grocery: 'grocery',
    };

    return aliasMap[value] || value || 'shopping';
  }

  resolveCartModule(item, module) {
    if (module && module !== 'shopping') {
      return this.normalizeModuleName(module);
    }

    const moduleType = item?.moduleType || item?.module || item?.entryType;
    if (moduleType) {
      return this.normalizeModuleName(moduleType);
    }

    return 'shopping';
  }

  getItemImage(item) {
    return (
      item?.imageUrl ||
      item?.image ||
      item?.images?.[0] ||
      ''
    );
  }

  normalizeCartItem(item, quantity, module) {
    return {
      ...item,
      module,
      moduleType: item?.moduleType || module,
      productId: item?.productId || item?.dishId || item?.id,
      image: this.getItemImage(item),
      imageUrl: this.getItemImage(item),
      quantity: Number(item?.quantity || quantity || 1),
      addedAt: item?.addedAt || new Date().toISOString(),
    };
  }

  normalizeUser(user) {
    if (!user) return null;

    const addresses = Array.isArray(user.addresses)
      ? user.addresses.map((address) => ({
          ...address,
          type: address.type || address.label || 'home',
          street: address.street || address.address || address.line1 || '',
          city: address.city || '',
          zip: address.zip || address.zipCode || address.postalCode || '',
        }))
      : [];

    return {
      ...user,
      addresses,
      payments: Array.isArray(user.payments) ? user.payments : [],
      settings: user.settings || {},
    };
  }
}

// Export singleton instance
const stateManager = new StateManager();

// Backwards-compatible static facade used by several pages.
[
  'getUser',
  'setUser',
  'isAuthenticated',
  'logout',
  'addToCart',
  'removeFromCart',
  'updateCartItemQuantity',
  'clearCart',
  'getCart',
  'getCartSubtotal',
  'getCartCount',
  'addToWishlist',
  'removeFromWishlist',
  'isInWishlist',
  'getWishlist',
  'setPreference',
  'getPreference',
  'setLanguage',
  'getLanguage',
  'setTheme',
  'getTheme',
  'getOrders',
  'setOrders',
  'addOrder',
  'getDiscount',
  'setDiscount',
].forEach((methodName) => {
  StateManager[methodName] = (...args) => stateManager[methodName](...args);
});
