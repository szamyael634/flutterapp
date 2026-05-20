# Mama's Kitchen

Sustainable food marketplace MVP built with Flutter and Supabase.

## What is included

- Riverpod-based Flutter app scaffold for buyer, seller, and rider roles
- Supabase-authenticated role gating and profile loading
- Buyer marketplace, cart, checkout, orders, and notifications flows
- Seller store setup, document submission, product creation, and recommendation actions
- Rider delivery request claiming and status updates
- Local Supabase migration and Edge Function sources for payments and sustainability logic

## Flutter run configuration

Run the app with Dart defines so the Supabase project and keys stay out of the repo:

```bash
flutter run ^
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co ^
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxx ^
  --dart-define=APP_SCHEME=mamaskitchen ^
  --dart-define=APP_HOST=login-callback
```

## Supabase setup

1. Create or restore a Supabase project.
2. Apply the SQL in [supabase/migrations/202605210001_mamas_kitchen_schema.sql](supabase/migrations/202605210001_mamas_kitchen_schema.sql).
3. Deploy the Edge Functions under `supabase/functions/`.
4. Add secrets to Supabase:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY` or publishable key equivalent for function-side user verification
   - `SUPABASE_SERVICE_ROLE_KEY`
   - `PAYMONGO_SECRET_KEY`
   - `PAYMONGO_WEBHOOK_SECRET`
   - `VERYFI_CLIENT_ID`
   - `VERYFI_USERNAME`
   - `VERYFI_API_KEY`
   - `VERYFI_CLIENT_SECRET`
   - `APP_BASE_URL`

## PayMongo notes

- Keep PayMongo secret and webhook secrets in Supabase secrets only.
- Do not commit real secret keys.
- Treat the test secret in the original PRD as compromised and rotate it before use.
- Keep Veryfi credentials in Supabase Edge Function secrets as well; do not embed them in Flutter client code.

## Current limitation

This environment does not currently have `flutter` or `dart` available on PATH, so the code was scaffolded and reviewed statically but not executed here.
