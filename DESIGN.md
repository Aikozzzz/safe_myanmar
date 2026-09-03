# SafeMyanmar Mobile Design Specification

This document describes the implemented Figma-aligned Material 3 experience.
The archived Figma zip is a visual and interaction reference, not a package of
runtime assets; the app does not ship or load files from that archive.

SafeMyanmar is an emergency information application, not an official warning,
prediction, dispatch, medical, or guaranteed-safety service.

## Foundation

| Role | Light value | Use |
|---|---|---|
| Primary | `#0E7C78` | Navigation selection, primary actions, focus |
| Background | `#F7FAFA` | Screen canvas |
| Surface | `#FFFFFF` | Navigation, cards, grouped content |
| Text | `#14212B` | Primary text and icons |
| Danger | `#D92D20` | Destructive or emergency emphasis only |

- Retain Material 3 components and system light/dark mode.
- Use the platform system font stack so Android can select Burmese-capable
  glyphs. Do not bundle or force a Latin-only font.
- Use an 8dp spacing rhythm, clear hierarchy, restrained elevation, and at
  least 48x48dp for every interactive target.
- Never communicate status by color alone. Pair semantic color with text and an
  icon where appropriate.
- Keep warnings, timestamps, sources, and uncertainty visible rather than hidden
  behind color, gestures, or map graphics.

## Navigation

Use a persistent five-destination bottom `NavigationBar`: Home, Map, SOS,
Guide, and More. Each branch keeps its own navigation state. Selecting SOS only
opens the SOS screen; it never prepares a draft or opens messaging by itself.

The earthquake list/detail routes remain outside the shell at `/alerts` and
`/alerts/:id`. Guide article, assistant, profile, and contact forms are nested
under their corresponding shell branches.

## Implemented Screens

### Home And Alerts

- Home is a Safety Center with large, labeled actions for earthquake
  information, Map, SOS setup, and the offline Guide. Each card performs only
  navigation; opening SOS never prepares or sends a message.
- The alert list distinguishes loading, current, cached, stale, successful
  empty, and unavailable states without treating empty results as all clear.
- Alert cards and detail preserve USGS attribution, magnitude, depth,
  coordinates, event and update times, retrieval time, review status, and a
  trusted source action.
- Preliminary values use uncertainty language and never infer severity or
  affected area from magnitude alone.

### Map And Location

- Initial state explains why location is useful and does not request permission
  until the user selects **Use my location**. After a successful grant, later
  launches reuse that choice while OS permission remains granted and do not ask
  again.
- Status cards distinguish requesting, precise, approximate, denied,
  permanently denied, service disabled, last known, and recoverable error.
- Denial remains usable with a retry. Permanent denial offers app settings;
  disabled services offer location settings. No screen requests background
  location.
- Coordinates, capture time, precision, and last-known status remain visible
  when location is available.
- A valid optional public Mapbox token renders location, fictional shelter
  markers, fictional hazard polygons, and route lines. Without it, the screen
  shows a configuration-unavailable card while retaining non-map controls and
  statuses.
- The map follows a Waze-inspired interaction: a readable street map is the
  visual focus, a floating location action recenters on the user's available
  location, and tapping that action or the user marker opens a detail sheet
  with precision, coordinates, and capture time.
- An interactive map legend lists available layers, pairs every marker color
  with an icon and label, and provides a visibility control for each layer.
  Tapping a legend entry opens an in-map summary; tapping a shelter, hazard,
  context-area candidate, route, or nearby SOS marker opens its details without
  leaving the map. Hazard and context summaries state the source, data time,
  cache state, rationale, and uncertainty in text outside the map as well.
- Shelter, disaster type, and walking/driving selectors precede a separate
  route-request action. No route request occurs from changing a selector.
- Up to three ranked route cards act as the route option selector. The selected
  option uses an icon, text, semantic selected state, and a stronger map line;
  selection never relies on color alone.
- Every option displays distance, duration, hazard-intersection count,
  rationale, generation time, hazard-data time, source, directions provider,
  profile-selection reason, and uncertainty notice.

### SOS

- SOS is organized as a setup-and-review sequence with a readiness summary,
  recipients, optional message, location and nearby-sharing choices, the exact
  outgoing preview, confirmation, and draft history.
- The screen shows selected recipients, optional user text, the exact composed
  body, profile/location data to be stored, and the direct-SMS disclosure
  before activation.
- A profile is required. SMS sharing requires at least one explicitly selected
  emergency contact; Bluetooth sharing may be selected as the sole transport.
- Pointer users hold the control to confirm. An accessible activation path uses
  two explicit review/confirmation dialogs before sending.
- Confirmation persists a local draft before invoking Android `SmsManager`.
  Equivalent active drafts within five minutes are reused rather than duplicated.
- Implemented draft statuses include **Prepared**, **SMS sending**, **SMS accepted
  by device**, **SMS failed**, **Composer opened**, **Failed to open**, and
  **Cancelled**. Device acceptance does not mean carrier delivery.
- Draft cards allow explicit reopen, cancel, and remove actions. Destructive
  reset/removal actions require confirmation.
- A separate checkbox allows the user to share limited SOS data with nearby
  SafeMyanmar Android users. It never starts from navigation or from opening the
  SOS screen and does not replace SMS confirmation.
