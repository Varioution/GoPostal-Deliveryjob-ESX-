# GoPostal Deliveryjob (ESX)

Kortom
- Je neemt dienst bij het depot en start een route.
- Je pakt een doos uit de bus, levert bij het adres en gaat door.
- Aan het eind ga je terug naar het depot en krijg je je geld.

Zo begin je
- Ga naar het depotped en kies “In dienst / Start”.
- Spring in de bus. Achterkant = dozen.

Onderweg
- Doos pakken: loop naar de achterkant van de bus en druk `E`.
- Normaal bezorgen: bij het adres staat een persoon. Loop erheen en geef de doos.
- Niet thuis: je krijgt een melding + korte tekst (blauwe marker volgen). Leg de doos neer bij die marker met `E`.
- Pickup (pakket ophalen): je ziet vroeg een melding dat er een pakket klaarligt. Bij het huis staat één persoon met doos. Gebruik `ox_target` om die doos aan te nemen. Daarna laad je hem in de bus met `E`.
- Handtekening: soms moet je tekenen. Er komt een simpele teken schermpje met ox. Tekenen met muis.

Instellingen (config.lua)
- `DeliveriesPerRoute`: aantal adressen in je route.
- `PayPerDrop`: geld per doos.
- `FinishBonusPerDrop`: extra bonus bij afronden.
- `SignatureChance`: kans op handtekening.
- `NotHomeChance`: kans dat iemand niet thuis is.
- `PickupChance`: kans op ophalen.
- `BackDropRadius`: radius om neer te leggen bij de blauwe marker.

Features
- Handtekening (ox_lib): teken met muis.
- Pickup: persoon met doos, pak via `ox_target`, daarna inladen met `E`.
- Niet thuis: melding + blauwe marker, leg neer met `E`.
- Dozen in de bus zien er netjes uit met meer ruimte.

Wat is nieuw
- Handtekening via ox
- Pickup systeem (persoon met doos, aannemen, inladen in bus)
- Niet thuis = neerleggen in de buurt (blauwe marker volgen, neerleggen telt meteen)

Afronden
- Ga terug naar het depot en kies “Afronden”. Je krijgt je uitbetaling over de bezorgde dozen.

Tip
- Wil je de percentages veranderen voor bepaalde kansen? Zet bijvorobeeld `NotHomeChance` hoger en geef bij adressen `nh` of `back` coördinaten op.