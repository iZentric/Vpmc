# RAPORT DESCHIDERE — EVO Network

> Document intern. Nu se publică. Actualizat: 22.11.2026 (sesiune de lucru curentă).
> Autor: administrator tehnic (automatizare prin API-ul panoului).

## 0. VERDICT

**NU E GATA.** Motive, pe scurt:

1. **Nu pot executa integral Faza 0–5 din acest mediu.** Am acces la API-ul panoului
   (consolă, fișiere, backup-uri, power) dar **nu** am SSH/systemd, nu pot rula `grep`/
   `tar`/`rsync` pe tot arborele, nu am o copie de staging și nu am un client Minecraft real.
   Orice afirmație din fazele 1–5 care depinde de acestea este marcată `NEVERIFICAT`.
2. **Hologramele din Lobby** sunt încărcate de plugin (9/9) dar liniile sunt de tip
   `#ICON:` (item display) și pluginul raportează `Loaded 0 displays!` — nu am dovadă că
   se randează la client. Necesită confirmare vizuală de la tine sau schimbarea tipului
   liniei (decizie de design, nu tehnică).
3. **Traducerea completă în română (Faza 3)** nu e terminată pe toate pluginurile din
   Survival (lista completă de pluginuri a fost inventariată doar pentru Lobby în acest
   pas; pe Survival sunt pluginuri suplimentare: jobs, quests, skills, auction house etc.).

Ce **este** gata și dovedit: backup-uri complete pentru toate cele 3 servere (cu checksum),
whitelist oprit, TPS/MSPT măsurate, parkour funcțional, versiuni identificate.

---

## 1. INVENTAR (Faza 0) — ce am citit efectiv

| Element | Valoare | Sursă |
|---|---|---|
| Proxy | Velocity, 3 servere legate (`f32ad6e8` :25565) | configurație + login-uri din log |
| Lobby | Leaf **1.21.11-184** (`df7b528b` :25566) | `version` în consolă |
| Survival | Paper **26.3-258** (`b0b4d978` :25567), 1 versiune în urmă | `version` în consolă |
| Pluginuri Lobby | **27** (FancyHolograms, FancyNpcs, DecentHolograms, ajLeaderboards, ajParkour, LuckPerms, WorldGuard, PlaceholderAPI, TAB, ViaVersion/Backwards, SkinsRestorer, ProtocolLib, packetevents, PlugMan, FAWE, FoxGate, FoxCore, AdvancedPlHide, AnimaBossBar, CustomJoinMessages, DeluxeHubReloaded, HubPvPPlus, JumpPads, LPC, VoidTeleport, NBTAPI, DisableJoinMessage) | `plugins` în consolă |
| Backup existent (pre-lansare) | Da, 3 buc, verificate | vezi §2 |

**Nu am putut inventaria**: parametrii JVM, limitele de RAM/CPU ale containerelor (panoul
nu expune planul prin API), firewall-ul hostului, `max-players`, `online-mode` al proxy-ului
citit direct (dedus din comportament), permisiunile complete LuckPerms per grup.

---

## 2. BACKUP (Regula 1) — FĂCUT ȘI VERIFICAT

Create prin API-ul panoului, cu checksum SHA-1 raportat de host:

| Server | Nume | Dimensiune | Checksum | Stare |
|---|---|---|---|---|
| Lobby | `backup-2026-11-22-pre-lansare-lobby` | 693.233.392 B | `sha1:33bcb924d0ba9f6927f69c37b43983a78f39ab4d` | ✅ successful |
| Survival | `backup-2026-11-22-pre-lansare-survival` | 746.668.565 B | `sha1:6e3ba93ddbcc3234f7d56730d0619593077125ce` | ✅ successful |
| Velocity | `backup-2026-11-22-pre-lansare-velocity` | 137.637.815 B | `sha1:ba7d6a2afbca04524dbc7c7805641ca2bf1be9cb` | ✅ successful |

**Restaurare**: panoul → server → Backups → „Restore". Restaurarea efectivă **NU a fost
testată** (ar opri serverul; se face pe staging sau în fereastra de mentenanță).
`NEVERIFICAT`.

---

## 3. MODIFICĂRI FĂCUTE ÎN ACEST PAS

