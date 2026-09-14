---
name: Executive Slate
colors:
  surface: '#f8f9ff'
  surface-dim: '#cbdbf5'
  surface-bright: '#f8f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eff4ff'
  surface-container: '#e5eeff'
  surface-container-high: '#dce9ff'
  surface-container-highest: '#d3e4fe'
  on-surface: '#0b1c30'
  on-surface-variant: '#45464d'
  inverse-surface: '#213145'
  inverse-on-surface: '#eaf1ff'
  outline: '#76777d'
  outline-variant: '#c6c6cd'
  surface-tint: '#565e74'
  primary: '#000000'
  on-primary: '#ffffff'
  primary-container: '#131b2e'
  on-primary-container: '#7c839b'
  inverse-primary: '#bec6e0'
  secondary: '#0051d5'
  on-secondary: '#ffffff'
  secondary-container: '#316bf3'
  on-secondary-container: '#fefcff'
  tertiary: '#000000'
  on-tertiary: '#ffffff'
  tertiary-container: '#002113'
  on-tertiary-container: '#009668'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dae2fd'
  primary-fixed-dim: '#bec6e0'
  on-primary-fixed: '#131b2e'
  on-primary-fixed-variant: '#3f465c'
  secondary-fixed: '#dbe1ff'
  secondary-fixed-dim: '#b4c5ff'
  on-secondary-fixed: '#00174b'
  on-secondary-fixed-variant: '#003ea8'
  tertiary-fixed: '#6ffbbe'
  tertiary-fixed-dim: '#4edea3'
  on-tertiary-fixed: '#002113'
  on-tertiary-fixed-variant: '#005236'
  background: '#f8f9ff'
  on-background: '#0b1c30'
  surface-variant: '#d3e4fe'
typography:
  display-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.015em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Manrope
    fontSize: 16px
    fontWeight: '500'
    lineHeight: 24px
  body-md:
    fontFamily: Manrope
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Manrope
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
  label-lg:
    fontFamily: Manrope
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Manrope
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Manrope
    fontSize: 11px
    fontWeight: '700'
    lineHeight: 14px
    letterSpacing: 0.04em
  data-mono:
    fontFamily: Manrope
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: -0.01em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-mobile: 0.75rem
  margin: 1.5rem
  margin-mobile: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

This design system establishes an executive-grade operational environment tailored for fast-paced inventory management, invoicing, and real-time cash flow oversight. It bridges high-density utility with the polished restraint of contemporary financial applications. 

The visual style blends Corporate Modernism with crisp architectural precision:
- **Tone:** Authoritative, razor-sharp, dependable, and swift.
- **Visual Weight:** Light, breathable canvasing framed by structural deep slate tones and high-contrast typographic hierarchy.
- **Emotional Impact:** Reassures business owners with order, fiscal stability, and rapid operational feedback. It intentionally strips out playful fluff in favor of dense, legible data layouts, clear status delineations, and tactile interaction surfaces.

## Colors

The palette balances structural foundational tones with vivid, semantic feedback cues:

- **Primary (`#0F172A` - Deep Slate):** Anchors headers, primary brand marks, navigation bars, and definitive structural cards. Communicates security and institutional weight.
- **Secondary (`#2563EB` - Royal Blue):** Drives primary interaction points, interactive links, focused states, and key operational calls to action such as generating invoices or adjusting inventory counts.
- **Tertiary (`#10B981` - Emerald Green):** Reserved strictly for positive financial states, successful reconciliations, and healthy in-stock metrics.
- **Neutral (`#64748B` - Slate Muted):** Used for auxiliary labels, metadata, inactive icons, and structural line dividers.

### Supporting Semantic Colors
- **Amber Warning (`#F59E0B`):** Low stock thresholds, pending invoice processing, and review warnings.
- **Crimson Critical (`#EF4444`):** Out-of-stock anomalies, overdue invoices, and destructive administrative actions.
- **Surface Foundations:** Background canvas relies on pure neutral off-white (`#F8FAFC`), layered against pristine white (`#FFFFFF`) cards and soft slate borders (`#E2E8F0`).

## Typography

Typographic decisions pair the geometric modernism of **Plus Jakarta Sans** for structural headers with the rational legibility and balanced proportions of **Manrope** for analytical body text and data grids.

- **Headlines & Figures:** Plus Jakarta Sans provides strong horizontal anchors for total inventory counts, invoice amounts, and modal titles.
- **Body & Tabular Readouts:** Manrope is tuned for tabular figure alignment, ensuring financial amounts, SKUs, and unit counts align vertically without jitter.
- **Micro-Copy:** Label styles use subtle positive tracking (`0.02em` to `0.04em`) to maintain sharp scannability at small sizes within badges and invoice status markers.

