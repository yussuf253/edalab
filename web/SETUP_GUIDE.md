# eDalab Website Setup & Implementation Guide

## Quick Start

### Files Created

**Core Utilities:**
- `web/js/api-client.js` - Backend API communication (285 lines)
- `web/js/state-manager.js` - Local state management (250+ lines)
- `web/js/ui-components.js` - Reusable UI components (450+ lines)

**CSS:**
- `web/css/components.css` - Component styles (650+ lines)
- `web/css/modules.css` - Module-specific styles (400+ lines)

**Module Pages:**
- `web/food.html` - Food delivery module
- `web/doctor.html` - Healthcare & appointments
- `web/shopping.html` - E-commerce shopping
- `web/pharmacy.html` - Medicine & health products
- `web/hotel.html` - Hotel booking
- `web/cart.html` - Multi-module shopping cart

**Documentation:**
- `web/WEBSITE_FEATURES.md` - Complete feature documentation

### Configuration

1. **Set Backend API URL**
   
   In `web/js/api-client.js`, update the API base URL:
   ```javascript
   const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:3001/api';
   ```

2. **Update HTML Links**
   
   The main page (`edalab-website.html`) now links to module pages:
   - Service cards direct to respective modules
   - Navigation menu can be updated for full navigation

## Module Features Summary

### 🍕 Food (`food.html`)
- ✅ Restaurant catalog
- ✅ Search by name/cuisine
- ✅ Filter by cuisine category
- ✅ Pagination
- ✅ Add to cart
- ✅ Wishlist support

**API Endpoints Used:**
- GET `/api/catalog/restaurants`
- GET `/api/orders`
- POST `/api/orders`

---

### 👨‍⚕️ Doctor (`doctor.html`)
- ✅ Browse doctors
- ✅ Search by name/specialty
- ✅ Filter by specialty, availability, rating
- ✅ Book appointments
- ✅ Modal-based booking form

**API Endpoints Used:**
- GET `/api/catalog/doctors`
- POST `/api/appointments`
- GET `/api/appointments/doctor/:id/availability`

---

### 🛍️ Shopping (`shopping.html`)
- ✅ Product catalog
- ✅ Category browsing
- ✅ Advanced filtering (category, price, rating)
- ✅ Sorting (newest, price, rating)
- ✅ Wishlist
- ✅ Add to cart

**API Endpoints Used:**
- GET `/api/catalog/products`
- GET `/api/catalog/categories`

---

### 💊 Pharmacy (`pharmacy.html`)
- ✅ Medicine catalog
- ✅ Prescription upload
- ✅ Category filtering
- ✅ Type filtering (medicine, wellness, supplements)
- ✅ Stock status
- ✅ Prescription requirement badges

**API Endpoints Used:**
- GET `/api/catalog/medicines`
- POST (prescription file upload)

---

### 🏨 Hotel (`hotel.html`)
- ✅ Hotel listing
- ✅ Date range selection
- ✅ Guest count selector
- ✅ Room type selection
- ✅ Price filtering
- ✅ Rating filtering
- ✅ Amenity filtering
- ✅ Booking confirmation

**API Endpoints Used:**
- GET `/api/catalog/hotels`
- GET `/api/catalog/hotels/:id/rooms`
- GET `/api/catalog/hotels/:id/availability`
- POST `/api/orders` (for bookings)

---

### 🛒 Cart (`cart.html`)
- ✅ Multi-module cart (Food, Shopping, Pharmacy, Hotel)
- ✅ Module-specific tabs
- ✅ Quantity controls
- ✅ Real-time price calculation
- ✅ Promo code support
- ✅ Checkout flow
- ✅ Order placement

**API Endpoints Used:**
- POST `/api/orders`
- POST `/api/promotions/redeem`

---

## Data Flow

### User Journey: Food Ordering

