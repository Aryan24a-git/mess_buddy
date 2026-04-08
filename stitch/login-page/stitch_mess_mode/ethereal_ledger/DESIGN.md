# Design System Document

## 1. Overview & Creative North Star: "The Ethereal Ledger"
This design system moves away from the rigid, spreadsheet-like architecture of traditional expense trackers. Our Creative North Star is **The Ethereal Ledger**—a concept that treats financial data not as a static table, but as a fluid, high-end digital environment. 

We break the "template" look through **tonal depth** and **intentional breathing room**. Instead of boxing data into claustrophobic containers, we use glassmorphism and soft gradients to create a sense of infinite space. The aesthetic is fast, minimal, and premium, prioritizing the "glanceability" required for busy hostel environments while maintaining the sophisticated polish of a private wealth management tool.

---

## 2. Colors & Surface Architecture

### Palette Definition
The palette is rooted in a deep, nocturnal base, punctuated by high-vibrancy accents that guide the eye toward actionable data.

*   **Core Background:** `#111317` (Surface/Surface-Dim)
*   **Primary Accent:** `#C4C0FF` (Primary) — Used for high-priority CTAs and total balance highlights.
*   **Secondary Accent:** `#A2E7FF` (Secondary) — Used for "New Transaction" actions and growth indicators.
*   **Tertiary/Warning:** `#FFB785` (Tertiary) — Used for pending debts or split-bill alerts.

### The "No-Line" Rule
To maintain a high-end feel, **1px solid opaque borders are strictly prohibited for sectioning.** Physical boundaries must be defined through:
1.  **Tonal Shifts:** Placing a `surface-container-low` card on a `surface` background.
2.  **Glass Differentiation:** Overlapping a `rgba(255, 255, 255, 0.08)` card with a `backdrop-filter: blur(12px)`.

### Surface Hierarchy & Nesting
Treat the UI as a series of stacked frosted sheets. 
*   **Level 0 (Base):** `surface` (#111317).
*   **Level 1 (Sections):** `surface-container-low` (#1A1C20).
*   **Level 2 (Interactive Cards):** Glassmorphic fills (`rgba(255,255,255,0.08)`) with a "Ghost Border" (1px `outline-variant` at 15% opacity).

---

## 3. Typography: Editorial Authority

We use a dual-typeface system to balance technical precision with modern elegance.

*   **Display & Headlines (Plus Jakarta Sans):** Our "Hero" font. Use `display-lg` (3.5rem) for massive balance numbers and `headline-sm` (1.5rem) for category titles. The wide aperture of Jakarta Sans feels expensive and airy.
*   **Body & Labels (Manrope):** Our functional workhorse. Manrope's geometric nature ensures that even at `body-sm` (0.75rem), metadata remains legible.

**Typographic Intent:**
*   **Key Numbers:** Always `Bold`. Money is the hero of the story.
*   **Labels:** `Medium`. They should feel supportive, not dominant.
*   **Metadata:** `Regular` at `label-sm`. Use `on-surface-variant` (#C7C4D8) to de-emphasize secondary info.

---

## 4. Elevation & Depth: Tonal Layering

Traditional shadows feel "muddy" in dark mode. We achieve lift through **Tonal Layering** and **Ambient Light**.

*   **The Layering Principle:** To lift a card, do not use a black shadow. Instead, increase the lightness of the glass fill or the `surface-container` tier.
*   **Ambient Shadows:** For floating elements (Modals/FABs), use a wide-dispersion shadow: `box-shadow: 0 20px 40px rgba(0, 0, 0, 0.4)`.
*   **The Glassmorphism Rule:** All cards must use `backdrop-filter: blur(20px)`. This allows the vibrant primary/secondary accents to "bleed" through the background as the user scrolls, creating a dynamic, living interface.

---

## 5. Components

### Buttons
*   **Primary:** A vibrant gradient from `primary` (#C4C0FF) to `primary-container` (#8781FF). High-rounded corners (`full` scale).
*   **Secondary (Glass):** `rgba(255, 255, 255, 0.1)` background with a "Ghost Border" of `primary` at 20% opacity.
*   **Tertiary:** No background. `label-md` weight text in `secondary-fixed-dim`.

### Cards & Lists (The Ledger Items)
*   **Constraint:** Forbid divider lines.
*   **Implementation:** Separate transaction items using `spacing-4` (1rem) vertical gaps.
*   **Visual Cue:** Use a subtle `surface-bright` (#37393E) left-accent bar (4px width) to indicate "paid" vs "unpaid" status instead of an icon.

### Input Fields
*   **Default State:** `surface-container-highest` background with `rounded-lg` (1rem). 
*   **Active State:** The "Ghost Border" illuminates. 1px solid `secondary` at 30% opacity. Backdrop blur increases by 10%.

### Additional App-Specific Components
*   **The "Split-Indicator" Chip:** A micro-component showing hostel room-mate avatars. These should overlap by -8px to emphasize "shared" space.
*   **Debt Glow-Card:** For users who owe money, the card background should have a subtle inner-glow of `tertiary-container` at 5% opacity to create a gentle sense of urgency.

---

## 6. Do's and Don'ts

### Do:
*   **Do** use asymmetrical spacing. A `24px` top margin and `16px` side margin can make a screen feel like a custom editorial layout rather than a generic app.
*   **Do** lean into the "Ghost Border." A border that is barely visible is more premium than one that is easily seen.
*   **Do** use the `20px` (xl) roundedness for large summary cards and `12px` (md) for nested elements.

### Don't:
*   **Don't** use pure black (#000000) or pure white (#FFFFFF) for surfaces. It breaks the "frosted glass" illusion.
*   **Don't** use standard "drop shadows" on cards. If it doesn't look like it's floating in a 3D space via color shift, don't force it with a shadow.
*   **Don't** use more than two font weights on a single card. Let the size and color do the heavy lifting for hierarchy.