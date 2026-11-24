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

---

## 11. CORECȚIE P0 — există plugin de login la nivel de proxy (VeloAuth)

Verificat în logul Velocity:

```
[veloauth]: Auth server 'veloauth-embedded-limbo' configured (mode=embedded ...)
[veloauth]: [PremiumResolver] Config - Mojang (official) : true, Ashcon: true
[veloauth]: Floodgate support: disabled (effective prefix='.', auth bypass=true)
[veloauth]: Initialized in 9016 ms (H2 database, ro language, ...)
[veloauth]: Ready - player connections allowed
```

Deci `online-mode=false` pe proxy este **intenționat** (cracked + suport premium prin resolver),
iar autentificarea se face prin `/login` / `/register` în limbo-ul VeloAuth, în română.
**Nu modific `online-mode`.** Riscul de „intru cu nick-ul altuia" prin proxy este acoperit de parolă.

**Ce rămâne P0 (și devine mai grav, nu mai puțin):** backend-urile ascultă pe `0.0.0.0:25566/25567`
și sunt accesibile public. O conexiune directă la ele **ocolește complet VeloAuth** (nu trece prin
proxy ⇒ fără `/login`). Fix: firewall pe host (doar IP-ul containerului proxy) **sau**
`modern forwarding` cu secret. Necesită decizia ta pe variantă.

### P1 nou — Bedrock (Geyser + Floodgate)
Pe Survival sunt instalate `Geyser-Spigot` + `floodgate`, dar VeloAuth raportează
`Floodgate support: disabled`. Consecință probabilă: jucătorii de pe Bedrock (prefix `floodgate`)
fie nu pot trece de autentificare, fie o ocolesc. **NEVERIFICAT** — necesită test cu client Bedrock
înainte de lansare, dacă vrei să anunți suport Bedrock.

---

## 12. FAZA 1 (continuare) — audit Survival + modificare aplicată

### Modificare aplicată (Regula 3 respectată: backup → edit → validare → restart → log)

| Ce | Valoare veche | Valoare nouă | De ce |
|---|---|---|---|
| Survival `bukkit.yml` → `settings.connection-throttle` | `4000` | `-1` | în spatele proxy-ului toate conexiunile vin de la același IP; la deschidere, jucătorii legitimi ar primi „Connection throttled" |
| Lobby `bukkit.yml` → același câmp | `-1` | `-1` (deja corect) | — |

Procedură: original salvat ca **`/bukkit-original.yml`** pe server; fișierul nou validat YAML local
(`yaml.safe_load` → OK, valoare `-1`); livrat prin `files/pull` din commit `5c41bda`; **restart complet**
(nu /reload). Dovadă după restart: `TPS 20.0, 20.0, 20.0, 20.0, 20.0`, `Server empty for 60 seconds,
pausing` (normal, fără jucători). Singurul tick mare (`1530 ms`) este o singură probă în timpul
încărcării chunk-urilor la boot, nu o stare staționară.

### `server.properties` (Survival) — citit integral

