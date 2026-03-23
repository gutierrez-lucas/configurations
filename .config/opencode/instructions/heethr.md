# Heethr — Snow Melting Ecosystem
## Product & Code Knowledge Base
**Version:** 2.2 · **Last updated:** March 2026

This file is the authoritative permanent reference for the Heethr platform. It is loaded by OpenCode at the start of every session. Do not re-analyse what is already documented here — extend it as new repositories are connected.

---

## 1. What is Heethr?

Heethr is a comprehensive B2B/B2C digital ecosystem for the **snow melting industry**. It connects contractors/installers, customers/homeowners, dealers, and vendors through a unified platform.

**Legal entity:** Agib Creations
**Key people:** Rami (founder/lead), Eric (merchant/accounting), Vince (partner)
**Markets:** Canada (bilingual EN/FR), North America
**Shop URL:** https://shop.heethr.com
**API base URL:** https://api.heethr.com/v1
**Swagger (dev):** http://localhost:3000/swagger

---

## 2. User Roles

| Role | `users.role` value | Description |
|------|-------------------|-------------|
| Admin | `ADMIN` | Full platform management; bypasses all RolesGuard checks |
| Contractor | `CONTRACTOR` | Primary mobile app user — installs, manages projects, buys products |
| Customer / Homeowner | `CUSTOMER` | Receives project package, views compliance & warranty |
| Dealer | `DEALER` | Receives linked contractors' orders, has own dealer portal |
| Vendor | `VENDOR` | Product supplier |
| Student | `STUDENT` | LMS-only access for training |

`users.role` is stored as `varchar` (not a native PostgreSQL enum). `ADMIN` role bypasses all `RolesGuard` checks unconditionally.

---

## 3. Infrastructure & Architecture

### Two-server setup

| Server | Provider | What Runs There |
|--------|----------|----------------|
| Server 1 | Digital Ocean (`57.159.25.69`) | NestJS Backend API, PostgreSQL DB (Amazon RDS), React Admin + Dealer Dashboard |
| Server 2 | Hostinger | WordPress marketing site, webinar landing pages, Heethr Academy LMS |

**SSH access to Digital Ocean VM:** Use the certificate (private key) shared by the team:
```bash
chmod 400 /path/to/key.pem
ssh -i /path/to/key.pem <username>@57.159.25.69
# Default username is likely `ubuntu` (Ubuntu droplet) or `root`
```

### Technology Stack (actual, from code)

| Layer | Technology |
|-------|-----------|
| Mobile App | Flutter (iOS + Android), Dart SDK ^3.x, go_router v14, Provider, Dio HTTP |
| Backend API | NestJS 11 (TypeScript), REST, Swagger at `/swagger`, JWT (passport-jwt), TypeORM 0.3 |
| Database | PostgreSQL (Amazon RDS), UUID PKs via `uuid_generate_v4()` |
| Admin Dashboard | React + Vite + TypeScript, shadcn/ui, Tailwind CSS |
| Marketing / LMS | WordPress (Hostinger) |
| AI Engine | External API at `https://apilayoutgenerator.heethr.com` (env: `LAYOUT_API_BASE`) |
| Payments | Stripe SDK v18 (API version `2024-06-20`); ACSS Debit (Canadian PADs) supported |
| Storage | **Local disk** at `uploads/` (served as static). No AWS S3 in current codebase. |
| Email | nexrush.com HTTP relay (`https://nexrush.com/send-mail.php`); Nodemailer/GoDaddy SMTP for deletion emails only |
| CRM / Inventory | Zoho Inventory + Zoho Books v3 (OAuth2 refresh-token) |
| Push Notifications | Firebase Admin SDK (FCM) — service account JSON in repo root |
| Analytics | Google Analytics + Facebook Pixel (WordPress side) |
| Logging | nestjs-pino (Pino) — structured JSON or pretty format via `LOGGER_FORMAT` |
| Deployment (backend) | AWS Elastic Beanstalk (`application.yaml` in repo root) |
| Deployment (dashboard) | Static hosting — Netlify / Vercel / S3 + CloudFront |
| App Distribution | Apple App Store (iOS), Google Play (Android) |

### CORS allowed origins (backend)
- `*.karmikkarma.com` and `*.heethr.com` (any port, HTTP or HTTPS)
- `localhost` and `127.0.0.1` (HTTP, any port)
- `57.159.25.69` (Digital Ocean server IP)
- Requests with **no `Origin` header** always pass (mobile apps, curl)
- Credentials: enabled

---

## 4. Repository Index

| Repo | Local path | Status |
|------|-----------|--------|
| Backend API | `/home/lucas/Work/Heether/snow-melting-backend` | **Analysed — see Section 11** |
| Admin Dashboard | `/home/lucas/Work/Heether/snow_melting_dashboard` | **Analysed — see Section 12** |
| Mobile App (Flutter) | N/A | Out of scope — not being analysed |

### Backend dev setup
```bash
cd /home/lucas/Work/Heether/snow-melting-backend
yarn install
cp .env.example .env   # fill values (see Section 11.4)
npm run migrations      # run TypeORM migrations
yarn start:dev          # hot-reload on :3000
```

### Git branches (backend)
| Branch | Purpose |
|--------|---------|
| `main` | Current default / production branch |
| `cleanup` | Refactoring / cleanup work |
| `lara` | Feature branch |
| `lms` | LMS feature work |
| `yahya-connect-zoho` | Zoho integration work |

