# ConnectALU

A mobile platform connecting ALU students seeking hands-on experience with
verified, student-led startups in the ALU ecosystem.

## 1. The problem, reframed

A generic "internship board" app is a CRUD exercise: post a listing, browse
listings, apply. That doesn't hold up as a real product because it ignores
the two actual failure modes on campus:

- **Trust asymmetry.** Students can't tell a legitimate ALU venture from
  someone posting "internships" with no accountability. Founders can't tell
  a serious applicant from someone mass-applying to pad a CV.
- **Process overhead.** Early-stage founders have no HR function. They need
  something between "a spreadsheet" and "a full ATS" — lightweight enough
  to actually use.

So the product's real job is **verified matching with low friction on both
sides**, not just posting and browsing. Every architectural decision below
traces back to that.

## 2. Why these technology choices

| Decision | Reasoning |
|---|---|
| **Riverpod** over BLoC/Provider | Compile-time provider safety, no `BuildContext` dependency for business logic (testable in plain Dart via `ProviderContainer`), and `StreamProvider` maps directly onto Firestore's real-time listeners without BLoC's extra event/state boilerplate. For a project this size, that ceremony isn't worth paying for. |
| **Firebase** (Auth, Firestore, Storage, Functions) | Required by the brief, and it genuinely fits: Firestore's snapshot listeners solve "real-time updates" natively, and Cloud Functions give a server-authoritative place to mint verification claims (see below) — something a plain REST backend would need more scaffolding for. |
| **go_router** | Declarative routing with a single `redirect` callback (see `app_router.dart`) means auth-gating and onboarding-gating logic lives in exactly one place instead of being duplicated as guards inside every screen. |
| **Cloud Functions + custom claims** for verification | A founder must never be able to self-declare "verified" by writing to their own Firestore document. Custom claims are only mintable server-side with the Admin SDK, so this is the one place client code cannot forge its way past. |

## 3. The verification / trust layer

This is the feature that answers "how only valid startups will be allowed
on the platform," and it's designed as three independent layers so no
single bug collapses the whole guarantee:

1. **UI layer** — the "Post opportunity" button is hidden unless
   `startup.isVerified`.
2. **Security rules layer** (`firestore.rules`) — writes to `opportunities`
   require the caller's auth token to contain the startup's ID in a
   `verifiedStartups` custom claim. This is enforced even if someone
   bypasses the app entirely and calls the Firestore SDK directly.
3. **Cloud Function layer** (`functions/index.js`) — `reviewStartup` is the
   only code path that can set `verificationStatus: verified` and mint the
   corresponding claim, and it itself checks `auth.token.admin === true`.

A startup is created as `pending` and is invisible to the student-facing
discovery query (`watchVerifiedStartups` filters `verificationStatus ==
'verified'`) until an admin approves it.

## 4. Data model rationale

See `lib/models/` for full schemas. Two choices worth calling out:

- **`applications` is a top-level collection**, not nested under
  `opportunities/{id}/applications`. A student's "my applications" view
  needs one indexed query (`where studentId == uid`) instead of a
  collection-group query across every opportunity in the database — this
  matters once the platform has hundreds of postings.
- **Denormalized display fields** (`startupName`, `startupLogoUrl` on
  `Opportunity`; `opportunityTitle`, `startupName` on `Application`) trade
  a small amount of write-time duplication for feed rendering that never
  needs an extra round-trip per list item. Given these fields change
  rarely (a startup renaming itself is rare), the staleness risk is low
  and acceptable.

## 5. State management architecture

Every feature follows the same three-layer pattern:

```
Repository (pure Firestore/Storage access, no Flutter imports)
      ↓
Riverpod Provider (StreamProvider / FutureProvider / StateNotifier)
      ↓
UI (ConsumerWidget, reads providers, never touches Firestore directly)
```

This is the maintainability argument: swapping Firestore for another
backend later only touches the repository layer, and every provider is
independently testable by overriding it in a `ProviderScope` in widget
tests.

Notable providers:

- `rankedOpportunityFeedProvider` — composes the raw Firestore stream with
  client-side skill-match ranking and free-text search, so the "smart
  feed" logic lives in exactly one place shared by the discover screen,
  search screen, and (indirectly) the bookmark screen.