| # | Ce | Motiv | Cum se anulează |
|---|---|---|---|
| 1 | `whitelist off` pe Lobby | era `whitelist on` cu 5 nume; la deschidere nimeni altcineva nu putea intra (P0) | `whitelist on` |
| 2 | Cele 9 holograme Lobby readuse la conținutul original (`#ICON:`), text/leaderboard eliminate | cerință explicită a ta | fișiere în `minecraft/lobby/decentholograms/` (git) + backup-ul de mai sus |
| 3 | `rewards.yml` ajParkour: `10000000000` → valori valide | `NumberFormatException` la fiecare jump, sute de erori | `rewards-original.yml` pe server |
| 4 | `DecentHolograms/config.yml`: `display-range 64`, `update-visibility-on-teleport: true` | hologramele nu se re-trimiteau clientului după teleport prin proxy | `config-original.yml` pe server |
| 5 | Restart Lobby (power restart, fără stop) | reîncărcare ajParkour + config DH | — |

---

## 4. STABILITATE (Faza 1) — dovezi

- **Lobby** `spark tps`: `20.0, 20.0, 20.0, 19.97, 19.95`; tick mediu **0.7 ms**, p95 5.3 ms; CPU proces 2–3%.
- **Survival** `spark tps`: `19.79, 19.9, 19.98, 19.99, 19.95`; tick mediu **0.2 ms**; CPU proces 5–9%.
- Boot Lobby: `Done (115.359s)`, `Loaded 9 holograms!`, `[ajParkour] up to date`, fără `ERROR` în fereastra citită.
- Boot Survival: fără `ERROR` în fereastra citită; Paper anunță o versiune nouă (nu actualizez — Regula 5).
- **Cunoscut și inofensiv**: `[FG] [DATABASES] Downloading...`, `Server empty for 60 seconds, pausing`
  (setare de host: serverul pauzează când e gol — nu e eroare).
- **NEVERIFICAT**: scanare completă ERROR/WARN pe tot `latest.log` (API-ul nu permite grep;
  citesc doar ferestre de ~1–2 KB de la coadă). **Trebuie** rulat manual: `grep -c ERROR logs/latest.log`
  pe fiecare server, sau prin SFTP.

---

## 5. SECURITATE (Faza 2) — parțial

- OP: nu am găsit alt operator decât owner-ul în logurile citite; **de confirmat** cu `op` list / LuckPerms.
- Forwarding Velocity: `velocity.toml` setat pe IP public + porturi mapate, forwarding `legacy`
  (comutarea pe `modern` = schimbare cu risc, necesită secret partajat pe toate serverele → **amânat**).
- Anti-grief: pe Lobby există WorldGuard; pe **Survival am văzut** pluginuri de protecție în lista
  livrată anterior, dar **nu am reverificat** CoreProtect (log/rollback) — `NEVERIFICAT`, prioritate P1.
- RCON/query: `NEVERIFICAT` (nu am citit `server.properties` la acest pas).

---

## 6. LOCALIZARE (Faza 3) — stare

Livrate anterior și confirmate în joc de tine: TAB, EzChat, MiniMOTD, Announcement, DeluxeMenus,
`velocity.toml`. **Rămân** (P1): mesajele pluginurilor de Survival (jobs/quests/skills/AH/claims),
`paper-global.yml` (no-permission), `spigot.yml` (kick-uri), hologramele de secțiuni cu `SOON`,
mesajele de fallback ale proxy-ului. `NEVERIFICAT` integral.

---

## 7. BLOCAJE CARE DEPIND DE TINE (toate într-un singur loc)