---

## 5. Core Product Modules

### 5.1 E-Commerce
- Product catalog synced from Zoho Inventory (stored in `products.items` JSONB)
- Real-time inventory via Zoho `inventoryadjustments` API
- Contractor-specific pricing/discounts via `products.discount`
- AI pre-filled cart via layout generator API (`POST /app/v1/heethr-app/heethr-app-estimation-api/`)
- Accessory suggestions surfaced from product dependency logic
- Stripe checkout: tax via Stripe Tax API (fallback: 14.9% hardcoded as `TAX_RATE`)
- Dealer linking: backend scans dealers within 65 km of contractor address

### 5.2 AI Cable Layout Design Engine
- External API at `https://apilayoutgenerator.heethr.com`
- Inputs: `{ areas: [{ area, spacing, cable_type: mesh|loose, surface_type }], voltage }`
- `cable_type` normalization: `1` → `mesh`, `2` → `loose`
- `surface_type` normalization: maps material names (`concrete`, `asphalt`) and numeric codes
- 20-second timeout; errors surface `response.data.detail` field
- ⚠️ Debug `console.log("aaa", ...)` present in `src/integrations/cost-estimation.client.ts` — remove before production

### 5.3 Estimate / Proposal Generation
- `POST /api/v1/estimates` — calls cost API, saves base64 files, sends emails + push notifications
- Status field: `estimates.status` (workflow) + `estimates.hiring_status` + `estimates.status_completed`
- `estimates.send = true` when estimate has been sent to customer
- `estimates.accepted_as_project = true` when hired contractor creates a project from it
- `GET /api/v1/estimates/:id/pdf` — generates PDF using `pdfkit`

### 5.4 Project Management & Compliance
- `projects` table linked to `steps` (OneToMany)
- Status lifecycle: `pending → in_progress → completed → cancelled` (enum `enum_projects_status`)
- Steps store images as PostgreSQL `text[]` array
- Compliance stored separately in `compliances` table — 5 JSON sections: `preparation`, `cables`, `embedment`, `pavementInstallation`, `panelInstallation`

### 5.5 LMS — Heethr Academy
- Course → Section → Lesson hierarchy in DB
- Lesson types: `video`, `assignment`, `pdf`
- Enrollment tracked in `user_course_enrollments`
- Per-lesson progress in `user_lesson_progress`
- Certificates issued to `user_certificates` on course completion
- Assignments: `assignment` → `question[]` (MCQ with `correctIndex`); attempts in `assignment_attempt`

### 5.6 Contractor Marketplace — HirePlace
- `GET /api/v1/users/publiccontractor` — public contractor listing with project count
- `GET /api/v1/users/contractors/by-distance` — sorted by distance from coordinates
- `GET /api/v1/dealers/public` — public dealer listing
- Ratings via `user_ratings` table — unique constraint per rater+rated pair

### 5.7 End-User / Homeowner Portal
- Authenticated via same JWT system
- Projects visible via `GET /api/v1/projects` (public endpoint, filtered by ownership in service)
- Compliance records via `GET /api/v1/compliances/by-estimate/:estimateId`

### 5.8 Subscriptions
- Plans: `cold`, `warm`, `hot` (stored in `plan_pricing.plan_id`)
- Pricing stored in `plan_pricing` table (admin-editable)
- Stripe: PaymentIntent, Checkout Sessions, auto-renewal subscriptions, webhooks
- `GET /api/v1/subscriptions/plans/available` — public plan list

---

## 6. Physical Products

| Category | Notes |
|----------|-------|
| Heating Cables | Core product — branded **ecoMELT 15W**. Bilingual EN/FR docs. |
| Controllers | Thermostat/controller units |
| Panels | Electrical panels/distribution |
| Strips | Heating strips (alternative to cable) |
| Clips | Installation accessories |
| Caution Tape | Safety/marking accessories |

ecoMELT 15W docs: installation guide (EN+FR), warranty (EN+FR), test log sheet (EN+FR). Located in `HeetherDocs/PRODUCTS/DOCUMENTATION/HEATING CABLES/`.

---

## 7. Compliance & Cable Testing Protocol

### Pre-installation tests (mandatory)
- **Resistance Test:** within −5% to +10% of tagged value (Ω)
- **Insulation Test:** new cables must read **>2200 MΩ** (Perfect Health)

### Insulation health thresholds

| Reading | Status | Action |
|---------|--------|--------|
| >2200 MΩ | Perfect | Proceed |
| 500–2200 MΩ | Good | Proceed with note |
| 100–500 MΩ | Mediocre | Installer discretion + document reason |
| 50–100 MΩ | Poor | Installer discretion + document reason |
| <50 MΩ | Critical | Do not install. Replace. |

During installation: if readings drop, installer must stop and diagnose. All tests: photo documentation + timestamped log. Records retained minimum 5 years. Compliance data feeds `compliances` table → homeowner warranty validity.

---

## 8. Business & Payment Model
- Platform is subscription-based + product sales
- Transaction amounts: $5,000–$20,000
- Payment: credit card (~3% fee) and EFT/ACSS Debit ($0.50/transaction)
- Primary processor: Stripe (`STRIPE_SECRET_KEY` env var)
- `TAX_RATE = 0.149` (14.9%) hardcoded fallback in `src/app.constants.ts`
- Zoho Books integration for invoicing (OAuth2 refresh-token)
- Polvo/EFT integration: in progress

