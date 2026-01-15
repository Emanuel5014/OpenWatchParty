# OpenWatchParty - Audit de Latence UX

> **Date**: 2026-01-15
> **Version auditée**: main (v1.1 - optimisée)
> **Auditeur**: Claude Code
> **Focus**: Latences perçues par l'utilisateur dans les interactions client-serveur

---

## Résumé Exécutif

Cet audit analyse les **délais perçus par l'utilisateur** lors des interactions avec OpenWatchParty. Le système privilégie la **fiabilité de synchronisation** sur la réactivité, avec des délais intentionnels pour éviter les artefacts de désynchronisation.

### Latences Clés (v1.1 - Optimisées)

| Action | Latence v1.0 | Latence v1.1 | Ressenti |
|--------|--------------|--------------|----------|
| Host: Play | 1.5-1.7s | **1.0-1.2s** ✓ | Amélioré |
| Host: Pause | 320-400ms | **320-400ms** | Acceptable |
| Host: Seek | 320ms + buffering | **320ms + buffering** | Variable |
| Mise à jour position | 2-4s | **1-2s** ✓ | Amélioré |
| Rejoindre une room | < 500ms | **< 500ms** | Rapide |
| Correction de drift | Continue (500ms) | **Continue (500ms)** | Invisible |

> 💡 **Nouveau en v1.1**: Indicateur visuel de synchronisation (spinner pendant le délai, badge "Synced")

---

## 1. Délais par Action Utilisateur

### 1.1 Host: Lecture (Play)

```
[Host clique Play]
    → 20-100ms réseau
    → Serveur ajoute target_server_ts = now + 1500ms
    → 20-100ms réseau vers clients
    → Client attend jusqu'à target_server_ts
    → [1500ms d'attente]
    → video.play()
```

| Composant | Durée | Configurable |
|-----------|-------|--------------|
| Réseau (aller) | 20-100ms | Non |
| Traitement serveur | < 5ms | Non |
| **Délai de scheduling** | **1500ms** | `PLAY_SCHEDULE_MS` |
| Réseau (retour) | 20-100ms | Non |
| **Total** | **1540-1700ms** | |

**Pourquoi 1500ms ?**
- Permet le buffering HLS (300-500ms typique)
- Attend que tous les clients soient "ready"
- Évite que certains clients ratent le démarrage

**Impact UX**: Le play semble lent comparé à un lecteur local (< 100ms). C'est le compromis pour la synchronisation de groupe.

---

### 1.2 Host: Pause

| Composant | Durée |
|-----------|-------|
| Réseau (aller) | 20-100ms |
| **Délai de scheduling** | **300ms** |
| Réseau (retour) | 20-100ms |
| **Total** | **320-400ms** |

**Impact UX**: La pause est ~5x plus rapide que le play. Ressenti acceptable.

---

### 1.3 Host: Seek (Avance/Recul)

| Composant | Durée |
|-----------|-------|
| Réseau + scheduling | 320-400ms |
| **Re-buffering HLS** | **500-2000ms** |
| **Total** | **820-2400ms** |

**Problèmes identifiés:**
- **Throttle de 500ms** entre seeks consécutifs (playback.js:230)
- **Seuil minimum de 2.5s** pour broadcaster un seek (`SEEK_THRESHOLD`)
- Les petits seeks (< 2.5s) sont absorbés par le sync loop

**Impact UX**: Le seek frame-par-frame est impossible. Les seeks rapides sont coalescés.

---

### 1.4 Mises à jour de position (State Updates)

```
[Host bouge dans la vidéo]
    → Throttle client: attend jusqu'à 2000ms
    → Envoi state_update
    → Throttle serveur: 500ms minimum entre updates
    → Broadcast aux clients
```

| Composant | Durée |
|-----------|-------|
| **Throttle client** | **jusqu'à 2000ms** |
| Réseau | 40-200ms |
| Throttle serveur | jusqu'à 500ms |
| **Total potentiel** | **2-4 secondes** |

**Impact UX**: Si le host recule de 5 secondes, les clients peuvent ne pas voir le changement pendant 2-4 secondes.

