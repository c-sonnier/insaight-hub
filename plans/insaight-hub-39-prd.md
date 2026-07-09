---
issue: https://github.com/c-sonnier/insaight-hub/issues/39
branch: insaight-hub/39
date: 2026-07-09
status: awaiting-approval
authors: [coder, designer]
reviewed_by: dhh
flow: fork-pr
---

# PRD: Allow @mentions in comments (#39)

## Problem

Comments on an insight have no way to pull a specific teammate into the conversation.
You can reply, but the person you want to reach only finds out if they happen to revisit
the insight. Every other collaboration surface (issue trackers, chat, docs) lets you type
`@name` to address and notify someone directly. Insight comments should too.

## The two decisions (issue left these to the dev team)

### Decision 1 — What a mention does: **in-app + email notification** (not highlight-only)

A mention delivers a real notification, reusing the notification stack the app already has
(`Notification` model, `NotifiableFanOut`, ActionCable broadcast, `NotificationsMailer`).

Rationale: highlight-only and notify-on-mention require the *identical* backend work —
resolve the typed token to a `User` in the account. The only thing highlight-only saves is
the delivery call, and the delivery machinery already exists, is used by `NotifyCommentJob`,
and already fans out to in-app + email honoring per-identity preferences with a dedupe guard.
Shipping highlight-only would build the hard part and then deliberately skip the one cheap,
useful step. The notification *is* the point of a mention. Approved simplest-*complete* cut.

### Decision 2 — Who is mentionable: **members of the insight's organization (Account) only**

Comments are `Account`-scoped and `User` *is* the account-membership model
(`belongs_to :account, :identity`). The mentionable set is exactly `current_account.users`.
"All hub users" would leak the existence of identities across tenants (a multi-tenant
boundary violation) and is meaningless — you cannot notify someone who has no access to the
insight. Rejected.

## Mention token (DHH decision — resolved a coder/designer split)

The two research tracks disagreed on token shape. The coder proposed deriving a handle from
the email local-part (`@owner`); the designer proposed an id-carrying token. **Ruling: use the
id-carrying token.** There is no unique username/handle column on `User`/`Identity` today,
and adding one is a migration + uniqueness rule + backfill + profile UI — out of scope for a
first cut. Deriving a handle from the email local-part is functional but (a) leaks the email
local-part into stored comment bodies and (b) fails silently when two members share a local-part
on different domains (the mention resolves to nobody). The id token avoids both.

- **Stored/typed token:** `@[Display Name](u:<user_id>)` — e.g. `@[Ada Lovelace](u:42)`.
  Lives verbatim in `comments.body`; the body stays the single source of truth (no join table,
  no hidden field). The name is a display cache; the id is the resolution key.
- **What the author sees while typing:** they pick a name from the typeahead and the Stimulus
  controller inserts the token. The literal token is briefly visible in the textarea — accepted
  as honest and trivially correct (a pretty in-textarea chip requires a contenteditable rewrite,
  rejected as scope + framework contamination).
- **Resolution (notifications):** `Comment#mentioned_users` extracts ids with
  `/@\[[^\]]*\]\(u:(\d+)\)/` and returns `account.users.where(id: ids)`. Tenant-safe by
  construction: an id belonging to another account resolves to nothing. No fuzzy matching, no
  `substr/instr` SQL, no ambiguity rule.
- **Resolution (rendering):** resolve each id to a `User` in the comment's account; display the
  *current* name (so renames stay fresh), falling back to the cached name in the token if the id
  no longer resolves in that account.

## Backend plan

Files to add or change (fewest files; fat model + existing job, DHH style — no service objects):

