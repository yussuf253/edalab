# EdaLab Firebase + PostgreSQL Backend Schema

## Recommended split

Use a hybrid backend:

- Firebase Auth: sign-in, sign-up, password reset, session identity.
- Firestore: mobile-facing realtime documents, carts, notifications, user profile projection, lightweight order tracking, promotions, and client-friendly denormalized reads.
- PostgreSQL: authoritative source of truth for transactional records, catalogs, pricing, bookings, analytics-safe relations, and finance-friendly history.
- Cloud Functions or Cloud Run: orchestrate writes so Firestore stays a projection layer instead of becoming the only source of truth.

## What the current codebase already persists

From the Flutter app and the deleted backend history, the currently implemented backend contract is:

- `users`
- `addresses`
- `orders`
- `appointments`
- `modules`

These are visible in:

- `AuthProvider` login/register/profile/address APIs
- order creation in shopping, food, hotel, ride, and laundry flows
- doctor appointment booking and appointment history
- the original Prisma schema and Express routes under the deleted `backend/` tree

## What the app UI clearly expects next

The rest of the modules are still using local sample models, but they already define stable backend entities:

- Shopping: products, brands, categories, wishlist, checkout, promotions
- Food: restaurants, menu categories, menu items, food carts, tracking
- Grocery: grocery categories, grocery items, cart, coupons
- Pharmacy: medicines, prescription flag, dosage, package size
- Doctor: doctors, reviews, appointment slots, appointments
- Hotel: hotels, amenities, bookings
- Ride: ride categories, ride requests, tracking, payment choice
- Laundry: laundry services, laundry orders, pickup windows
- Cross-cutting: notifications, payment methods, rewards, coupons, promotions

## PostgreSQL source-of-truth schema

This repository now includes a PostgreSQL Prisma schema at:

- `backend/prisma/schema.prisma`

That schema normalizes the app into these groups:

- Identity: `User`, `Address`, `PaymentMethod`
- Engagement: `WishlistItem`, `Notification`, `Promotion`, `UserCoupon`
- Catalog: `ProductCategory`, `Product`, `Restaurant`, `RestaurantMenuCategory`, `RestaurantMenuItem`, `Doctor`, `DoctorReview`, `Hotel`, `RideCategory`, `LaundryService`
- Transactions: `Order`, `OrderItem`, `Appointment`, `HotelBooking`, `RideBooking`, `LaundryOrder`

## Firestore deployment schema

Treat Firestore as a read-optimized projection and realtime layer.

### 1. User root

Collection: `users/{uid}`

Suggested fields:

```json
{
  "email": "user@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "phone": "+25300000000",
  "avatarUrl": null,
  "dateOfBirth": null,
  "points": 2450,
  "defaultAddressId": "addr_1",
  "defaultPaymentMethodId": "pm_1",
  "createdAt": "serverTimestamp",
  "updatedAt": "serverTimestamp"
}
```

Subcollections:

- `users/{uid}/addresses/{addressId}`
- `users/{uid}/payment_methods/{paymentMethodId}`
- `users/{uid}/wishlist/{wishlistItemId}`
- `users/{uid}/notifications/{notificationId}`
- `users/{uid}/rewards/{rewardDocId}`
- `users/{uid}/coupons/{couponId}`
- `users/{uid}/cart/{cartItemId}`

### 2. Addresses

Collection: `users/{uid}/addresses/{addressId}`

```json
{
  "label": "Home",
  "line1": "123 Main Street",
  "line2": null,
  "city": "Djibouti",
  "state": null,
  "postalCode": null,
  "country": "DJ",
  "latitude": null,
  "longitude": null,
  "isDefault": true,
  "createdAt": "serverTimestamp",
  "updatedAt": "serverTimestamp"
}
```

### 3. Payment methods

Collection: `users/{uid}/payment_methods/{paymentMethodId}`

Never store raw PAN or CVV in Firestore.

```json
{
  "type": "CARD",
  "brand": "Visa",
  "last4": "4242",
  "providerRef": "stripe_pm_xxx",
  "expiryMonth": 12,
  "expiryYear": 2028,
  "isDefault": true,
  "createdAt": "serverTimestamp",
  "updatedAt": "serverTimestamp"
}
```

### 4. Cart

Collection: `users/{uid}/cart/{cartItemId}`

This matches the current `CartItem` model.

```json
{
  "moduleType": "shopping",
  "entityId": "p1",
  "name": "Nike Air Max 270",
  "brand": "Nike",
  "imageUrl": null,
  "price": 129.99,
  "quantity": 2,
  "color": "Black",
  "size": "US 10",
  "metadata": {},
  "updatedAt": "serverTimestamp"
}
```