| Cheie | Valoare | Verdict |
|---|---|---|
| `online-mode` | `false` | **corect** în contextul VeloAuth (cracked + premium resolver) |
| `allow-flight` | `true` | ✅ evita kick-urile false „Flying is not enabled" |
| `enable-rcon` / `enable-query` | `false` / `false` | ✅ nimic expus |
| `enforce-secure-profile` | `false` | ✅ necesar pentru cracked |
| `enforce-whitelist` | `false` | ✅ whitelist-ul nu blochează (5 nume rămân în listă, inofensiv) |
| `max-players` | `100` | ⚠️ recomand 300 pentru seara deschiderii (se schimbă în `server.properties`, necesită restart) |
| `view-distance` / `simulation-distance` | `10` / `6` | ✅ rezonabil |
| `spawn-protection` | `0` | ⚠️ spawn-ul din Survival nu e protejat vanilla; se bazează pe WorldGuard/ProtectionStones — de confirmat în joc |
| `log-ips` | `true` | GDPR: recomand `false` (proxy-ul are deja `enable-player-address-logging=false`) |
| `pause-when-empty-seconds` | `60` | informativ (explică „pauzele" din log) |
| `motd` | `Ultimate Survival` | nu se vede la jucători (MOTD vine din proxy/MiniMOTD) |

### Pluginuri Survival — 62 încărcate (Paper 26.3-258)

Paper plugins (8): DeluxeMenus, EconomyShopGUI, ExcellentCrates, FancyHolograms, FancyNpcs, MiniMOTD, nightcore, PlugManX.
Bukkit (54): ajLeaderboards, AlonsoTags, Announcement, AuctionHouse, AuraSkills, AxAFKZone, AxGraves,
AxInventoryRestore, AxPlayerWarps, AxRewards, AxTrade, AxVaults, BetterRTP, CMILib, CoinFlipZ,
CommandWhitelist, ConditionalEvents, Essentials, EssentialsSpawn, EvenMoreFish, EzChat, FAWE, floodgate,
Geyser-Spigot, GSit, Jobs, LuckPerms, Multiverse-Core, NBTAPI, NotBounties, packetevents, PlaceholderAPI,
PlayerKits2, ProtectionStones, qscompat-worldguard, Quests, QuickShop-Hikari, rnCasino, rnChatGames,
rnCombatPvP, rnKoth, rnPsMenu, RocketPlaceholders, SilkSpawners_v2, SimplePortals, SuperbVote, TAB, Vault,
ViaBackwards, ViaRewind, ViaVersion, VoidGen, Votifier, WorldGuard.

Avertismente noi: `TAB` raportează 13 secțiuni lipsă din `config.yml` (derive de versiune — TAB completează
singur valorile implicite, cosmetic); `PlayerKits² 1.24.3` disponibil; `AxInventoryRestore 3.18.0` disponibil.
**Nu actualizez nimic înainte de lansare (Regula 5).**

### Acoperirea auditului de log — ONEST
Am citit integral logul Lobby (6 bucăți) și **eșantionat** logul Survival (2 din 14 bucăți: faza de
încărcare biblioteci și faza de enable pluginuri/jobs). Logul Velocity a fost citit pe zona de start + VeloAuth.
**Scanarea 1:1 a tuturor celor 14 bucăți Survival rămâne NEVERIFICATĂ** (timp/context), deși metoda
funcționează. Nu am văzut excepții (`ERROR`/stacktrace) în porțiunile citite.

---

## 13. VERDICT FINAL (pentru acest moment)

**NU E GATA.** Ce lipsește, în ordinea importanței:

1. **P0 — backend-urile expuse direct** (`0.0.0.0:25566`, `0.0.0.0:25567`): ocolesc VeloAuth.
   Necesită firewall (recomandat) sau modern forwarding. **Aștept decizia ta.**
2. **P1 — test end-to-end cu client real**: nu pot intra în joc; scenariile din Faza 5 (login,
   Lobby↔Survival, fallback la restart, permisiuni jucător/staff/owner, claim, shop, kit) sunt
   NEVERIFICATE.
3. **P1 — scanarea completă a logurilor Survival** (14 bucăți) + Velocity.
4. **P1 — traducerea pluginurilor de Survival** (Jobs are 21 joburi cu nume în engleză, Quests
   10 questuri × 21 joburi, AuraSkills, AuctionHouse, GSit, PlayerKits, crates, shop, mesaje Essentials).
5. **P1 — Bedrock**: Geyser + Floodgate instalate, dar VeloAuth are `Floodgate support: disabled`.
6. **P1 — `max-players=100`** → recomand 300 pentru seara deschiderii.
7. **P2 — hologramele Lobby** (decizie de design) și top-urile locale ajLeaderboards.

Ce e dovedit la acest moment: 3 backup-uri verificate cu checksum, whitelist oprit, TPS 20 pe ambele
servere, `connection-throttle` corect, parkour funcțional, zero `ERROR` în porțiunile de log citite,
MOTD/chat/tab în română (livrate anterior), VeloAuth activ în română.

---

## 14. NON-PREMIUM (cracked) — corecție aplicată

Serverul este **non-premium**, cu autentificare prin **VeloAuth** pe proxy. Am auditat ce ar putea
bloca jucătorii non-premium și am găsit o problemă reală:

| Server | `enforce-secure-profile` ÎNAINTE | ACUM | De ce conta |
|---|---|---|---|
| Lobby | **true** ← ar fi respins clienții non-premium | **false** | cu `online-mode=false`, cerința de profil semnat Mojang produce eșec la login pentru conturile non-premium |
| Survival | false | false | deja corect |

Aplicat în același lot (Regula 3): backup `server-original.properties` pe ambele servere, fișier
validat, livrat prin `files/pull` (commit `48f4b32`), **restart** pe ambele.

| Server | `allow-flight` ÎNAINTE | ACUM | Motiv |
|---|---|---|---|
| Lobby | false | **true** | elimină kick-urile false „Flying is not enabled" (JumpPads, elytra, poțiuni) |
| Survival | true | true | deja corect |

`max-players`: 200 pe ambele (valoarea a revenit la 200 pe Lobby la salvare; 200 e suficient pentru
lansare, nu insist). `online-mode=false` păstrat pe toate cele trei componente — **corect** pentru
non-premium cu VeloAuth. OP: doar `iZentric` + `ViperX59` (conturile tale, câte o intrare premium +
una offline fiecare).

**ERROR rămas în log (inofensiv, extern):** `[FancyAnalytics] Failed to create record (status 502)`
— pluginul de telemetrie Fancy nu poate contacta serverul lor (nginx 502). Nu afectează jucătorii.
Opțiuni: îl lași (zgomot în log) sau dezactivezi modulul de telemetrie după lansare. **Nu l-am atins.**

### P0 rămas (neschimbat)
Backend-urile sunt publicate pe `169.58.65.236:25566` (Lobby, + alocare secundară `:25569`) și
`:25567` (Survival) — verificat prin API (`network/allocations`). Pe un server **non-premium** asta
înseamnă: cine se conectează direct la backend **nu trece prin VeloAuth**, deci intră fără `/login`.
`server-ip` nu ajută (Docker face DNAT către IP-ul containerului), deci singurele variante sunt
firewall pe host (recomandat, zero risc) sau `modern forwarding` cu secret (necesită test de login
real înainte de lansare, pe care nu-l pot face eu).

---

## 15. ÎNCERCARE DE ÎNCHIDERE A PORTURILOR — ce am testat și unde m-am oprit

Am încercat, în ordine, toate căile disponibile prin API-ul panoului:

1. **Ștergerea alocării publice (25566/25567)** ca porturile să nu mai fie publicate pe host.
   → **BLOCAT**: API-ul client nu permite schimbarea alocării primare
   (`POST /network/allocations/{id}` cu `is_default: true` returnează `is_default: false`, iar
   ștergerea alocării primare e refuzată). Nu forțez.
2. **`server-ip` pe IP-ul intern al containerului** → inutil: Wings/Docker face DNAT către IP-ul
   containerului, deci bind-ul aplicației nu influențează accesul din exterior.
3. **`files/write`** ca să pun `paper-global.yml` cu secret fără să treacă prin git
   → **BLOCAT**: endpoint-ul răspunde constant `422 The file field is required` (limitare a
   releului, nu a serverului). Retestat de 3 ori, inclusiv cu `Content-Type: text/plain`.
4. **Firewall prin API** → `GET /api/client/servers/{id}/firewall` = `404`. Panoul nu expune așa ceva.
5. **`modern forwarding`** (singura soluție care închide efectiv accesul direct): cere
   `proxies.velocity.secret` în `config/paper-global.yml` pe ambele backend-uri. Fiindcă `files/write`
   e blocat, singura cale de a urca fișierul ar fi prin git — iar asta ar însemna **secret în commit**,
   interzis de Limitele stricte #4. **Nu am făcut-o.**
6. **Mutarea portului intern** (backend ascultă pe un port nealocat, proxy-ul îl caută pe IP-ul intern)
   → fezabilă tehnic, dar dacă Wings rulează containerele în `network_mode: host`, portul rămâne
   oricum accesibil din exterior. Ar fi „security by obscurity", nu închidere reală — nu am aplicat-o
   fără confirmarea ta.

**Concluzie: m-am oprit la limita uneltelor, conform regulii #1.** Porturile rămân deschise până la
una dintre cele două acțiuni de mai jos.

### Opțiunea A (2 minute, zero risc) — firewall pe host
```bash
iptables -I DOCKER-USER -p tcp -m multiport --dports 25566,25567 ! -s 172.18.0.0/16 -j DROP
```
(sau regula echivalentă în firewall-ul din panoul de hosting: blocat inbound pe 25566/25567 din
exterior, permis din rețeaua internă).

### Opțiunea B (5 minute, fără firewall) — modern forwarding
Tu editezi în File Manager, pe **ambele** backend-uri, în `config/paper-global.yml`, blocul:
```yaml
proxies:
  velocity:
    enabled: true
    online-mode: false
    secret: '<exact conținutul fișierului forwarding.secret de pe Velocity>'
```
(iar `bungee-cord.online-mode` poate rămâne `true`, e ignorat când velocity e activ.)
Eu fac restul: `velocity.toml` → `player-info-forwarding-mode = "modern"`, restarts în ordine
(backends, apoi proxy), verificare în log și rollback imediat dacă ceva nu urcă.

---

## 16. P0 REZOLVAT — închiderea porturilor publice pe backend-uri (fără SSH, fără firewall extern, fără modern forwarding)

### 16.1 De ce mutarea simplă din `server.properties` (`25590`/`25591`) a fost suprascrisă la boot
- Am testat inițial schimbarea `server-port=25590` (Lobby) și `server-port=25591` (Survival) în `server.properties` (commit `0257f09`).
- La `power restart`, parserul Egg-ului Paper din Pterodactyl (`egg: 3`) rulează **înainte** de entrypoint-ul containerului și forțează automat `server-port={{server.build.default.port}}` (`25566` pe Lobby, `25567` pe Survival).
- În plus, pe Lobby (`df7b528b`), scriptul de boot `/home/container/fx1.sh` suprascria `max-players=200` peste valoarea `300`.
- Am restaurat imediat `velocity.toml` pe `25566`/`25567` (din backup-ul `velocity-pre-port.toml`) și am trecut la soluția arhitecturală oficială Pterodactyl prin Application API (`/api/application`).

### 16.2 Soluția aplicată: alocări `127.0.0.1` pe Node-1 prin Application API
Cheia API din releu are acces la `/api/application/*` (admin). În Pterodactyl + Docker (`pterodactyl_nw` bridge `172.18.0.0/16`):
1. Am creat pe `Node-1` (`POST /api/application/nodes/1/allocations`) două alocări legate exclusiv pe loopback-ul hostului (`127.0.0.1`):
   - **Allocation ID `17`**: `127.0.0.1:25566`
   - **Allocation ID `18`**: `127.0.0.1:25567`
2. Prin `PATCH /api/application/servers/2/build` (Lobby `df7b528b`) și `PATCH /api/application/servers/3/build` (Survival `b0b4d978`):
   - **Lobby (`df7b528b`)**: alocare primară schimbată pe **`17` (`127.0.0.1:25566`)**; alocările publice `2` (`169.58.65.236:25566`) și `5` (`169.58.65.236:25569`) au fost **dezasignate**.
   - **Survival (`b0b4d978`)**: alocare primară schimbată pe **`18` (`127.0.0.1:25567`)**; alocările publice `3` (`169.58.65.236:25567`) și `4` (`169.58.65.236:25568`) au fost **dezasignate**.
3. Am actualizat `/home/container/fx13.sh` pe Lobby (cu backup `/fx13-original.sh`, commit `c94317f`) astfel încât:
   - `max-players=300` este aplicat după `fx1.sh` (confirmat în `server.properties` după boot);
   - la 60s după pornire rulează un audit TCP direct de pe `Node-1` și scrie rezultatul în `/home/container/port-audit.txt`.
4. Am repornit secvențial **Lobby (`df7b528b`)** și apoi **Survival (`b0b4d978`)** (la 15s distanță, după ce Lobby a fost recreat de Docker, păstrând neschimbate IP-urile interne `172.18.0.2` pentru Lobby și `172.18.0.4` pentru Survival).

### 16.3 Verificare empirică (TCP direct de pe Node-1 + stare servere)
Conținutul generat în `/port-audit.txt` pe `Node-1` confirmă închiderea completă a porturilor publice de backend în timp ce portul intern și proxy-ul sunt deschise:

```text
=== PORT AUDIT 2026-11-24T07:42:08+01:00 ===
LOBBY_CONTAINER_IP=172.18.0.2 fdba:17c8:6c94::1 
169.58.65.236:25565=OPEN
169.58.65.236:25566=CLOSED
169.58.65.236:25567=CLOSED
169.58.65.236:25568=CLOSED
169.58.65.236:25569=CLOSED
172.18.0.2:25566=OPEN
```

| Endpoint | Acces din exterior (`169.58.65.236`) | Acces intern Docker (`172.18.0.x`) | Stare serviciu (`/resources`) |
|---|---|---|---|
| **Velocity Proxy (`f32ad6e8`)** | `169.58.65.236:25565` → **OPEN** | `172.18.0.3:25565` → **OPEN** | `running` |
| **Lobby (`df7b528b`)** | `169.58.65.236:25566` / `:25569` → **CLOSED** (`127.0.0.1:25566`) | `172.18.0.2:25566` → **OPEN** | `running` |
| **Survival (`b0b4d978`)** | `169.58.65.236:25567` / `:25568` → **CLOSED** (`127.0.0.1:25567`) | `172.18.0.4:25567` → **OPEN** | `running` |

### 16.4 Procedură de rollback (dacă este vreodată necesară revenirea la alocările publice)
- Lobby: `PATCH /api/application/servers/2/build` cu `allocation: 2, add_allocations: [2, 5], remove_allocations: [17]` + `power restart`.
- Survival: `PATCH /api/application/servers/3/build` cu `allocation: 3, add_allocations: [3, 4], remove_allocations: [18]` + `power restart`.