**Exception**: Les changements de `play_state` (play/pause) contournent le throttle et sont envoyés immédiatement.

---

### 1.5 Rejoindre une Room

| Étape | Durée |
|-------|-------|
| Envoi join_room | 20-100ms |
| Réception room_state | inclus |
| Chargement vidéo | variable |
| Envoi ready | 20-100ms |
| **Total (hors vidéo)** | **< 500ms** |

**Impact UX**: Rejoindre une room est rapide. Le délai perçu vient du chargement vidéo.

---

## 2. Mécanismes de Synchronisation

### 2.1 Synchronisation d'Horloge (Clock Sync)

```javascript
// Ping envoyé toutes les 10 secondes
ping { client_ts: Date.now() }

// Pong reçu avec server_ts
rtt = now - client_ts
offset = server_ts + (rtt / 2) - now
serverOffsetMs = 0.6 * old + 0.4 * new  // EMA smoothing
```

| Paramètre | Valeur | Impact |
|-----------|--------|--------|
| Intervalle ping | 10s | Overhead minimal |
| Précision | ±RTT/2 | Dépend du réseau |
| Lissage EMA | 60/40 | Évite les sauts |

**Impact UX**: Invisible. Critique pour la synchronisation en arrière-plan.

---

### 2.2 Boucle de Correction de Drift (Sync Loop)

Exécutée toutes les **500ms** pour les clients (non-hosts).

```javascript
drift = expected_position - actual_position

if (|drift| < 0.04s)     → Rien (zone morte)
if (|drift| < 2.0s)      → Ajuster playbackRate (0.85x - 1.50x)
if (|drift| >= 2.0s)     → Seek forcé
```

| Paramètre | Valeur | Impact UX |
|-----------|--------|-----------|
| `DRIFT_DEADZONE_SEC` | 0.04s (40ms) | Imperceptible |
| `DRIFT_SOFT_MAX_SEC` | 2.0s | Seek si > 2s |
| `PLAYBACK_RATE_MIN` | 0.85x | Ralentissement max |
| `PLAYBACK_RATE_MAX` | 1.50x | Accélération max |
| `DRIFT_GAIN` | 0.20 | Agressivité correction |

**Formule de correction**: `rate = 1 + sqrt(drift) * 0.20`

| Drift | Playback Rate |
|-------|---------------|
| 0.1s | 1.06x |
| 0.5s | 1.14x |
| 1.0s | 1.20x |
| 2.0s+ | Seek forcé |

**Impact UX**: Les corrections sont douces et progressives. Pas de "saut" visible sauf si drift > 2s.

---

### 2.3 Lead Time (Compensation de Latence)

```javascript
SYNC_LEAD_MS = 300ms

adjustedPosition = position + (elapsed + 300) / 1000
```

**Exemple**:
- Serveur envoie position=120s à t=1000
- Client reçoit à t=1050 (50ms latence)
- Position ajustée = 120 + (50 + 300)/1000 = **120.35s**

**Impact UX**: Sans lead time, les clients seraient toujours légèrement en retard.

---

## 3. Throttling et Cooldowns

### 3.1 Tableau des Throttles

| Mécanisme | Durée | Fichier | Raison |
|-----------|-------|---------|--------|
| State update (client) | 2000ms | playback.js:293 | Réduire traffic |
| State update (serveur) | 500ms | ws.rs:18 | Éviter flood |
| Seek debounce | 500ms | playback.js:230 | Coalescence |
| Command cooldown | 2000ms | ws.rs:20 | Anti-feedback |
| Sync cooldown | 5000ms | ws.js | Post-resume stability |
| Suppress (isSyncing) | 2000ms | state.js:52 | Anti-echo |

---

### 3.2 Problème: Sync Cooldown de 5 secondes

Après réception d'une commande play, les clients ignorent les mises à jour de position pendant **5 secondes**.

**Scénario problématique**:
1. Host clique play → Client reçoit et démarre
2. Host seek à +10s pendant les 5 premières secondes
3. Client ne corrige pas sa position (en cooldown)
4. Après 5s, le sync loop corrige via playbackRate

