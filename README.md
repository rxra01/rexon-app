# Rexon Retail — Invoicing, Inventory & Ledger (Khata) Engine

<p align="center">
  <strong>Modern, Lightning-Fast Retail Operating System for Indian Small & Medium Merchants</strong>
</p>

<p align="center">
  <a href="https://rexon-35454.web.app"><strong>🌐 Live Web App</strong></a> •
  <a href="https://rexon-35454.web.app/rexon.apk"><strong>📱 Download Android APK</strong></a> •
  <a href="#key-features"><strong>Key Features</strong></a> •
  <a href="#architecture"><strong>Architecture</strong></a> •
  <a href="#getting-started"><strong>Getting Started</strong></a>
</p>

---

## 🌟 Overview

**Rexon Retail** is an enterprise-grade retail POS and store management suite built with Flutter and Firebase. It eliminates paper registers, spreadsheet errors, and stock mismatch by providing lightning-fast billing, automatic stock decrementing, customer credit ledger (Khata), and multi-tenant Cloud Firestore synchronization.

### 🔗 Live Deployments
- **Web App (PWA)**: [https://rexon-35454.web.app](https://rexon-35454.web.app)
- **Release APK**: [https://rexon-35454.web.app/rexon.apk](https://rexon-35454.web.app/rexon.apk)
- **Firebase Project**: `rexon-35454`

---

## 🚀 Key Features

### 1. High-Velocity POS & Invoicing
- **Multi-Input Item Selection**: Barcode scanner lookup, SKU instant search, category grid filtering, and quick item taps.
- **Dynamic Pricing & Calculations**: Automatic subtotal, itemized / flat discounts, customizable GST tax computations.
- **Multi-Mode Settlements**: Cash, UPI, Cards, Bank Transfer, and Credit (Udhaar).
- **Thermal Receipt Modal & Print Preview**: Clean 80mm / 58mm POS receipt layout ready for Bluetooth thermal printers and WhatsApp invoice sharing.
- **Atomic Voiding**: Invoice cancellation that immediately restores inventory quantities and reverses customer dues.

### 2. Live Inventory & Stock Auditing
- **Instant Stock Tracking**: Real-time current stock, minimum stock safety thresholds, low-stock warnings, and out-of-stock badges.
- **Stock Movement Log**: Immutable audit ledger recording every opening stock entry, sale deduction, manual adjustment, and voided transaction.
- **Barcode & SKU Generation**: Automatic SKU generation for loose/unbranded goods and barcode assignment.

### 3. Customer Ledger (Khata & Udhaar)
- **Customer Directory**: Track phone numbers, addresses, and purchase histories.
- **Credit Balance Tracking**: Automatic debt accumulation when invoices are marked "partial" or "unpaid".
- **Payment Settlement**: Record payments against specific invoices or general balance with receipt notes.

### 4. Hybrid Cloud Firestore + Offline Cache
- **Direct Cloud Firestore Persistence**: Multi-tenant data structure under `businesses/{businessId}/...`.
- **Offline Resilience**: Instant local read/write with `SharedPreferences` cache and automatic background cloud sync when online.
- **Cross-Platform**: Full support for Android, Web, macOS, Windows, and iOS.

---

## 🏗️ Architecture & Cloud Schema

Rexon adheres to tenant-isolated multi-tenant design in Cloud Firestore:

```
firestore
├── businesses/{businessId}             # Store profile & settings
│   ├── products/{productId}           # Catalog items & stock counts
│   ├── sales/{saleId}                 # Invoices & line items
│   ├── customers/{customerId}         # Khata directory & balances
│   ├── payments/{paymentId}           # Settlement transactions
│   └── stock_movements/{movementId}   # Immutable stock audit logs
```

---

## 🛠️ Tech Stack

- **Frontend**: [Flutter 3.x](https://flutter.dev) (Dart 3)
- **State Management**: `Provider` architecture with separation of repository and presentation layers
- **Backend & DB**: [Google Firebase](https://firebase.google.com) (Cloud Firestore Native Mode, Firebase Authentication, Firebase Hosting)
- **Typography & Theme**: Google Fonts (*Plus Jakarta Sans*, *Manrope*, *JetBrains Mono*) with custom Tailwind-inspired slate/emerald/amber palette

---

## 📦 Getting Started

### Prerequisites
- Flutter SDK (3.24.0 or higher)
- Android Studio / VS Code
- Git

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/rxra01/rexon-app.git
   cd rexon-app
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run Static Analysis & Tests**:
   ```bash
   flutter analyze
   flutter test
   ```

4. **Launch Application Locally**:
   ```bash
   # Run in Chrome
   flutter run -d chrome

   # Run on connected Android device / emulator
   flutter run -d android
   ```

5. **Build for Production**:
   ```bash
   # Build Web
   flutter build web --release

   # Build Android APK
   flutter build apk --release
   ```

---

## 🔒 Security & Rules

Security rules in `firestore.rules` protect merchant data boundaries across tenant subcollections while allowing low-latency POS write batches.

---

## 📄 License

Proprietary — Developed for Rexon Retail. All rights reserved.