- Nearby sharing broadcasts a temporary event ID, UTC timestamp, fixed-point
  latitude/longitude when available, location status, and battery value for ten
  minutes. The user may optionally provide a short alias and message for nearby
  receivers. These are limited to 16 and 48 UTF-8 bytes and are sent in
  versioned metadata fragments; the alias is not the full profile name. Profile
  data and contacts remain excluded. Received coordinates and metadata are
  peer-supplied. The UI labels an event `Verified` only when alias and
  coordinates are present, and `Unverified` otherwise; neither label confirms
  peer identity or rescue delivery. The Map tab plots located events and the
  SOS details can open a Google Maps query or explicitly request an in-app route
  to a located, unexpired SOS event. The route is drawn on the Mapbox map only
  after the user taps the route action and retains peer-coordinate uncertainty.
- An opt-in foreground receiver shows peer-received events as unverified local
  alerts. A separate relay opt-in may rebroadcast each valid event once over
  Bluetooth only, limited to one hop. It does not merge them with official
  earthquake alerts or imply rescue acknowledgement. Optional sound is
  user-controlled. Receivers omit unavailable battery and RSSI values rather
  than displaying placeholders.

### Guide And Assistant

- Guide provides large deterministic quick actions for earthquake, flood, fire,
  first aid, Map, and SOS, followed by explicit Map, SOS, and assistant next
  steps. No quick action requests location or activates SOS automatically.
- Guide opens with an offline/source-backed label, introduction, assistant
  action, search field, and category chips.
- Article cards show English and Myanmar titles and source. Detail shows both
  answers, content version, source name/URL, source date when known, review date,
  and translation warning.
- Tier 1 assistance is always deterministic: weighted keyword intent matching,
  structured SOS text extraction, and retrieval of approved Drift content.
- Tier 2 is optional checksum-validated local ONNX intent refinement. It runs
  only when deterministic classification returns unknown and must meet the
  configured confidence threshold before its result is used.
- Tier 3 is optional checksum-validated local LiteRT-LM Gemma 3 answering for
  general questions and rewording of supplied verified English content. It
  prioritizes disaster topics, is not used for trapped-person, first-aid, SOS,
  or safer-route intents, and may not add facts, diagnoses, route claims,
  rescue claims, or instructions.
- Capability banners identify optional tiers as available or unavailable.
  Missing models are normal, and deterministic retrieval remains active.
- Assistant actions only navigate after a separate user tap. The assistant never
  activates SOS, shares location, or requests a route automatically.

### More, Profile, And Contacts

- More summarizes the local profile and selected contact counts, then links to
  profile, emergency-contact management, and Settings.
- Settings contains the English/Myanmar choice and six persisted SOS
  preferences for location sharing, nearby receiving, one-hop relay, alert
  sound, and background receiving. Permission-dependent options request only
  the relevant platform permission when enabled.
- Profile edits one local display name. Contact forms validate name, phone
  number, relationship label, and explicit SOS selection.
- Contact cards pair SOS selection text with a switch and provide separate edit
  and confirmed delete actions. The implemented maximum is ten contacts.
- Privacy cards explain that profile/contact records are local secure-storage
  data. Loading, saving, retry, corrupt-data, and confirmed reset states remain
  visible and recoverable.

## Simulation And Stale Rules

- Fictional or mixed shelter, hazard, and route data remains explicitly gated,
  sourced to `SafeMyanmar Demo`, timestamped, and accompanied by an uncertainty
  notice. The client keeps technical simulation markers out of normal cards and
  uses a concise demonstration-data notice instead.
- Simulation is an explicit non-production backend opt-in. The UI must never
  style simulation data as an official alert or silently mix it into the USGS
  earthquake feed.
- `ENABLE_SIMULATION_ANALYSIS` is a separate non-production backend-only mode.
  It may combine fictional hazard geometry with collected navigation data for
  `/context-areas` analysis, but the response must identify both sources and
  simulation uncertainty. It must not alter alert, hazard, or shelter lists.
- Cached alert data shows its last successful update. Data beyond its freshness
  threshold displays **Stale information** and is not described as live.
- Cached navigation and route responses remain available after a remote failure
  only with cache timestamps and unavailable/cached warnings.
- Preliminary, incomplete, unavailable, cached, or model-derived information
  uses language such as "may change" and "based on currently available
  information."
- Never use "safe route," "all clear," guaranteed arrival, guaranteed rescue,
  prediction, or guaranteed recovery language. "Suggested safer route" always
  retains source, timestamps, and uncertainty; gated fictional or mixed data
  also retains its demonstration notice.

## Responsive Reference

Design and test first at the archived Figma reference viewport of **390x844**.
Content uses safe areas, 16dp horizontal padding, scrolls vertically when
needed, and does not depend on fixed text heights. Wider phones and tablets may
increase margins or constrain readable content width; narrow screens must keep
all critical controls and labels visible.

## Accessibility

- Meet WCAG AA contrast for text and named foreground/background pairs.
- Support platform text scaling to at least 200% without clipping, ellipsis on
  critical copy, or inaccessible actions.
- Keep 48dp minimum touch targets, including icon buttons, route cards, and
  navigation destinations.
- Provide concise localized labels for icons and controls, logical semantic
  order, visible keyboard focus, standard back behavior, and live-region status
  announcements where state changes asynchronously.
- Use icons with text for critical status and actions; do not rely on gesture,
  position, sound, map graphics, or color alone.
- Provide the dialog-based SOS confirmation path for users who cannot perform a
  sustained hold gesture.
- Keep user-visible strings in ARB localization resources and allow Burmese
  text expansion and line wrapping.
