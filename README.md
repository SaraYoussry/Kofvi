# Kofvi website + Content Planner

This repo serves two things on GitHub Pages:

- **kofvi.com** (root `index.html` + `assets/`): the Kofvi shop homepage. Buyers purchase on Etsy (kofvi.etsy.com).
- **kofvi.com/planner/** (`planner/index.html`): the "My planners" hub. It lists every web app planner, shows which ones the signed-in account has unlocked, and links to each demo.
- **kofvi.com/planner/social/** (`planner/social/`): the Kofvi Content Planner. Demo with no sign-in: `/planner/social/?demo`.

## Content Planner

A scrapbook-style social media planner that runs in the browser. Buyers sign in with an email link, and their plan and photos sync to their own private account on every device.

- **App:** `planner/social/index.html` (built) + `planner/config.js` (public Supabase settings, shared by every planner)
- **Source:** `app/src.html` and `app/assets.js`. After editing, run `python3 build.py` to rebuild `planner/social/index.html`.
- **Database:** `supabase/migrations/` (run the files in date order). Product id: `social-media-planner`.

## One-time setup

1. **Database.** In Supabase, open **SQL Editor**, paste the whole migration file and press **Run** (skip this if the Supabase GitHub integration already applied it).
2. **Keys.** In Supabase, go to **Project Settings > API** and copy the **Project URL** and the **anon / publishable** key into `planner/config.js`. Never use the service_role or secret key.
3. **Sign-in links.** In Supabase, go to **Authentication > URL Configuration**:
   - Site URL: `https://kofvi.com/planner/`
   - Redirect URLs: add `https://kofvi.com/planner/**` (covers the hub and every planner).
4. **Hosting.** GitHub repo **Settings > Pages**: deploy from branch `main`, folder `/ (root)`.
5. **Custom domain.** The `CNAME` file sets `kofvi.com`. At Namecheap (Advanced DNS) delete the Shopify records (A `@` 23.227.38.65, CNAME `www` shops.myshopify.com) and add A `@` 185.199.108.153, 185.199.109.153, 185.199.110.153, 185.199.111.153 and CNAME `www` sarayoussry.github.io. In **Settings > Pages > Custom domain** type `kofvi.com`, then tick **Enforce HTTPS** once the check passes.

## Access codes

Each planner has its own access code (printed in its Etsy download PDF). A new buyer needs a code to create an account. A signed-in buyer can enter another planner's code to unlock that planner on the same account. Returning buyers only need their email.

In Supabase **SQL Editor**:

```sql
-- add a new code
insert into public.access_codes (code, product, note) values ('KOFVI-NEW-CODE', 'social-media-planner', 'Etsy PDF v2');
-- retire an old code (existing accounts keep working)
update public.access_codes set active = false where code = 'KOFVI-SOCIAL-2027';
```