**Impact UX**: Désynchronisation temporaire de 5s dans ce cas edge.

---

## 4. Problèmes UX Identifiés

### 4.1 Critique: Délai de Play de 1.5s

| Aspect | Détail |
|--------|--------|
| **Problème** | Le play prend 1.5s, ressenti comme lent |
| **Cause** | `PLAY_SCHEDULE_MS = 1500` pour sync groupe |
| **Workaround possible** | Réduire à 1000ms si réseau fiable |
| **Risque** | Certains clients pourraient rater le démarrage |

---

### 4.2 Haute: State Updates Décalés (2-4s)

| Aspect | Détail |
|--------|--------|
| **Problème** | Position du host peut être décalée de 2-4s |
| **Cause** | Double throttle (client 2s + serveur 500ms) |
| **Impact** | Clients voient une position "stale" |
| **Solution possible** | Réduire `STATE_UPDATE_MS` à 1000ms |

---

### 4.3 Moyenne: Seek Throttle Agressif

| Aspect | Détail |
|--------|--------|
| **Problème** | Seeks < 2.5s ne sont pas broadcastés |
| **Cause** | `SEEK_THRESHOLD = 2.5` trop élevé |
| **Impact** | Petits ajustements non synchronisés |
| **Solution possible** | Réduire à 1.0s |

---

### 4.4 Moyenne: Cooldown Post-Play Trop Long

| Aspect | Détail |
|--------|--------|
| **Problème** | 5s de cooldown après play |
| **Cause** | `syncCooldownUntil` dans ws.js |
| **Impact** | Seeks du host ignorés pendant 5s |
| **Solution possible** | Réduire à 2-3s |

---

## 5. Recommandations d'Optimisation

> **Note**: Toutes les recommandations ci-dessous ont été **implémentées** dans la version 1.1.

### Priorité 1 - Impact UX Fort ✅

| # | Changement | Avant | Après | Risque | Statut |
|---|------------|-------|-------|--------|--------|
| 1 | Réduire play delay | 1500ms | 1000ms | Désync si réseau lent | ✅ Implémenté |
| 2 | Réduire state throttle client | 2000ms | 1000ms | Plus de traffic | ✅ Implémenté |
| 3 | Réduire sync cooldown | 5000ms | 2000ms | Feedback loops | ✅ Implémenté |

**Fichiers modifiés:**
- `ws.rs:16` - `PLAY_SCHEDULE_MS: 1000`
- `state.js:54` - `STATE_UPDATE_MS: 1000`
- `ws.js` - `syncCooldownUntil = nowMs() + 2000`

### Priorité 2 - Amélioration Mineure ✅

| # | Changement | Avant | Après | Risque | Statut |
|---|------------|-------|-------|--------|--------|
| 4 | Réduire seek threshold | 2.5s | 1.0s | Plus de broadcasts | ✅ Implémenté |
| 5 | Réduire seek debounce | 500ms | 250ms | Plus de messages | ✅ Implémenté |

**Fichiers modifiés:**
- `state.js:53` - `SEEK_THRESHOLD: 1.0`
- `playback.js:230` - debounce `250ms`

### Priorité 3 - Feedback Visuel ✅

| # | Changement | Avant | Après | Impact | Statut |
|---|------------|-------|-------|--------|--------|
| 6 | Feedback visuel play | Aucun | Spinner + countdown | UX perçue | ✅ Implémenté |
| 7 | Indicateur de sync | Aucun | Badge animé | Confiance utilisateur | ✅ Implémenté |

**Fichiers modifiés:**
- `state.js` - Nouveaux états `syncStatus`, `pendingPlayUntil`
- `ws.js` - Utilisation de `scheduleAt()` pour play, mise à jour `syncStatus`
- `ui.js` - Nouveau composant `buildSyncStatusIndicator()`, styles CSS animés
- `playback.js` - Mise à jour `syncStatus` dans `syncLoop()`

**États de synchronisation:**
- `pending_play` - Spinner orange avec countdown pendant le délai schedulé
- `syncing` - Point jaune pulsant pendant le rattrapage de drift
- `synced` - Point vert fixe quand la position est synchronisée