### 5. Wishlist

Collection: `users/{uid}/wishlist/{wishlistItemId}`

```json
{
  "moduleType": "SHOPPING",
  "entityId": "p1",
  "title": "Nike Air Max 270",
  "subtitle": "Nike",
  "imageUrl": null,
  "price": 129.99,
  "createdAt": "serverTimestamp"
}
```

### 6. Orders

Collection: `orders/{orderId}`

Use this as the mobile-facing order projection. The canonical write still lands in PostgreSQL.

```json
{
  "userId": "firebase_uid",
  "moduleType": "SHOPPING",
  "status": "PENDING",
  "moduleRefType": "PRODUCT_ORDER",
  "moduleRefId": null,
  "addressId": "addr_1",
  "paymentMethodId": "pm_1",
  "promotionId": null,
  "subtotal": 259.98,
  "tax": 20.80,
  "deliveryFee": 0,
  "discount": 0,
  "total": 280.78,
  "currency": "USD",
  "notes": null,
  "items": [
    {
      "entityId": "p1",
      "name": "Nike Air Max 270",
      "brand": "Nike",
      "quantity": 2,
      "unitPrice": 129.99,
      "lineTotal": 259.98,
      "color": "Black",
      "size": "US 10",
      "metadata": {}
    }
  ],
  "createdAt": "serverTimestamp",
  "updatedAt": "serverTimestamp"
}
```

Tracking subcollection:

- `orders/{orderId}/events/{eventId}`

```json
{
  "status": "DISPATCHED",
  "title": "Order out for delivery",
  "description": "Courier has picked up your order",
  "createdAt": "serverTimestamp"
}
```

### 7. Doctor appointments

Collection: `appointments/{appointmentId}`

```json
{
  "userId": "firebase_uid",
  "doctorId": "d1",
  "doctorName": "Dr. Sarah Johnson",
  "specialty": "Cardiologist",
  "appointmentAt": "2026-03-24T10:00:00.000Z",
  "timeSlot": "10:00 AM",
  "appointmentType": "video",
  "status": "UPCOMING",
  "notes": "Booked via EdaLab Super App",
  "createdAt": "serverTimestamp",
  "updatedAt": "serverTimestamp"
}
```

### 8. Hotel bookings

Collection: `hotel_bookings/{bookingId}`

```json
{
  "userId": "firebase_uid",
  "hotelId": "h1",
  "hotelName": "Grand Royale Hotel",
  "roomType": "Standard Room",
  "guestName": "John Doe",
  "guestEmail": "john@example.com",
  "guestPhone": "+25300000000",
  "checkInAt": "2026-03-25T12:00:00.000Z",
  "checkOutAt": "2026-03-28T12:00:00.000Z",
  "nights": 3,
  "guestCount": 2,
  "status": "CONFIRMED",
  "subtotal": 899.97,
  "serviceFee": 45.00,
  "tax": 72.00,
  "total": 1016.97,
  "createdAt": "serverTimestamp",
  "updatedAt": "serverTimestamp"
}
```

### 9. Ride bookings

Collection: `ride_bookings/{rideId}`

```json
{
  "userId": "firebase_uid",
  "rideCategoryId": "r1",
  "vehicleName": "Economy",
  "pickupLabel": "123 Main Street",
  "dropoffLabel": "City Mall, Downtown",
  "distanceKm": 5.2,
  "estimatedFare": 11.24,
  "tax": 0.90,
  "total": 12.14,
  "status": "REQUESTED",
  "etaLabel": "3 min",
  "driverName": null,
  "driverPhone": null,
  "createdAt": "serverTimestamp",
  "updatedAt": "serverTimestamp"
}
```

Realtime tracking subcollection:

- `ride_bookings/{rideId}/tracking/{trackingId}`

```json
{
  "lat": 11.5721,
  "lng": 43.1456,
  "heading": 90,
  "speedKph": 24,
  "recordedAt": "serverTimestamp"
}
```

### 10. Laundry orders

Collection: `laundry_orders/{laundryOrderId}`

```json
{
  "userId": "firebase_uid",
  "serviceId": "l1",
  "serviceName": "Wash & Fold",
  "itemCount": 6,
  "itemBreakdown": {
    "Shirts": 3,
    "Pants": 2,
    "Dresses": 1,
    "Jackets": 0
  },
  "pickupAt": "2026-03-23T14:00:00.000Z",
  "timeSlot": "02:00 - 04:00",
  "status": "SCHEDULED",
  "subtotal": 150.00,
  "tax": 12.00,
  "total": 162.00,
  "createdAt": "serverTimestamp",
  "updatedAt": "serverTimestamp"
}
```

