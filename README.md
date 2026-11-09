# Kofvi Content Planner

A scrapbook-style social media planner that runs in the browser. Buyers sign in with an email link, and their plan and photos sync to their own private account on every device.

- **App:** `index.html` (built) + `config.js` (public Supabase settings)
- **Source:** `app/src.html` and `app/assets.js`. After editing, run `python3 build.py` to rebuild `index.html`.
- **Database:** `supabase/migrations/20261109000000_planner_init.sql`

## One-time setup

1. **Database.** In Supabase, open **SQL Editor**, paste the whole migration file and press **Run** (skip this if the Supabase GitHub integration already applied it).
2. **Keys.** In Supabase, go to **Project Settings > API** and copy the **Project URL** and the **anon / publishable** key into `config.js`. Never use the service_role or secret key.
3. **Sign-in links.** In Supabase, go to **Authentication > URL Configuration**:
   - Site URL: the address of the app (for example `https://planner.kofvi.com/`)
   - Redirect URLs: add the same address, plus `https://sarayoussry.github.io/Kofvi/` while testing.
4. **Hosting.** GitHub repo **Settings > Pages**: deploy from branch `main`, folder `/ (root)`.
5. **Custom domain (optional).** At your domain registrar, add a `CNAME` record: name `planner`, value `sarayoussry.github.io`. Then type `planner.kofvi.com` in **Settings > Pages > Custom domain** and tick **Enforce HTTPS**.

## Access codes

New buyers need an access code (printed in the Etsy download PDF) to create an account. Returning buyers only need their email.

In Supabase **SQL Editor**:

```sql
-- add a new code
insert into public.access_codes (code, note) values ('KOFVI-NEW-CODE', 'Etsy PDF v2');
-- retire an old code (existing accounts keep working)
update public.access_codes set active = false where code = 'KOFVI-SOCIAL-2027';
```
