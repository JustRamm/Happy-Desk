<p align="center">
  <img src="assets/brand/U&ME.svg" width="200" alt="U&ME Logo"/>
</p>

<h3 align="center">Happy Desk</h3>
<p align="center">workplace joy, reinvented.</p>

---

## what is this?

Happy Desk is a team engagement app built with Flutter. the idea is simple — work doesn't have to feel like a grind. this app brings together attendance tracking, team communication, anonymous appreciation, and a bunch of small features that make day-to-day office life a little more fun.

it's still a work in progress, but the core stuff is in place.

## what's in here right now

- **clock in / clock out** — auto-detects location, tracks work sessions, has a break mode
- **leave management** — apply for leave, check history, view stats (beach umbrella icon, because why not)
- **direct messages** — 1:1 chat with teammates, search, online indicators
- **team notifications** — broadcast feed for clock-ins, approved leaves, coffee break invites, weekly hero shoutouts
- **NGL jar** — anonymous appreciation notes from teammates. you can read them but you won't know who sent them
- **weekly hero** — peer nominations, the team votes, someone gets the crown for the week
- **coffee break invites** — send a group coffee break nudge to your team
- **profile & settings** — avatar picker, department selection, notification preferences, theme stuff
- **onboarding flow** — paginated sign-up with role selection (founder vs employee), leadership code generation, invite codes
- **splash screen** — fluid orange animation with the U&ME logo reveal

## tech

- Flutter (Dart)
- Google Fonts (Plus Jakarta Sans, Be Vietnam Pro)
- SVG rendering via `flutter_svg`
- no backend hooked up yet — all data is local/mock for now

## project structure

```
lib/
├── screens/          # all the app screens
├── widgets/          # reusable components (modals, nav bar, etc)
├── services/         # stores and notification logic
├── theme/            # colors, typography, design tokens
assets/
├── brand/            # U&ME logo, app icons
├── avatars/          # profile avatar presets
web/                  # web-specific config and icons
```

## running it

```bash
flutter pub get
flutter run -d chrome    # or any device/emulator
```

needs Flutter 3.x. tested mostly on Chrome (web) so far.

## what's next

- actual backend (Firebase or similar)
- real auth flow
- push notifications
- proper image upload for avatars
- admin dashboard for founders
- dark mode (the theme tokens are partially ready)

## screenshots

*coming soon — the app changes too fast right now to keep these up to date*

---

built with late-night coffee and Flutter.
