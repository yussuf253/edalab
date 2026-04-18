# EdaLab App

## Amplitude Analytics Setup

Amplitude is integrated in the user app through `lib/core/analytics/analytics_service.dart`.

1. Provide your Amplitude API key at runtime:

```bash
flutter run --dart-define=AMPLITUDE_API_KEY=YOUR_AMPLITUDE_API_KEY
```

2. For release builds, pass the same `--dart-define` in CI/CD build commands.

3. If `AMPLITUDE_API_KEY` is not provided, analytics is automatically disabled with a safe no-op behavior.

## What Is Tracked

- App lifecycle: open/resume
- Automatic screen views from GoRouter navigation
- Auth funnel: login/register/session restore/logout (+ failures)
- Profile and address management actions (+ failures)
- Cart lifecycle: hydrate, add/remove items, quantity changes, promo actions
- Checkout funnel: view, place-order tap, validation failures, completion
- Conversion completion flows in checkout, ride, hotel, doctor, home services, and laundry
