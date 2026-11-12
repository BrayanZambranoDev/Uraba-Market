# Design System Strategy: The Living Archive

This design system is a "Jungle-Tech" manifesto. It is designed to bridge the gap between the raw, untamed vitality of the Urabá region and the precision of world-class luxury e-commerce. We are moving away from the "app-in-a-box" aesthetic toward a "Digital Editorial" experience. 

### 1. Creative North Star: "Organic Heritage"
The Creative North Star for this system is **The Living Archive.** Every interface should feel like a high-end botanical journal curated for a modern global audience. We reject the rigid, sterile grids of standard marketplaces. Instead, we embrace:
*   **Intentional Asymmetry:** Elements should feel like they are growing into the space, not just placed there.
*   **Tonal Depth:** We define space through color and light, never through structural lines.
*   **Tactile Sophistication:** Using glassmorphism and organic radii to mimic the way light filters through a jungle canopy.

---

### 2. Color & Atmosphere
Our palette is rooted in the earth but polished for the screen. We use depth and transparency to create a sense of place.

*   **Primary (`#01261f`) & Primary Container (`#1a3c34`):** These represent the deep, mysterious jungle. Use these for high-impact brand moments and immersive backgrounds.
*   **Secondary (`#006e1c`):** The vibrant banana leaf. Use this sparingly for interactive highlights and success states to provide a "pop" of life.
*   **Tertiary (`#301b17`):** The cacao brown. This is our "anchor" color, providing warmth and heritage to text and small UI accents.
*   **Surface & Background (`#fbfbe2` / `#f5f5dc`):** The Caribbean sand. This is the canvas. It is warm, breathable, and premium.

#### The "No-Line" Rule
**Explicit Instruction:** Designers are prohibited from using 1px solid borders for sectioning or containment. Boundaries must be defined solely through background color shifts.
*   Example: A `surface-container-low` section sitting on a `surface` background provides all the definition needed.
*   **Signature Textures:** Use subtle linear gradients from `primary` to `primary-container` on hero sections to create "visual soul." Avoid flat fills on large areas.

---

### 3. Typography: The Editorial Voice
We use a high-contrast typographic scale to create a sense of hierarchy and prestige.

*   **The Heritage Serif (notoSerif):** Used for all `display` and `headline` roles. This font carries the weight of history and quality. It should always feel expansive and intentional.
*   **The Precision Sans (manrope):** Used for `body`, `title`, and `label` roles. This provides the "tech" in "jungle-tech"—clean, highly legible, and modern.

**Hierarchy Note:** To achieve the high-end editorial look, use `display-lg` (3.5rem) for hero titles paired immediately with `body-md` for descriptions. This extreme "Size Gap" is a hallmark of luxury design.

---

### 4. Elevation & Depth: Tonal Layering
In this system, we do not "drop shadows" in the traditional sense. We layer light.

*   **The Layering Principle:** Depth is achieved by "stacking" surface tiers. Place a `surface-container-lowest` card on a `surface-container-low` background to create a soft, natural lift.
*   **Ambient Shadows:** If an element must float (like a bottom sheet or a floating action button), use a shadow tinted with the `on-surface` color at only 4-6% opacity. It should look like a soft glow, not a grey blur.
*   **Glassmorphism:** For overlays and navigation bars, use `surface-variant` with a 60% opacity and a `backdrop-filter: blur(20px)`. This allows the vibrant colors of product photography to bleed through, making the UI feel integrated into the "jungle."
*   **The "Ghost Border" Fallback:** If a border is required for accessibility, use the `outline-variant` at 15% opacity. Never use 100% opaque outlines.

---

### 5. Signature Components

#### Buttons
*   **Primary:** High-pill shape (`rounded-full`), using `primary` background with `on-primary` text. Add a subtle 2px inner-glow (lighter green) on the top edge to simulate a 3D organic surface.
*   **Secondary:** `surface-container-highest` background with `on-surface` text. No border.

#### Cards & Lists
*   **The Card Rule:** Cards must never have borders. Use the `xl` (1.5rem) roundedness scale to feel organic.
*   **List Separation:** Forbid divider lines. Separate list items using `8px` of vertical white space or a very subtle shift from `surface` to `surface-container-low`.

#### Input Fields
*   **Styling:** Use "Soft Inset" styling. A `surface-container-highest` background with an `xl` corner radius. The label (`label-md`) should sit elegantly above the field in `tertiary`.

#### Interactive Chips
*   **Filter Chips:** Use `secondary-container` for active states. The shape should be `rounded-full` to mimic the smooth stones of a Caribbean beach.

---

### 6. Do’s and Don'ts

#### Do:
*   **Use Generous Whitespace:** Let the "sand" (`surface`) breathe. Luxury is defined by the space you don't use.
*   **Use "Hero" Photography:** Photography should be full-bleed or use organic, non-rectangular masks (e.g., leaf-inspired curves).
*   **Asymmetric Grids:** Offset images from text blocks to create a rhythmic, magazine-like flow.

#### Don't:
*   **Don't use Pure Black:** Use `primary` or `tertiary` for dark tones. Pure black kills the organic warmth of the system.
*   **Don't use Standard Icons:** Use thin-stroke, rounded icons that match the `manrope` weight.
*   **Don't Over-Animate:** Transitions should be "Liquid-Slow." Use long durations (400ms-600ms) with elegant ease-in-out curves to mimic natural movement.

### 7. Accessibility
While we prioritize aesthetics, readability is non-negotiable. Ensure that all `on-surface` and `on-primary` text meets WCAG AA standards against their respective backgrounds. Use the `error` (`#ba1a1a`) token sparingly—it should feel like a warning "poison dart frog" red, distinct from the lush surroundings.