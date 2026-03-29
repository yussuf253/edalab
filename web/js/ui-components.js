/**
 * Reusable UI Components & Utilities
 * Building blocks for the website features
 */

const UIComponents = {
  getImageSrc(item, fallback = 'https://via.placeholder.com/200x200') {
    return item?.imageUrl || item?.image || item?.images?.[0] || fallback;
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
      cartLabel = 'Cart',
      loginLabel = 'Login',
      registerLabel = 'Create Account',
      profileLabel = 'Profile',
      logoutLabel = 'Logout',
      appLabel = 'Get Started',
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
          <button class="n-ghost" data-auth-action="login">Sign In</button>
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
      this.showToast('Logged out successfully', 'success');
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
      { key: 'home', label: 'Home', href: 'edalab-website.html' },
      { key: 'food', label: 'Food', href: 'food.html' },
      { key: 'shopping', label: 'Shopping', href: 'shopping.html' },
      { key: 'pharmacy', label: 'Pharmacy', href: 'pharmacy.html' },
      { key: 'doctor', label: 'Doctor', href: 'doctor.html' },
      { key: 'hotel', label: 'Hotel', href: 'hotel.html' },
      { key: 'ride', label: 'Ride', href: 'ride.html' },
      { key: 'services', label: 'Services', href: 'home-services.html' },
      { key: 'laundry', label: 'Laundry', href: 'laundry.html' },
    ];

    return `
      <div class="nav-w nav-w-unified">
        <a class="nav-logo" href="edalab-website.html">
          <div class="nav-logo-icon">
            <svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8z"/></svg>
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
              <span class="nav-icon-label">Wishlist</span>
              <span class="nav-badge is-empty" id="${wishlistCountId}" data-nav-badge="wishlist">0</span>
            </a>
            <a href="cart.html" class="nav-icon-btn" aria-label="Cart">
              <span class="nav-icon-symbol">🛒</span>
              <span class="nav-icon-label">Cart</span>
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
      link.classList.toggle('on', link.dataset.navLink === normalizedOptions.active);
    });

    this.syncAuthNav({
      containerSelector: '#nav .nav-auth-slot',
      mode: 'profile',
      loginLabel: 'Login',
      registerLabel: 'Register',
      profileLabel: 'Profile',
      logoutLabel: 'Logout',
      logoutRedirect: normalizedOptions.logoutRedirect,
    });

    this.updateUnifiedNavbarBadges(normalizedOptions);

    window.__edaUnifiedNavState = normalizedOptions;
    if (!window.__edaUnifiedNavBound) {
      stateManager.subscribe('auth', () => this.syncAuthNav({
        containerSelector: '#nav .nav-auth-slot',
        mode: 'profile',
        loginLabel: 'Login',
        registerLabel: 'Register',
        profileLabel: 'Profile',
        logoutLabel: 'Logout',
        logoutRedirect: (window.__edaUnifiedNavState || normalizedOptions).logoutRedirect,
      }));
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
  document.addEventListener('DOMContentLoaded', () => UIComponents.bootUnifiedNavbar(), { once: true });
} else {
  UIComponents.bootUnifiedNavbar();
}