---

## 9. Known Gaps & Pending Items (as of March 2026)
- Final AI model hosting decision
- Polvo/EFT integration in progress
- CRM final selection (HubSpot vs. Mailchimp vs. Zoho)
- Video hosting/streaming for LMS
- Multi-vendor supplier API (future)
- Customer review system in marketplace (scope pending)
- `migrations/main.ts` has wrong entity glob (`restaurant` instead of `domain`) — migrations still run correctly but this should be fixed

---

## 10. Instructions for OpenCode (Heethr-specific)

- Treat this file as authoritative product + code reference. Do not re-analyse what is already here.
- When a new repository is connected, enhance Section 4 (Repository Index) and add a new backend-style section for that repo.
- The platform is bilingual (EN/FR) — respect this in all user-facing strings. Translation shape: `{ en: string, fr: string }` stored as JSONB.
- Quebec Law 25 and GDPR compliance are non-negotiable. Flag any code change affecting PII fields.
- Pino logger redacts these fields automatically: `email`, `password`, `passwordConfirmation`, `accessToken`, `firstName`, `lastName`, `line1`, `line2`, `line3`, `complement`, `city`, `postalCode`, `countryCode`, `state`.
- `ADMIN` role bypasses all `RolesGuard` checks. Never add role restrictions that need to apply to admins without accounting for this.
- All API routes use `/api/v1/` prefix except `shipping` (no prefix — inconsistency in codebase).
- File storage is **local disk** (`uploads/`), not S3. The product docs mentioned S3 but the actual code uses disk.
- Email is sent via nexrush.com HTTP relay, not SendGrid. SendGrid is not present in the codebase.

---

## 11. Backend API — Code Reference
**Repo:** `/home/lucas/Work/Heether/snow-melting-backend`
**Stack:** NestJS 11, TypeScript, TypeORM 0.3, PostgreSQL, Passport-JWT

### 11.1 Directory Structure

```
src/
├── main.ts                    # Bootstrap: CORS, Swagger, static files, port 3000
├── app.module.ts              # Root module — imports all 35 domain modules
├── app.config.ts              # AppConfig class (validated from application.yaml)
├── app.constants.ts           # Global constants (TAX_RATE, DEFAULT_PAGE_SIZE, etc.)
├── app.globals.ts             # useGlobalDefaults() — registers pipes, guards, filters, interceptors
├── app.service.ts             # App-level service
├── config/
│   └── database.config.ts     # DatabaseConfig type
├── database/
│   └── database.module.ts     # SnowMeltingDatabaseModule — TypeORM setup, auto-loads all entities
├── domain/                    # All 35 feature modules (see 11.2)
├── errors/
│   └── service-validation.error.ts  # ServiceValidationError — throw for 400 business errors
├── filters/                   # 4 global exception filters (see 11.5)
├── guards/
│   ├── jwt.guard.ts           # JwtAuthGuard — global; supports @Public() soft-fail
│   ├── roles.guard.ts         # RolesGuard — per-route; ADMIN always passes
│   └── decorators/
│       ├── public-route.decorator.ts  # @Public()
│       └── roles.decorator.ts         # @Roles([UserRole.CONTRACTOR, ...])
├── integrations/
│   └── cost-estimation.client.ts  # AI layout API client (axios, 20s timeout)
├── interceptors/
│   ├── exclude-null.interceptor.ts     # Strips null from all responses
│   └── snake-case-serializer.interceptor.ts  # NOT globally registered
├── lib/
│   └── logger/logger.factory.ts  # Pino logger factory
├── middlewares/
│   └── body-parser.middleware.ts  # Raw body for /webhook/, JSON (50MB) for rest
├── migrations/                # 6 TypeORM migrations (+ main.ts DataSource config)
├── pipes/
│   └── validation.factory.ts  # ValidationPipe: transform=true, whitelist=true, enableImplicitConversion
└── utils/
    ├── email.utils.ts         # Email via nexrush.com HTTP relay + Nodemailer fallback
    ├── fcm.service.ts         # Firebase FCM push notifications
    └── zoho.helper.ts         # Zoho Inventory + Books API client
```

### 11.2 Domain Modules (35 total)