- `_RouterRefreshNotifier` — bridges Riverpod's stream-based auth/profile
  state into go_router's `Listenable`-based `refreshListenable`, so
  navigation redirects react to auth and onboarding state changes, not
  just explicit navigation calls.

## 6. Feature-to-requirement mapping

| Requirement | Where |
|---|---|
| Auth & onboarding | `features/auth/` — email + Google sign-in, role-selection onboarding gated by router redirect |
| Startup profiles + verification | `features/startup/` + `firestore.rules` + `functions/index.js` |
| Opportunity posting | `features/opportunities/presentation/post_opportunity_screen.dart`, gated by verified-founder custom claim |
| Discovery & search | `opportunity_feed_screen.dart`, `search_screen.dart`, backed by `rankedOpportunityFeedProvider` |
| Application submission | `features/applications/presentation/apply_screen.dart`, transactional write in `ApplicationRepository.submitApplication` |
| Real-time updates | Every list/detail screen is a `StreamProvider` off Firestore snapshots |
| Firebase backend | Auth, Firestore, Storage, Functions — see `firebase.json` (not included; run `flutterfire configure`) |
| State management | Riverpod throughout, described above |

## 7. Beyond the minimum

- **Skill-matched feed** (`Opportunity.matchScore`) — ranks the discovery
  feed by overlap between an opportunity's `skillsRequired` and the
  student's declared `skills`, computed client-side since the working set
  per query is small. This is the single feature that most changes the
  product from "board" to "platform."
- **Application status timeline** (`my_applications_screen.dart`) — a
  visual pipeline (Submitted → In Review → Interview → Decision) driven by
  `Application.statusHistory`, which the founder updates from
  `applicant_list_screen.dart`.
- **Scoped chat** — messaging only unlocks once a founder moves an
  applicant to the "Interview" stage, so it can't become a general-purpose
  spam inbox.
- **Bookmarking** — a simple array field on the user doc
  (`savedOpportunityIds`), toggled from the opportunity detail screen.
- **Founder analytics dashboard** — a lightweight applicant funnel
  (Applied → Interview → Accepted) per opportunity, computed from the
  existing `applications` stream rather than a separate aggregation
  pipeline, kept accurate server-side via the `onApplicationWritten`
  Cloud Function as a safety net against client-side drift.

## 8. Scalability notes

- Composite indexes for every non-trivial query are declared explicitly in
  `firestore.indexes.json` rather than left to be auto-suggested at
  runtime — documenting these up front makes the read-cost profile of the
  app auditable.
- The discovery feed is capped (`limit(50)`) with the expectation of
  cursor-based pagination (`startAfterDocument`) as a next step once
  listing volume grows past a single page.
- `applicantCount` is maintained via a Firestore transaction on write
  (`ApplicationRepository.submitApplication`) and independently
  reconciled server-side (`onApplicationWritten`), so the founder-facing
  counts can't silently drift under concurrent writes.

## 9. Project structure

```
lib/
  core/            theme, router, cross-cutting services
  models/          plain Dart data classes (no Firestore types leak past here)
  features/
    auth/          data/ providers/ presentation/
    startup/       data/ providers/ presentation/
    opportunities/ data/ providers/ presentation/
    applications/  data/ providers/ presentation/
    chat/          data/ providers/ presentation/
    dashboard/     presentation/  (founder analytics)
  shared/widgets/  MainShell bottom-nav scaffold
functions/         Cloud Functions (verification, applicant-count reconciliation)
firestore.rules
firestore.indexes.json
```

## 10. Setup

This scaffold intentionally omits `firebase_options.dart` and
`google-services.json`/`GoogleService-Info.plist`, since those are
project-specific and generated per Firebase project.

```bash
flutter pub get
flutterfire configure          # generates firebase_options.dart, links your Firebase project
firebase deploy --only firestore:rules,firestore:indexes,functions
flutter run
```

You'll also need to manually set `{ admin: true }` as a custom claim on
at least one account (via the Firebase Admin SDK or console) to act as the
startup-review admin during development.