| File | Change |
|------|--------|
| `app/models/notification.rb` | Add `comment_mention: "comment_mention"` to `enum :action`. No migration — `action` is a string column and the inclusion validation reads `actions.keys`. |
| `app/models/comment.rb` | Add `MENTION_PATTERN = /@\[[^\]]*\]\(u:(\d+)\)/` and `#mentioned_users` → `account.users.where(id: <parsed ids>)`. `Comment` already `belongs_to :account`. |
| `app/jobs/notify_comment_job.rb` | After the existing owner `deliver(... :comment_created ...)`, fan out mentions: `mentioned = engagement.engageable.mentioned_users.where.not(id: [actor_id, owner&.id].compact)`; `deliver(recipients: mentioned, action: :comment_mention, insight_item:, actor:, comment:) if mentioned.any?`. No new job, no controller change — `Engagement.after_create_commit :notify_insight_owner` already enqueues this job on comment create. |
| `app/mailers/notifications_mailer.rb` | Add `comment_mention(recipient:, actor:, insight_item:, comment:)` — signature must match the other actions because `NotifiableFanOut#deliver` calls `NotificationsMailer.public_send(action, recipient:, actor:, insight_item:, comment:)`. Subject e.g. `"#{actor_name} mentioned you in a comment on \"#{insight_item.title}\""`. Reuse the account-scoped `insight_url`/`preferences_url` helpers (they set `script_name`). |
| `app/views/notifications_mailer/comment_mention.html.erb` + `.text.erb` | New; mirror `comment_created.*`, headline "You were mentioned in a comment". Render the comment body through the plain-text mention formatter (see frontend helper) so the email shows `@Ada Lovelace`, not the raw token. |
| `app/views/notifications/_notification.html.erb` | Add a `when "comment_mention"` branch ("mentioned you in a comment on") and include it in the comment-preview condition alongside `comment_created`. |
| `config/routes.rb` | `resources :members, only: [:index]` → add `collection { get :mentionable }`. (`members_controller.rb` and the `members` resource already exist.) |
| `app/controllers/members_controller.rb` | Add `#mentionable`: `scope = current_account.users.includes(:identity)`; if `params[:q]` present, `joins(:identity).where("identities.name LIKE :q OR identities.email_address LIKE :q", q: "#{params[:q]}%")`; `render json: scope.limit(10).map { { id:, name: } }`. Inherits `AccountScoped` — same-account-only and membership-gated automatically. Returns `id` + `name` only (no handle/email — nothing to leak). |

Data model: **no new table, no new columns.** Mentions are parsed from the body at notify
time and at render time. The durable record of a delivered mention is the `notifications` row
itself (`recipient_id`, `comment_id`, `action: comment_mention`).

Notification wiring reuses `NotifiableFanOut#deliver`, which already: checks
`identity.in_app_notifications?` / `identity.email_notifications?` independently per recipient,
creates the in-app `Notification` (ActionCable-broadcast via `after_create_commit`), enqueues
the mailer, and dedupes via `create_notification`'s
`recipient.notifications.unread.exists?(action:, insight_item:, comment:)` guard.

### Edge cases (all resolved)

- **Self-mention:** author excluded via `where.not(id: actor_id)`.
- **Insight-owner double-notify:** owner already gets `comment_created` from the same job;
  excluded from mention recipients via `where.not(id: owner.id)`. Owner gets exactly one
  notification for a comment that also @-mentions them.
- **Cross-account:** `mentioned_users` queries only `account.users`; a foreign id resolves to nothing.
- **Per-identity prefs:** honored free by `deliver`.
- **Job retry / double callback:** suppressed by the existing unread-exists guard, per recipient.
- **Comment deletion:** `Comment has_many :notifications, dependent: :destroy` cleans up mention rows.
- **Editing a comment to add a mention:** notifications fire on create only (job is on
  `after_create_commit`). Editing renders the chip but does **not** notify in v1 — see scope note.

## Frontend plan

Files to add or change:

| File | Change |
|------|--------|
| `app/javascript/controllers/mentions_controller.js` | New Stimulus controller; auto-registers via `pin_all_from "app/javascript/controllers"` (no importmap edit, no npm build). |
| `app/helpers/mention_helper.rb` | New. `render_comment_body(comment)` (HTML, XSS-safe) and a plain-text variant for emails. |
| `app/views/comments/_form.html.erb` | Wrap with `data-controller="mentions"` + `data-mentions-url-value`, add textarea targets/actions, add the dropdown `<ul>`. Used by both the new-comment and reply forms (typeahead comes free in replies). |
| `app/views/comments/_comment.html.erb` | Replace `simple_format(comment.body, ...)` with `render_comment_body(comment)`. |

### Typeahead — `mentions_controller.js`

