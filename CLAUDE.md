# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository layout

Monorepo with two independently-built projects and a solution file (`bitirmeDeneme.sln`):

- **`VeterinerAPI/`** — ASP.NET Core (.NET 10) REST API. MySQL via Pomelo EF Core, Firebase Admin for auth.
- **`VeterinerApp/`** — Flutter mobile app (Riverpod, go_router, dio, firebase_auth). UI language is Turkish.

The app is a veterinary clinic platform with three user roles: **`owner`** (pet owner), **`vet`** (veterinarian), **`clinic_admin`** (clinic manager). Role is a string on the `User` entity (default `owner`).

## Commands

### Backend (`VeterinerAPI/`)
```bash
dotnet build                                    # compile
dotnet run                                      # runs on http://localhost:5295
dotnet ef migrations add <Name>                 # create migration
dotnet ef database update                       # apply migrations
```
Requires `appsettings.json` (gitignored) with `ConnectionStrings:DefaultConnection`, and `firebase-adminsdk.json` (gitignored) in the project root. Without the Firebase file, `FirebaseApp` is not initialized and auth verification fails. `appsettings.example.json` is the template.

### Frontend (`VeterinerApp/`)
```bash
flutter pub get                                 # install deps (required after pulling)
flutter analyze                                 # lint / static analysis
flutter run                                     # run on device/emulator
flutter test                                    # run all tests
flutter test test/path_test.dart                # run a single test file
```

> Note: Flutter SDK is often not installed on the primary dev machine — frontend changes may need to be verified on a separate device. Prefer writing compilable Dart carefully rather than relying on local `flutter analyze`.

## Backend architecture

**Layering:** Controller → Service (`Services/Implementations/`, interface in `Services/Interfaces/`) → Repository (generic `Repository<T>` + entity-specific repos) → EF Core `AppDbContext`. All registered as scoped in `Program.cs`. Business logic lives in Services; controllers are thin.

**Request pipeline (order matters, see `Program.cs`):**
1. `GlobalExceptionMiddleware` — maps exceptions to HTTP + `ApiResponse`. **Convention:** `UnauthorizedAccessException`→403, `KeyNotFoundException`→404, `ArgumentException`/`InvalidOperationException`→400, everything else→500. Throw these from services to control status codes.
2. Security headers → CORS (`AppCorsPolicy`) → rate limiter → authentication → authorization → `UserResolverMiddleware`.

**Auth flow:** Flutter sends `Authorization: Bearer <Firebase ID token>`. `FirebaseAuthHandler` (custom `AuthenticationHandler`, scheme `"Firebase"`) verifies the token and adds a `FirebaseUid` claim. `UserResolverMiddleware` then looks up the local `User` and stores `context.Items["UserId"]` / `["UserRole"]`. Controllers read identity two ways: `HttpContext.Items["UserId"]` (owner-scoped endpoints) or `User.FindFirstValue("FirebaseUid")` passed into vet/clinic services which re-resolve the entity. There is no `[Authorize(Roles=...)]`; role enforcement is done inside services (e.g. `GetVetAsync` throws if `user.Role != "vet"`).

**Rate limiting:** named policies — `GeneralPolicy` (60/min, applied to all endpoints), `AuthPolicy` (5/10min on register/login), `AppointmentPolicy` (5/min on appointment creation). 429 responses include `Retry-After`.

**Responses:** everything wraps in `ApiResponse<T>` (`{ success, message, data }`), camelCase JSON.

**Background work:** `AppointmentStatusWorker` (hosted service, every 15 min) flips `pending` appointments whose date has passed to `expired`.

**Seeding:** `DbSeeder.SeedDataAsync` runs on every startup but is idempotent — it no-ops once the `Clinics` table is non-empty (`if (await context.Clinics.AnyAsync()) return;`), so re-seeding requires clearing the DB. It creates 1 clinic (PatiLife, İstanbul/Kadıköy), 1 vet (Cerrahi, weekday 09:00–18:00 / 30-min slots), 1 owner + 1 animal (Karabaş) + 1 vaccine record. Two nuances:
- The seeded `clinic_admin` user **is also the vet** (`Vet.UserId == adminUser.Id`) — a single `User` can be both `clinic_admin` and `vet`. This is why services re-resolve identity by role rather than assuming one role per user.
- Seeded users carry **fake Firebase UIDs** (`dummy_admin_uid_123`, `dummy_owner_uid_456`) — they are DB fixtures that **cannot log in** through the real Firebase flow. A usable account requires registering via `/api/auth/register` with a real Firebase user.