1. **Acces SSH/SFTP** (sau „da" pentru a lucra exclusiv prin API). Fără el nu pot: grep pe loguri
   întregi, backup manual cu arhivă, staging, `systemd`, firewall. Recomandare: dă-mi SFTP-ul.
2. **Decizie holograme**: „le vreau vizibile" (schimb `#ICON:` → text/`#HEAD:`) sau „le las exact așa".
   Recomandare: text mic sub iconiță; se face în ~5 minute, cu backup.
3. **Domeniul/IP-ul public + SRV**: confirmă ce trebuie să scrie jucătorul (ex. `play.domeniu.ro`).
4. **Staging**: o copie a serverului pentru test end-to-end (Faza 5). Fără ea, testele cu client real
   rămân la tine.
5. **Regulile comunității + link Discord** — text final, ca să-l pun în Lobby/anunțuri.

---

## 8. PLAN PRIMELE 24h (urgență)

- **Rollback**: panou → Backups → Restore pe serverul afectat (serverul se oprește automat).
  Backup-urile din §2 sunt „pre-lansare", deci rollback-ul readuce exact starea de acum.
- **TPS scăzut**: `spark tps`, apoi `spark profiler start` / `spark profiler stop` → link; verifică
  entități (item frames, NPC-uri), chunk-uri încărcate, pluginuri care fac task-uri sincron.
- **Grief**: `/co i` (dacă e CoreProtect pe Survival) → rollback pe regiune; dacă nu există, decizie
  P1 imediată.
- **Atac/join flood**: `whitelist on` temporar + LuckPerms/permisiuni + velocity `modern` doar cu secret.
- **Restart sigur**: `power restart` (niciodată `stop`), anunț în chat cu 60s înainte.

## 9. CE TREBUIE VERIFICAT MANUAL (max. 5 minute)

1. Intră pe server cu un cont nou → vezi MOTD, Lobby, holograme, selector Survival.
2. Click pe NPC Parkour (pornește parcursul), click pe NPC Practice/Oneblock (SOON).
3. Pe Survival: pune/asigură un claim, `/sethome` + `/home`, un `/rtp`.
4. Repornește Survival din panou cu tine conectat → trebuie să ajungi în Lobby cu mesaj în română.
5. În consolă: `grep -c "ERROR" logs/latest.log` pe fiecare server.

---

## 10. FAZA 1 — AUDIT COMPLET DE LOG (metodă nouă, verificată)

**Acces**: SFTP-ul (`169.58.65.236:2022`) este **blocat din sandbox-ul meu la nivel de rețea**
(conexiunea TCP se deschide, apoi e resetată — egress allowlist). NU e o problemă la voi.
**Soluție găsită**: API-ul panoului emite un link semnat de descărcare
(`/files/download` → `http://169.58.65.236:8080/download/file?token=…`), pe care îl pot citi integral.
Deci **pot citi logurile întregi** — Faza 1 nu mai e blocată.

### P0 — găsite în log (dovedite)

1. **Backend-urile ascultă pe `0.0.0.0` și rulează cu `online-mode=false`** + forwarding `legacy`:
   log-ul Lobby conține avertismentul standard: *„This server will make no attempt to authenticate
   usernames… opens up the ability for hackers to connect with any username they choose."*
   ⇒ oricine se poate conecta **direct** la `169.58.65.236:25566` / `:25567` cu ce nume vrea
   (inclusiv al tău) și ocolește proxy-ul.
   **Opțiuni**: (a) firewall pe host, doar IP-ul proxy-ului către 25566/25567 — cea mai bună;
   (b) `player-info-forwarding-mode = "modern"` + `forwarding.secret` + `proxies.velocity` în
   `paper-global.yml` pe ambele backend-uri (respinge conexiunile directe). (b) e o schimbare
   mare, cu risc de lockout — se face cu test, nu în ultima oră.
2. **`velocity.toml`: `online-mode = false`** pe proxy. Dacă serverul e *premium*, trebuie `true`
   (altfel oricine intră cu orice nick). Dacă e *cracked*, rămâne `false` — **decizie de business**,
   nu o schimb; notat ca atare.
3. **Whitelist era PORNIT** pe Lobby (5 nume) — **REZOLVAT** (`whitelist off`).

### P1 — avertismente catalogate (NU le ating înainte de lansare, Regula 5)

| Avertisment | Verdict | Acțiune |
|---|---|---|
| `NBTAPI 2.15.3` — versiune nesuportată pe 1.21.11, „some functions may not work" | risc mediu (API pentru itemi/GUI) | update la 2.16.1 **după** lansare, cu test |
| `FancyNpcs 2.11.0` → 2.12.1, `FancyHolograms 2.11.0` → 2.12.0, `packetevents 2.13.0` → 2.14.0 | informativ | după lansare |
| `Leaf`: module experimentale `OptimizeDespawn`, `OptimizeRandomTick` active | risc mic | lasă (merge stabil acum) |
| `Leaf`: `faster-random-generator` mută slime chunk-urile | informativ | notat pentru ferme |
| `DisableJoinMessage v1.0` fără `api-version` (legacy) | inofensiv | lasă |
| `AnimaBossBar` raportează versiunea `${project.version}` | build prost la plugin | inofensiv |
| `ViaVersion`: protocoalele 1.20.5–1.21.4 „easily exploitable" | risc dacă accepți versiuni vechi | recomandat update ViaVersion, nu block-versions (ar scoate jucători legitimi) |
| `ajLeaderboards: Using H2 flatfile… Loaded 2 boards` | confirmă ce am spus: board-urile sunt **locale**, nu partajate cu Survival | dacă vrei top real: MySQL comun (după lansare) |

### Mediu confirmat din log
Java **25 (Temurin 25.0.5.1)**, Leaf 1.21.11-184, 27 pluginuri, `Starting Minecraft server on 0.0.0.0:25566`,
spawn pregătit în 2 ms, `Done` fără excepții. `velocity.toml`: `lobby = 172.18.0.2:25566`,
`survival = 172.18.0.4:25567` (rețea Docker internă — corect), `login-ratelimit = 0`.
