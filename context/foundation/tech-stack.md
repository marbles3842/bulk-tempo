---
starter_id: flutter
package_manager: pub
project_name: bulk-tempo
hints:
  language_family: dart
  team_size: solo
  deployment_target: playstore
  ci_provider: github-actions
  ci_default_flow: auto-deploy-on-merge
  bootstrapper_confidence: verified
  path_taken: standard
  quality_override: false
  self_check_answers: null
  has_auth: true
  has_payments: false
  has_realtime: false
  has_ai: false
  has_background_jobs: false
---

## Why this stack

Flutter is the verified, typed, convention-based starter for this small Dart mobile project and its five-week after-hours MVP. The first release targets Google Play, with GitHub Actions and automatic deployment on merge. The product needs separate email-and-password accounts and private data available across devices; Firebase Authentication and Firebase cloud storage are the user's chosen services for those needs. The Flutter starter does not include that integration, so it must be added after scaffolding. AI guidance remains outside the required MVP.