| Module | Controller prefix | Key entities | Notes |
|--------|------------------|-------------|-------|
| `admins` | `/api/v1/admins` | — | Admin user management |
| `assignment` | `/api/v1/assignments` | `assignment`, `question`, `assignment_attempt` | LMS quiz engine |
| `author` | `/api/v1/authors` | `author` | Course authors |
| `banners` | `/api/v1/banners` | `banners` | Shop/LMS banners (`type: shop|lms`) |
| `brands` | `/api/v1/brands` | `brands` | Product brands (bilingual JSONB name) |
| `categories` | `/api/v1/categories` | `categories` | Proxies to Zoho for list; bilingual JSONB name |
| `certification` | `/api/v1/certifications` | `certification` | LMS certificate programs |
| `compliances` | `/api/v1/compliances` | `compliances` | Cable install compliance records |
| `coupons` | `/api/v1/coupons` | `coupons` | Discount codes |
| `course` | `/api/v1/courses` | `course`, `section`, `lesson`, `comment`, `user_certificates`, `user_course_enrollments`, `user_lesson_progress` | Full LMS course system |
| `dashboard` | `/api/v1/dashboard` | — | Stats + activity (admin/contractor views) |
| `dealers` | `/api/v1/dealers` | — | Dealer management + self-registration |
| `doc` | `/api/v1/docs` | `doc` | Documents/files |
| `estimates` | `/api/v1/estimates` | `estimates`, `products` | Core: proposals, AI cost, PDF gen, Stripe |
| `faq` | `/api/v1/faq` | `faq` | FAQ items (`type: shop|lms`) |
| `feedback` | `api/v1/feedback` ⚠️ no leading slash | `feedback` | User feedback/bug reports |
| `helpcenter` | `/api/v1/helpcenter` | `helpcenter` | Help articles (`type: shop|lms`) |
| `image` | `/api/v1/image` | — | Base64 image upload → disk |
| `layout-generator` | `/api/v1/layout-generator` | — | Proxies to external layout API |
| `locations` | `/api/v1/locations` | `locations` | Named locations per user |
| `notifications` | `/api/v1/notifications` | `notifications` | In-app + FCM push notifications |
| `options` | `/api/v1/options` | `options` | Product options (bilingual JSONB name) |
| `orders` | `/api/v1/orders` | `orders` | Orders + Zoho SO + dealer routing |
| `products` | `/api/v1/products` | `products` | Zoho-synced product catalog |
| `project-address` | `/api/v1/project-addresses` | `project_addresses` | Saved project addresses |
| `projects-steps` | `/api/v1/projects-steps` | `steps` | Compliance step groups (up to 10 images each) |
| `projects` | `/api/v1/projects` | `projects` | Project management |
| `shared` | — | — | Shared types/utilities |
| `shipping` | `/shipping` ⚠️ no `/api/v1/` | — | Shipping quotes/booking/tracking (all public) |
| `subscriptions` | `/api/v1/subscriptions` | `subscriptions`, `plan_pricing` | Subscription plans + Stripe billing |
| `user-ratings` | `/api/v1/user-ratings` | `user_ratings` | Contractor ratings (unique per rater+rated) |
| `users-payments-info` | `/api/v1/payments-info` | `users_payments_info` | Stripe payment method tokens |
| `users-push-tokens` | `/api/v1/users-push-tokens` | `users_push_tokens` | FCM device tokens |
| `users` | `/api/v1/users` | `users`, `refresh_tokens` | Full auth lifecycle + SSO cookie |
| `zoho` | `/api/v1/zoho` | — | Zoho webhook receivers |

### 11.3 Authentication Flow

```
Request
  │
  ▼
JwtAuthGuard (global — all routes)
  ├── @Public() route + no Authorization header → pass, no user
  ├── @Public() route + invalid Bearer token → soft fail, pass without user
  ├── @Public() route + valid Bearer token → attach user, pass
  └── Protected route
        └── passport-jwt validates Bearer → JwtStrategy.validate() → DB lookup
              ├── Valid → request.user = { sub, email, role, lang }
              └── Invalid/missing → 401 UnauthorizedException
  │
  ▼
RolesGuard (per-route via @Roles([...]))
  ├── No @Roles() decorator → pass
  ├── user.role === ADMIN (case-insensitive) → always pass
  └── user.role in requiredRoles → pass / 403 Forbidden
```

**Key auth details:**
- `ignoreExpiration: true` in JWT strategy — tokens never expire by time; only rotation/revocation controls validity
- OTP store is **in-memory** (Map) — lost on restart; breaks in multi-instance deploys
- OTP `'1111'` is hardcoded as a bypass in `verify-otp` endpoint — any OTP verification passes with `1111` (test backdoor, must be removed before production)
- SSO: login sets `refreshToken` cookie on `.heethr.com` domain
- Refresh token rotated on every use (stored in `refresh_tokens` table)
- Password hashing: bcrypt with sentinel `%%...%%` wrapper; `DEFAULT_SALT_ROUNDS = 10`

### 11.4 Environment Variables

| Variable | Required | Default | Purpose |
|----------|----------|---------|---------|
| `DB_TYPE` | Yes | — | Database driver (`postgres`) |
| `DB_HOST` | Yes | — | PostgreSQL host |
| `DB_PORT` | Yes | — | PostgreSQL port |
| `DB_USERNAME` | Yes | — | PostgreSQL user |
| `DB_PASS` | Yes | — | PostgreSQL password |
| `DB_NAME` | Yes | — | PostgreSQL database name |
| `DB_SYNCHRONIZE` | No | `false` | TypeORM sync — **must be false in production** |
| `DB_SSL_ENABLED` | No | — | Enable SSL for DB connection |
| `DB_SSL_REJECT_UNAUTHORIZED` | No | — | Reject self-signed DB certs |
| `JWT_SECRET` | Yes | — | Access token HMAC secret |
| `JWT_EXPIRES_IN` | Yes | — | Access token lifetime (e.g. `15m`) |
| `JWT_REFRESH_SECRET` | Yes | — | Refresh token HMAC secret |
| `JWT_REFRESH_TOKEN_LIFETIME` | Yes | — | Refresh token lifetime (e.g. `7d`) |
| `STRIPE_SECRET_KEY` | Yes | — | Stripe secret key — throws on startup if missing |
| `LAYOUT_API_BASE` | No | `https://apilayoutgenerator.heethr.com` | AI layout generator base URL |
| `SERVICE_NAME` | No | `api` | Service name for logs/APM |
| `SERVICE_VERSION` | No | `1.0.0` | Semver for logs + Swagger |
| `APM_ENVIRONMENT` | No | `local` | Deployment environment tag for APM |
| `LOGGER_LEVEL` | No | `debug` | Pino log level |
| `LOGGER_FORMAT` | No | `plain` | `plain` or `json` |

