# FormBars

**Reliable Druid shapeshift, Prowl, and powershift action bar paging for WoW Forever (`16001`).**

`FormBars` fixes Druid Bar 1 paging issues on WoW Forever where powershifting (`/cast !Dire Bear Form`, `/cast !Cat Form`) or entering **Prowl** causes Bar 1 to get stuck on your Caster bar or lose its form page. It works seamlessly with both **Blizzard's default action bars** and **Dominos**.

---

## Why FormBars?

On WoW Forever's client (`16001`):
- Rapidly powershifting with `!Form` macros can cause `[bonusbar:N]` conditions to drop to `0` and miss the re-shift, leaving Bar 1 stuck on Caster Form (`Page 1`).
- **Dominos** defaults to `[bonusbar]` conditions for Druids and omits a default paging offset for **Prowl** (`Page 8`).

`FormBars` replaces unreliable `[bonusbar]` checks with dynamic **`[form:N]`** and **`[form:N,stealth]`** state drivers that automatically detect your character's exact shapeshift bar slot indices—even as you unlock new forms while leveling.

---

## Features

- **Powershift-Safe Paging:** Uses `[form:N]` conditions (with `[bonusbar:N]` as secondary fallback) so `/cast !Dire Bear Form` and `/cast !Cat Form` reliably return to your Bear or Cat bar.
- **Dedicated Prowl Bar:** Automatically switches Bar 1 to **Page 8** (slots `85–96`) when stealthed in Cat Form (`[form:N,stealth]`).
- **Blizzard & Dominos Support:**
  - **With Dominos:** Updates `Dominos.BarStates` for `bear`, `cat`, and `prowl` to use `[form:N]` and ensures `prowl` (`Page 8`) is mapped on `DominosFrame1`.
  - **With Default Blizzard Bars:** Uses a taint-free `SecureHandlerStateTemplate` header to update `ActionButton1`–`ActionButton12` cleanly without breaking `Shift+1..6` paging in Caster Form.
- **Zero-Config & Combat-Safe:** Automatically rebuilds bindings when forms change (`UPDATE_SHAPESHIFT_FORMS`, `SPELLS_CHANGED`), deferring updates cleanly until after combat if needed.
- **Helpful Prowl Reminder:** Alerts you once if your Page 8 Prowl slots still contain level-1 Caster spells (`Moonfire` / `Wrath`) copied by the server.

---

## Action Bar Page Mapping

| Form / State | Bar 1 Page | Action Slots |
| :--- | :---: | :---: |
| **Caster / Human / Travel / Aquatic** | Page 1 | `1 – 12` |
| **Cat Form** | Page 7 | `73 – 84` |
| **Cat Form + Prowl (Stealth)** | Page 8 | `85 – 96` |
| **Bear / Dire Bear Form** | Page 9 | `97 – 108` |
| **Moonkin / Tree of Life** | Page 10 | `109 – 120` |

---

## Installation

1. Download or clone this repository.
2. Copy the `FormBars` folder into your WoW Forever AddOns directory:
   ```text
   World of Warcraft\_forever_\Interface\AddOns\FormBars\
   ```
3. Ensure the folder contains:
   - `FormBars.toc`
   - `FormBars.lua`
   - `FormBars.tga`
4. Enable **FormBars** in the **AddOns** menu and `/reload` (or log in).

---

## Recommended Powershift Macros

Use `!` before the form name so pressing the macro while already shifted refreshes the form instead of canceling it:

**Bear Powershift**
```wow
#showtooltip Dire Bear Form
/cast !Dire Bear Form
```

**Cat Powershift**
```wow
#showtooltip Cat Form
/cast !Cat Form
```

**Prowl Setup Note:** If your Prowl bar (`Page 8`) shows `Moonfire` / `Wrath` the first time you stealth, simply enter Cat Form + Prowl and drag your Stealth abilities (`Pounce`, `Ravage`, `Shred`, etc.) onto Bar 1 to overwrite them.

---

## Slash Commands

- `/formbars` or `/fb` — Prints your current mode (`Dominos` or `Blizzard`), detected `[form:N]` slot indices, and active Bar 1 page/action state.