**Static files:** uploaded images served from `wwwroot/`; `FileService`/`image_upload_service` handle uploads.

## Frontend architecture

**Structure:** feature-first under `lib/features/<feature>/presentation/screens/` (+ `data/models/` where present). Cross-cutting code in `lib/core/` and shared widgets in `lib/shared/widgets/`.

**Networking:** `DioClient` (`core/network/dio_client.dart`) is the single HTTP entry point. `baseUrl = http://10.0.2.2:5295/api` (Android-emulator alias for host localhost — **change to the machine's LAN IP for a physical device**). An interceptor injects the Firebase ID token on every request and rewrites 429s into a friendly message. There is **no repository/provider layer for most features** — screens are `StatefulWidget`s that call `DioClient().dio` directly and hold local state.

**Routing:** `core/router/app_router.dart` — a single `GoRouter`. Roles land on different home routes: `/home` (owner), `/clinic-home` (clinic_admin), `/vet-home` (vet).

**Theming (design system):** token-based. `core/theme/` holds `app_colors` (light+dark `ColorScheme` + `AppSemanticColors` ThemeExtension), `app_spacing`, `app_radius`, `app_typography`, and `app_theme`. Access via `BuildContext` extensions: **`context.scheme`** (ColorScheme) and **`context.colors`** (semantic: `textSecondary`, `outline`, `surfaceAlt`, `success`, `warning`, `info`). Dark mode via `theme_mode_provider` (Riverpod + shared_preferences, default `ThemeMode.system`). **When touching UI:** use tokens + `lib/shared/widgets/*` (AppCard, StatCard, StatusBadge, EmptyState, ErrorState, MenuTile, InfoRow…), never hardcoded `Colors.*`/inline `TextStyle`.

**Appointment status:** `core/utils/appointment_status.dart` is the single source for status label/icon/color (`pending`, `confirmed`, `completed`, `cancelled`, `no_show`, `expired`).

## Appointment domain (the core workflow)

Booking (owner) → confirmation (vet **or** clinic_admin, both can act on the same appointment). Key invariants:

- **Status is a string** on `Appointment` (`MaxLength(20)`), validated by `UpdateAppointmentStatusRequest`'s regex (`pending|confirmed|cancelled|completed|no_show`). `expired` is set only by the background worker, never via the API.
- **State machine:** `Services/AppointmentStatusRules.cs` is the single source for allowed transitions (`pending→confirmed/cancelled`, `confirmed→completed/no_show/cancelled`; the rest are terminal). Both `VetService.UpdateAppointmentStatusAsync` and `ClinicService.UpdateClinicAppointmentStatusAsync` call `EnsureTransition(...)`. Add new transitions there, not in the services.
- **Cancellation** is a soft update: `CancelAppointmentAsync` sets status to `cancelled` (row is kept). Slot availability (`GetAppointmentsByVetAndDateAsync`) excludes `cancelled`, so the slot frees up automatically. `completed` appointments cannot be cancelled.
- **Slots are local wall-clock**, generated from `VetSchedule` (start/end/slotDuration per weekday) minus already-booked times. Booking validates `request.AppointmentDate.TimeOfDay` against these.
- **Timezone caveat:** the frontend sends the picked time with a `Z` suffix and the whole system treats appointment times as naive wall-clock end-to-end (write and read use the same value, so display is consistent). Do **not** "fix" this by converting only the frontend to true UTC — it breaks slot matching (`TimeOfDay` no longer equals the local schedule slot). A correct fix requires coordinating schedule/slot generation and the worker's `DateTime.UtcNow` comparisons together.

## Conventions

- User-facing strings and code comments are in **Turkish**; keep new ones consistent.
- Sanitize user-provided free text with `Helpers/InputSanitizer.Sanitize(...)` before persisting (see appointment notes).
- Vet specialties come from a single canonical list (`Constants/VetSpecialties.cs`, exposed via `GET /api/specialties`) — reuse it rather than hardcoding.
- MySQL does not support filtered/partial unique indexes; enforce "one active appointment per slot" at the application level, not via a DB constraint.