**⚠️ Hardcoded secrets that must be moved to env vars:**
- `src/utils/zoho.helper.ts` — Zoho `clientId`, `clientSecret`, `refreshToken`, `zapikey`, `organizationId`
- `src/utils/email.utils.ts` — GoDaddy SMTP password `300Landscapers!` and `info@heethr.com` credentials
- `src/app.constants.ts` — `FILES_BASE_URL` hardcoded to `http://localhost:3000`

### 11.5 Global Middleware & Error Handling

**Request pipeline order:**
1. `bodyParser` middleware — raw body for `/webhook/`, JSON (50 MB limit) for all others
2. `cookie-parser`
3. `compression` (gzip/deflate)
4. `JwtAuthGuard` (global guard)
5. `RolesGuard` (per-route)
6. `ValidationPipe` — `transform: true`, `whitelist: true`, `enableImplicitConversion: true`
7. `ExcludeNullInterceptor` — strips `null` from all responses
8. Exception filters (registered globally):
   - `QueryFailedErrorFilter` — maps PostgreSQL error codes to HTTP status
   - `ServiceValidationErrorFilter` — `ServiceValidationError` → 400
   - `EntityNotFoundErrorFilter` — TypeORM not found → 404
   - `EntityPropertyNotFoundErrorFilter` — bad column ref → 400 (GET) or 500 (mutations)

**Throwing business errors from services:**
```typescript
throw new ServiceValidationError('message one', 'message two');
// → 400 Bad Request with { message: ['message one', 'message two'] }
```

### 11.6 Database Schema Summary

All entities extend `AbstractEntity` (uuid PK + `created_at` + `updated_at`) unless noted.
All PKs are UUID generated by `uuid_generate_v4()`.

**Core tables:**

| Table | Key columns | Relations |
|-------|------------|-----------|
| `users` | `email` (unique), `phone_number` (unique), `role` (varchar), `lang` (enum: en/fr), `address_latitude/longitude`, `business_address_latitude/longitude` | `refresh_tokens` (1:1), `estimates` (1:M), `user_dealers` join (M:M self) |
| `refresh_tokens` | `token`, `expiresAt` | `users` (M:1, CASCADE) |
| `estimates` | `status`, `hiring_status`, `status_completed`, `send`, `accepted_as_project`, `projectNumber` (auto-increment), `floorPlanFiles`, `winter_images` (json) | `products` (1:M), `users` customer+hired (M:1), `estimate_contractors` (M:M), self-ref `relatedEstimate` |
| `compliances` | `estimateId`, `preparation/cables/embedment/pavementInstallation/panelInstallation` (json), `progress` | `estimates` (M:1, CASCADE) |
| `projects` | `status` enum (pending/in_progress/completed/cancelled), `floor_plan`, `progress` | `users` contractor+customer (M:1), `steps` (1:M) |
| `steps` | `images` (text[]), `status` enum | `projects` (M:1, CASCADE) |
| `orders` | `products` (json snapshot), `tax`, `total`, `subtotal`, `discount`, `payment_reference`, `sales_order`, `tracking_number` | `users` (M:1, SET NULL) |
| `products` | `items` (jsonb — full Zoho payload), `item_id`, `status`, `discount` | `users` dealer (M:1), `estimates` (M:1) |
| `subscriptions` | `name`, `status` (varchar), `stripe_subscription_id`, `expires_at`, `starts_at` | `users` (M:1, SET NULL) |
| `plan_pricing` | `plan_id` PK (cold/warm/hot), `monthly_price`, `annual_price` | — |
| `notifications` | `title`, `message`, `userId`, `read` | `users` (M:1, CASCADE) |
| `user_ratings` | `raterId`, `ratedId`, `rating` (1-5), `review` — unique(raterId, ratedId) | `users` rater+rated (M:1) |
| `user_dealers` | join: `user_id` + `dealer_id` (both → `users`) | — |
| `estimate_contractors` | join: `estimate_id` + `contractor_id` | — |

**LMS tables:**

| Table | Notes |
|-------|-------|
| `course` | `courseTitle`, `description`, `coverImage`, `sort_order` |
| `section` | `title`; belongs to `course` |
| `lesson` | `type` (video/assignment/pdf), `videoId`, `pdfLink`; belongs to `section` |
| `comment` | Course comments + replies |
| `author` | Course author profiles |
| `certification` | Certificate programs (`passing_score`, `grading`) |
| `assignment` | `title` + `questions` (simple-json array) |
| `question` | `questionText`, `answers` (json array), `correctIndex` |
| `assignment_attempt` | `user_id`, `assignment_id`, `score`, `max_score`, `completed_at` |
| `user_course_enrollments` | unique(user, course) |
| `user_lesson_progress` | unique(user, lesson) |
| `user_certificates` | unique(user, course); `earned_at` |

**Content/config tables:**

