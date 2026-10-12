## 2026-10-06 - Accessible IconButtons with Tooltips
**Learning:** Icon-only buttons (such as modal close icons and password visibility toggle icons) without explicit `tooltip` properties lack semantic descriptions for screen readers (TalkBack/VoiceOver) and hover hints on web/desktop.
**Action:** Always provide explicit `tooltip` parameters for `IconButton`s, including dynamic tooltips for stateful toggle buttons (e.g. `_obscurePassword ? 'Show password' : 'Hide password'`).
