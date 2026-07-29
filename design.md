---
name: U & ME Design System
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

## Mandatory Design Rules & Directives

> **STRICT EMOJI POLICY:** No use of emojis is appreciated anywhere in the codebase, UI text, notifications, or assets. Always use clean vector Material icons (`Icons.*`) or custom SVG painters.  
> **DESIGN ANALYSIS RULE:** Always inspect and analyze `design.md` before implementing any UI changes, and update this document whenever design patterns evolve.

---

## Brand & Style

**App Name:** U & ME  
The brand personality is exuberant, supportive, and community-driven. It aims to transform mundane workplace stress into moments of calm, connection, and appreciation between colleagues. The target audience consists of modern startup and hybrid teams who value mental well-being, psychological safety, and a "people-first" culture.

The visual style is a mix of **Modern Minimalist structure** and **Tactile/Vibrant energy**. It utilizes organic rounded shapes and character illustrations to humanize the interface. A key differentiator is the use of subtle textures and soft elevation.

---

## Navigation Architecture & Bottom Bar

1. **Bottom Navigation Bar (`CustomBottomNavBar`):**
   - **Style:** Modern floating pill navigation bar with active gradient pills (`[#FF6B35, #FF8552]`) and vibrant soft shadow glow.
   - **4 Core Tabs:**
     - **Tab 0 — Home (`HomeScreen`):** `Icons.home_outlined` / `Icons.home_rounded`
     - **Tab 1 — Kudos (`KudosScreen`):** `Icons.auto_awesome_outlined` / `Icons.auto_awesome_rounded`
     - **Tab 2 — Messages (`ChatNotificationsScreen`):** `Icons.chat_bubble_outline_rounded` / `Icons.chat_bubble_rounded`
     - **Tab 3 — Profile (`ProfileScreen`):** `Icons.person_outline_rounded` / `Icons.person_rounded`

---

## Screen Architecture & Layout Rules

1. **Home Screen (`HomeScreen`):**
   - **Top Header Bar:** Brand logo on left + **Notifications Bell Icon** (`Icons.notifications_rounded`) and **Coffee Break Icon** (`Icons.local_cafe_rounded`) on right.
   - **Greeting Headline:** "Let's spread some joy today."
   - **First Card Position:** **Clock-In / Work Session Card** is ALWAYS first.
   - **De-Stress Quick Actions:** 60s Breathing & Desk Stretches.
   - **Educational Cards:** Daily Stress-Buster Skill Card, Daily Joy Quest Card, NGL Jar Card (Soft Lavender `#EEF0FF`), & Weekly Hero Card.

2. **Kudos & Recognition Hub (`KudosScreen`):**
   - **Top Header Bar:** Brand logo on left + Notifications Bell Icon & Coffee Break Icon on right (matching Home Screen).
   - **Header Title:** "Kudos & Teammate Recognition"
   - **Hero Cards:** NGL Appreciation Jar Card (Soft Lavender `#EEF0FF`) & Weekly Hero Nominations Card (Soft Emerald `#D1FAE5`).

3. **NGL Jar Screen (`JarScreen`):**
   - Contains the **Paper Shredder Stress Vent** widget with custom SVG vector shredder, text-to-paper-strips shredding animation, and sound effect.

4. **Messages Hub (`ChatNotificationsScreen`):**
   - Dedicated messaging tab for direct & group teammate conversations.
   - **Top-Right Header Action:** New Chat & Search selector to initiate 1-on-1 colleague conversations.

5. **Standalone Notifications Screen (`NotificationsScreen`):**
   - Accessed via top-right Notifications Bell icon on Home & Kudos screens.
   - Displays coffee break invites with working **Join Break** & **Decline** action buttons.

6. **1-on-1 Direct Chat Screen (`DirectChatScreen`):**
   - Dedicated 1-on-1 direct messaging interface for each colleague.
   - **Top-Right Action:** Coffee Icon (`Icons.local_cafe_rounded`) immediately sends an individual 5-minute coffee break invite to that colleague.