- `static targets = ["input", "list"]`
- `static values = { url: String, minChars: { type: Number, default: 0 }, debounce: { type: Number, default: 150 } }`
- Attach to the form/wrapper; the textarea gets
  `data-mentions-target="input"` and
  `action: "input->mentions#onInput keydown->mentions#onKeydown blur->mentions#onBlur"`.
  The dropdown is a `<ul data-mentions-target="list" role="listbox">` in a `relative` wrapper
  right under the textarea, `absolute w-full max-w-xs max-h-60 overflow-y-auto z-50 hidden`.
- **onInput:** from `selectionStart`, scan back to the nearest `@` at string-start or preceded by
  whitespace with no whitespace between it and the caret → that's the query. Debounced
  `fetch(url + "?q=" + encodeURIComponent(query), { headers: { Accept: "application/json" }, credentials: "same-origin" })`.
  Store the `@`-start index for insertion.
- **render:** `<li role="option" id="mention-opt-{id}">` rows showing the name; `activeIndex`
  default 0; set `aria-activedescendant` on the textarea; highlight active row `bg-base-200`.
  No avatars in v1 (the avatar helper renders HTML from a user object, not a URL — names only).
- **onKeydown (list open only):** Arrow up/down move + wrap (`preventDefault`); Enter **and** Tab
  select active option (`preventDefault` so Enter doesn't submit / insert newline); Escape closes.
  List closed → do nothing (normal typing/submit).
- **select:** replace `[atIndex, caret]` in the value with `@[Name](u:id) ` (trailing space),
  restore caret after the token, dispatch an `input` event, close.
- **click:** delegated `mousedown` on the list (fires before blur) → select.
- **onBlur:** `close()` on a short `setTimeout` (matches the `setTimeout` pattern in
  `comments_controller.js`) so a `mousedown` selection lands first.
- Dropdown anchors to the textarea (not the caret) — no caret-coordinate math, which is the
  trap that forces heavyweight combobox libs. Works identically in the comments drawer.

### Rendering a mention (XSS-safe) — `mention_helper.rb`

Order of operations is the whole security story: **escape first, then inject known-safe markup.**

1. `simple_format(comment.body, { class: "..." })` — escapes the raw body (any literal
   `<script>` becomes `&lt;script&gt;`) and returns an `html_safe` buffer.
2. Split the escaped buffer on the token regex `/@\[([^\]]+)\]\(u:(\d+)\)/`. Token chars
   `[](): ` are not HTML-special, so they survive escaping intact and the regex matches reliably.
3. Rebuild with `safe_join`: non-matched segments are the already-escaped `SafeBuffer` slices;
   matched segments become a `content_tag(:span, "@#{display_name}", class: "badge badge-primary badge-sm align-baseline")`.
   Resolve `u:id` to a `User` in `comment.account`; use its current name, else the token's cached
   name (`CGI.unescapeHTML` the captured group). `content_tag` escapes the name argument, so the
   visible glyphs are escaped exactly once — no double-escape, no injection.
4. **Chip is a non-navigating `<span>`, not a link** — there is no public user-profile route
   (only self `profile` and admin-namespaced `users`). A profile link is a possible follow-up.

Every byte that reaches the browser unescaped is either `simple_format`'s own `<p>/<br>`, our
literal daisyui class strings, or `content_tag`-generated markup whose text is escaped. No
user-originated byte is ever emitted raw.

The plain-text variant (for `comment_mention`/`comment_created` emails) reduces each token to
`@Name` so the email body reads naturally.

### States / responsive

- Loading: a single disabled "Searching…" row (debounced 150ms).
- Empty query (`@` just typed, `minChars: 0`): fetch with empty `q` returns the first N account
  members so `@` immediately suggests.
- No match: one non-selectable "No people found" row; Enter does nothing, does not submit.
- Dismiss: Escape, blur, selection, or deleting past the `@`.
- Drawer/small screens: `absolute w-full max-w-xs z-50` list scrolls internally (`max-h-60`),
  stays within the column, never forces horizontal page scroll.

## Scope for v1 (explicit)

- Typeahead is wired on the **create and reply** forms (shared `_form.html.erb`). The **edit**
  form (`_edit_form.html.erb`) is **not** wired with the typeahead, because editing does not
  send notifications in v1 — we don't ship UI that implies a notification it won't send. Existing
  mention tokens still render as chips in edited bodies and everywhere else.
- No user-chosen handles/usernames (id token needs none).
- Mention chip does not link anywhere (no profile route exists).

## Verification oracle

### Backend — Minitest (repo uses fixtures + minitest; fixtures in `test/fixtures/`)

`test/controllers/members_controller_test.rb` (new):
1. `GET /members/mentionable.json` as a default-account member returns only default-account users;
   no user from another account appears.
2. `?q=` filters by name/email prefix.
3. Unauthenticated request is blocked by the `AccountScoped` membership gate.

`test/models/comment_test.rb` (extend):
4. Body `"hey @[Member User](u:<member_id>) look"` in the default account → `#mentioned_users`
   == `[member_user]`.
5. Body with `u:<id>` of a user in another account → `#mentioned_users` empty (no leak).
6. Body with a non-existent id → empty.

`test/jobs/notify_comment_job_test.rb` (extend):
7. Comment by member mentioning themselves → no `comment_mention` notification for the author.
8. Comment by member mentioning a third member (not the insight owner) → exactly one
   `comment_mention` for that member; owner still gets their one `comment_created`.
9. Comment by member mentioning the insight owner → owner gets `comment_created` and **zero**
   `comment_mention` (no double-notify).
10. Prefs: mentioned identity with `email_notifications: false` → in-app row created,
    `assert_no_enqueued_emails` for the mention; with `in_app_notifications: false` → email
    enqueued, no in-app row.
11. Idempotency: run the job twice for the same mentioning engagement →
    `assert_difference "Notification.count"` on run 1, `assert_no_difference` on run 2.

`test/mailers/notifications_mailer_test.rb` (extend):
12. `comment_mention(...)` renders with `to == recipient.email_address` and subject containing
    "mentioned you"; body shows `@Name`, not the raw token.

### Frontend — system test (Capybara) / manual pass

13. Typing `@` opens a `role="listbox"` of account members; typing narrows it; a non-match shows
    "No people found".
14. A member of a different account never appears in the list.
15. Arrow keys move the highlight and update `aria-activedescendant`; Enter selects and does **not**
    submit or insert a newline; Escape closes; click selects.
16. Selecting "Ada Lovelace" inserts `@[Ada Lovelace](u:42) ` with the caret after it.
17. The posted comment shows a `badge badge-primary` chip reading `@Ada Lovelace` (not the raw token).
18. Posting a body of `<script>alert(1)</script> hi @[Ada Lovelace](u:42)` renders the script as
    visible escaped text (no alert, no `<script>` in the DOM) and still renders the chip.
19. A token with an unresolved/foreign id renders as a plain non-link chip — no 500, no broken href.
20. Typeahead works in a reply form and in the comments drawer on a narrow viewport without
    horizontal page scroll.

## Ordered task breakdown

| # | Task | Owner |
|---|------|-------|
| 1 | Add `comment_mention` to the `Notification` action enum | coder |
| 2 | `Comment::MENTION_PATTERN` + `#mentioned_users` (account-scoped by id) | coder |
| 3 | `members#mentionable` JSON endpoint + route | coder |
| 4 | Extend `NotifyCommentJob` to fan out `comment_mention` (exclude actor + owner) | coder |
| 5 | `NotificationsMailer#comment_mention` + mailer views + `_notification.html.erb` branch | coder |
| 6 | `mention_helper.rb` — `render_comment_body` (HTML, XSS-safe) + plain-text variant | designer |
| 7 | `mentions_controller.js` Stimulus typeahead | designer |
| 8 | Wire `_form.html.erb` (create + reply); swap `_comment.html.erb` to `render_comment_body` | designer |
| 9 | Backend tests (oracle 1–12) | coder |
| 10 | System test (oracle 13–20) | designer |

## Open questions (business only — technical questions resolved by research)

1. **Handles/usernames later?** v1 uses id tokens and exposes no handle or email — this is
   *better* for privacy than a handle scheme. Only revisit if the product wants vanity `@names`;
   that's a follow-up (add `handle` to `Identity` + account-scoped uniqueness + profile UI).
2. **Notify when a mention is added by *editing* a comment?** v1 notifies on create only. Confirm
   that's acceptable for the first cut.
3. **Should a mention chip link to a user profile?** No public profile page exists today, so v1
   renders a non-navigating chip. Confirm, or greenlight a follow-up profile route.
