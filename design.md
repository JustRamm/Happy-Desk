---
name: Happy Desk Design System
colors:
  surface: '#faf8ff'
  surface-dim: '#d6d9ef'
  surface-bright: '#faf8ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f2ff'
  surface-container: '#ebedff'
  surface-container-high: '#e4e7fe'
  surface-container-highest: '#dee1f8'
  on-surface: '#171b2b'
  on-surface-variant: '#594139'
  inverse-surface: '#2c3041'
  inverse-on-surface: '#eff0ff'
  outline: '#8d7168'
  outline-variant: '#e1bfb5'
  surface-tint: '#ab3500'
  primary: '#ab3500'
  on-primary: '#ffffff'
  primary-container: '#ff6b35'
  on-primary-container: '#5f1900'
  inverse-primary: '#ffb59d'
  secondary: '#95416c'
  on-secondary: '#ffffff'
  secondary-container: '#ff99c8'
  on-secondary-container: '#7b2c56'
  tertiary: '#006c53'
  on-tertiary: '#ffffff'
  tertiary-container: '#00ae88'
  on-tertiary-container: '#00392b'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdbd0'
  primary-fixed-dim: '#ffb59d'
  on-primary-fixed: '#390c00'
  on-primary-fixed-variant: '#832600'
  secondary-fixed: '#ffd8e6'
  secondary-fixed-dim: '#ffafd2'
  on-secondary-fixed: '#3d0025'
  on-secondary-fixed-variant: '#782953'
  tertiary-fixed: '#64fbce'
  tertiary-fixed-dim: '#3fdeb3'
  on-tertiary-fixed: '#002117'
  on-tertiary-fixed-variant: '#00513e'
  background: '#faf8ff'
  on-background: '#171b2b'
  surface-variant: '#dee1f8'
typography:
  headline-xl:
    fontFamily: Plus Jakarta Sans
    fontSize: 40px
    fontWeight: '800'
    lineHeight: 48px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  body-lg:
    fontFamily: Be Vietnam Pro
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Be Vietnam Pro
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-md:
    fontFamily: Be Vietnam Pro
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
  label-sm:
    fontFamily: Be Vietnam Pro
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  xs: 4px
  sm: 12px
  md: 24px
  lg: 40px
  xl: 64px
  gutter: 16px
  margin-mobile: 20px
  margin-desktop: 80px
---

## Brand & Style

The brand personality is exuberant, supportive, and community-driven. It aims to transform mundane workplace tasks like clocking in into moments of joy and connection. The target audience consists of modern startup teams who value transparency, mental well-being, and a "people-first" culture.

The visual style is a mix of **Modern Minimalist structure** and **Tactile/Vibrant energy**. It utilizes organic, non-geometric shapes and character-driven illustrations to humanize the interface. A key differentiator is the use of subtle grainy textures on cards and surfaces, giving the digital experience a more grounded, physical feel that avoids the sterile look of traditional enterprise software.

## Colors

The palette is intentionally high-contrast and saturated to evoke energy and optimism. 

- **Primary (Vivid Orange):** Used for main actions and the most critical information like 'Clock-in'.
- **Secondary (Soft Pink):** Used for supportive features, wellness prompts, and the 'NGL Jar'.
- **Tertiary (Bright Green):** Indicates success states, positive attendance streaks, and 'Weekly Hero' status.
- **Accent (Sunny Yellow):** Used for highlights, playful icons, and decorative background elements.
- **Neutral:** A deep navy-charcoal is used for typography to maintain legibility against the vibrant background colors, rather than using pure black.

All surfaces should use the warm off-white background to keep the interface feeling approachable and soft.

## Typography

The typography system prioritizes warmth and personality. **Plus Jakarta Sans** is used for headings; its rounded terminals and geometric-yet-friendly construction perfectly mirror the brand's optimism. **Be Vietnam Pro** is used for body text and labels to ensure high readability with a contemporary, casual flair.

Headlines should use tight letter-spacing and heavy weights to command attention. Body text is kept airy with generous line heights to ensure the app feels "breathable" and stress-free.

## Layout & Spacing

This design system utilizes a **Fluid Grid** model with a focus on generous internal padding. Elements are not cramped; they are given "room to breathe" to reduce cognitive load.

- **Mobile:** A 4-column fluid grid with 20px side margins. Content cards usually span the full width of the grid.
- **Desktop:** A 12-column grid centered in a max-width container of 1280px. 
- **Rhythm:** All spacing follows an 8px base unit. Component internal padding should lean towards the 'md' (24px) scale to reinforce the "large and friendly" aesthetic.

## Elevation & Depth

Hierarchy is achieved through **Tonal Layers** and **Ambient Shadows** rather than traditional heavy shadows.

- **Soft Shadows:** Use extremely diffused shadows with a slight tint of the primary or secondary color (e.g., a subtle orange-tinted shadow for a primary button). Shadow opacity should never exceed 10%.
- **Grainy Textures:** Apply a 5% opacity monochromatic noise overlay to card surfaces to create a tactile, "paper-like" depth.
- **Organic Overlays:** Backgrounds should feature large, semi-transparent blobs or "squiggles" in secondary colors to create a sense of three-dimensional space without using formal Z-index layers.

## Shapes

The shape language is dominated by **Organic Roundedness**. Straight lines and sharp corners are strictly avoided to maintain the friendly tone.

- **Primary Radius:** 16px (1rem) for standard cards and containers.
- **Large Radius:** 32px (2rem) for prominent dashboard headers and "Hero" cards.
- **Icons:** Icons should feature rounded caps and joins, avoiding any razor-sharp points.
- **Buttons:** Use fully pill-shaped (rounded-full) containers for primary calls to action.

## Components

### Buttons
Primary buttons are large, pill-shaped, and use the Primary Orange. They should have a subtle 2px bottom "offset" shadow of a darker orange to give them a "squishy," pressable feel.

### Cards
Cards are the primary container. They must feature a subtle grain texture and a 1px soft border that is 10% darker than the card's background color. This ensures they "pop" against the off-white app background.

### Input Fields
Inputs should have a thick 2px border and high internal padding (16px). When focused, the border color should switch to the Secondary Pink, accompanied by a soft glow.

### The 'NGL Jar' (Special Component)
A container with a unique, slightly asymmetrical organic shape (resembling a glass jar) with a semi-transparent background and a "shimmer" effect.

### Chips & Badges
Used for 'Weekly Hero' tags. These should use the Tertiary Green with white text, featuring a high-contrast bold font weight to stand out as an achievement.

### Interaction States
Hover and active states should involve a slight scale-up (1.02x) rather than just a color change, reinforcing the playful, bouncy nature of the UI.
