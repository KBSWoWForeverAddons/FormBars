# Changelog

## [v1.0.0] - 2026-11-20

### Added
- Reliable `[form:N]` and `[form:N,stealth]` Bar 1 paging for Bear Form (`Page 9`), Cat Form (`Page 7`), Cat Form + Prowl (`Page 8`), and Moonkin / Tree of Life (`Page 10`) on WoW Forever (`16001`).
- Seamless support for both **Blizzard's default `MainActionBar`** and **Dominos** (`DominosFrame1`).
- Powershift-safe state driver handling so `/cast !Dire Bear Form` and `/cast !Cat Form` macros reliably return to the active form bar.
- Automatic one-time reminder if Page 8 Prowl slots still contain level-1 Caster spells (`Moonfire` / `Wrath`).
- `/formbars` (`/fb`) slash command to inspect active mode, detected form slots, and current Bar 1 state.
- Custom `FormBars` addon icon for the Blizzard AddOns menu.