| Table | Notes |
|-------|-------|
| `banners` | `type` enum (shop/lms) |
| `categories` | `name` JSONB `{en, fr}` |
| `brands` | `name` JSONB `{en, fr}` |
| `options` | `name` JSONB `{en, fr}` |
| `faq` | `type` enum (shop/lms) |
| `helpcenter` | `type` enum (shop/lms) |
| `doc` | Documents/files |
| `coupons` | `code` (unique), `discount_percent` |
| `locations` | Named locations per user |
| `project_addresses` | Saved addresses with lat/lng |
| `users_payments_info` | Stripe payment method tokens |
| `users_push_tokens` | FCM device tokens + `enabled` flag |
| `feedback` | User feedback with `resolved` flag |

### 11.7 Migrations Log

| Timestamp | Change |
|-----------|--------|
| `1738166400000` | ADD `users.country varchar(64)` |
| `1738170000000` | ADD `estimates.status_completed varchar(50) DEFAULT 'pending'` |
| `1738171000000` | ADD `notifications.read boolean DEFAULT false` |
| `1738172000000` | ADD `estimates.winter_images json` + `estimates.review boolean DEFAULT false` |
| `1738180000000` | CREATE TABLE `feedback` |
| `1738181000000` | CREATE TABLE `plan_pricing` |

### 11.8 Key API Routes Reference

**Auth & Users (`/api/v1/users`)**
| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/api/v1/users` | Public | Sign up |
| POST | `/api/v1/users/login` | Public | Login → tokens + SSO cookie |
| POST | `/api/v1/users/refresh` | Public | Rotate refresh token |
| POST | `/api/v1/users/logout` | Public | Revoke refresh token |
| POST | `/api/v1/users/forgot-password` | Public | Send OTP |
| POST | `/api/v1/users/verify-otp` | Public | Verify OTP → reset token |
| POST | `/api/v1/users/reset-password` | Public | Reset password |
| POST | `/api/v1/users/verify-email` | Public | Verify email OTP |
| GET | `/api/v1/users/publiccontractor` | Public | Contractor marketplace listing |
| GET | `/api/v1/users/contractors/by-distance` | Public | Contractors sorted by distance |
| GET | `/api/v1/users/dealers/by-distance` | Public | Dealers sorted by distance |
| PATCH | `/api/v1/users/:id` | Public | Update user profile |
| POST | `/api/v1/users/invite-contractor` | JWT (Dealer) | Invite contractor |

**Estimates (`/api/v1/estimates`)**
| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/api/v1/estimates` | JWT | Create estimate (calls AI, saves files, sends emails) |
| PATCH | `/api/v1/estimates/:id` | JWT | Update estimate (triggers emails on status change) |
| GET | `/api/v1/estimates/:id/pdf` | JWT | Generate PDF |

**Orders & Payments**
| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/api/v1/orders` | JWT + Roles | Create order → Zoho SO + dealer routing |
| POST | `/api/v1/orders/:id/pay` | Public | Verify Stripe PI → mark paid + create subscription |
| POST | `/api/v1/payments/create-intent` | Public | Create Stripe PaymentIntent |
| POST | `/api/v1/payments/create-pad-intent` | Public | Create ACSS Debit PaymentIntent |
| POST | `/api/v1/payments/calculate-tax` | Public | Stripe Tax API (fallback 14.9%) |
| POST | `/api/v1/payments/webhook` | Public | Stripe webhook handler |

**Subscriptions (`/api/v1/subscriptions`)**
| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api/v1/subscriptions/plans/available` | Public | List plan tiers with pricing |
| POST | `/api/v1/subscriptions/create-stripe-subscription` | Public | Create auto-renewing Stripe subscription |
| POST | `/api/v1/subscriptions/create-checkout-session` | Public | Stripe Checkout session |
| POST | `/api/v1/subscriptions/webhook` | Public | Stripe subscription lifecycle webhook |

**Shipping (no `/api/v1/` prefix)**
| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/shipping/quote` | Public | Get shipping quotes |
| POST | `/shipping/ship` | Public | Book shipment |
| GET | `/shipping/:shipmentId/tracking` | Public | Get tracking events |

### 11.9 Known Issues & Security Concerns (backend)

| # | File | Issue | Severity |
|---|------|-------|----------|
| 1 | `src/utils/zoho.helper.ts` | Zoho `clientId`, `clientSecret`, `refreshToken`, `zapikey` hardcoded | **Critical** |
| 2 | `src/utils/email.utils.ts` | GoDaddy SMTP password `300Landscapers!` hardcoded in plaintext | **Critical** |
| 3 | `src/domain/users/dto/signup.dto.ts:56` + `user.controller.ts:163` + `user.service.ts:41` | `role` field in signup DTO is typed `string` (no `@IsEnum(UserRole)`). Controller uppercases it but never validates it. Service spreads `...input` directly into `repository.create()`. **Any anonymous user can POST `"role":"ADMIN"` and receive a valid JWT with ADMIN role.** Fix: add `@IsEnum(UserRole)` to DTO and set a safe default in the service. | **Critical** |
| 4 | `src/app.constants.ts` | `FILES_BASE_URL` hardcoded to `http://localhost:3000` | High |
| 5 | `src/domain/users/auth/jwt.strategy.ts` | `ignoreExpiration: true` — tokens never expire | High |
| 6 | `src/domain/users/services/email-verification-otp.service.ts` | OTP store in-memory — lost on restart, breaks multi-instance | High |
| 7 | `src/main.ts` | Duplicate `Vary: Origin` middleware registered twice | Low |
| 8 | `src/integrations/cost-estimation.client.ts` | `console.log("aaa", ...)` debug statement | Low |
| 9 | `src/migrations/main.ts` | Entity glob points to `restaurant` instead of `domain` | Medium |
| 10 | `POST /api/v1/notifications/test-push-all` | Fully public — sends FCM to all users | High |
| 11 | `POST /api/v1/products/:id/inventory` | Fully public — directly adjusts Zoho inventory | High |
| 12 | `DELETE /api/v1/users/permanent/:id` | No role guard — any authenticated user can permanently delete any other user | **Critical** |