---

## 6. Constantes de Timing - Référence (v1.1)

### Client (state.js)

```javascript
SUPPRESS_MS: 2000,          // Durée lock anti-echo
SEEK_THRESHOLD: 1.0,        // Seuil minimum pour broadcast seek (était 2.5)
STATE_UPDATE_MS: 1000,      // Intervalle state updates (était 2000)
SYNC_LEAD_MS: 300,          // Compensation latence
DRIFT_DEADZONE_SEC: 0.04,   // Zone morte (40ms)
DRIFT_SOFT_MAX_SEC: 2.0,    // Seuil seek forcé
PLAYBACK_RATE_MIN: 0.85,    // Ralentissement max
PLAYBACK_RATE_MAX: 1.50,    // Accélération max
DRIFT_GAIN: 0.20,           // Gain correction
UI_CHECK_MS: 2000,          // Check UI
PING_MS: 10000,             // Intervalle ping
HOME_REFRESH_MS: 5000,      // Refresh home
SYNC_LOOP_MS: 500,          // Boucle correction
```

### Client (playback.js)

```javascript
seekDebounce: 250,          // Debounce entre seeks (était 500)
```

### Client (ws.js)

```javascript
syncCooldownDuration: 2000, // Cooldown après play (était 5000)
```

### Serveur (ws.rs)

```rust
PLAY_SCHEDULE_MS: 1000,           // Délai play (était 1500)
CONTROL_SCHEDULE_MS: 300,         // Délai pause/seek
MIN_STATE_UPDATE_INTERVAL_MS: 500,// Throttle serveur
COMMAND_COOLDOWN_MS: 2000,        // Cooldown anti-feedback
POSITION_JITTER_THRESHOLD: 0.5,   // Seuil jitter position
```

---

## 7. Diagramme de Flux - Play (v1.1)

```
Host                    Server                  Client
  |                        |                       |
  |-- player_event ------->|                       |
  |   (action: play)       |                       |
  |                        |-- calcul target_ts -->|
  |                        |   (now + 1000ms)      |
  |                        |                       |
  |                        |<-- player_event ------|
  |                        |    (avec target_ts)   |
  |                        |                       |
  |                        |    [syncStatus:       |
  |                        |     pending_play]     |
  |                        |    [spinner affiché]  |
  |                        |                       |
  |                    [1000ms passent]            |
  |                        |                       |
  |                        |           video.play()|
  |                        |    [syncStatus:       |
  |                        |     syncing]          |
  |                        |                       |
  |                    [drift < 40ms]              |
  |                        |                       |
  |                        |    [syncStatus:       |
  |                        |     synced] ✓         |
```

---

## Conclusion

OpenWatchParty fait un **compromis délibéré** entre réactivité et fiabilité de synchronisation.

### Latences après optimisation (v1.1)

| Action | Avant | Après | Amélioration |
|--------|-------|-------|--------------|
| **Play** | 1.5-1.7s | **1.0-1.2s** | -33% |
| **State updates** | 2-4s | **1-2s** | -50% |
| **Seek sync** | > 2.5s | **> 1.0s** | Meilleure granularité |
| **Seek debounce** | 500ms | **250ms** | -50% |
| **Sync cooldown** | 5s | **2s** | -60% |

### Points forts (v1.1)
- Synchronisation robuste même sur réseaux instables
- Correction de drift douce et invisible
- Pas de "saut" visible sauf désync majeure (> 2s)
- **Nouveau**: Indicateur visuel de synchronisation (spinner, badge)
- **Nouveau**: Feedback utilisateur pendant l'attente de play

### Risques à surveiller
- Le délai de play réduit à 1000ms peut causer des désync sur réseaux très lents
- Plus de messages WebSocket avec les nouveaux seuils

---

## Historique

| Date | Version | Changements |
|------|---------|-------------|
| 2026-01-15 | 1.0 | Création initiale |
| 2026-01-15 | 1.1 | Implémentation de toutes les recommandations P1/P2/P3 |
