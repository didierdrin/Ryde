# IremboPay — Mobile app (`ryde_rw`) + Ryde backend

This document describes the **complete implementation** for IremboPay on the Flutter app and how it connects to the **current Ryde backend** and **mozypizza-callbacks**. Use it to port the same flow to another platform.

## Architecture

| Layer | Role |
|--------|------|
| **Ryde backend** | Creates Irembo invoices with the **secret key** (`@irembo/irembopay-node-sdk`), stores `invoice_number` on `payments` or `rental_payment_intents`, exposes `POST /api/orders/subscribe` for the callback service. |
| **mozypizza-callbacks** | Receives the IremboPay webhook, verifies `irembopay-signature`, forwards to Ryde `POST /api/orders/subscribe` with `X-Internal-Secret`. |
| **Mobile app** | Only the **public key**; calls Ryde to obtain `invoiceNumber`; opens checkout (WebView + Irembo inline script); **polls** Ryde for final status (webhook is authoritative). |

**Never ship in the mobile app:** `IREMBOPAY_SECRET_KEY`, `MOZYPIZZA_INTERNAL_SECRET`.

## Ryde backend — environment variables

See `ryde-backend/.env.example`. Typical variables:

| Variable | Role |
|----------|------|
| `IREMBOPAY_SECRET_KEY` | Server-side invoice API |
| `IREMBOPAY_ENVIRONMENT` | `sandbox` \| `checkout` \| `production` (SDK base URL) |
| `IREMBOPAY_ACCOUNT_ID` | Payment account identifier (e.g. `PI-…`) → `paymentAccountIdentifier` |
| `IREMBOPAY_PRODUCT_ID` | Product code (e.g. `PC-…`) → line item `code` |
| `MOZYPIZZA_INTERNAL_SECRET` | Must match the value on **mozypizza-callbacks** (`X-Internal-Secret`) |

**Callbacks service:** set `MOZYPIZZA_API_URL` to your Ryde API origin (with or without trailing `/api`; the callback normalizes to `.../api/orders/subscribe`). Same `IREMBOPAY_SECRET_KEY` as used for invoices (webhook HMAC). Same `MOZYPIZZA_INTERNAL_SECRET` as Ryde.

## Ryde API — endpoints used by mobile

All authenticated routes use `Authorization: Bearer <JWT>` unless noted.

| Method | Path | Purpose |
|--------|------|---------|
| `GET` | `/api/payments/trip/:tripId` | Load payment; body includes `payment` with `payment_id`, `payment_status`, etc. |
| `POST` | `/api/payments/:paymentId/create-invoice` | Create Irembo invoice for a trip payment; returns `invoiceNumber`, `paymentId`. |
| `POST` | `/api/payments/create-invoice-for-amount` | Body: `{ amount, address?, vehicleRef? }`; returns `invoiceNumber`, `intentId` (rental-style flows). |
| `GET` | `/api/payments/rental-intent/:intentId` | Poll intent: `intent.status` (`PENDING` / `COMPLETED` / `FAILED`). |
| `POST` | `/api/orders/subscribe` | **Internal only** — called by mozypizza-callbacks, not by the app. Header `X-Internal-Secret`. |

## Polling contract (authoritative status)

- **Trip:** after the widget reports success in the UI, poll `GET /api/payments/trip/:tripId` until `payment.payment_status` is `COMPLETED` or `FAILED` (or stop on timeout).
- **Rental intent:** poll `GET /api/payments/rental-intent/:intentId` until `intent.status` is `COMPLETED` or `FAILED`.

Do **not** rely only on the Irembo client callback for financial truth; the webhook → `subscribe` path updates the database.

## Flutter implementation — file map

| File | Purpose |
|------|---------|
| `lib/config/api_config.dart` | `baseUrl` from `--dart-define=RYDE_API_BASE_URL` (fallback default in code). |
| `lib/config/irembopay_config.dart` | `IREMBOPAY_PUBLIC_KEY` via `--dart-define`; builds HTML for WebView; chooses inline script URL (`pk_live_*` → production dashboard script, else sandbox). Optional `IREMBOPAY_PRODUCTION_WIDGET`. |
| `lib/service/api_service.dart` | `createPaymentInvoice`, `createInvoiceForAmount`, `getRentalIntent`, `waitForTripPaymentStatus`, `waitForRentalIntentStatus`, plus existing `getPaymentByTrip`. |
| `lib/screens/payments/irembopay_webview_screen.dart` | `WebView` + `IremboPayBridge` JS channel; loads `IremboPayConfig.checkoutHtml(invoiceNumber)`. |
| `lib/screens/myTrips/trips.dart` | Passenger: load payment, show **Pay with IremboPay** when pending, run create-invoice → WebView → poll. |
| `pubspec.yaml` | `webview_flutter` dependency. |
| `.github/workflows/flutter_build.yml` | CI: `flutter build apk` / `appbundle` with `--dart-define=IREMBOPAY_PUBLIC_KEY` and `--dart-define=RYDE_API_BASE_URL`. |

## Local run / build (examples)

From the `ryde_rw` directory (Flutter project root):

```bash
flutter pub get

flutter run \
  --dart-define=IREMBOPAY_PUBLIC_KEY=pk_your_public_key \
  --dart-define=RYDE_API_BASE_URL=https://your-ryde-api.onrender.com/api
```

Release build:

```bash
flutter build apk --release \
  --dart-define=IREMBOPAY_PUBLIC_KEY=pk_your_public_key \
  --dart-define=RYDE_API_BASE_URL=https://your-ryde-api.onrender.com/api
```

## WebView / JS bridge

1. HTML loads IremboPay **inline.js** from the correct dashboard host (sandbox vs production) to match the **public** key.
2. On load, JS runs `IremboPay.initiate({ publicKey, invoiceNumber, locale: EN, callback })`.
3. Callback posts to `IremboPayBridge.postMessage(JSON.stringify({ ok: true } | { ok: false, err: ... }))`.
4. Flutter pops the route with `true`/`false` and then polls the backend.

## Porting to another platform

1. Use the **same** Ryde endpoints and JWT for authenticated calls.
2. Embed the same **inline.js** URL + `IremboPay.initiate` pattern (WebView, in-app browser, or web page).
3. After UI success, **poll** trip payment or rental intent until `COMPLETED` / `FAILED`.
4. Keep invoice creation and webhooks on the server + callbacks service only.

## Database notes (backend)

- Migration `002_irembopay.sql`: `payments.invoice_number`, enum `IREMBO_PAY`, table `rental_payment_intents`.
- Webhook resolution: match `invoiceNumber` to `payments.invoice_number` or `rental_payment_intents.invoice_number`.

## Related projects in the workspace

- **Web:** `ryde-web` — `REACT_APP_IPAY_PUBLIC_KEY`, inline script in `public/index.html`, trips/rentals polling.
- **Backend:** `ryde-backend` — `services/irembopayService.js`, `controllers/paymentController.js`, `routes/orders.js` (`/subscribe`).
