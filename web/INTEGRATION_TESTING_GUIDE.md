# eDalab Website - Backend Integration & Testing Guide

## Quick Start

### Prerequisites
- Backend server running on `http://localhost:5050`
- Node.js (for backend) running and seeded with data
- Modern web browser (Chrome, Firefox, Safari, Edge)

### 1. Start the Backend Server

```bash
# In the /backend directory
npm install
npm run dev
```

The backend should start on **PORT 5050** as configured in `.env`

### 2. Access the Website

Open your browser and navigate to:
```
file:///Users/youssoufhassan/edalab_app/web/edalab-website.html
```

Or set up a local web server:

```bash
# Using Python 3
cd /Users/youssoufhassan/edalab_app/web
python3 -m http.server 8000

# Then visit: http://localhost:8000/edalab-website.html
```

### 3. Test the Modules

#### Main Landing Page
- ✅ Visit `edalab-website.html`
- ✅ Click on service cards (Food, Doctor, Shopping, Pharmacy, Hotel)
- ✅ Should navigate to respective module pages

#### Food Module (`food.html`)
- ✅ Click "Food" on main page or visit directly
- ✅ Should load restaurants from `/api/catalog/restaurants`
- ✅ Test search by restaurant name
- ✅ Test filter by cuisine
- ✅ Test pagination (next/prev pages)
- ✅ Add items to cart
- ✅ Verify cart count updates

**Expected API Calls:**
```
GET http://localhost:5050/api/catalog/restaurants
GET http://localhost:5050/api/catalog/restaurants?search=<query>
GET http://localhost:5050/api/catalog/restaurants?cuisine=<cuisine>
```

#### Doctor Module (`doctor.html`)
- ✅ Load doctors from `/api/catalog/doctors`
- ✅ Test search by name/specialty
- ✅ Apply filters (specialty, availability, rating)
- ✅ Click "Book Appointment" button
- ✅ Fill in appointment form (date, time, reason)
- ✅ Submit appointment

**Expected API Calls:**
```
GET http://localhost:5050/api/catalog/doctors
POST http://localhost:5050/api/appointments
```

#### Shopping Module (`shopping.html`)
- ✅ Load categories from `/api/catalog/categories`
- ✅ Load products from `/api/catalog/products`
- ✅ Filter by category
- ✅ Filter by price range
- ✅ Sort by (newest, price low→high, price high→low, rating)
- ✅ Add to cart & wishlist
- ✅ Verify wishlist heart icon updates

**Expected API Calls:**
```
GET http://localhost:5050/api/catalog/categories
GET http://localhost:5050/api/catalog/products
POST http://localhost:5050/api/wishlist/add (if implemented)
```

#### Pharmacy Module (`pharmacy.html`)
- ✅ Load medicines from `/api/catalog/medicines`
- ✅ Test category filters (Medicines, Wellness, Supplements, etc.)
- ✅ Test type filters
- ✅ Test stock availability filters
- ✅ Upload prescription file (optional)
- ✅ Add items to cart

**Expected API Calls:**
```
GET http://localhost:5050/api/catalog/medicines
GET http://localhost:5050/api/catalog/medicines?category=<cat>
POST http://localhost:5050/api/prescriptions/upload (if implemented)
```

#### Hotel Module (`hotel.html`)
- ✅ Select check-in date (today or later)
- ✅ Select check-out date (after check-in)
- ✅ Select number of guests (1-5+)
- ✅ Select room type (Single, Double, Suite, Villa)
- ✅ Search hotels (should load from `/api/catalog/hotels`)
- ✅ Filter by price range
- ✅ Filter by star rating
- ✅ Filter by amenities
- ✅ Click "Book Now" button
- ✅ Fill booking form & submit

**Expected API Calls:**
```
GET http://localhost:5050/api/catalog/hotels?checkIn=<date>&checkOut=<date>&guests=<n>&roomType=<type>
POST http://localhost:5050/api/bookings
```

