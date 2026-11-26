# Secrets and keys

Step `secrets` on the Shipyard board. Done means: every key is listed with where it lives and what
uses it, none is in a repo, and leaked keys are rotated.

Checked on 26 November 2026. This file lists names and places only. **Never write a key's value here.**

## What Haven Notes has

Haven is built to need almost none: the app has no third-party SDK and no server of its own in
production, and the website is static.

| Piece | Keys it uses | Where they live |
|---|---|---|
| iOS and macOS app | None of its own. Purchases go through StoreKit 2 with Apple directly; there is no analytics, crash or payment SDK | Nothing to store |
| Website (`docs/`, Astro, Vercel project `havennotes`) | None. No environment variables in code, and the Vercel project has none set (`vercel env ls`, 26 Nov 2026) | Nothing to store |
| Sync server (`haven-sync-server/`, outside this repo, not deployed anywhere) | `JWT_SECRET` (signs sync sessions), plus the plain settings `PORT` and `DB_PATH` | Only `.env.example` exists, with placeholder values. If the server is ever deployed, `JWT_SECRET` goes in the host's secret store, never in a file that is committed |
| Old landing page (`haven-landing/`, outside this repo) | None. Its email form posts to Buttondown's public embed address for the list `haven` | The Buttondown account itself is a login, below |

## Secret: the Apple account (shared by every app on team T592C9M4H4)

The App Store Connect API key, the signing certificates and the Apple Account itself are the same
for every app on the team (Restitute, DuetWallet, Snuff Out and DayQuota among them). They are listed once, in
Restitute's `ops/secrets.md` ("Secret: the Apple account"), with where each lives and what uses it.
Haven adds nothing to that list: it has no RevenueCat project, so no in-app purchase key is held by
a third party.

## Logins (no key on disk; the owner holds them)

| Account | Used for |
|---|---|
| GitHub (`alynius`) | This repo |
| Vercel (team `younes-projects-7f9bcd2a`) | Hosting and DNS for havennotes.app; deploys run from the CLI with the owner's local login |
| Hostinger | Registrar for havennotes.app |
| Buttondown | The `haven` email list from the old landing page |

## Checks

- No key in the repo: `git grep` for common key formats (Stripe, RevenueCat, Aptabase, AWS, private-key
  blocks, `api_key = "..."`) finds nothing in tracked files (26 Nov 2026).
- `.env` files are ignored by `.gitignore`, so a future server key can't be committed by accident.
- Nothing has leaked, so nothing needs rotating.

## Left to do (the owner)

- Confirm each login above is in a password manager with two-factor sign-in on.
- If the sync server is deployed (the open question on the board), generate `JWT_SECRET` on the host
  and add a row here saying where it lives.