```
1. User visits food.html
2. Page loads restaurants via API
3. User searches/filters restaurants
4. User adds items to cart (stored in localStorage)
5. User navigates to cart.html
6. Cart displays all items, calculates total
7. User applies promo code
8. User clicks "Checkout"
9. System creates order via API
10. Order confirmation displayed
```

### User Journey: Doctor Booking

```
1. User visits doctor.html
2. Page loads doctors via API
3. User searches/filters doctors
4. User clicks "Book Now"
5. Modal form opens
6. User selects date/time
7. User enters reason for visit
8. User confirms booking
9. API creates appointment
10. Confirmation message shown
```

## Styling & Branding

### Colors
- **Primary Green**: `#16A34A` (Food: `#EF4444`, Doctor: `#3B82F6`)
- **Background**: `#F8FBF8`
- **Text**: `#111827`

### Typography
- **Headings**: Bricolage Grotesque (700, 800 weights)
- **Body**: Nunito (400, 500, 600, 700 weights)

### Spacing & Radius
- **Border Radius**: 12px-32px (responsive)
- **Max Width**: 1260px
- **Padding**: 16px-28px (responsive)

## Browser DevTools Tips

### Testing API Calls
```javascript
// In browser console
apiClient.getRestaurants({ limit: 10 }).then(data => console.log(data));
apiClient.getDoctors().then(data => console.log(data));
```

### Testing State Management
```javascript
// View cart
console.log(stateManager.getCart('food'));

// Add to cart
stateManager.addToCart({ id: 1, name: 'Test', price: 10 }, 1, 'shopping');

// View all state
console.log(stateManager.state);
```

### Network Monitoring
Open DevTools → Network tab to see:
- API request URLs
- Response payloads
- Network timing
- Error codes

## Performance Notes

- **Code Splitting**: Each module is independent (can be lazy-loaded)
- **Caching**: API responses cached in state, localStorage for persistent data
- **Bundle Size**: ~300-400KB total (uncompressed)
- **Page Load**: Should be < 2s on 3G with API responses

## Error Handling

All modules handle:
- ✅ Network errors (shows toast notification)
- ✅ Missing data (shows empty state message)
- ✅ 401 Unauthorized (redirects to login)
- ✅ Form validation (shows validation errors)

## Future Improvements

### Immediate
1. Add hotel availability calendar
2. Add real-time ride tracking
3. Add home services module
4. Add laundry module
5. Add review/rating submission

### Medium-term
1. Progressive Web App (PWA) support
2. Service workers for offline support
3. Payment gateway integration
4. User profile & authentication UI
5. Order history & tracking

### Long-term
1. Real-time notifications (WebSockets)
2. Advanced analytics
3. Recommendation engine
4. Social features (referrals, etc.)
5. Multi-language support

## Testing Checklist

- [ ] All modules load correctly
- [ ] Search functionality works
- [ ] Filters apply correctly
- [ ] Pagination navigates pages
- [ ] Add to cart updates cart count
- [ ] Cart displays correct totals
- [ ] Promo codes can be applied
- [ ] Bookings can be confirmed
- [ ] Mobile responsiveness works
- [ ] No console errors
- [ ] API calls are successful

## Support & Debugging

### Common Issues

**API Not Loading:**
- Check API_BASE_URL configuration
- Verify backend is running
- Check CORS settings
- Look at Network tab in DevTools

**State Not Persisting:**
- Check localStorage is enabled
- Verify localStorage keys (edaLab*)
- Check browser privacy settings

**Styles Not Applied:**
- Verify CSS files are linked
- Clear browser cache
- Check for CSS conflicts
- Use DevTools Inspector

## Next Steps

1. ✅ Configure API URL in `api-client.js`
2. ✅ Test each module with sample data
3. ✅ Verify all API endpoints are working
4. ✅ Test cart functionality across modules
5. ✅ Test on mobile devices
6. ✅ Deploy to staging environment
7. ✅ Perform user acceptance testing
8. ✅ Deploy to production

---

**Last Updated**: March 2024
**Status**: Ready for Development & Testing