#### Cart Page (`cart.html`)
- ✅ Add items from multiple modules (food, shopping, pharmacy, hotel)
- ✅ Go to cart page
- ✅ Verify module tabs show all modules with items
- ✅ Switch between tabs
- ✅ Update quantity (+ and - buttons)
- ✅ Remove items
- ✅ Enter promo code
- ✅ View order total
- ✅ Click "Place Order"

**Expected API Calls:**
```
GET http://localhost:5050/api/promotions/redeem?code=<CODE>
POST http://localhost:5050/api/orders
```

## Debugging

### Open Browser DevTools
- **Windows/Linux**: `F12` or `Ctrl+Shift+I`
- **Mac**: `Cmd+Option+I`

### Check Network Tab
1. Open DevTools → Network tab
2. Perform an action (search, filter, add to cart)
3. Look for API calls like:
   - `GET /api/catalog/restaurants`
   - `GET /api/catalog/doctors`
   - etc.

### Expected Network Responses

**Successful Response (200):**
```json
{
  "success": true,
  "data": [...],
  "message": "Success"
}
```

**Error Response (4xx/5xx):**
```json
{
  "success": false,
  "error": "Error message",
  "message": "What went wrong"
}
```

### Check Console for Errors
1. Open DevTools → Console tab
2. Look for red error messages
3. Common issues:
   - "Failed to fetch from localhost:5050" → Backend not running
   - "CORS error" → Backend CORS settings incorrect
   - "API error 401" → Authentication token missing/invalid
   - "Cannot read property 'name' of undefined" → Data structure mismatch

### Check LocalStorage (State Persistence)
1. Open DevTools → Application tab
2. Click "Local Storage" → your website URL
3. Should see keys like:
   - `authToken` - JWT token
   - `cart` - Shopping cart JSON
   - `wishlist` - Saved items
   - `appPreferences` - User preferences

## Troubleshooting

### Issue: "Cannot reach API" or "Failed to fetch"

**Solution:**
1. Verify backend is running on port 5050
   ```bash
   lsof -i :5050
   ```
2. Check backend is using correct `CORS_ORIGIN=*`
3. Check API_BASE_URL in `api-client.js` is `http://localhost:5050/api`

### Issue: No data showing on modules

**Solution:**
1. Check Network tab for failed requests
2. Check if database has seed data
3. Run backend seed script:
   ```bash
   cd /backend
   npx prisma db seed
   ```
4. Verify API responses in DevTools Network tab

### Issue: Cart not persisting

**Solution:**
1. Check if localStorage is enabled in browser
2. Verify `stateManager.js` is loaded (check Network tab)
3. Check Application tab for localStorage entries
4. Try clearing localStorage and refreshing

### Issue: Can't book appointment/hotel

**Solution:**
1. Check if backend endpoints exist:
   - `/api/appointments` (POST)
   - `/api/bookings` (POST)
   - `/api/orders` (POST)
2. Check response in Network tab for error messages
3. Verify form data is valid

### Issue: Images not loading

**Solution:**
1. Images fetch from API or are embedded as base64
2. Check Network tab for failed image requests
3. Verify backend serves images on correct endpoint

## Performance Testing

### Measure Load Times
1. Open DevTools → Performance tab
2. Click record, perform action, stop recording
3. Review timings for:
   - API response time (ideally < 500ms)
   - Page render time (ideally < 1000ms)
   - Total interaction time (ideally < 2000ms)

### Test Pagination
1. Go to Food module
2. Page should show 12 items
3. Click "Next Page"
4. Should load new items without full page reload
5. Click "Previous Page"
6. Should show original items

### Test Search Performance
1. Type in search box
2. Should see results update (debounced)
3. No multiple API calls for single keystroke
4. Results should appear in < 500ms

## Mobile Testing