---

## 12. Admin Dashboard — Code Reference
**Repo:** `/home/lucas/Work/Heether/snow_melting_dashboard`
**Stack:** React 19, Vite 6, TypeScript 5.7, Tailwind CSS v4, shadcn/ui (Radix UI), Zustand, React Hook Form, Zod, react-i18next, Recharts, react-router-dom v7

### 12.1 Directory Structure

```
src/
├── main.tsx                   # Entry point — BrowserRouter wraps App
├── App.tsx                    # Renders <AppRouter />
├── i18n.ts                    # i18next setup — loads en.json + fr.json, default lang: en
├── langStore.ts               # Zustand store — selected language (en|fr), persisted to localStorage
├── routes/
│   └── AppRouter.tsx          # All routes — lazy-loaded, 3 layout sections (see 12.3)
├── components/
│   ├── Layouts/
│   │   ├── EcommerceDashboardLayout.tsx  # Admin dashboard shell — redirects non-admin to /
│   │   ├── EcommerceLayout.tsx           # Public shop shell — Header + Footer + Outlet
│   │   └── LmsLayout.tsx                # LMS shell — LMS Header + Footer + Outlet
│   ├── ecommerceDashboard/    # All dashboard-specific components
│   │   ├── app-sidebar.tsx    # Sidebar nav definition (navMain, navSecondary, documents)
│   │   ├── site-header.tsx    # Top header bar with page title
│   │   ├── nav-user.tsx       # User menu (account, billing, logout — UI only, not wired)
│   │   ├── dashboardComponents/  # Charts, stats cards, last-transactions table
│   │   ├── ordersComponents/     # OrdersTable — uses local data.json (not live API)
│   │   ├── customersComponents/  # ClientsTable + ClientInformationCard
│   │   ├── categoriesComponents/ # CategoriesTable
│   │   ├── brandsComponents/     # BrandsTable
│   │   ├── coursesComponents/    # CoursesTable
│   │   ├── StudentsComponents/   # StudentsTable
│   │   ├── suppliersComponents/  # SuppliersTable
│   │   ├── transactionComponents/# TransactionsTable
│   │   └── products/             # ProductInfo form (Add Product)
│   ├── ecommerceComponents/   # Public shop components (Header, Footer, cards, etc.)
│   └── ui/                    # shadcn/ui primitives
├── pages/
│   ├── dashboardEcommerce/    # Admin dashboard pages (see 12.3)
│   ├── ecommercePages/        # Public shop pages (see 12.3)
│   └── LmsPages/              # LMS pages (see 12.3)
├── hooks/
│   ├── use-api.tsx            # Generic API hook wrapping axiosInstance (get/post/put/del + loading/error)
│   └── use-mobile.ts          # Responsive breakpoint hook
├── stores/
│   └── useUserStore.ts        # Zustand user store — persists to localStorage as "heethr-user"
├── interfaces/                # TypeScript interfaces (see 12.4)
├── lib/
│   ├── axiosInstence.ts       # Axios instance — auto-attaches Bearer token, auto-refreshes on 401
│   └── utils.ts               # shadcn cn() utility
└── locales/
    ├── en.json                # English translations
    └── fr.json                # French translations
```

### 12.2 Environment Variables

| Variable | Required | Notes |
|----------|----------|-------|
| `VITE_BACKEND` | Yes | Backend API base URL — e.g. `http://165.22.200.135:3000` |

**⚠️ Current `.env` points to `http://165.22.200.135:3000` (staging/DO server), not `api.heethr.com`.**

### 12.3 Route Map

**Public shop (`/` → `EcommerceLayout`)**

| Path | Component | Notes |
|------|-----------|-------|
| `/` | `HomePage` | Shop home |
| `/categories` | `CategoryPage` | Category listing |
| `/product` | `ProductPage` | Product detail |
| `/cart` | `CartPage` | Shopping cart |
| `/checkout` | `Checkout` | Checkout flow |

**LMS (`/lms` → `LmsLayout`)**

| Path | Component | Notes |
|------|-----------|-------|
| `/lms` | `HomeLms` | Course catalog with hero + search (static data) |
| `/lms/courses/:id` | `CourseDetail` | Course detail + enroll |
| `/lms/course` | `CourseVideo` | Lesson video player |
| `/lms/assignment` | `Assignment` | Assignment/quiz page |
| `/lms/home` | `EnrolledHome` | Enrolled student home |

**Admin dashboard (`/dashboard` → `EcommerceDashboardLayout`)**
Guard: redirects to `/` if `user.role !== "admin"` (client-side only).