### 11. Promotions

Collection: `promotions/{promotionId}`

```json
{
  "moduleType": "GROCERY",
  "title": "Fresh Basket Countdown",
  "description": "Produce and pantry staples are discounted before noon.",
  "code": "FRESH30",
  "discountType": "PERCENT",
  "discountValue": 30,
  "active": true,
  "priority": 100,
  "startsAt": "serverTimestamp",
  "endsAt": "serverTimestamp",
  "metadata": {
    "bannerStyle": "flash_sale"
  }
}
```

### 12. Catalog mirror

Collection family: `catalog/{module}/items/{docId}`

Suggested module docs:

- `catalog/shopping/items/{productId}`
- `catalog/food/items/{restaurantId}`
- `catalog/grocery/items/{itemId}`
- `catalog/pharmacy/items/{medicineId}`
- `catalog/doctor/items/{doctorId}`
- `catalog/hotel/items/{hotelId}`
- `catalog/ride/items/{categoryId}`
- `catalog/laundry/items/{serviceId}`

This is optional if PostgreSQL drives catalog APIs directly, but it is useful for:

- offline reads
- low-latency home feeds
- promotions
- search projections

## Module-by-module mapping

### Shopping

Source from code:

- `ProductModel`
- wishlist UI
- cart and checkout

Needs:

- catalog product records
- wishlist projection
- order/order items
- promotions

### Food

Source from code:

- `RestaurantModel`
- `MenuCategory`
- `MenuItem`
- food cart and tracking screens

Needs:

- restaurant catalog
- menu categories
- menu items
- food orders and order events

### Grocery

Source from code:

- `GroceryCategory`
- `GroceryModel`

Needs:

- grocery categories
- grocery items
- grocery orders

### Pharmacy

Source from code:

- `PharmacyModel`

Needs:

- medicine catalog
- prescription flag
- pharmacy orders

### Doctor

Source from code:

- `DoctorModel`
- `ReviewModel`
- `AppointmentModel`
- booking screen and appointments screen

Needs:

- doctors
- doctor reviews
- appointments
- optional timeslot inventory

### Hotel

Source from code:

- `HotelModel`
- hotel booking flow

Needs:

- hotels
- hotel bookings

### Ride

Source from code:

- `RideCategory`
- ride booking and tracking screens

Needs:

- ride categories
- ride bookings
- tracking points

### Laundry

Source from code:

- `LaundryService`
- laundry order flow

Needs:

- laundry services
- laundry orders

### Profile, Rewards, Notifications

Source from code:

- addresses
- payment methods
- coupons
- notifications
- reward points

Needs:

- user profile projection
- subcollections for addresses, payment methods, wishlist, notifications, coupons, rewards

## Recommended notification source-of-truth design

Use the database as the canonical notification store and keep device storage as a cache.

### Canonical record

PostgreSQL table or Firestore document should store:

```json
{
  "id": "notif_123",
  "userId": "firebase_uid",
  "title": "Order confirmed",
  "body": "Your food order is now being prepared.",
  "module": "food",
  "priority": "high",
  "route": "/orders",
  "dedupeKey": "order:ord_123:/orders",
  "metadata": {
    "orderId": "ord_123",
    "restaurantName": "Burger Palace"
  },
  "createdAt": "serverTimestamp",
  "readAt": null
}
```

### What should create notifications

- Order status changes
- Ride lifecycle changes
- Appointment and booking confirmations
- Pharmacy and care reminders
- Promotions and coupon activations
- Account/security actions

### Client sync model

1. App loads cached notifications first for fast UI.
2. App fetches `/notifications/{userId}` to refresh from backend.
3. App merges remote records with local cache using `id` and `dedupeKey`.
4. App calls `/notifications/{id}/read` when an item is opened.
5. App registers FCM device tokens so backend can deliver new events immediately.

### Suggested REST endpoints

- `GET /notifications/:userId`
- `POST /notifications`
- `PATCH /notifications/:id/read`
- `POST /notifications/device-tokens`

## Deployment files added

- `firebase.json`
- `firebase/firestore.rules`
- `firebase/firestore.indexes.json`
- `backend/prisma/schema.prisma`

## Important implementation note

Because the current Flutter app still calls a custom REST API, this schema generation is the data design layer, not the final runtime migration.

The clean migration path is:

1. Move auth to Firebase Auth.
2. Keep transactional writes going through a server using PostgreSQL.
3. Mirror successful writes into Firestore for mobile reads and realtime updates.
4. Replace Flutter `ApiClient` calls module by module once the new backend endpoints or Firebase repositories are ready.
