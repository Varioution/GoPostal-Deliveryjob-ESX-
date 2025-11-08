# GoPostal Deliveryjob (ESX)

Wat doet het
- Je gaat in dienst bij het depot en start een route.
- Je pakt een doos uit het busje en levert bij de NPC.
- Je rondt af bij het depot en krijgt je uitbetaling.

Gebruik (simpel)
- Start: loop naar het depot en kies “Start route”.
- Doos pakken: ga naar de achterzijde van het busje. Druk op `E`.
- Levering: loop naar de NPC en geef de doos.
- Afronden: terug naar het depot, kies “Afronden” en bevestig.

Keuzes (kort)
- Oppakken met `E`: snel en duidelijk.
- Alleen oppakken dichtbij het afleveradres preventeert abuse/bugs.

Config (config.lua)
- `DeliveriesPerRoute`: aantal adressen (standaard 20).
- `PayPerDrop`: uitbetaling per doos (standaard 400).
- `FinishBonusPerDrop`: extra per doos bij afronden (standaard 0).

Installatie
- In `server.cfg`: `ensure deliveryjob` (`deliveryjob` kan gerenamed worden)