| Path | Component | API Connected? | Notes |
|------|-----------|---------------|-------|
| `/dashboard` | `DashboardHome` | No | Charts + static orders table |
| `/dashboard/order-management` | `OrderManagement` | No | Uses local `data.json` |
| `/dashboard/customers` | `Customers` | No | Static mock data |
| `/dashboard/customers/details` | `CustomerDetails` | Partial | Detail card |
| `/dashboard/categories` | `Categories` | Yes | CRUD — `GET/POST /api/v1/categories` |
| `/dashboard/brands` | `Brands` | Yes | CRUD — `GET/POST /api/v1/brands` |
| `/dashboard/products` | `Products` | No | Placeholder (`<div>Products</div>`) |
| `/dashboard/products/add` | `AddProduct` | Yes | `POST /api/v1/products` with bilingual fields |
| `/dashboard/suppliers` | `Suppliers` | No | Table only |
| `/dashboard/transactions` | `Transactions` | No | Table only |
| `/dashboard/courses` | `Courses` | Yes | `GET /api/v1/courses`; Add Course modal (not wired to API) |
| `/dashboard/students` | `Students` | No | Table only |
| `/dashboard/admins` | `Admins` | No | Placeholder |
| `/dashboard/admins/roles` | `AdminRoles` | No | Placeholder |

### 12.4 State Management

**`useUserStore` (`src/stores/useUserStore.ts`)**
- Zustand store persisted to `localStorage` key `"heethr-user"`
- Shape: `{ user: IUser | null, setUser, resetUser, updateUser, refreshToken }`
- `refreshToken()` calls `POST /api/v1/users/refresh` and updates stored tokens
- ⚠️ `updateUser()` has a bug: saves to `localStorage` key `"user"` instead of `"heethr-user"`

**`useLanguageStore` (`src/langStore.ts`)**
- Zustand store persisted to `localStorage` key `"language"`
- Values: `"en" | "fr"`, default `"fr"`
- Note: `i18n.ts` initializes i18next with default `lng: "en"` — these two defaults are inconsistent

**`useApi` hook (`src/hooks/use-api.tsx`)**
- Thin wrapper around `axiosInstance` exposing `{ get, post, put, del, loading, error }`
- `error` state is typed `null` but set to `any` — not typed strictly

### 12.5 HTTP Client

`src/lib/axiosInstence.ts` (note: typo in filename — "Instence"):
- Base URL: `import.meta.env.VITE_BACKEND`
- Request interceptor: reads `localStorage["heethr-user"]`, injects `Authorization: Bearer <access_token>`
- Response interceptor: on 401, auto-calls `useUserStore.refreshToken()` and retries once (`_retry` flag)
- On refresh failure: calls `resetUser()` (logs out)

### 12.6 Key Interfaces

| Interface | File | Shape |
|-----------|------|-------|
| `IUser` | `interfaces/IUser.ts` | `id`, `access_token`, `refresh_token`, `email`, `role`, `fullname`, `phone_number`, `image?`, `contractor_info?` |
| `IProductFormData` | `interfaces/IProductFormData.ts` | `name{en,fr}`, `description{en,fr}`, `product_number`, `price`, `discount`, `tax`, `quantity`, `brand_id`, `category_id`, `uom`, `options_values[]` |
| `ICategory` | `interfaces/ICategory.ts` | `id`, `name_object{en,fr}`, `name?`, `image` |
| `IBrand` | `interfaces/IBrand.ts` | `id`, `name_object{en,fr}`, `name?`, `image` |
| `ICourse` | `interfaces/ICourse.ts` | `id`, `title?`, `name_object{en,fr}?`, `description`, `category`, `url`, `prerequisites` |
| `IStudent` | `interfaces/IStudent.ts` | `id`, `name`, `progress`, `lastActivity`, `avgScore`, `quizzesTaken`, `quizzesMissed` |

### 12.7 Known Issues & Gaps (dashboard)

| # | File | Issue | Severity |
|---|------|-------|----------|
| 1 | `EcommerceDashboardLayout.tsx` | Auth guard is client-side only (`user.role !== "admin"`) — no token verification | High |
| 2 | `nav-user.tsx` | Sidebar user info is hardcoded (`shadcn` / `m@example.com`) — not wired to real user | High |
| 3 | `useUserStore.ts` | `updateUser()` writes to `localStorage["user"]` instead of `"heethr-user"` | Medium |
| 4 | `i18n.ts` vs `langStore.ts` | Default language mismatch — i18next defaults `en`, langStore defaults `fr` | Medium |
| 5 | `lib/axiosInstence.ts` | Filename typo: `axiosInstence` should be `axiosInstance` | Low |
| 6 | `OrderManagement/index.tsx` | Uses static `data.json` — not connected to backend | Medium |
| 7 | `Customers/index.tsx` | Uses hardcoded mock data — not connected to backend | Medium |
| 8 | `Products/index.tsx` | Placeholder only — `<div>Products</div>` | High |
| 9 | `Admins/index.tsx` | Placeholder only — `<div>Admins</div>` | High |
| 10 | `courses/AddCourseForm.tsx` | Form `handleSubmit` only `console.log`s — not wired to API | Medium |
| 11 | `DashboardHome/index.tsx` | Charts use static data — not connected to backend | Medium |
| 12 | `.env` | `VITE_BACKEND` points to IP `165.22.200.135:3000` not production domain | Low |
