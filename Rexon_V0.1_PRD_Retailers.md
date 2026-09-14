# Rexon V0.1 — Product Requirements Document
## Vertical: Retailers
**Version:** 0.1 (MVP) &nbsp;|&nbsp; **Author:** Rexon Product &nbsp;|&nbsp; **Backend:** Firebase (Firestore + Firebase Authentication) &nbsp;|&nbsp; **Client:** Flutter (Android, iOS, Web, Desktop)

---

## 1. Purpose

Deliver the smallest usable version of Rexon for a single-outlet retailer: log in, set up the shop, manage products and stock, bill a customer, and see what's owed and what's low. Every other Rexon capability (multi-branch, B2B, website, AI, automation) is explicitly out of scope for V0.1.

## 2. Target User

A single-location retail shop owner (e.g. garments, electronics/mobile, hardware, general retail) currently tracking stock and bills on paper, in a notebook app, or in Tally/Vyapar/myBillBook, who wants a simpler mobile-first tool for daily billing and stock tracking.

**Primary persona:** Shop Owner (also the primary/only user in V0.1 — staff roles are P2, see §6.9).

## 3. Goals for V0.1

- Owner can create an account and set up their shop in under 10 minutes.
- Owner can add products and track stock without spreadsheets.
- Owner can bill a customer (invoice) in under 60 seconds for a simple sale.
- Owner can see, at a glance: today's sales, low-stock items, and who owes money.
- Data is safe per-tenant (one retailer never sees another retailer's data).

## 4. Non-Goals (Explicitly Out of Scope for V0.1)

- Multi-branch / multi-warehouse (→ V0.3)
- B2B catalogue, MOQ, credit-term ordering (→ V0.4)
- Customer/supplier portals (→ V0.5)
- Website builder (→ V0.6)
- AI assistant/analytics/forecasting (→ V0.7)
- Workflow automation engine (→ V0.8)
- Multiple apps for employees/customers/suppliers (→ V0.9)
- Payment gateway / UPI links / WhatsApp integration (→ V0.2)
- Barcode/QR scanning (→ V0.2)
- PDF invoice generation, CSV export (→ V0.2, unless a fast Cloud Function based PDF proves trivial — see §11 open question)
- Employee accounts beyond a single "Owner" login (→ P2 within V0.1 if time allows, else V0.2)

## 5. Scope: Modules in This PRD

| # | Module | Priority |
|---|---|---|
| 1 | Authentication & Login | P0 |
| 2 | Business Profile & Setup | P0 |
| 3 | Product & Inventory Management | P0 |
| 4 | Customer (Lightweight) | P0 |
| 5 | Sales & Invoicing | P0 |
| 6 | Payment Recording | P0 |
| 7 | Dashboard & Basic Reports | P1 |
| 8 | Low-Stock / Payment Notifications | P1 |
| 9 | Roles (Owner/Staff) | P2 |

---

## 6. Functional Requirements

### 6.1 Authentication & Login (P0)

**User stories**
- As a shop owner, I can sign up with phone number (OTP) or email + password.
- As a shop owner, I can log in on a new device and reach my same shop data.
- As a shop owner, I can reset my password / re-verify OTP if locked out.

**Requirements**
- Firebase Authentication: Phone (OTP) as primary method for the Indian retail audience; Email/Password as fallback.
- On first successful login, if no business profile exists for this user → route to Business Setup (§6.2).
- On subsequent logins, route directly to Dashboard.
- Session persists on device (no re-login every app open).
- One Firebase Auth user = one Owner account in V0.1 (multi-user per business is P2, §6.9).

**Data**
- Firebase Auth handles credentials natively — no custom `users` password storage needed.
- `businesses/{businessId}/owner_uid` links the Auth UID to the business/tenant.

### 6.2 Business Profile & Setup (P0)

**User stories**
- As a shop owner, I can enter my shop's name, type, address, and contact details once, at setup.
- As a shop owner, I can edit my profile later from Settings.

**Fields**
- Business name
- Business type (dropdown: Retailer — pre-filled for this build; kept as a field for future multi-vertical reuse)
- Owner name
- Phone
- Email (optional)
- Address
- GSTIN (optional — many small retailers are unregistered; must not block signup if blank)
- Business logo (optional, image upload)
- Currency (default ₹ INR, not editable in V0.1)

**Requirements**
- Setup is a short wizard: Business Info → (optional) Add first product → Done. Do not force full product catalogue entry before reaching the Dashboard — let the owner explore first.
- GSTIN, if entered, should be format-validated (15-character pattern) but not verified against a government API in V0.1.

**Data — Firestore**
```
businesses/{businessId}
  ownerUid: string
  name: string
  type: "retailer"
  ownerName: string
  phone: string
  email: string | null
  address: string
  gstin: string | null
  logoUrl: string | null
  createdAt: timestamp
```

### 6.3 Product & Inventory Management (P0)

**User stories**
- As a shop owner, I can add a product with name, price, and starting stock.
- As a shop owner, I can see current stock for every product at a glance.
- As a shop owner, I can manually adjust stock (correction, damage, etc.) with a reason.
- As a shop owner, I get warned when a product is low on stock.

**Fields (per product)**
- Product name (required)
- SKU (optional — auto-generate if blank)
- Barcode (optional, manual entry field only in V0.1; scanning is V0.2)
- Category (free text or simple dropdown, owner-defined)
- Unit (piece, kg, box, etc. — simple dropdown)
- Purchase price (cost)
- Selling price
- Opening stock
- Current stock (system-maintained, not directly editable — only via stock movements)
- Minimum stock level (for low-stock alerts)

**Requirements**
- Every stock change (sale, manual adjustment) must be recorded as a `stock_movement`, never a silent overwrite of `currentStock` — this is what makes stock auditable and safe against concurrent edits.
- Stock decrement on sale must be an atomic Firestore transaction against the product's `currentStock` to prevent overselling from two devices/sessions at once.
- Low-stock is computed as `currentStock <= minStockLevel` and surfaces on the Dashboard (§6.7) and as a notification (§6.8).

**Data — Firestore**
```
businesses/{businessId}/products/{productId}
  name: string
  sku: string
  barcode: string | null
  category: string | null
  unit: string
  purchasePrice: number
  sellingPrice: number
  currentStock: number
  minStockLevel: number
  createdAt: timestamp
  updatedAt: timestamp

businesses/{businessId}/stock_movements/{movementId}
  productId: string
  type: "sale" | "adjustment" | "opening"
  quantityChange: number      // negative for reductions
  reason: string | null       // required for "adjustment"
  referenceId: string | null  // e.g. linked saleId
  createdAt: timestamp
  createdBy: string           // uid
```

### 6.4 Customer (Lightweight) (P0)

**User stories**
- As a shop owner, I can bill a customer without creating a profile (walk-in sale).
- As a shop owner, I can optionally save a returning customer's name and phone to track their purchase history and dues.

**Fields**
- Name
- Phone (used as the practical unique lookup)
- Address (optional)
- Outstanding amount (system-maintained from unpaid/partial invoices)

**Requirements**
- Sales must support a "Walk-in / Cash Customer" default so billing is never blocked on customer entry.
- Searching by phone number should surface an existing customer to avoid duplicates.

**Data — Firestore**
```
businesses/{businessId}/customers/{customerId}
  name: string
  phone: string | null
  address: string | null
  outstandingAmount: number   // derived, updated on invoice/payment events
  createdAt: timestamp
```

### 6.5 Sales & Invoicing (P0)

**User stories**
- As a shop owner, I can create a bill: pick products, quantities, apply a discount, see the total, and save it.
- As a shop owner, I can mark a bill as Paid, Partially Paid, or Unpaid at the time of billing.
- As a shop owner, I can view past invoices and reprint/reshare one.

**Fields (per invoice)**
- Invoice number (auto-incremented per business, e.g. `INV-0001`)
- Customer (linked, or walk-in)
- Line items: product, quantity, unit price (editable per line for discounts/negotiated price), line total
- Overall discount (optional, ₹ or %)
- Tax (optional, only if business GSTIN is set — simple flat rate field for V0.1, not full GST slabs)
- Grand total
- Payment status: Paid / Partial / Unpaid
- Amount paid (if partial)
- Date/time

**Requirements**
- Saving an invoice must, in one atomic operation: (a) create the `sales` document + `sale_items`, (b) decrement stock via `stock_movements` for each line item, (c) update the customer's `outstandingAmount` if not fully paid.
- Invoice must be viewable and shareable as text/image share (native OS share sheet on mobile; download/print on web/desktop) in V0.1; true PDF generation is a stretch goal (see §11) but not a blocker for launch.
- No invoice editing after save in V0.1 — corrections happen via a linked credit/cancellation note (simplify: allow "Void" with reason, which reverses stock and dues; a full return/refund flow is V0.2).

**Data — Firestore**
```
businesses/{businessId}/sales/{saleId}
  invoiceNumber: string
  customerId: string | null   // null = walk-in
  customerName: string        // denormalized for fast display, even for walk-ins
  items: [
    { productId, productName, quantity, unitPrice, lineTotal }
  ]
  discount: number
  tax: number
  grandTotal: number
  paymentStatus: "paid" | "partial" | "unpaid"
  amountPaid: number
  voided: boolean
  voidReason: string | null
  createdAt: timestamp
  createdBy: string
```

### 6.6 Payment Recording (P0)

**User stories**
- As a shop owner, I can record a payment against an unpaid/partial invoice.
- As a shop owner, I can record what payment method was used.

**Fields**
- Linked invoice (or standalone against a customer's overall dues)
- Amount
- Method: Cash / UPI / Bank Transfer / Card / Cheque / Other
- Date
- Note (optional)

**Requirements**
- Recording a payment updates the linked invoice's `paymentStatus`/`amountPaid` and the customer's `outstandingAmount` atomically.

**Data — Firestore**
```
businesses/{businessId}/payments/{paymentId}
  saleId: string | null
  customerId: string | null
  amount: number
  method: "cash" | "upi" | "bank_transfer" | "card" | "cheque" | "other"
  note: string | null
  createdAt: timestamp
```

### 6.7 Dashboard & Basic Reports (P1)

**User stories**
- As a shop owner, I open the app and immediately see how the shop is doing today.

**Dashboard cards**
- Today's sales (total ₹ + count of bills)
- Outstanding receivables (total ₹ owed by customers)
- Low-stock products (count, tap to view list)
- Recent transactions (last 5–10 sales)

**Reports (simple list/table views, no charts required for V0.1)**
- Sales report (date range filter)
- Inventory report (current stock list)
- Outstanding receivables list

### 6.8 Notifications (P1)

- Low-stock alert when a product crosses `minStockLevel` (in-app + Firebase Cloud Messaging push).
- Overdue/outstanding payment reminder is a stretch goal for V0.1; formal reminder scheduling is V0.2.

### 6.9 Roles (P2 — stretch for V0.1)

- V0.1 ships single-user (Owner) per business.
- If time allows: a second role "Staff" with restricted access (can bill sales, cannot see finance/reports/edit products). Full permission granularity is V0.2+ per the master roadmap.

---

## 7. Architecture

**Decision:** single Flutter codebase targeting Android, iOS, Web, and Desktop (Windows/macOS), backed by Firebase. Chosen over a native-per-platform approach because a single small team cannot sustain four separate native codebases at V0.1, and over a plain web-app-in-a-wrapper approach because retail billing needs native-grade performance and reliable offline behavior (see §8, Offline tolerance).

**Layers**
```
Flutter UI (Widgets)
   ↓
State management (Riverpod/Bloc — pick one, be consistent)
   ↓
Repository layer (abstracts Firestore/Auth/Storage — never call Firebase SDK directly from UI)
   ↓
Firebase: Firestore | Authentication | Cloud Functions | Storage | FCM
```

**Client vs. server-side logic — the one rule that matters most:**
Simple reads (product list, dashboard) go direct from the Flutter client to Firestore. Anything that touches **money or stock** — creating a sale, recording a payment, adjusting stock — must go through a **Cloud Function**, not a direct client write. The client calls a callable Cloud Function (e.g. `createSale`), the function runs the Firestore transaction (decrement stock, update dues, write the invoice) server-side, and only then does the client see the result. This is what makes the security requirement in the master document ("server-side business logic," "server-side payment verification") actually true, rather than just stated intent — a raw client write to `sales/` would let a compromised or buggy client corrupt stock or dues directly.

**Firestore Security Rules**, as a consequence of the above, can stay simple: reads are scoped to `request.auth.uid == businesses/{businessId}.ownerUid`; writes to `products`, `sales`, `payments`, `stock_movements` are denied from the client entirely and only permitted via the Admin SDK inside Cloud Functions.

**Auth flow:** Phone OTP via Firebase Auth → on success, look up or create the `businesses/{businessId}` document linked to that `ownerUid` → route to Setup (new) or Dashboard (returning).

**Offline & sync:** Firestore's offline persistence covers simple reads/cached views across all four platforms. Because sales/payments route through Cloud Functions (not direct writes), a fully offline sale cannot be finalized in real time — V0.1 should queue an offline sale locally and submit it to the Cloud Function once connectivity returns, showing it as "pending sync" in the UI rather than silently pretending it's confirmed.

**Desktop & Web specifics:** same Flutter codebase and Cloud Functions backend; no separate API needed. Desktop build is lower priority to actually ship first (owners bill from phones on the shop floor) — sequence as Android → Web → iOS → Desktop unless a specific pilot retailer needs desktop/iOS on day one.

## 8. Non-Functional Requirements

- **Tenant isolation:** every Firestore read/write must be scoped by `businessId`; Firestore Security Rules must enforce that a user can only access documents under their own `businesses/{businessId}` (matched via `ownerUid`, and later `staffUids` once roles ship).
- **Data integrity:** stock decrements and payment/dues updates must use Firestore transactions or batched writes, not sequential unguarded writes, to prevent race conditions from double-billing or concurrent stock edits.
- **Offline tolerance:** Firestore's offline persistence should be enabled so billing keeps working on a spotty connection and syncs once back online — important for retail shop-floor conditions.
- **Performance:** product list and dashboard should load in under 2 seconds for a catalogue of up to ~2,000 products (reasonable ceiling for a single retail outlet).
- **Backup:** rely on Firebase's built-in Firestore durability for V0.1; a scheduled export (Cloud Function → Cloud Storage) is a good early addition even pre-V0.2, since this is financial data.

## 9. Firestore Structure Summary

```
businesses/{businessId}
  products/{productId}
  stock_movements/{movementId}
  customers/{customerId}
  sales/{saleId}
  payments/{paymentId}
```

All collections are subcollections under `businesses/{businessId}` — this keeps tenant isolation simple to express in Security Rules (`match /businesses/{businessId}/{document=**} { allow read, write: if request.auth.uid == resource.data.ownerUid ... }` style, refined once roles exist).

## 10. Success Criteria for V0.1

- A real retailer can go from signup to their first saved invoice without any hand-holding.
- Stock numbers stay accurate after a day of real billing (no drift from race conditions).
- Owner can answer "what do I have low on stock" and "who owes me money" from the Dashboard alone, without asking anyone.

## 11. Open Questions

- **PDF invoices:** is a lightweight Cloud Function–generated PDF feasible in the V0.1 timeline, or does invoice sharing ship as formatted text/image only, with true PDF deferred to V0.2 as the master roadmap states?
- **GST/tax handling:** V0.1 above assumes a simple flat tax field. If early retailer conversations show GST-slab-accurate invoicing is a hard requirement (not a nice-to-have), this needs to move from V0.2 into V0.1 scope.
- **Staff logins:** confirm whether any pilot retailer actually needs a second user on day one, or whether single-Owner-login is sufficient to get the first 3–10 customers live.
