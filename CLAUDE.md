# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

PatiLife ("Yapay Zeka Destekli Veteriner Klinik Uygulaması") is a veterinary clinic platform with two parts that live in one repo:

- `VeterinerAPI/` — ASP.NET Core (.NET 10) REST API backed by MySQL via EF Core (Pomelo).
- `VeterinerApp/` — Flutter mobile client (`veteriner_app`).

User-facing strings, comments, commit messages, and API messages are in **Turkish** — match that convention when adding code.

## Commands

### Backend (`VeterinerAPI/`)
```bash
dotnet run                       # runs on http://localhost:5295 (ASPNETCORE_ENVIRONMENT=Development)
dotnet build
dotnet ef migrations add <Name>  # create a migration
dotnet ef database update        # apply pending migrations
```
OpenAPI/Swagger is mapped only in Development. There is no test project.

### Frontend (`VeterinerApp/`)
```bash
flutter pub get
flutter run                      # against an Android emulator by default
flutter analyze                  # lint (flutter_lints)
flutter test                     # runs widget/unit tests under test/
flutter test test/foo_test.dart  # run a single test file
flutter build apk --release
```

## Configuration (required before running)

These files are git-ignored / not committed and must exist locally:

- `VeterinerAPI/appsettings.Development.json` — set `ConnectionStrings:DefaultConnection` (MySQL). See `appsettings.example.json` for the shape.
- `VeterinerAPI/firebase-adminsdk.json` — Firebase Admin service-account credentials. Loaded at startup from the content root; **without it, token verification silently never initializes** (`Program.cs` only calls `FirebaseApp.Create` if the file exists).
- `VeterinerApp/lib/core/network/dio_client.dart` — `baseUrl` is hardcoded to `http://10.0.2.2:5295/api` (Android emulator → host loopback). Change for real devices or production.

## Authentication & request flow (the key cross-cutting concern)

Auth is **Firebase-based, stateless on the backend**. Understanding this flow is essential:

1. Flutter authenticates with Firebase Auth directly. `DioClient`'s interceptor attaches the Firebase ID token as `Authorization: Bearer <token>` on every request.
2. `FirebaseAuthHandler` (a custom `AuthenticationHandler`, registered as the `"Firebase"` scheme) verifies the token and produces claims, notably `FirebaseUid`.
3. `UserResolverMiddleware` runs **after** auth, looks up the local `User` row by `FirebaseUid`, and stashes `UserId` + `UserRole` into `HttpContext.Items`.
4. Controllers read the local user via `HttpContext.Items["UserId"]` (not from claims). Pattern:
   ```csharp
   if (!HttpContext.Items.TryGetValue("UserId", out var uidObj)) return Unauthorized();
   int userId = (int)uidObj!;
   ```

There is no local password store — the Firebase UID is the link between Firebase and the `users` table. Registration (`POST /api/auth/register`) requires an already-authenticated Firebase token and creates/links the local `User` row.

### Roles
`User.Role` is a string: `owner`, `vet`, or `clinic_admin`. The Flutter client routes by role after calling `/auth/me` (see `splash_screen.dart`): `clinic_admin` → `/clinic-home`, `vet` → `/vet-home`, `owner` → `/home`. The feature folders `clinic_panel/`, `vet_panel/`, and the owner-facing features mirror these roles.

## Backend architecture

Layered, with DI registrations in `Program.cs`:

**Controller → Service (interface) → Repository (interface) → AppDbContext**

- **Repositories** (`Repositories/`): generic `Repository<T>` / `IRepository<T>` plus per-entity repositories (e.g. `IUserRepository.GetByFirebaseUidAsync`). Add new ones to both the `Interfaces`/`Implementations` folders and register in `Program.cs`.
- **Services** (`Services/`): business logic. See `AuthService` for the cascade soft-delete pattern (deactivating a user anonymizes the row, cancels future appointments, deactivates animals/clinic/vet, then deletes the Firebase user).
- **DTOs** (`DTOs/`): all responses wrap data in `ApiResponse<T>` (`{ success, message, data }`). The Flutter side reads `response.data['success']` / `['data']`. Keep this envelope.
- **Entities** (`Models/Entities/`): EF models with explicit `[Table]`/`[Column]` snake_case mappings. Relationships and indexes are configured in `AppDbContext.OnModelCreating` (mostly `DeleteBehavior.Restrict` — cascades are deliberately avoided except for schedules/vaccines/reviews). `AppDbContext.SaveChanges*` auto-updates any `UpdatedAt` property on modified entities.
- **Middleware order matters** (`Program.cs`): `GlobalExceptionMiddleware` (outermost, returns sanitized 500s) → security headers → static files → CORS → rate limiter → authentication → authorization → `UserResolverMiddleware` → controllers.
- **Background work**: `AppointmentStatusWorker` (hosted service) marks `pending` appointments past their date as `expired` every 15 minutes.
- **Seeding**: `DbSeeder.SeedDataAsync` runs on every startup in `Program.cs`.

### Rate limiting
Three fixed-window policies, applied via `[EnableRateLimiting("...")]`:
- `GeneralPolicy` (60/min) — applied globally to all controllers.
- `AuthPolicy` (5 per 10 min) — on register endpoints (brute-force protection).
- `AppointmentPolicy` (5/min) — on appointment creation.
The Flutter `DioClient` translates HTTP 429 into a Turkish "too many requests" error using the `Retry-After` header.

### File uploads
`FileService` saves images under `wwwroot/uploads/<folder>/` with a GUID filename, validates extension (`.jpg/.jpeg/.png/.webp`) and 5 MB max, returns a relative URL like `/uploads/profiles/<guid>.jpg`, and guards `DeleteImage` against path traversal. Profile-photo upload replaces and deletes the old file (see `AuthController.UploadProfilePhoto`).

## Frontend architecture

Feature-first layout under `lib/features/<feature>/` (`auth`, `animals`, `appointments`, `clinics`, `clinic_panel`, `vet_panel`, `home`, `profile`), each with `data/models/` and `presentation/screens/`. Shared infra is in `lib/core/` (`network/dio_client.dart`, `router/app_router.dart`, `theme/app_theme.dart`, `services/image_upload_service.dart`).

- **Routing**: `go_router`, all routes declared centrally in `AppRouter` (`core/router/app_router.dart`).
- **State**: `flutter_riverpod` is a dependency and `main.dart` wraps the app in `ProviderScope`, but screens currently use `StatefulWidget` + `setState` and instantiate `DioClient()` directly inside methods. There is no provider layer yet — follow the existing direct-Dio pattern unless intentionally introducing providers.
- Models parse from the `ApiResponse` envelope via `fromJson` (e.g. `data.map((e) => AppointmentModel.fromJson(e))`).
- Localization: `intl` with `tr_TR` initialized in `main.dart`.

## Deployment

`DEPLOY_CHECKLIST.md` (Turkish) is the source of truth for production cutover: secrets out of git, production CORS origins (`Cors:AllowedOrigins`), `ASPNETCORE_ENVIRONMENT=Production`, EF migrations applied, Flutter `baseUrl` set to the HTTPS production URL, and a release build.