## Layout & Spacing

The layout is built on a tight, deterministic 4px base grid optimized for handheld operation:

- **Mobile First Canvas:** Base horizontal margin is fixed at `1rem` (16px) on mobile viewports to prioritize screen estate for dense list views, transitioning to `1.5rem` (24px) on tablet and desktop interfaces.
- **Section Rhythm:**
  - `space-xs` (4px) strictly defines inline icon-to-label offsets and badge inner vertical padding.
  - `space-sm` (8px) separates list item content rows, compact input fields, and tag groups.
  - `space-md` (16px) governs internal card padding and default vertical stacking.
  - `space-lg` (24px) separates logical dashboard panels, KPI overview groupings, and form fieldsets.
  - `space-xl` (32px) defines major container margins and modal sheet section breaks.

## Elevation & Depth

This design system avoids exaggerated, dark drop shadows, adopting an executive architectural depth strategy relying on low-contrast structural outlines paired with ambient, diffused shadows:

- **Surface 0 (Base Canvas):** `#F8FAFC`. Completely flat, non-elevated background.
- **Surface 1 (Cards & Data Panels):** `#FFFFFF` background bound by a 1px continuous stroke of `#E2E8F0`. Shadow: `0px 1px 3px rgba(15, 23, 42, 0.04), 0px 1px 2px rgba(15, 23, 42, 0.02)`.
- **Surface 2 (Floating Action Elements & Dropdowns):** `#FFFFFF` canvas with a refined border of `#CBD5E1`. Shadow: `0px 4px 6px -1px rgba(15, 23, 42, 0.07), 0px 2px 4px -2px rgba(15, 23, 42, 0.04)`.
- **Surface 3 (Modals & Bottom Drawers):** `#FFFFFF` resting above an ambient scrim of `#0F172A` with 30% opacity. Shadow: `0px 20px 25px -5px rgba(15, 23, 42, 0.1), 0px 8px 10px -6px rgba(15, 23, 42, 0.05)`.

## Shapes

The design system standardizes on an engineered `Level 2` curvature, bringing softness without compromising precision:

- **Base Radius (0.5rem / 8px):** Buttons, text input boxes, dropdown selectors, and small notification chips.
- **Large Radius (`rounded-lg`, 1rem / 16px):** Metric widgets, list item containers, and operational workflow modals.
- **Extra Large Radius (`rounded-xl`, 1.5rem / 24px):** Primary mobile dashboard hero cards, fiscal overview blocks, and mobile sheet bottom sheets.
- **Full Radius (Pill):** Dedicated exclusively to inline operational status indicators (e.g., "Paid", "Overdue", "In Stock").

## Components

### Buttons
- **Primary:** Background `#2563EB`, text `#FFFFFF`, radius 8px, font `label-lg`. Smooth active transition to `#1D4ED8` with no drop shadow to sustain clean contrast.
- **Dark Neutral (Executive):** Background `#0F172A`, text `#FFFFFF`. Used for high-level system triggers (e.g., "Export Ledger").
- **Secondary:** Transparent background, 1px solid stroke in `#E2E8F0`, text `#0F172A`. Hover transitions background to `#F1F5F9`.
- **Destructive:** Background `#FEE2E2`, text `#B91C1C`, 1px solid stroke in `#FECACA`.

### Badges & Status Chips
Pill-shaped containers (`rounded-full`) utilizing tinted surfaces with high-contrast text for critical financial tracking:
- **Paid / Healthy Stock:** Background `#ECFDF5`, border `#A7F3D0`, text `#047857`.
- **Pending / Low Stock:** Background `#FFFBEB`, border `#FDE68A`, text `#B45309`.
- **Overdue / Out of Stock:** Background `#FEF2F2`, border `#FECACA`, text `#B91C1C`.
- **Draft / Inactive:** Background `#F1F5F9`, border `#E2E8F0`, text `#475569`.

### Input Fields
- Enclosed input frames with 8px radius, `#FFFFFF` fill, 1px border stroke of `#CBD5E1`.
- Focused state applies a 1px border of `#2563EB` paired with an external 3px box-shadow halo in `rgba(37, 99, 235, 0.15)`.
- Suffix elements handle currency signs (`$`, `€`) and SKU scanner quick-actions with muted slate styling.

### Lists & Inventory Rows
- Structured within `rounded-lg` containers with separated 1px borders in `#F1F5F9`.
- Left-aligned primary attributes (Item name, SKU, Invoice ID) paired with right-aligned high-visibility tabular numbers (Quantity count, Balance sum) in `data-mono`.

### Cards
- Standard operational card utilizes `rounded-xl` (24px) geometry, 16px internal padding, crisp `#E2E8F0` framing, and clean separation between analytical KPI headers and contextual historical charts.