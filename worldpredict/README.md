# WorldPredict PWA

Production-ready Progressive Web App for world event predictions with parental monitoring.

## Quick Start

1. **Supabase Setup** (REQUIRED):
   - Go to https://nfvkxdgcfqakfvzbwnyh.supabase.co
   - Run SQL from `/supabase/schema.sql`
   - Enable Row Level Security with `/supabase/rls.sql`
   - Auth > Settings: Confirm email/password providers enabled

2. **Local Test**:
   ```
   # Open in browser
   c:/project/parent retry/worldpredict/index.html
   ```

3. **Deploy to Netlify**:
   - Drag `worldpredict/` folder to https://app.netlify.com/drop
   - OR `netlify deploy --prod --dir=worldpredict`

4. **Environment**:
   No server-side env needed. Frontend uses Supabase public anon key.

## Features
- PWA: Offline, installable
- Roles: User (child), Parent
- Auth: Email/password + child_code linking
- Dashboards, predictions, activity logs
- Responsive gaming UI

## Supabase Config (already in JS)
```
URL: https://nfvkxdgcfqakfvzbwnyh.supabase.co
Anon key: sb_publishable_ZYCsRSUnTyd49_BtlPnI4Q_M6KY20Qd
```

Enjoy predicting the future! 🚀