### Using Chrome DevTools
1. Open DevTools (F12)
2. Click "Toggle device toolbar" (Ctrl+Shift+M)
3. Select device (iPhone, iPad, Android)
4. Test all modules on mobile view

### Breakpoints to Test
- **Mobile**: 320px, 375px, 425px
- **Tablet**: 768px, 1024px
- **Desktop**: 1366px, 1920px

### Touch Testing
1. On mobile devices or emulator
2. Tap buttons and links
3. Swipe to navigate tabs
4. Pinch to zoom (if enabled)

## Security Testing

### Check API Authentication
1. Try accessing endpoints without auth token
2. Should see "Unauthorized" or 401 error
3. Try accessing with expired token
4. Should redirect to login

### Check Data Validation
1. Try submitting empty forms
2. Should show validation errors
3. Try submitting invalid data (wrong date format)
4. Should show helpful error messages

## API Endpoint Reference

### Catalog Endpoints (GET)
```
/api/catalog/restaurants         - Get all restaurants
/api/catalog/doctors             - Get all doctors
/api/catalog/products            - Get all products
/api/catalog/medicines           - Get all medicines
/api/catalog/hotels              - Get all hotels
/api/catalog/categories          - Get product categories
/api/catalog/home-services       - Get home services (for future module)
/api/catalog/laundry-services    - Get laundry services (for future module)
```

### Transaction Endpoints (POST)
```
/api/orders                      - Create new order
/api/appointments                - Create appointment
/api/bookings                    - Create hotel booking
/api/prescriptions/upload        - Upload prescription
/api/rides                       - Create ride request
```

### User Endpoints
```
GET  /api/users/profile          - Get user info
POST /api/auth/login             - User login
POST /api/auth/register          - User registration
POST /api/auth/logout            - User logout
```

### Promo Endpoints
```
GET /api/promotions/redeem?code=CODE  - Apply promo code
GET /api/promotions/list              - Get available promos
```

## Testing Checklist

### Functionality
- [ ] Food module loads restaurants
- [ ] Doctor module loads doctors
- [ ] Shopping module loads products
- [ ] Pharmacy module loads medicines
- [ ] Hotel module loads hotels
- [ ] Search works across all modules
- [ ] Filters work correctly
- [ ] Cart adds/removes items
- [ ] Cart persists after page reload
- [ ] Booking flows work
- [ ] Promo codes apply discount
- [ ] Order can be placed

### Responsiveness
- [ ] Desktop layout looks good
- [ ] Tablet layout is readable
- [ ] Mobile layout is usable
- [ ] Images scale properly
- [ ] Text is readable at all sizes
- [ ] Buttons are tappable on mobile

### Performance
- [ ] Pages load in < 2 seconds
- [ ] API responses in < 500ms
- [ ] Smooth scrolling
- [ ] No lag on interactions
- [ ] Cart updates instantly
- [ ] Search results appear quickly

### Browser Compatibility
- [ ] Chrome latest
- [ ] Firefox latest
- [ ] Safari latest
- [ ] Edge latest
- [ ] Mobile Chrome
- [ ] Mobile Safari

### Error Handling
- [ ] Network errors show message
- [ ] Validation errors are helpful
- [ ] API errors are handled
- [ ] Missing data shows fallback
- [ ] Can recover from errors

## Next Steps

1. **Start Backend**: Run `npm run dev` in `/backend`
2. **Open Website**: Navigate to `edalab-website.html`
3. **Test Modules**: Follow testing steps above
4. **Debug Issues**: Use DevTools Network and Console tabs
5. **Report Bugs**: Document any issues found
6. **Optimize**: Improve performance based on findings

## Support

For issues or questions:
1. Check DevTools Console for error messages
2. Review Network tab for API responses
3. Check localStorage for state
4. Verify backend is running
5. Check API endpoint documentation in backend code

---

**Last Updated**: March 29, 2026
**Backend Version**: Expected v1.0.0
**Website Version**: v1.0.0
