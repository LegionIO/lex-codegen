# Changelog

## [0.2.0] - 2026-03-26

### Added
- `Helpers::TierClassifier` for gap complexity classification (simple vs complex) based on occurrence count thresholds
- `Helpers::GeneratedRegistry` with `Legion::Data::Local` persistence for tracking generated functions with status, tier, confidence, and usage metrics
- `Runners::FromGap` with tiered code generation: routes simple gaps to runner method generation and complex gaps to full extension scaffolding via `Runners::Generate`
- `Runners::ReviewHandler` for validation verdict processing: approve, reject, retry (with max-retry guard), and park actions against `GeneratedRegistry`
- `Actor::GapSubscriber` AMQP subscription actor with Apollo corroboration for gap priority boosting before generation
- `Actor::ReviewSubscriber` AMQP subscription actor for routing review verdicts to `ReviewHandler`
- Transport layer: `Exchanges::Codegen`, `Queues::GapQueue`, `Queues::ReviewQueue`, `Messages::GenerateFromGap`, `Messages::ReviewResult`
- `Legion::Data::Local` migration for `generated_functions` table with status, gap, tier, confidence, attempt count, and usage columns

## [0.1.5] - 2026-03-26

### Added
- `Helpers::GeneratedRegistry` — in-memory (and optional `Legion::Data::Local` SQLite) registry for tracking generated functions: `persist`, `list`, `get`, `update_status`, `record_usage`, `load_on_boot`, `reset!`
- `local_migrations/20260326000001_create_generated_functions.rb` — Sequel migration for the `generated_functions` table with status/gap/tier/confidence/usage columns

## [0.1.4] - 2026-03-23

### Changed
- `AutoFix#auto_fix` passes `caller: { extension: 'lex-codegen', operation: 'auto_fix' }` and `intent: { capability: :reasoning }` to `Legion::LLM.chat` for attribution and model routing

## [0.1.3] - 2026-03-22

### Changed
- Add runtime dependencies: legion-cache, legion-crypt, legion-data, legion-json, legion-logging, legion-settings, legion-transport
- Replace Legion::Logging stub in spec_helper with real sub-gem requires
- Add Helpers::Lex stub to spec_helper for standalone spec runs
- Update auto_fix_spec to use hide_const for Legion::Data::Local unavailability contexts

## [0.1.2] - 2026-03-20

### Added
- `codegen_fixes` table migration for self-healing pipeline tracking
- `Runners::AutoFix` for LLM-powered automated extension repair with git branch creation and spec validation
- Migration registration via `Legion::Data::Local.register_migrations`

## [0.1.0] - 2026-03-13

### Added
- Initial release
